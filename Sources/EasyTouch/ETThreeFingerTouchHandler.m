#import "ETThreeFingerTouchHandler.h"

static const CGFloat ETTouchMovementCancellationThreshold = 0.05;
static const NSTimeInterval ETMinimumTouchSessionDuration = 0.05;
static const NSTimeInterval ETMaximumTouchSessionDuration = 0.7;

@implementation ETTouchPoint

- (instancetype)initWithNormalizedPosition:(NSPoint)normalizedPosition {
    self = [super init];
    if (self != nil) {
        _normalizedPosition = normalizedPosition;
    }
    return self;
}

@end

@implementation ETTouchFrame

- (instancetype)initWithFingerCount:(NSUInteger)fingerCount
                          timestamp:(NSTimeInterval)timestamp
                        touchPoints:(NSArray<ETTouchPoint *> *)touchPoints {
    self = [super init];
    if (self != nil) {
        _fingerCount = fingerCount;
        _timestamp = timestamp;
        _touchPoints = [[touchPoints sortedArrayUsingComparator:^NSComparisonResult(ETTouchPoint *firstPoint, ETTouchPoint *secondPoint) {
            if (firstPoint.normalizedPosition.x < secondPoint.normalizedPosition.x) {
                return NSOrderedAscending;
            }
            if (firstPoint.normalizedPosition.x > secondPoint.normalizedPosition.x) {
                return NSOrderedDescending;
            }
            if (firstPoint.normalizedPosition.y < secondPoint.normalizedPosition.y) {
                return NSOrderedAscending;
            }
            if (firstPoint.normalizedPosition.y > secondPoint.normalizedPosition.y) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }] copy] ?: @[];
    }
    return self;
}

@end

@interface ETTouchSession : NSObject
@property (nonatomic, assign, getter=isActive) BOOL active;
@property (nonatomic, assign) NSUInteger maxFingerCount;
@property (nonatomic, assign) NSTimeInterval startTimestamp;
@property (nonatomic, assign) NSTimeInterval lastTimestamp;
@property (nonatomic, copy) NSArray<ETTouchPoint *> *initialTouchPoints;
@property (nonatomic, assign, getter=hasMoved) BOOL moved;
@end

@implementation ETTouchSession
@end

@interface ETThreeFingerTouchHandler ()
@property (nonatomic, strong) id<ETShortcutSending> shortcutSender;
@property (nonatomic, strong) ETTouchSession *currentTouchSession;
@property (nonatomic, strong) ETTouchSession *lastCompletedTouchSession;
@end

@implementation ETThreeFingerTouchHandler

- (instancetype)initWithShortcutSender:(id<ETShortcutSending>)shortcutSender {
    self = [super init];
    if (self != nil) {
        _shortcutSender = shortcutSender;
    }
    return self;
}

- (BOOL)updateWithTouchingFingerCount:(NSUInteger)touchingFingerCount {
    return [self updateWithTouchingFingerCount:touchingFingerCount timestamp:0];
}

- (BOOL)updateWithTouchingFingerCount:(NSUInteger)touchingFingerCount timestamp:(NSTimeInterval)timestamp {
    ETTouchFrame *touchFrame = [[ETTouchFrame alloc] initWithFingerCount:touchingFingerCount timestamp:timestamp touchPoints:@[]];
    return [self updateWithTouchFrame:touchFrame];
}

- (BOOL)updateWithTouchFrame:(ETTouchFrame *)touchFrame {
    ETTouchSession *completedSession = [self updateTouchSessionWithTouchFrame:touchFrame];
    if (![self touchSessionIsEligibleForShortcut:completedSession]) {
        return NO;
    }

    return [self.shortcutSender sendShortcutForFingerCount:completedSession.maxFingerCount];
}

- (void)reset {
    if (self.currentTouchSession != nil) {
        self.currentTouchSession.active = NO;
        self.lastCompletedTouchSession = self.currentTouchSession;
        self.currentTouchSession = nil;
    }
}

- (void)applicationDidEnterBackground {
    [self reset];
}

- (ETTouchSession *)updateTouchSessionWithTouchFrame:(ETTouchFrame *)touchFrame {
    if (touchFrame.fingerCount == 0) {
        return [self finishCurrentSessionWithTimestamp:touchFrame.timestamp];
    }

    if (self.currentTouchSession == nil) {
        [self startSessionWithTouchFrame:touchFrame];
        return nil;
    }

    [self updateCurrentSessionWithTouchFrame:touchFrame];
    return nil;
}

- (void)startSessionWithTouchFrame:(ETTouchFrame *)touchFrame {
    ETTouchSession *touchSession = [[ETTouchSession alloc] init];
    touchSession.active = YES;
    touchSession.maxFingerCount = touchFrame.fingerCount;
    touchSession.startTimestamp = touchFrame.timestamp;
    touchSession.lastTimestamp = touchFrame.timestamp;
    touchSession.initialTouchPoints = touchFrame.touchPoints;
    self.currentTouchSession = touchSession;
}

- (void)updateCurrentSessionWithTouchFrame:(ETTouchFrame *)touchFrame {
    self.currentTouchSession.lastTimestamp = touchFrame.timestamp;
    if (touchFrame.fingerCount > self.currentTouchSession.maxFingerCount) {
        self.currentTouchSession.maxFingerCount = touchFrame.fingerCount;
    }
    [self updateCurrentSessionMovementWithTouchPoints:touchFrame.touchPoints];
}

- (ETTouchSession *)finishCurrentSessionWithTimestamp:(NSTimeInterval)timestamp {
    if (self.currentTouchSession == nil) {
        return nil;
    }

    self.currentTouchSession.active = NO;
    self.currentTouchSession.lastTimestamp = timestamp;
    self.lastCompletedTouchSession = self.currentTouchSession;
    self.currentTouchSession = nil;
    return self.lastCompletedTouchSession;
}

- (void)updateCurrentSessionMovementWithTouchPoints:(NSArray<ETTouchPoint *> *)touchPoints {
    NSArray<ETTouchPoint *> *initialTouchPoints = self.currentTouchSession.initialTouchPoints;
    if (initialTouchPoints.count == 0 || initialTouchPoints.count != touchPoints.count) {
        return;
    }

    for (NSUInteger index = 0; index < initialTouchPoints.count; index += 1) {
        NSPoint initialPosition = initialTouchPoints[index].normalizedPosition;
        NSPoint currentPosition = touchPoints[index].normalizedPosition;
        CGFloat xDelta = currentPosition.x - initialPosition.x;
        CGFloat yDelta = currentPosition.y - initialPosition.y;
        CGFloat distance = hypot(xDelta, yDelta);
        if (distance > ETTouchMovementCancellationThreshold) {
            self.currentTouchSession.moved = YES;
            return;
        }
    }
}

- (BOOL)touchSessionDurationIsEligibleForShortcut:(ETTouchSession *)touchSession {
    if (touchSession.startTimestamp <= 0 || touchSession.lastTimestamp <= touchSession.startTimestamp) {
        return YES;
    }

    NSTimeInterval duration = touchSession.lastTimestamp - touchSession.startTimestamp;
    return duration >= ETMinimumTouchSessionDuration && duration <= ETMaximumTouchSessionDuration;
}

- (BOOL)touchSessionIsEligibleForShortcut:(ETTouchSession *)touchSession {
    if (touchSession == nil) {
        return NO;
    }
    if (touchSession.hasMoved) {
        return NO;
    }
    return [self touchSessionDurationIsEligibleForShortcut:touchSession];
}

@end
