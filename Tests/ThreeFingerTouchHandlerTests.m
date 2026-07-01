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

static id ETCurrentTouchSession(ETThreeFingerTouchHandler *handler) {
    return [handler valueForKey:@"currentTouchSession"];
}

static id ETLastCompletedTouchSession(ETThreeFingerTouchHandler *handler) {
    return [handler valueForKey:@"lastCompletedTouchSession"];
}

static ETTouchFrame *ETMakeTouchFrame(NSUInteger fingerCount, NSTimeInterval timestamp) {
    NSMutableArray<ETTouchPoint *> *touchPoints = [NSMutableArray arrayWithCapacity:fingerCount];
    for (NSUInteger index = 0; index < fingerCount; index += 1) {
        CGFloat coordinate = (CGFloat)(index + 1) / (CGFloat)(fingerCount + 1);
        ETTouchPoint *touchPoint = [[ETTouchPoint alloc] initWithNormalizedPosition:NSMakePoint(coordinate, coordinate)];
        [touchPoints addObject:touchPoint];
    }
    return [[ETTouchFrame alloc] initWithFingerCount:fingerCount timestamp:timestamp touchPoints:touchPoints];
}

static ETTouchFrame *ETMakeTouchFrameWithPositions(NSTimeInterval timestamp, NSArray<NSValue *> *positions) {
    NSMutableArray<ETTouchPoint *> *touchPoints = [NSMutableArray arrayWithCapacity:positions.count];
    for (NSValue *positionValue in positions) {
        ETTouchPoint *touchPoint = [[ETTouchPoint alloc] initWithNormalizedPosition:positionValue.pointValue];
        [touchPoints addObject:touchPoint];
    }
    return [[ETTouchFrame alloc] initWithFingerCount:touchPoints.count timestamp:timestamp touchPoints:touchPoints];
}

static NSArray<NSValue *> *ETThreeFingerPositions(CGFloat offset) {
    return @[
        [NSValue valueWithPoint:NSMakePoint(0.20 + offset, 0.30)],
        [NSValue valueWithPoint:NSMakePoint(0.50 + offset, 0.50)],
        [NSValue valueWithPoint:NSMakePoint(0.80 + offset, 0.70)]
    ];
}

static NSArray<NSValue *> *ETFourFingerPositions(CGFloat offset) {
    return @[
        [NSValue valueWithPoint:NSMakePoint(0.15 + offset, 0.25)],
        [NSValue valueWithPoint:NSMakePoint(0.35 + offset, 0.45)],
        [NSValue valueWithPoint:NSMakePoint(0.65 + offset, 0.55)],
        [NSValue valueWithPoint:NSMakePoint(0.85 + offset, 0.75)]
    ];
}

static void testThreeFingerTouchDoesNotSendShortcutUntilTouchEnds(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:1];
    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:3];

    ETAssert(sender.shortcutCount == 0, @"Three-finger touch should not send the bound shortcut until all fingers are lifted.");
}

static void testThreeFingerTouchSendsShortcutOnceWhenTouchEnds(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:0];
    [handler updateWithTouchingFingerCount:0];

    ETAssert(sender.shortcutCount == 1, @"Three-finger touch should send the bound shortcut once when the touch session ends.");
    ETAssert(sender.lastFingerCount == 3, @"Three-finger touch should send the three-finger shortcut.");
}

static void testUnboundFingerCountsDoNotPostShortcut(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:0];
    [handler updateWithTouchingFingerCount:1];
    [handler updateWithTouchingFingerCount:2];
    [handler updateWithTouchingFingerCount:5];
    [handler updateWithTouchingFingerCount:0];

    ETAssert(sender.shortcutCount == 0, @"Only bound finger counts should send a shortcut.");
}

static void testEmptyZeroFingerUpdatesDoNotStartOrTriggerSession(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:0];
    [handler updateWithTouchingFingerCount:0];

    ETAssert(sender.shortcutCount == 0, @"Empty zero-finger updates should not send a shortcut.");
    ETAssert(ETCurrentTouchSession(handler) == nil, @"Empty zero-finger updates should not start a touch session.");
    ETAssert(ETLastCompletedTouchSession(handler) == nil, @"Empty zero-finger updates should not complete a touch session.");
}

static void testFourFingerTouchCanSendBoundShortcutWhenTouchEnds(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:4];
    [handler updateWithTouchingFingerCount:4];
    [handler updateWithTouchingFingerCount:0];

    ETAssert(sender.shortcutCount == 1, @"Four-finger touch should send its bound shortcut once when the touch session ends.");
    ETAssert(sender.lastFingerCount == 4, @"Four-finger touch should send the four-finger shortcut.");
}

