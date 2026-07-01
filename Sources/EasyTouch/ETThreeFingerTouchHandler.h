#import <Foundation/Foundation.h>
#import "ETShortcutSending.h"

@interface ETTouchPoint : NSObject

@property (nonatomic, assign, readonly) NSPoint normalizedPosition;

- (instancetype)initWithNormalizedPosition:(NSPoint)normalizedPosition NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface ETTouchFrame : NSObject

@property (nonatomic, assign, readonly) NSUInteger fingerCount;
@property (nonatomic, assign, readonly) NSTimeInterval timestamp;
@property (nonatomic, copy, readonly) NSArray<ETTouchPoint *> *touchPoints;

- (instancetype)initWithFingerCount:(NSUInteger)fingerCount
                          timestamp:(NSTimeInterval)timestamp
                        touchPoints:(NSArray<ETTouchPoint *> *)touchPoints NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface ETThreeFingerTouchHandler : NSObject

- (instancetype)initWithShortcutSender:(id<ETShortcutSending>)shortcutSender NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)updateWithTouchFrame:(ETTouchFrame *)touchFrame;
- (BOOL)updateWithTouchingFingerCount:(NSUInteger)touchingFingerCount;
- (BOOL)updateWithTouchingFingerCount:(NSUInteger)touchingFingerCount timestamp:(NSTimeInterval)timestamp;
- (void)applicationDidEnterBackground;
- (void)reset;

@end
