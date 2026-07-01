#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import "ETShortcutBindingRecorder.h"
#import "ETShortcutSending.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ETKeyboardEventPosting <NSObject>

- (void)postKeyPressWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags;

@end

@interface ETKeyboardShortcutSender : NSObject <ETShortcutSending>

@property (nonatomic, strong, readonly, nullable) ETShortcutBinding *shortcutBinding;

- (instancetype)initWithEventPoster:(id<ETKeyboardEventPosting>)eventPoster NS_DESIGNATED_INITIALIZER;
- (instancetype)init;
- (void)updateShortcutBinding:(ETShortcutBinding *)shortcutBinding;
- (void)updateShortcutBinding:(ETShortcutBinding *)shortcutBinding forFingerCount:(NSUInteger)fingerCount;
- (void)removeShortcutBindingForFingerCount:(NSUInteger)fingerCount;
- (nullable ETShortcutBinding *)shortcutBindingForFingerCount:(NSUInteger)fingerCount;

@end

NS_ASSUME_NONNULL_END
