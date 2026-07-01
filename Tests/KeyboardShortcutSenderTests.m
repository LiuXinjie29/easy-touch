#import <Foundation/Foundation.h>
#import "ETKeyboardShortcutSender.h"
#import "ETShortcutBindingRecorder.h"
#import "ETThreeFingerTouchHandler.h"

static const CGKeyCode ETKeyCodeK = 40;

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

static void testRecordedKeyboardInputBindsToThreeFingerTouch(void) {
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];
    ETSpyKeyboardEventPoster *eventPoster = [[ETSpyKeyboardEventPoster alloc] init];
    ETKeyboardShortcutSender *sender = [[ETKeyboardShortcutSender alloc] initWithEventPoster:eventPoster];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];
    CGEventFlags flags = kCGEventFlagMaskCommand | kCGEventFlagMaskShift;

    [recorder beginRecording];
    BOOL consumed = [recorder handleKeyDownWithKeyCode:ETKeyCodeK flags:flags];
    [sender updateShortcutBinding:recorder.recordedBinding];
    [handler updateWithTouchingFingerCount:3];

    ETAssert(consumed, @"Recording should consume the typed shortcut before binding it.");
    ETAssert(eventPoster.postCount == 1, @"Three-finger touch should send the recorded keyboard shortcut.");
    ETAssert(eventPoster.lastKeyCode == ETKeyCodeK, @"Three-finger touch should send the recorded key.");
    ETAssert((eventPoster.lastFlags & flags) == flags, @"Three-finger touch should send the recorded modifiers.");
}

int main(void) {
    @autoreleasepool {
        testRecordedKeyboardInputBindsToThreeFingerTouch();
        puts("KeyboardShortcutSenderTests passed");
    }
    return 0;
}
