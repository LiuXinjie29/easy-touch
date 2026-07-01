#import <Foundation/Foundation.h>
#import "ETThreeFingerTouchHandler.h"

@interface ETSpyShortcutSender : NSObject <ETShortcutSending>
@property (nonatomic, assign) NSUInteger shortcutCount;
@end

@implementation ETSpyShortcutSender
- (void)sendShortcut {
    self.shortcutCount += 1;
}
@end

static void ETAssert(BOOL condition, NSString *message) {
    if (!condition) {
        [NSException raise:@"ETTestFailure" format:@"%@", message];
    }
}

static void testThreeFingerTouchSendsShortcutOnce(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:1];
    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:3];

    ETAssert(sender.shortcutCount == 1, @"Three-finger touch should send the bound shortcut once while held.");
}

static void testThreeFingerTouchCanTriggerAgainAfterFingerCountChanges(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:2];
    [handler updateWithTouchingFingerCount:3];

    ETAssert(sender.shortcutCount == 2, @"Three-finger touch should trigger again after the count changes.");
}

static void testNonThreeFingerCountsDoNotPostShortcut(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:0];
    [handler updateWithTouchingFingerCount:1];
    [handler updateWithTouchingFingerCount:2];
    [handler updateWithTouchingFingerCount:4];
    [handler updateWithTouchingFingerCount:5];

    ETAssert(sender.shortcutCount == 0, @"Only exactly three fingers should send the bound shortcut.");
}

static void testContinuesListeningToTrackpadWhenApplicationEntersBackground(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler applicationDidEnterBackground];
    [handler updateWithTouchingFingerCount:3];

    ETAssert(sender.shortcutCount == 1, @"Application should continue listening to the trackpad when it enters the background.");
}

int main(void) {
    @autoreleasepool {
        testThreeFingerTouchSendsShortcutOnce();
        testThreeFingerTouchCanTriggerAgainAfterFingerCountChanges();
        testNonThreeFingerCountsDoNotPostShortcut();
        testContinuesListeningToTrackpadWhenApplicationEntersBackground();
        puts("ThreeFingerTouchHandlerTests passed");
    }
    return 0;
}
