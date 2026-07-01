#import "ETShortcutBindingControlsView.h"

@interface ETShortcutBindingControlsView ()
@property (nonatomic, strong) ETKeyboardShortcutSender *shortcutSender;
@property (nonatomic, strong) ETShortcutBindingRecorder *recorder;
@property (nonatomic, strong) NSButton *changeShortcutButton;
@property (nonatomic, strong) NSTextField *currentShortcutLabel;
@end

@implementation ETShortcutBindingControlsView

- (instancetype)initWithShortcutSender:(ETKeyboardShortcutSender *)shortcutSender
                              recorder:(ETShortcutBindingRecorder *)recorder {
    self = [super initWithFrame:NSZeroRect];
    if (self != nil) {
        _shortcutSender = shortcutSender;
        _recorder = recorder;
        [self setupControls];
    }
    return self;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent *)event {
    if (![self handleShortcutKeyDownWithKeyCode:event.keyCode flags:(CGEventFlags)event.modifierFlags]) {
        [super keyDown:event];
    }
}

- (void)beginShortcutRecording:(nullable id)sender {
    (void)sender;
    __weak ETShortcutBindingControlsView *weakSelf = self;
    BOOL usingSystemEventTap = [self.recorder beginRecordingWithCompletion:^(ETShortcutBinding *binding) {
        ETShortcutBindingControlsView *strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        [strongSelf.shortcutSender updateShortcutBinding:binding];
        strongSelf.currentShortcutLabel.stringValue = @"Shortcut updated.";
    }];

    self.currentShortcutLabel.stringValue = @"Press a shortcut...";
    if (!usingSystemEventTap) {
        self.currentShortcutLabel.stringValue = @"Press a shortcut... Enable Input Monitoring if this does not work.";
    }
    [self.window makeFirstResponder:self];
}

- (BOOL)handleShortcutKeyDownWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags {
    BOOL consumed = [self.recorder handleKeyDownWithKeyCode:keyCode flags:flags];
    if (!consumed) {
        return NO;
    }

    return YES;
}

- (void)setupControls {
    self.changeShortcutButton = [NSButton buttonWithTitle:@"Change Shortcut"
                                                   target:self
                                                   action:@selector(beginShortcutRecording:)];
    self.changeShortcutButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.changeShortcutButton.accessibilityIdentifier = @"ChangeShortcutButton";

    self.currentShortcutLabel = [NSTextField labelWithString:@"Current shortcut: Option+S"];
    self.currentShortcutLabel.font = [NSFont systemFontOfSize:13];
    self.currentShortcutLabel.textColor = NSColor.secondaryLabelColor;
    self.currentShortcutLabel.alignment = NSTextAlignmentCenter;
    self.currentShortcutLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.currentShortcutLabel.accessibilityIdentifier = @"CurrentShortcutLabel";

    [self addSubview:self.changeShortcutButton];
    [self addSubview:self.currentShortcutLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.changeShortcutButton.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.changeShortcutButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.currentShortcutLabel.topAnchor constraintEqualToAnchor:self.changeShortcutButton.bottomAnchor constant:8],
        [self.currentShortcutLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.currentShortcutLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor],
        [self.currentShortcutLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],
        [self.currentShortcutLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
}

@end