static void testFourFingerTouchPassingThroughThreeOnlySendsFourFingerShortcut(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:4];
    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:0];

    ETAssert(sender.shortcutCount == 1, @"Touch session that reaches four fingers should only send one shortcut.");
    ETAssert(sender.lastFingerCount == 4, @"Touch session that reaches four fingers should send the four-finger shortcut.");
}

static void testThreeFingerSessionWithFingerCountChangesOnlyTriggersOnceForMaxCount(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:2];
    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:0];

    ETAssert(sender.shortcutCount == 1, @"One touch session should send at most one shortcut when all fingers are lifted.");
    ETAssert(sender.lastFingerCount == 3, @"Touch session should send the shortcut for the maximum finger count reached.");
}

static void testIndependentThreeFingerSessionsCanEachTrigger(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:0];
    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:0];

    ETAssert(sender.shortcutCount == 2, @"Separate three-finger touch sessions should each send a shortcut.");
    ETAssert(sender.lastFingerCount == 3, @"Separate three-finger touch sessions should send the three-finger shortcut.");
}

static void testContinuesListeningToTrackpadWhenApplicationEntersBackground(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler applicationDidEnterBackground];
    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:0];

    ETAssert(sender.shortcutCount == 1, @"Application should continue listening to the trackpad when it enters the background.");
}

static void testTouchSessionTracksLifecycleAndTimestamps(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:1 timestamp:10.0];
    id activeSession = ETCurrentTouchSession(handler);

    ETAssert(activeSession != nil, @"Touch session should start when fingers begin touching.");
    ETAssert([[activeSession valueForKey:@"active"] boolValue], @"Touch session should be active while fingers are touching.");
    ETAssert([[activeSession valueForKey:@"startTimestamp"] doubleValue] == 10.0, @"Touch session should record its start timestamp.");
    ETAssert([[activeSession valueForKey:@"lastTimestamp"] doubleValue] == 10.0, @"Touch session should record its initial last timestamp.");

    [handler updateWithTouchingFingerCount:0 timestamp:12.5];
    id completedSession = ETLastCompletedTouchSession(handler);

    ETAssert(ETCurrentTouchSession(handler) == nil, @"Touch session should clear when all fingers are lifted.");
    ETAssert(completedSession == activeSession, @"Completed session should be retained after touch end.");
    ETAssert(![[completedSession valueForKey:@"active"] boolValue], @"Completed touch session should not be active.");
    ETAssert([[completedSession valueForKey:@"lastTimestamp"] doubleValue] == 12.5, @"Touch session should record its end timestamp as the last timestamp.");
}

static void testTouchSessionTracksMaxFingerCount(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:1 timestamp:1.0];
    [handler updateWithTouchingFingerCount:3 timestamp:2.0];
    [handler updateWithTouchingFingerCount:2 timestamp:3.0];
    [handler updateWithTouchingFingerCount:4 timestamp:4.0];
    [handler updateWithTouchingFingerCount:0 timestamp:5.0];

    id completedSession = ETLastCompletedTouchSession(handler);
    ETAssert([[completedSession valueForKey:@"maxFingerCount"] unsignedIntegerValue] == 4, @"Touch session should retain the maximum finger count seen before ending.");
    ETAssert([[completedSession valueForKey:@"startTimestamp"] doubleValue] == 1.0, @"Touch session start timestamp should remain unchanged after updates.");
    ETAssert([[completedSession valueForKey:@"lastTimestamp"] doubleValue] == 5.0, @"Touch session last timestamp should advance through the end event.");
}

static void testTouchFrameInputTracksLifecycleAndMaxFingerCount(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    ETTouchFrame *firstFrame = ETMakeTouchFrame(1, 10.0);
    ETAssert(firstFrame.fingerCount == 1, @"Touch frame should expose its finger count.");
    ETAssert(firstFrame.touchPoints.count == 1, @"Touch frame should retain normalized touch points.");
    ETAssert(NSEqualPoints(firstFrame.touchPoints.firstObject.normalizedPosition, NSMakePoint(0.5, 0.5)), @"Touch point should expose its normalized position.");

    [handler updateWithTouchFrame:firstFrame];
    id activeSession = ETCurrentTouchSession(handler);
    ETAssert(activeSession != nil, @"Touch frame input should start a touch session.");
    ETAssert([[activeSession valueForKey:@"startTimestamp"] doubleValue] == 10.0, @"Touch frame input should set the session start timestamp.");

    [handler updateWithTouchFrame:ETMakeTouchFrame(3, 10.1)];
    [handler updateWithTouchFrame:ETMakeTouchFrame(2, 10.15)];
    [handler updateWithTouchFrame:ETMakeTouchFrame(0, 10.2)];

    id completedSession = ETLastCompletedTouchSession(handler);
    ETAssert(ETCurrentTouchSession(handler) == nil, @"Touch frame input should clear the active session when all fingers lift.");
    ETAssert(completedSession == activeSession, @"Touch frame input should retain the completed session.");
    ETAssert([[completedSession valueForKey:@"maxFingerCount"] unsignedIntegerValue] == 3, @"Touch frame input should preserve the maximum finger count in the session.");
    ETAssert([[completedSession valueForKey:@"lastTimestamp"] doubleValue] == 10.2, @"Touch frame input should update the last timestamp through the end frame.");
    ETAssert(sender.shortcutCount == 1, @"Touch frame input should still trigger once at session end.");
    ETAssert(sender.lastFingerCount == 3, @"Touch frame input should trigger based on the session maximum finger count.");
}

