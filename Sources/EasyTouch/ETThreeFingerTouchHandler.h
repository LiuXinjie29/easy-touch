#import <Foundation/Foundation.h>
#import "ETShortcutSending.h"

@interface ETThreeFingerTouchHandler : NSObject

- (instancetype)initWithShortcutSender:(id<ETShortcutSending>)shortcutSender NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)updateWithTouchingFingerCount:(NSUInteger)touchingFingerCount;
- (void)applicationDidEnterBackground;
- (void)reset;

@end
