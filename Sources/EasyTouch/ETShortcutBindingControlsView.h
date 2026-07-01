#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import "ETKeyboardShortcutSender.h"
#import "ETShortcutBindingRecorder.h"

NS_ASSUME_NONNULL_BEGIN

@interface ETShortcutBindingControlsView : NSView

@property (nonatomic, strong, readonly) NSButton *addBindingButton;
@property (nonatomic, strong, readonly) NSButton *removeBindingButton;
@property (nonatomic, strong, readonly) NSButton *changeShortcutButton;
@property (nonatomic, strong, readonly) NSStackView *shortcutListView;
@property (nonatomic, strong, readonly) NSTextField *touchCountLabel;
@property (nonatomic, strong, readonly) NSTextField *currentShortcutLabel;
@property (nonatomic, strong, readonly) NSTextField *recordingStatusLabel;

- (instancetype)initWithShortcutSender:(ETKeyboardShortcutSender *)shortcutSender
                              recorder:(ETShortcutBindingRecorder *)recorder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(NSRect)frameRect NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (void)addShortcutBinding:(nullable id)sender;
- (void)addShortcutBindingWithFingerCount:(NSUInteger)fingerCount;
- (void)removeShortcutBinding:(nullable id)sender;
- (void)selectShortcutBindingAtIndex:(NSUInteger)index;
- (void)beginShortcutRecording:(nullable id)sender;
- (BOOL)handleShortcutKeyDownWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags;

@end

NS_ASSUME_NONNULL_END
