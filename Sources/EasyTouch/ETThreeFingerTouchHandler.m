#import "ETThreeFingerTouchHandler.h"

@interface ETThreeFingerTouchHandler ()
@property (nonatomic, strong) id<ETShortcutSending> shortcutSender;
@property (nonatomic, assign) BOOL threeFingerTouchActive;
@end

@implementation ETThreeFingerTouchHandler

- (instancetype)initWithShortcutSender:(id<ETShortcutSending>)shortcutSender {
    self = [super init];
    if (self != nil) {
        _shortcutSender = shortcutSender;
    }
    return self;
}

- (void)updateWithTouchingFingerCount:(NSUInteger)touchingFingerCount {
    if (touchingFingerCount != 3) {
        self.threeFingerTouchActive = NO;
        return;
    }

    if (self.threeFingerTouchActive) {
        return;
    }

    self.threeFingerTouchActive = YES;
    [self.shortcutSender sendOptionS];
}

- (void)reset {
    self.threeFingerTouchActive = NO;
}

@end
