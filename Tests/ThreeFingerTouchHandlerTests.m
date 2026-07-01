#import <Foundation/Foundation.h>
#import "ETThreeFingerTouchHandler.h"

@interface ETSpyShortcutSender : NSObject <ETShortcutSending>
@property (nonatomic, assign) NSUInteger optionSCount;
@end

@implementation ETSpyShortcutSender
- (void)sendOptionS {
    self.optionSCount += 1;
}
@end

static void ETAssert(BOOL condition, NSString *message) {
    if (!condition) {
        [NSException raise:@"ETTestFailure" format:@"%@", message];
    }
}

static void testThreeFingerTouchPostsOptionSOnce(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:1];
    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:3];

    ETAssert(sender.optionSCount == 1, @"Three-finger touch should post Option+S once while held.");
}

static void testThreeFingerTouchCanTriggerAgainAfterFingerCountChanges(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:2];
    [handler updateWithTouchingFingerCount:3];

    ETAssert(sender.optionSCount == 2, @"Three-finger touch should trigger again after the count changes.");
}

static void testNonThreeFingerCountsDoNotPostShortcut(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:0];
    [handler updateWithTouchingFingerCount:1];
    [handler updateWithTouchingFingerCount:2];
    [handler updateWithTouchingFingerCount:4];
    [handler updateWithTouchingFingerCount:5];

    ETAssert(sender.optionSCount == 0, @"Only exactly three fingers should post Option+S.");
}

int main(void) {
    @autoreleasepool {
        testThreeFingerTouchPostsOptionSOnce();
        testThreeFingerTouchCanTriggerAgainAfterFingerCountChanges();
        testNonThreeFingerCountsDoNotPostShortcut();
        puts("ThreeFingerTouchHandlerTests passed");
    }
    return 0;
}
