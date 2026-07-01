#import <Foundation/Foundation.h>
#import "ETKeyboardShortcutSender.h"
#import "ETThreeFingerTouchHandler.h"

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

static void testThreeFingerTouchPostsKeyboardInput(void) {
    ETSpyKeyboardEventPoster *eventPoster = [[ETSpyKeyboardEventPoster alloc] init];
    ETKeyboardShortcutSender *sender = [[ETKeyboardShortcutSender alloc] initWithEventPoster:eventPoster];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:3];

    ETAssert(eventPoster.postCount == 1, @"Three-finger touch should request keyboard input.");
    ETAssert(eventPoster.lastKeyCode == 1, @"Three-finger touch should input the S key.");
    ETAssert((eventPoster.lastFlags & kCGEventFlagMaskAlternate) == kCGEventFlagMaskAlternate, @"Three-finger touch should input with the Option modifier.");
}

int main(void) {
    @autoreleasepool {
        testThreeFingerTouchPostsKeyboardInput();
        puts("KeyboardShortcutSenderTests passed");
    }
    return 0;
}
