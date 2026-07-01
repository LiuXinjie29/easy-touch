#import <Foundation/Foundation.h>
#import "ETKeyboardShortcutSender.h"
#import "ETThreeFingerTouchHandler.h"

@interface ETGlobalTrackpadTouchMonitor : NSObject
- (instancetype)initWithTouchHandler:(ETThreeFingerTouchHandler *)touchHandler;
- (void)multitouchDeviceDidUpdateTouchingFingerCount:(NSUInteger)touchingFingerCount;
@end

@interface ETSpyKeyboardEventPoster : NSObject <ETKeyboardEventPosting>
@property (nonatomic, assign) NSUInteger postCount;
@property (nonatomic, assign) CGKeyCode lastKeyCode;
@property (nonatomic, assign) CGEventFlags lastFlags;
@end

@implementation ETSpyKeyboardEventPoster
- (void)postKeyPressWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags {
    self.postCount += 1;
    self.lastKeyCode = keyCode;
    self.lastFlags = flags;
}
@end

static void ETAssert(BOOL condition, NSString *message) {
    if (!condition) {
        [NSException raise:@"ETTestFailure" format:@"%@", message];
    }
}

static void testGlobalTrackpadMonitorTriggersKeyboardInputForThreeFingerTouch(void) {
    ETSpyKeyboardEventPoster *eventPoster = [[ETSpyKeyboardEventPoster alloc] init];
    ETKeyboardShortcutSender *sender = [[ETKeyboardShortcutSender alloc] initWithEventPoster:eventPoster];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];
    ETGlobalTrackpadTouchMonitor *monitor = [[ETGlobalTrackpadTouchMonitor alloc] initWithTouchHandler:handler];

    [monitor multitouchDeviceDidUpdateTouchingFingerCount:3];

    ETAssert(eventPoster.postCount == 1, @"Global trackpad monitor should request keyboard input for a three-finger touch.");
    ETAssert(eventPoster.lastKeyCode == 1, @"Global trackpad monitor should input the S key for a three-finger touch.");
    ETAssert((eventPoster.lastFlags & kCGEventFlagMaskAlternate) == kCGEventFlagMaskAlternate, @"Global trackpad monitor should input with the Option modifier.");
}

int main(void) {
    @autoreleasepool {
        testGlobalTrackpadMonitorTriggersKeyboardInputForThreeFingerTouch();
        puts("GlobalTrackpadTouchMonitorTests passed");
    }
    return 0;
}
