#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import "ETShortcutSending.h"

@protocol ETKeyboardEventPosting <NSObject>

- (void)postKeyPressWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags;

@end

@interface ETKeyboardShortcutSender : NSObject <ETShortcutSending>

- (instancetype)initWithEventPoster:(id<ETKeyboardEventPosting>)eventPoster NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

@end
