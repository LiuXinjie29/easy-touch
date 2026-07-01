#import <Foundation/Foundation.h>
#import "ETThreeFingerTouchHandler.h"

@interface ETGlobalTrackpadTouchMonitor : NSObject

- (instancetype)initWithTouchHandler:(ETThreeFingerTouchHandler *)touchHandler NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)start;
- (void)stop;
- (void)multitouchDeviceDidUpdateTouchingFingerCount:(NSUInteger)touchingFingerCount;
- (void)multitouchDeviceDidUpdateTouchingFingerCount:(NSUInteger)touchingFingerCount timestamp:(NSTimeInterval)timestamp;

@end