static void testThreeFingerTouchFrameTapWithoutMovementTriggersWhenTouchEnds(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.0, ETThreeFingerPositions(0.0))];
    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.1, ETThreeFingerPositions(0.0))];
    [handler updateWithTouchFrame:ETMakeTouchFrame(0, 1.2)];

    ETAssert(sender.shortcutCount == 1, @"Three-finger touch frame tap should trigger when all fingers lift.");
    ETAssert(sender.lastFingerCount == 3, @"Three-finger touch frame tap should trigger the three-finger shortcut.");
}

static void testThreeFingerTouchFrameMovementAboveThresholdDoesNotTrigger(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.0, ETThreeFingerPositions(0.0))];
    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.1, ETThreeFingerPositions(0.06))];
    [handler updateWithTouchFrame:ETMakeTouchFrame(0, 1.2)];

    id completedSession = ETLastCompletedTouchSession(handler);
    ETAssert([[completedSession valueForKey:@"moved"] boolValue], @"Three-finger touch frame movement above the threshold should mark the session as moved.");
    ETAssert(sender.shortcutCount == 0, @"Three-finger touch frame movement above the threshold should not trigger a shortcut.");
}

static void testThreeFingerTouchFrameJitterBelowThresholdStillTriggers(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.0, ETThreeFingerPositions(0.0))];
    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.1, ETThreeFingerPositions(0.02))];
    [handler updateWithTouchFrame:ETMakeTouchFrame(0, 1.2)];

    id completedSession = ETLastCompletedTouchSession(handler);
    ETAssert(![[completedSession valueForKey:@"moved"] boolValue], @"Three-finger touch frame jitter below the threshold should not mark the session as moved.");
    ETAssert(sender.shortcutCount == 1, @"Three-finger touch frame jitter below the threshold should still trigger.");
    ETAssert(sender.lastFingerCount == 3, @"Three-finger touch frame jitter should trigger the three-finger shortcut.");
}

static void testTouchFramePointOrderingDoesNotCreateFalseMovement(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    NSArray<NSValue *> *initialPositions = @[
        [NSValue valueWithPoint:NSMakePoint(0.80, 0.70)],
        [NSValue valueWithPoint:NSMakePoint(0.20, 0.30)],
        [NSValue valueWithPoint:NSMakePoint(0.50, 0.50)]
    ];
    NSArray<NSValue *> *jitteredPositions = @[
        [NSValue valueWithPoint:NSMakePoint(0.22, 0.30)],
        [NSValue valueWithPoint:NSMakePoint(0.52, 0.50)],
        [NSValue valueWithPoint:NSMakePoint(0.82, 0.70)]
    ];

    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.0, initialPositions)];
    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.1, jitteredPositions)];
    [handler updateWithTouchFrame:ETMakeTouchFrame(0, 1.2)];

    id completedSession = ETLastCompletedTouchSession(handler);
    ETAssert(![[completedSession valueForKey:@"moved"] boolValue], @"Touch point ordering changes should not create false movement.");
    ETAssert(sender.shortcutCount == 1, @"Touch point ordering changes with small jitter should still trigger.");
}

static void testFourFingerTouchFrameMovementAboveThresholdDoesNotTrigger(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.0, ETFourFingerPositions(0.0))];
    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.1, ETFourFingerPositions(0.06))];
    [handler updateWithTouchFrame:ETMakeTouchFrame(0, 1.2)];

    id completedSession = ETLastCompletedTouchSession(handler);
    ETAssert([[completedSession valueForKey:@"moved"] boolValue], @"Four-finger touch frame movement above the threshold should mark the session as moved.");
    ETAssert(sender.shortcutCount == 0, @"Four-finger touch frame movement above the threshold should not trigger a shortcut.");
}

static void testTouchSessionShorterThanMinimumDurationDoesNotTrigger(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:3 timestamp:1.0];
    [handler updateWithTouchingFingerCount:0 timestamp:1.03];

    ETAssert(sender.shortcutCount == 0, @"Three-finger session shorter than the minimum duration should not trigger.");
}

static void testTouchSessionLongerThanMaximumDurationDoesNotTrigger(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:3 timestamp:1.0];
    [handler updateWithTouchingFingerCount:0 timestamp:1.8];

    ETAssert(sender.shortcutCount == 0, @"Three-finger session longer than the maximum duration should not trigger.");
}

