#import "ETThreeFingerTouchHandler.h"

@interface ETThreeFingerTouchHandler ()
@property (nonatomic, strong) id<ETShortcutSending> shortcutSender;
@property (nonatomic, assign) NSUInteger activeTouchingFingerCount;
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
    if (touchingFingerCount == 0) {
        self.activeTouchingFingerCount = 0;
        return NO;
    }

    if (self.activeTouchingFingerCount == touchingFingerCount) {
        return NO;
    }

    self.activeTouchingFingerCount = touchingFingerCount;
    return [self.shortcutSender sendShortcutForFingerCount:touchingFingerCount];
}

- (void)reset {
    self.activeTouchingFingerCount = 0;
}

- (void)applicationDidEnterBackground {
    [self reset];
}

@end
