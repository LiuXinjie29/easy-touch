#import "ETShortcutBindingControlsView.h"

@interface ETShortcutBindingControlsView ()
@property (nonatomic, strong) ETKeyboardShortcutSender *shortcutSender;
@property (nonatomic, strong) ETShortcutBindingRecorder *recorder;
@property (nonatomic, strong) NSButton *changeShortcutButton;
@property (nonatomic, strong) NSStackView *shortcutListView;
@property (nonatomic, strong) NSTextField *touchCountLabel;
@property (nonatomic, strong) NSTextField *currentShortcutLabel;
@property (nonatomic, strong) NSTextField *recordingStatusLabel;
@end

@implementation ETShortcutBindingControlsView

static NSString *ETShortcutDisplayString(ETShortcutBinding *binding) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    CGEventFlags flags = binding.flags;

    if ((flags & kCGEventFlagMaskCommand) != 0) {
        [parts addObject:@"Command"];
    }
    if ((flags & kCGEventFlagMaskControl) != 0) {
        [parts addObject:@"Control"];
    }
    if ((flags & kCGEventFlagMaskAlternate) != 0) {
        [parts addObject:@"Option"];
    }
    if ((flags & kCGEventFlagMaskShift) != 0) {
        [parts addObject:@"Shift"];
    }

    NSDictionary<NSNumber *, NSString *> *keyNames = @{
        @0: @"A", @1: @"S", @2: @"D", @3: @"F", @4: @"H", @5: @"G", @6: @"Z", @7: @"X",
        @8: @"C", @9: @"V", @11: @"B", @12: @"Q", @13: @"W", @14: @"E", @15: @"R",
        @16: @"Y", @17: @"T", @18: @"1", @19: @"2", @20: @"3", @21: @"4", @22: @"6",
        @23: @"5", @25: @"9", @26: @"7", @28: @"8", @29: @"0", @31: @"O", @32: @"U",
        @34: @"I", @35: @"P", @37: @"L", @38: @"J", @40: @"K", @41: @";", @45: @"N",
        @46: @"M", @49: @"Space", @51: @"Delete", @53: @"Escape"
    };
    NSString *keyName = keyNames[@(binding.keyCode)];
    if (keyName == nil) {
        keyName = [NSString stringWithFormat:@"Key %hu", binding.keyCode];
    }
    [parts addObject:keyName];

    return [parts componentsJoinedByString:@"+"];
}

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
        [strongSelf refreshShortcutList];
        strongSelf.recordingStatusLabel.stringValue = @"Shortcut updated.";
    }];

    self.recordingStatusLabel.stringValue = @"Press a shortcut...";
    if (!usingSystemEventTap) {
        self.recordingStatusLabel.stringValue = @"Press a shortcut... Enable Input Monitoring if this does not work.";
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

- (void)refreshShortcutList {
    self.currentShortcutLabel.stringValue = ETShortcutDisplayString(self.shortcutSender.shortcutBinding);
}

- (void)setupControls {
    self.changeShortcutButton = [NSButton buttonWithTitle:@"Change Shortcut"
                                                   target:self
                                                   action:@selector(beginShortcutRecording:)];
    self.changeShortcutButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.changeShortcutButton.accessibilityIdentifier = @"ChangeShortcutButton";

    self.shortcutListView = [[NSStackView alloc] initWithFrame:NSZeroRect];
    self.shortcutListView.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.shortcutListView.spacing = 0;
    self.shortcutListView.translatesAutoresizingMaskIntoConstraints = NO;
    self.shortcutListView.accessibilityIdentifier = @"ShortcutBindingList";

    NSStackView *threeFingerRow = [[NSStackView alloc] initWithFrame:NSZeroRect];
    threeFingerRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    threeFingerRow.alignment = NSLayoutAttributeCenterY;
    threeFingerRow.spacing = 24;
    threeFingerRow.edgeInsets = NSEdgeInsetsMake(8, 12, 8, 12);
    threeFingerRow.translatesAutoresizingMaskIntoConstraints = NO;
    threeFingerRow.accessibilityIdentifier = @"ThreeFingerShortcutRow";

    self.touchCountLabel = [NSTextField labelWithString:@"3 Fingers"];
    self.touchCountLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
    self.touchCountLabel.textColor = NSColor.labelColor;
    self.touchCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.touchCountLabel.accessibilityIdentifier = @"ThreeFingerShortcutTouchCountLabel";

    self.currentShortcutLabel = [NSTextField labelWithString:@""];
    self.currentShortcutLabel.font = [NSFont systemFontOfSize:13];
    self.currentShortcutLabel.textColor = NSColor.labelColor;
    self.currentShortcutLabel.alignment = NSTextAlignmentRight;
    self.currentShortcutLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.currentShortcutLabel.accessibilityIdentifier = @"CurrentShortcutLabel";

    self.recordingStatusLabel = [NSTextField labelWithString:@""];
    self.recordingStatusLabel.font = [NSFont systemFontOfSize:12];
    self.recordingStatusLabel.textColor = NSColor.secondaryLabelColor;
    self.recordingStatusLabel.alignment = NSTextAlignmentCenter;
    self.recordingStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.recordingStatusLabel.accessibilityIdentifier = @"ShortcutRecordingStatusLabel";

    [threeFingerRow addArrangedSubview:self.touchCountLabel];
    [threeFingerRow addArrangedSubview:self.currentShortcutLabel];
    [self.shortcutListView addArrangedSubview:threeFingerRow];

    [self addSubview:self.changeShortcutButton];
    [self addSubview:self.shortcutListView];
    [self addSubview:self.recordingStatusLabel];
    [self refreshShortcutList];

    [NSLayoutConstraint activateConstraints:@[
        [self.shortcutListView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.shortcutListView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.shortcutListView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.touchCountLabel.widthAnchor constraintGreaterThanOrEqualToConstant:96],
        [self.currentShortcutLabel.widthAnchor constraintGreaterThanOrEqualToConstant:140],
        [self.changeShortcutButton.topAnchor constraintEqualToAnchor:self.shortcutListView.bottomAnchor constant:10],
        [self.changeShortcutButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.recordingStatusLabel.topAnchor constraintEqualToAnchor:self.changeShortcutButton.bottomAnchor constant:6],
        [self.recordingStatusLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.recordingStatusLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor],
        [self.recordingStatusLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],
        [self.recordingStatusLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
}

@end