static void testTouchSessionWithinDurationThresholdsTriggers(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:3 timestamp:1.0];
    [handler updateWithTouchingFingerCount:0 timestamp:1.2];

    ETAssert(sender.shortcutCount == 1, @"Three-finger session within the duration thresholds should trigger.");
    ETAssert(sender.lastFingerCount == 3, @"Eligible duration should trigger the three-finger shortcut.");
}

static void testMovedTouchSessionWithinDurationThresholdsDoesNotTrigger(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.0, ETThreeFingerPositions(0.0))];
    [handler updateWithTouchFrame:ETMakeTouchFrameWithPositions(1.1, ETThreeFingerPositions(0.06))];
    [handler updateWithTouchFrame:ETMakeTouchFrame(0, 1.2)];

    id completedSession = ETLastCompletedTouchSession(handler);
    ETAssert([[completedSession valueForKey:@"moved"] boolValue], @"Moved session should be marked as moved even with an eligible duration.");
    ETAssert(sender.shortcutCount == 0, @"Moved session should not trigger even when duration is within thresholds.");
}

static void testCountOnlyThreeFingerSessionStillTriggersWhenTouchEnds(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:3 timestamp:1.0];
    [handler updateWithTouchingFingerCount:3 timestamp:1.1];
    [handler updateWithTouchingFingerCount:0 timestamp:1.2];

    id completedSession = ETLastCompletedTouchSession(handler);
    ETAssert(![[completedSession valueForKey:@"moved"] boolValue], @"Count-only three-finger session should not be marked as moved.");
    ETAssert(sender.shortcutCount == 1, @"Count-only three-finger session should keep existing session-end trigger behavior.");
    ETAssert(sender.lastFingerCount == 3, @"Count-only three-finger session should trigger the three-finger shortcut.");
}

static void testCountOnlyThreeFingerSessionWithoutTimestampStillTriggersWhenTouchEnds(void) {
    ETSpyShortcutSender *sender = [[ETSpyShortcutSender alloc] init];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];

    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:3];
    [handler updateWithTouchingFingerCount:0];

    id completedSession = ETLastCompletedTouchSession(handler);
    ETAssert([[completedSession valueForKey:@"startTimestamp"] doubleValue] == 0, @"Count-only session without timestamp should keep a zero start timestamp.");
    ETAssert([[completedSession valueForKey:@"lastTimestamp"] doubleValue] == 0, @"Count-only session without timestamp should keep a zero end timestamp.");
    ETAssert(sender.shortcutCount == 1, @"Count-only session without timestamp should not be rejected by duration thresholds.");
    ETAssert(sender.lastFingerCount == 3, @"Count-only session without timestamp should trigger the three-finger shortcut.");
}

int main(void) {
    @autoreleasepool {
        testThreeFingerTouchDoesNotSendShortcutUntilTouchEnds();
        testThreeFingerTouchSendsShortcutOnceWhenTouchEnds();
        testUnboundFingerCountsDoNotPostShortcut();
        testEmptyZeroFingerUpdatesDoNotStartOrTriggerSession();
        testFourFingerTouchCanSendBoundShortcutWhenTouchEnds();
        testFourFingerTouchPassingThroughThreeOnlySendsFourFingerShortcut();
        testThreeFingerSessionWithFingerCountChangesOnlyTriggersOnceForMaxCount();
        testIndependentThreeFingerSessionsCanEachTrigger();
        testContinuesListeningToTrackpadWhenApplicationEntersBackground();
        testTouchSessionTracksLifecycleAndTimestamps();
        testTouchSessionTracksMaxFingerCount();
        testTouchFrameInputTracksLifecycleAndMaxFingerCount();
        testThreeFingerTouchFrameTapWithoutMovementTriggersWhenTouchEnds();
        testThreeFingerTouchFrameMovementAboveThresholdDoesNotTrigger();
        testThreeFingerTouchFrameJitterBelowThresholdStillTriggers();
        testTouchFramePointOrderingDoesNotCreateFalseMovement();
        testFourFingerTouchFrameMovementAboveThresholdDoesNotTrigger();
        testTouchSessionShorterThanMinimumDurationDoesNotTrigger();
        testTouchSessionLongerThanMaximumDurationDoesNotTrigger();
        testTouchSessionWithinDurationThresholdsTriggers();
        testMovedTouchSessionWithinDurationThresholdsDoesNotTrigger();
        testCountOnlyThreeFingerSessionStillTriggersWhenTouchEnds();
        testCountOnlyThreeFingerSessionWithoutTimestampStillTriggersWhenTouchEnds();
        puts("ThreeFingerTouchHandlerTests passed");
    }
    return 0;
}
