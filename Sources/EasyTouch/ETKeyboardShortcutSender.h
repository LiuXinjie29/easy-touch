#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import "ETShortcutBindingRecorder.h"
#import "ETShortcutSending.h"

@protocol ETKeyboardEventPosting <NSObject>

- (void)postKeyPressWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags;

@end

@interface ETKeyboardShortcutSender : NSObject <ETShortcutSending>

@property (nonatomic, strong, readonly) ETShortcutBinding *shortcutBinding;

- (instancetype)initWithEventPoster:(id<ETKeyboardEventPosting>)eventPoster NS_DESIGNATED_INITIALIZER;
- (instancetype)init;
- (void)updateShortcutBinding:(ETShortcutBinding *)shortcutBinding;

@end
