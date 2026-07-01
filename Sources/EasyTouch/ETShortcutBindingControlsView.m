#import "ETShortcutBindingControlsView.h"

@interface ETShortcutBindingRow : NSObject
@property (nonatomic, assign) NSUInteger fingerCount;
@property (nonatomic, strong, nullable) ETShortcutBinding *shortcutBinding;
@property (nonatomic, strong) NSStackView *rowView;
@property (nonatomic, strong) NSTextField *touchCountLabel;
@property (nonatomic, strong) NSTextField *shortcutLabel;
@property (nonatomic, strong) NSButton *changeButton;
@end

@implementation ETShortcutBindingRow
@end

@interface ETShortcutBindingControlsView ()
@property (nonatomic, strong) ETKeyboardShortcutSender *shortcutSender;
@property (nonatomic, strong) ETShortcutBindingRecorder *recorder;
@property (nonatomic, strong) NSButton *addBindingButton;
@property (nonatomic, strong) NSButton *removeBindingButton;
@property (nonatomic, strong) NSButton *changeShortcutButton;
@property (nonatomic, strong) NSStackView *shortcutListView;
@property (nonatomic, strong) NSTextField *touchCountLabel;
@property (nonatomic, strong) NSTextField *currentShortcutLabel;
@property (nonatomic, strong) NSTextField *recordingStatusLabel;
@property (nonatomic, strong) NSMutableArray<ETShortcutBindingRow *> *shortcutRows;
@property (nonatomic, assign) NSInteger recordingRowIndex;
@property (nonatomic, assign) NSInteger selectedRowIndex;
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
        _shortcutRows = [NSMutableArray array];
        _recordingRowIndex = -1;
        _selectedRowIndex = -1;
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
    NSInteger rowIndex = 0;
    if ([sender isKindOfClass:NSButton.class]) {
        rowIndex = ((NSButton *)sender).tag;
    }
    if (rowIndex < 0 || rowIndex >= (NSInteger)self.shortcutRows.count) {
        return;
    }

    self.recordingRowIndex = rowIndex;
    __weak ETShortcutBindingControlsView *weakSelf = self;
    BOOL usingSystemEventTap = [self.recorder beginRecordingWithCompletion:^(ETShortcutBinding *binding) {
        ETShortcutBindingControlsView *strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        NSInteger completedRowIndex = strongSelf.recordingRowIndex;
        if (completedRowIndex >= 0 && completedRowIndex < (NSInteger)strongSelf.shortcutRows.count) {
            ETShortcutBindingRow *row = strongSelf.shortcutRows[(NSUInteger)completedRowIndex];
            row.shortcutBinding = binding;
            [strongSelf.shortcutSender updateShortcutBinding:binding forFingerCount:row.fingerCount];
        }
        strongSelf.recordingRowIndex = -1;
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
    for (NSUInteger index = 0; index < self.shortcutRows.count; index += 1) {
        ETShortcutBindingRow *row = self.shortcutRows[index];
        ETShortcutBinding *binding = row.shortcutBinding;
        row.shortcutLabel.stringValue = binding == nil ? @"Not Set" : ETShortcutDisplayString(binding);
        row.changeButton.tag = (NSInteger)index;
        row.rowView.layer.backgroundColor = (self.selectedRowIndex == (NSInteger)index) ? NSColor.selectedControlColor.CGColor : NSColor.clearColor.CGColor;
    }
    self.removeBindingButton.enabled = self.shortcutRows.count > 1 && self.selectedRowIndex >= 0;
    if (self.shortcutRows.count > 0) {
        ETShortcutBindingRow *firstRow = self.shortcutRows[0];
        self.changeShortcutButton = firstRow.changeButton;
        self.touchCountLabel = firstRow.touchCountLabel;
        self.currentShortcutLabel = firstRow.shortcutLabel;
    }
}

- (void)addShortcutBinding:(nullable id)sender {
    (void)sender;
    NSUInteger fingerCount = [self promptForShortcutBindingFingerCount];
    if (fingerCount == 0) {
        return;
    }
    [self addShortcutBindingWithFingerCount:fingerCount];
    [self beginShortcutRecording:self.shortcutRows[(NSUInteger)self.selectedRowIndex].changeButton];
}

- (void)addShortcutBindingWithFingerCount:(NSUInteger)fingerCount {
    if (fingerCount == 0) {
        return;
    }

    NSInteger existingIndex = [self indexOfShortcutRowForFingerCount:fingerCount];
    if (existingIndex >= 0) {
        [self selectShortcutBindingRowAtIndex:existingIndex];
        self.recordingStatusLabel.stringValue = @"Finger count already exists.";
        return;
    }

    ETShortcutBindingRow *row = [self createShortcutBindingRowWithFingerCount:fingerCount shortcutBinding:nil];
    [self.shortcutRows addObject:row];
    [self.shortcutListView addArrangedSubview:row.rowView];
    [self sortShortcutRows];
    [self selectShortcutBindingRowAtIndex:[self indexOfShortcutRowForFingerCount:fingerCount]];
    [self refreshShortcutList];
}

- (void)removeShortcutBinding:(nullable id)sender {
    (void)sender;
    if (self.shortcutRows.count <= 1 || self.selectedRowIndex < 0 || self.selectedRowIndex >= (NSInteger)self.shortcutRows.count) {
        return;
    }

    NSUInteger removedIndex = (NSUInteger)self.selectedRowIndex;
    ETShortcutBindingRow *row = self.shortcutRows[removedIndex];
    [self.shortcutListView removeArrangedSubview:row.rowView];
    [row.rowView removeFromSuperview];
    [self.shortcutRows removeObjectAtIndex:removedIndex];
    [self.shortcutSender removeShortcutBindingForFingerCount:row.fingerCount];
    if (self.recordingRowIndex >= (NSInteger)self.shortcutRows.count) {
        self.recordingRowIndex = -1;
        [self.recorder cancelRecording];
    }
    self.selectedRowIndex = MIN((NSInteger)removedIndex, (NSInteger)self.shortcutRows.count - 1);
    [self refreshShortcutList];
}

- (void)setupControls {
    NSStackView *actionBar = [[NSStackView alloc] initWithFrame:NSZeroRect];
    actionBar.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    actionBar.spacing = 6;
    actionBar.translatesAutoresizingMaskIntoConstraints = NO;

    self.addBindingButton = [NSButton buttonWithTitle:@"+"
                                               target:self
                                               action:@selector(addShortcutBinding:)];
    self.addBindingButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.addBindingButton.accessibilityIdentifier = @"AddShortcutBindingButton";

    self.removeBindingButton = [NSButton buttonWithTitle:@"-"
                                                  target:self
                                                  action:@selector(removeShortcutBinding:)];
    self.removeBindingButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.removeBindingButton.accessibilityIdentifier = @"RemoveShortcutBindingButton";

    [actionBar addArrangedSubview:self.addBindingButton];
    [actionBar addArrangedSubview:self.removeBindingButton];

    self.shortcutListView = [[NSStackView alloc] initWithFrame:NSZeroRect];
    self.shortcutListView.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.shortcutListView.spacing = 10;
    self.shortcutListView.translatesAutoresizingMaskIntoConstraints = NO;
    self.shortcutListView.accessibilityIdentifier = @"ShortcutBindingList";

    self.recordingStatusLabel = [NSTextField labelWithString:@""];
    self.recordingStatusLabel.font = [NSFont systemFontOfSize:12];
    self.recordingStatusLabel.textColor = NSColor.secondaryLabelColor;
    self.recordingStatusLabel.alignment = NSTextAlignmentCenter;
    self.recordingStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.recordingStatusLabel.accessibilityIdentifier = @"ShortcutRecordingStatusLabel";

    ETShortcutBindingRow *threeFingerRow = [self createShortcutBindingRowWithFingerCount:3 shortcutBinding:self.shortcutSender.shortcutBinding];
    [self.shortcutRows addObject:threeFingerRow];
    [self.shortcutListView addArrangedSubview:threeFingerRow.rowView];
    self.selectedRowIndex = 0;

    [self addSubview:actionBar];
    [self addSubview:self.shortcutListView];
    [self addSubview:self.recordingStatusLabel];
    [self refreshShortcutList];

    [NSLayoutConstraint activateConstraints:@[
        [actionBar.topAnchor constraintEqualToAnchor:self.topAnchor],
        [actionBar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.addBindingButton.widthAnchor constraintEqualToConstant:28],
        [self.removeBindingButton.widthAnchor constraintEqualToConstant:28],
        [self.shortcutListView.topAnchor constraintEqualToAnchor:actionBar.bottomAnchor constant:8],
        [self.shortcutListView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.shortcutListView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.recordingStatusLabel.topAnchor constraintEqualToAnchor:self.shortcutListView.bottomAnchor constant:8],
        [self.recordingStatusLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.recordingStatusLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor],
        [self.recordingStatusLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],
        [self.recordingStatusLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
}

- (ETShortcutBindingRow *)createShortcutBindingRowWithFingerCount:(NSUInteger)fingerCount
                                                   shortcutBinding:(nullable ETShortcutBinding *)shortcutBinding {
    ETShortcutBindingRow *row = [[ETShortcutBindingRow alloc] init];
    row.fingerCount = fingerCount;
    row.shortcutBinding = shortcutBinding;

    row.rowView = [[NSStackView alloc] initWithFrame:NSZeroRect];
    row.rowView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.rowView.alignment = NSLayoutAttributeCenterY;
    row.rowView.spacing = 16;
    row.rowView.edgeInsets = NSEdgeInsetsMake(4, 0, 4, 0);
    row.rowView.wantsLayer = YES;
    row.rowView.translatesAutoresizingMaskIntoConstraints = NO;
    row.rowView.accessibilityIdentifier = [NSString stringWithFormat:@"%luFingerShortcutRow", (unsigned long)fingerCount];
    NSClickGestureRecognizer *clickRecognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(selectShortcutBindingRowFromGesture:)];
    [row.rowView addGestureRecognizer:clickRecognizer];

    row.touchCountLabel = [NSTextField labelWithString:[NSString stringWithFormat:@"%lu Fingers", (unsigned long)fingerCount]];
    row.touchCountLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
    row.touchCountLabel.textColor = NSColor.labelColor;
    row.touchCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    row.touchCountLabel.accessibilityIdentifier = [NSString stringWithFormat:@"%luFingerShortcutTouchCountLabel", (unsigned long)fingerCount];

    row.shortcutLabel = [NSTextField labelWithString:@""];
    row.shortcutLabel.font = [NSFont systemFontOfSize:13];
    row.shortcutLabel.textColor = NSColor.labelColor;
    row.shortcutLabel.alignment = NSTextAlignmentLeft;
    row.shortcutLabel.translatesAutoresizingMaskIntoConstraints = NO;
    row.shortcutLabel.accessibilityIdentifier = [NSString stringWithFormat:@"%luFingerShortcutLabel", (unsigned long)fingerCount];

    row.changeButton = [NSButton buttonWithTitle:@"Change Shortcut"
                                          target:self
                                          action:@selector(beginShortcutRecording:)];
    row.changeButton.translatesAutoresizingMaskIntoConstraints = NO;
    row.changeButton.accessibilityIdentifier = [NSString stringWithFormat:@"%luFingerChangeShortcutButton", (unsigned long)fingerCount];

    [row.rowView addArrangedSubview:row.touchCountLabel];
    [row.rowView addArrangedSubview:row.shortcutLabel];
    [row.rowView addArrangedSubview:row.changeButton];

    [NSLayoutConstraint activateConstraints:@[
        [row.touchCountLabel.widthAnchor constraintEqualToConstant:96],
        [row.shortcutLabel.widthAnchor constraintGreaterThanOrEqualToConstant:160],
    ]];

    if (fingerCount == 3) {
        self.changeShortcutButton = row.changeButton;
        self.touchCountLabel = row.touchCountLabel;
        self.currentShortcutLabel = row.shortcutLabel;
    }

    return row;
}

- (NSUInteger)promptForShortcutBindingFingerCount {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Add Touch Binding";
    alert.informativeText = @"Enter the number of fingers for this shortcut.";
    [alert addButtonWithTitle:@"Add"];
    [alert addButtonWithTitle:@"Cancel"];

    NSTextField *fingerCountField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 220, 24)];
    fingerCountField.placeholderString = @"Finger count";
    alert.accessoryView = fingerCountField;

    NSModalResponse response = [alert runModal];
    if (response != NSAlertFirstButtonReturn) {
        return 0;
    }

    NSInteger fingerCount = fingerCountField.integerValue;
    if (fingerCount <= 0) {
        self.recordingStatusLabel.stringValue = @"Enter a valid finger count.";
        return 0;
    }

    return (NSUInteger)fingerCount;
}

- (NSInteger)indexOfShortcutRowForFingerCount:(NSUInteger)fingerCount {
    for (NSUInteger index = 0; index < self.shortcutRows.count; index += 1) {
        if (self.shortcutRows[index].fingerCount == fingerCount) {
            return (NSInteger)index;
        }
    }
    return -1;
}

- (void)sortShortcutRows {
    [self.shortcutRows sortUsingComparator:^NSComparisonResult(ETShortcutBindingRow *firstRow, ETShortcutBindingRow *secondRow) {
        if (firstRow.fingerCount < secondRow.fingerCount) {
            return NSOrderedAscending;
        }
        if (firstRow.fingerCount > secondRow.fingerCount) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];

    for (NSView *view in self.shortcutListView.arrangedSubviews.copy) {
        [self.shortcutListView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    for (ETShortcutBindingRow *row in self.shortcutRows) {
        [self.shortcutListView addArrangedSubview:row.rowView];
    }
}

- (void)selectShortcutBindingRowFromGesture:(NSClickGestureRecognizer *)recognizer {
    NSInteger index = [self indexOfShortcutRowView:recognizer.view];
    if (index >= 0) {
        [self selectShortcutBindingRowAtIndex:index];
    }
}

- (NSInteger)indexOfShortcutRowView:(NSView *)rowView {
    for (NSUInteger index = 0; index < self.shortcutRows.count; index += 1) {
        if (self.shortcutRows[index].rowView == rowView) {
            return (NSInteger)index;
        }
    }
    return -1;
}

- (void)selectShortcutBindingRowAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.shortcutRows.count) {
        return;
    }
    self.selectedRowIndex = index;
    [self refreshShortcutList];
}

- (void)selectShortcutBindingAtIndex:(NSUInteger)index {
    [self selectShortcutBindingRowAtIndex:(NSInteger)index];
}

@end
