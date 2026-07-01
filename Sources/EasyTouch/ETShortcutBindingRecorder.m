#import "ETShortcutBindingRecorder.h"

@implementation ETShortcutBinding

- (instancetype)initWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags {
    self = [super init];
    if (self != nil) {
        _keyCode = keyCode;
        _flags = flags;
    }
    return self;
}

@end

@interface ETShortcutBindingRecorder ()
@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, strong, nullable) ETShortcutBinding *recordedBinding;
@end

@implementation ETShortcutBindingRecorder

- (void)beginRecording {
    self.recording = YES;
}

- (void)cancelRecording {
    self.recording = NO;
}

- (BOOL)handleKeyDownWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags {
    if (!self.isRecording) {
        return NO;
    }

    self.recordedBinding = [[ETShortcutBinding alloc] initWithKeyCode:keyCode flags:flags];
    self.recording = NO;
    return YES;
}

@end
