#import "ETShortcutBindingRecorder.h"

static CGEventRef ETShortcutBindingRecorderEventTapCallback(CGEventTapProxy proxy,
                                                            CGEventType type,
                                                            CGEventRef event,
                                                            void *userInfo);

@implementation ETShortcutBinding

- (instancetype)initWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags {
    self = [super init];
    if (self != nil) {
        _keyCode = keyCode;
        _flags = flags;
    }
    return self;
}

@end

@interface ETShortcutBindingRecorder ()
@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, assign, getter=isSystemEventTapActive) BOOL systemEventTapActive;
@property (nonatomic, strong, nullable) ETShortcutBinding *recordedBinding;
@property (nonatomic, copy, nullable) ETShortcutBindingRecorderCompletion completion;
@property (nonatomic, assign, nullable) CFMachPortRef eventTap;
@property (nonatomic, assign, nullable) CFRunLoopSourceRef eventTapRunLoopSource;
@end

@implementation ETShortcutBindingRecorder

- (void)dealloc {
    [self stopSystemEventTap];
}

- (BOOL)beginRecording {
    return [self beginRecordingWithCompletion:nil];
}

- (BOOL)beginRecordingWithCompletion:(nullable ETShortcutBindingRecorderCompletion)completion {
    [self stopSystemEventTap];
    self.recording = YES;
    self.completion = completion;
    return [self startSystemEventTap];
}

- (void)cancelRecording {
    [self stopSystemEventTap];
    self.recording = NO;
    self.completion = nil;
}

- (BOOL)handleKeyDownWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags {
    if (!self.isRecording) {
        return NO;
    }

    ETShortcutBinding *binding = [[ETShortcutBinding alloc] initWithKeyCode:keyCode flags:flags];
    ETShortcutBindingRecorderCompletion completion = self.completion;

    self.recordedBinding = binding;
    self.recording = NO;
    self.completion = nil;
    [self stopSystemEventTap];

    if (completion != nil) {
        completion(binding);
    }

    return YES;
}

- (BOOL)startSystemEventTap {
    CGEventMask keyDownMask = CGEventMaskBit(kCGEventKeyDown);
    CFMachPortRef eventTap = CGEventTapCreate(kCGHIDEventTap,
                                              kCGHeadInsertEventTap,
                                              kCGEventTapOptionDefault,
                                              keyDownMask,
                                              ETShortcutBindingRecorderEventTapCallback,
                                              (__bridge void *)self);
    if (eventTap == NULL) {
        self.systemEventTapActive = NO;
        return NO;
    }

    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    if (runLoopSource == NULL) {
        CFRelease(eventTap);
        self.systemEventTapActive = NO;
        return NO;
    }

    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);

    self.eventTap = eventTap;
    self.eventTapRunLoopSource = runLoopSource;
    self.systemEventTapActive = YES;
    return YES;
}

- (void)stopSystemEventTap {
    if (self.eventTap != NULL) {
        CGEventTapEnable(self.eventTap, false);
    }

    if (self.eventTapRunLoopSource != NULL) {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), self.eventTapRunLoopSource, kCFRunLoopCommonModes);
        CFRelease(self.eventTapRunLoopSource);
        self.eventTapRunLoopSource = NULL;
    }

    if (self.eventTap != NULL) {
        CFRelease(self.eventTap);
        self.eventTap = NULL;
    }

    self.systemEventTapActive = NO;
}

@end

static CGEventRef ETShortcutBindingRecorderEventTapCallback(CGEventTapProxy proxy,
                                                            CGEventType type,
                                                            CGEventRef event,
                                                            void *userInfo) {
    (void)proxy;

    ETShortcutBindingRecorder *recorder = (__bridge ETShortcutBindingRecorder *)userInfo;
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        if (recorder.eventTap != NULL) {
            CGEventTapEnable(recorder.eventTap, true);
        }
        return event;
    }

    if (type != kCGEventKeyDown) {
        return event;
    }

    CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    CGEventFlags flags = CGEventGetFlags(event);
    if ([recorder handleKeyDownWithKeyCode:keyCode flags:flags]) {
        return NULL;
    }

    return event;
}
