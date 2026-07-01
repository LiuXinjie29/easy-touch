#import "ETGlobalTrackpadTouchMonitor.h"
#import <dlfcn.h>

typedef void *ETMTDeviceRef;
typedef int (*ETMTContactCallbackFunction)(int device, void *touches, int touchCount, double timestamp, int frame);
typedef CFArrayRef (*ETMTDeviceCreateListFunction)(void);
typedef void (*ETMTRegisterContactFrameCallbackFunction)(ETMTDeviceRef device, ETMTContactCallbackFunction callback);
typedef void (*ETMTDeviceStartFunction)(ETMTDeviceRef device, int mode);
typedef void (*ETMTDeviceStopFunction)(ETMTDeviceRef device);

static __weak ETGlobalTrackpadTouchMonitor *ETActiveGlobalTrackpadTouchMonitor;

static int ETGlobalTrackpadContactFrameCallback(int device, void *touches, int touchCount, double timestamp, int frame) {
    (void)device;
    (void)touches;
    (void)timestamp;
    (void)frame;

    if (touchCount < 0) {
        touchCount = 0;
    }
    [ETActiveGlobalTrackpadTouchMonitor multitouchDeviceDidUpdateTouchingFingerCount:(NSUInteger)touchCount];
    return 0;
}

@interface ETGlobalTrackpadTouchMonitor ()
@property (nonatomic, strong) ETThreeFingerTouchHandler *touchHandler;
@property (nonatomic, assign) void *multitouchSupportHandle;
@property (nonatomic, assign) CFArrayRef devices;
@property (nonatomic, assign) ETMTDeviceStopFunction MTDeviceStop;
@property (nonatomic, assign, getter=isStarted) BOOL started;
@end

@implementation ETGlobalTrackpadTouchMonitor

- (instancetype)initWithTouchHandler:(ETThreeFingerTouchHandler *)touchHandler {
    self = [super init];
    if (self != nil) {
        _touchHandler = touchHandler;
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

- (BOOL)start {
    if (self.isStarted) {
        return YES;
    }

    void *handle = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_LAZY);
    if (handle == NULL) {
        return NO;
    }

    ETMTDeviceCreateListFunction MTDeviceCreateList = (ETMTDeviceCreateListFunction)dlsym(handle, "MTDeviceCreateList");
    ETMTRegisterContactFrameCallbackFunction MTRegisterContactFrameCallback = (ETMTRegisterContactFrameCallbackFunction)dlsym(handle, "MTRegisterContactFrameCallback");
    ETMTDeviceStartFunction MTDeviceStart = (ETMTDeviceStartFunction)dlsym(handle, "MTDeviceStart");
    ETMTDeviceStopFunction MTDeviceStop = (ETMTDeviceStopFunction)dlsym(handle, "MTDeviceStop");

    if (MTDeviceCreateList == NULL || MTRegisterContactFrameCallback == NULL || MTDeviceStart == NULL || MTDeviceStop == NULL) {
        dlclose(handle);
        return NO;
    }

    CFArrayRef devices = MTDeviceCreateList();
    if (devices == NULL || CFArrayGetCount(devices) == 0) {
        if (devices != NULL) {
            CFRelease(devices);
        }
        dlclose(handle);
        return NO;
    }

    ETActiveGlobalTrackpadTouchMonitor = self;
    self.multitouchSupportHandle = handle;
    self.devices = devices;
    self.MTDeviceStop = MTDeviceStop;

    CFIndex deviceCount = CFArrayGetCount(devices);
    for (CFIndex index = 0; index < deviceCount; index += 1) {
        ETMTDeviceRef device = (ETMTDeviceRef)CFArrayGetValueAtIndex(devices, index);
        MTRegisterContactFrameCallback(device, ETGlobalTrackpadContactFrameCallback);
        MTDeviceStart(device, 0);
    }

    self.started = YES;
    return YES;
}

- (void)stop {
    if (!self.isStarted) {
        return;
    }

    CFIndex deviceCount = CFArrayGetCount(self.devices);
    for (CFIndex index = 0; index < deviceCount; index += 1) {
        ETMTDeviceRef device = (ETMTDeviceRef)CFArrayGetValueAtIndex(self.devices, index);
        self.MTDeviceStop(device);
    }

    if (ETActiveGlobalTrackpadTouchMonitor == self) {
        ETActiveGlobalTrackpadTouchMonitor = nil;
    }
    if (self.devices != NULL) {
        CFRelease(self.devices);
        self.devices = NULL;
    }
    if (self.multitouchSupportHandle != NULL) {
        dlclose(self.multitouchSupportHandle);
        self.multitouchSupportHandle = NULL;
    }

    self.MTDeviceStop = NULL;
    self.started = NO;
}

- (void)multitouchDeviceDidUpdateTouchingFingerCount:(NSUInteger)touchingFingerCount {
    [self.touchHandler updateWithTouchingFingerCount:touchingFingerCount];
}

@end
