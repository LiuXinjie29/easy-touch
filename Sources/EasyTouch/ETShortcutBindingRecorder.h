#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface ETShortcutBinding : NSObject

@property (nonatomic, assign, readonly) CGKeyCode keyCode;
@property (nonatomic, assign, readonly) CGEventFlags flags;

- (instancetype)initWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface ETShortcutBindingRecorder : NSObject

@property (nonatomic, assign, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, strong, readonly, nullable) ETShortcutBinding *recordedBinding;

- (void)beginRecording;
- (void)cancelRecording;
- (BOOL)handleKeyDownWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags;

@end

NS_ASSUME_NONNULL_END
