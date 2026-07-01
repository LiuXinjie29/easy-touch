#import <Foundation/Foundation.h>

@protocol ETShortcutSending <NSObject>

- (void)sendShortcut;
- (BOOL)sendShortcutForFingerCount:(NSUInteger)fingerCount;

@end
