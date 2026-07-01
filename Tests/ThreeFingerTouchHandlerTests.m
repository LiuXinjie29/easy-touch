#import <Foundation/Foundation.h>
#import "ETThreeFingerTouchHandler.h"

@interface ETSpyShortcutSender : NSObject <ETShortcutSending>
@property (nonatomic, assign) NSUInteger shortcutCount;
@property (nonatomic, assign) NSUInteger lastFingerCount;
@end

@implementation ETSpyShortcutSender
- (void)sendShortcut {
    [self sendShortcutForFingerCount:3];
}
- (BOOL)sendShortcutForFingerCount:(NSUInteger)fingerCount {
    if (fingerCount != 3 && fingerCount != 4) {
        return NO;
    }
    self.shortcutCount += 1;
    self.lastFingerCount = fingerCount;
    return YES;
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

static void testUnboundFingerCountsDoNotPostShortcut(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:0];
    [handler updateWithTouchingFingerCount:1];
    [handler updateWithTouchingFingerCount:2];
    [handler updateWithTouchingFingerCount:5];

    ETAssert(sender.shortcutCount == 0, @"Only bound finger counts should send a shortcut.");
}

static void testFourFingerTouchCanSendBoundShortcut(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:4];
    [handler updateWithTouchingFingerCount:4];

    ETAssert(sender.shortcutCount == 1, @"Four-finger touch should send its bound shortcut once while held.");
    ETAssert(sender.lastFingerCount == 4, @"Four-finger touch should send the four-finger shortcut.");
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
        testUnboundFingerCountsDoNotPostShortcut();
        testFourFingerTouchCanSendBoundShortcut();
        testContinuesListeningToTrackpadWhenApplicationEntersBackground();
        puts("ThreeFingerTouchHandlerTests passed");
    }
    return 0;
}
