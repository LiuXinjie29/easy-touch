#import <Cocoa/Cocoa.h>
#import "ETKeyboardShortcutSender.h"
#import "ETShortcutBindingControlsView.h"
#import "ETThreeFingerTouchHandler.h"

static const CGKeyCode ETKeyCodeK = 40;

@interface ETSpyKeyboardEventPoster : NSObject <ETKeyboardEventPosting>
@property (nonatomic, assign) NSUInteger postCount;
@property (nonatomic, assign) CGKeyCode lastKeyCode;
@property (nonatomic, assign) CGEventFlags lastFlags;
@end

@implementation ETSpyKeyboardEventPoster
- (void)postKeyPressWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags {
    self.postCount += 1;
    self.lastKeyCode = keyCode;
    self.lastFlags = flags;
}
@end

static void ETAssert(BOOL condition, NSString *message) {
    if (!condition) {
        [NSException raise:@"ETTestFailure" format:@"%@", message];
    }
}

static NSTextField *ETTextFieldWithIdentifier(NSView *view, NSString *identifier) {
    if ([view isKindOfClass:NSTextField.class] && [view.accessibilityIdentifier isEqualToString:identifier]) {
        return (NSTextField *)view;
    }

    for (NSView *subview in view.subviews) {
        NSTextField *match = ETTextFieldWithIdentifier(subview, identifier);
        if (match != nil) {
            return match;
        }
    }

    return nil;
}

static NSButton *ETButtonWithIdentifier(NSView *view, NSString *identifier) {
    if ([view isKindOfClass:NSButton.class] && [view.accessibilityIdentifier isEqualToString:identifier]) {
        return (NSButton *)view;
    }

    for (NSView *subview in view.subviews) {
        NSButton *match = ETButtonWithIdentifier(subview, identifier);
        if (match != nil) {
            return match;
        }
    }

    return nil;
}

static void testShortcutChangeEntryExists(void) {
    ETSpyKeyboardEventPoster *eventPoster = [[ETSpyKeyboardEventPoster alloc] init];
    ETKeyboardShortcutSender *sender = [[ETKeyboardShortcutSender alloc] initWithEventPoster:eventPoster];
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];
    ETShortcutBindingControlsView *view = [[ETShortcutBindingControlsView alloc] initWithShortcutSender:sender recorder:recorder];

    ETAssert(view.addBindingButton != nil, @"Shortcut binding UI should expose an add binding button.");
    ETAssert(view.addBindingButton.action == @selector(addShortcutBinding:), @"Add binding button should append a shortcut row.");
    ETAssert([view.addBindingButton.accessibilityIdentifier isEqualToString:@"AddShortcutBindingButton"], @"Add binding button should be discoverable by UI tests.");
    ETAssert(view.removeBindingButton != nil, @"Shortcut binding UI should expose a remove binding button.");
    ETAssert(view.removeBindingButton.action == @selector(removeShortcutBinding:), @"Remove binding button should remove a shortcut row.");
    ETAssert([view.removeBindingButton.accessibilityIdentifier isEqualToString:@"RemoveShortcutBindingButton"], @"Remove binding button should be discoverable by UI tests.");
    ETAssert(view.changeShortcutButton != nil, @"Shortcut binding UI should expose a change shortcut button.");
    ETAssert([view.changeShortcutButton.target isEqual:view], @"Shortcut binding button should be wired to the controls view.");
    ETAssert(view.changeShortcutButton.action == @selector(beginShortcutRecording:), @"Shortcut binding button should start recording.");
    ETAssert([view.changeShortcutButton.accessibilityIdentifier isEqualToString:@"3FingerChangeShortcutButton"], @"Shortcut binding button should live inside the three-finger row.");
}

static void testShortcutBindingListShowsCurrentThreeFingerShortcut(void) {
    ETSpyKeyboardEventPoster *eventPoster = [[ETSpyKeyboardEventPoster alloc] init];
    ETKeyboardShortcutSender *sender = [[ETKeyboardShortcutSender alloc] initWithEventPoster:eventPoster];
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];
    ETShortcutBindingControlsView *view = [[ETShortcutBindingControlsView alloc] initWithShortcutSender:sender recorder:recorder];

    ETAssert(view.shortcutListView != nil, @"Shortcut binding UI should expose a list of touch shortcut bindings.");
    ETAssert([view.shortcutListView.accessibilityIdentifier isEqualToString:@"ShortcutBindingList"], @"Shortcut binding list should be discoverable by UI tests.");
    ETAssert(view.shortcutListView.arrangedSubviews.count == 1, @"Shortcut binding list should start with one row.");
    ETAssert([view.touchCountLabel.stringValue isEqualToString:@"3 Fingers"], @"Shortcut binding list should show the three-finger binding row.");
    ETAssert([view.currentShortcutLabel.stringValue isEqualToString:@"Option+S"], @"Shortcut binding list should show the current three-finger shortcut.");
    ETAssert(ETButtonWithIdentifier(view.shortcutListView.arrangedSubviews[0], @"3FingerChangeShortcutButton") != nil,
             @"Shortcut binding list should put the change shortcut button in the row.");
}

static void testShortcutBindingListAddsAndRemovesRowsInOrder(void) {
    ETSpyKeyboardEventPoster *eventPoster = [[ETSpyKeyboardEventPoster alloc] init];
    ETKeyboardShortcutSender *sender = [[ETKeyboardShortcutSender alloc] initWithEventPoster:eventPoster];
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];
    ETShortcutBindingControlsView *view = [[ETShortcutBindingControlsView alloc] initWithShortcutSender:sender recorder:recorder];

    [view addShortcutBindingWithFingerCount:4];
    [view addShortcutBindingWithFingerCount:5];

    ETAssert(view.shortcutListView.arrangedSubviews.count == 3, @"Shortcut binding list should append rows after adding bindings.");
    ETAssert([ETTextFieldWithIdentifier(view.shortcutListView.arrangedSubviews[0], @"3FingerShortcutTouchCountLabel").stringValue isEqualToString:@"3 Fingers"],
             @"Shortcut binding list should keep the three-finger row first.");
    ETAssert([ETTextFieldWithIdentifier(view.shortcutListView.arrangedSubviews[1], @"4FingerShortcutTouchCountLabel").stringValue isEqualToString:@"4 Fingers"],
             @"Shortcut binding list should append the four-finger row second.");
    ETAssert([ETTextFieldWithIdentifier(view.shortcutListView.arrangedSubviews[2], @"5FingerShortcutTouchCountLabel").stringValue isEqualToString:@"5 Fingers"],
             @"Shortcut binding list should append the five-finger row third.");
    ETAssert([ETTextFieldWithIdentifier(view.shortcutListView.arrangedSubviews[1], @"4FingerShortcutLabel").stringValue isEqualToString:@"Not Set"],
             @"New shortcut binding rows should start unset.");

    [view removeShortcutBinding:nil];

    ETAssert(view.shortcutListView.arrangedSubviews.count == 2, @"Shortcut binding list should remove the last row.");
    ETAssert(ETTextFieldWithIdentifier(view, @"5FingerShortcutTouchCountLabel") == nil,
             @"Removing a shortcut binding should remove that row from the view.");
}

static void testShortcutBindingListRemovesSelectedRow(void) {
    ETSpyKeyboardEventPoster *eventPoster = [[ETSpyKeyboardEventPoster alloc] init];
    ETKeyboardShortcutSender *sender = [[ETKeyboardShortcutSender alloc] initWithEventPoster:eventPoster];
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];
    ETShortcutBindingControlsView *view = [[ETShortcutBindingControlsView alloc] initWithShortcutSender:sender recorder:recorder];

    [view addShortcutBindingWithFingerCount:4];
    [view addShortcutBindingWithFingerCount:5];
    [view selectShortcutBindingAtIndex:1];
    [view removeShortcutBinding:nil];

    ETAssert(view.shortcutListView.arrangedSubviews.count == 2, @"Shortcut binding list should remove the selected row.");
    ETAssert(ETTextFieldWithIdentifier(view, @"4FingerShortcutTouchCountLabel") == nil,
             @"Removing a selected shortcut binding should remove that row from the view.");
    ETAssert([ETTextFieldWithIdentifier(view.shortcutListView.arrangedSubviews[1], @"5FingerShortcutTouchCountLabel").stringValue isEqualToString:@"5 Fingers"],
             @"Removing a selected shortcut binding should keep later rows.");
}

static void testShortcutBindingListRecordsFourFingerShortcut(void) {
    ETSpyKeyboardEventPoster *eventPoster = [[ETSpyKeyboardEventPoster alloc] init];
    ETKeyboardShortcutSender *sender = [[ETKeyboardShortcutSender alloc] initWithEventPoster:eventPoster];
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];
    ETShortcutBindingControlsView *view = [[ETShortcutBindingControlsView alloc] initWithShortcutSender:sender recorder:recorder];
    CGEventFlags flags = kCGEventFlagMaskCommand | kCGEventFlagMaskControl;

    [view addShortcutBindingWithFingerCount:4];
    NSButton *fourFingerChangeButton = ETButtonWithIdentifier(view, @"4FingerChangeShortcutButton");
    [view beginShortcutRecording:fourFingerChangeButton];
    BOOL consumed = [view handleShortcutKeyDownWithKeyCode:0 flags:flags];
    [sender sendShortcutForFingerCount:4];

    ETAssert(consumed, @"Shortcut binding UI should record the four-finger shortcut.");
    ETAssert([ETTextFieldWithIdentifier(view, @"4FingerShortcutLabel").stringValue isEqualToString:@"Command+Control+A"],
             @"Shortcut binding list should show the recorded four-finger shortcut.");
    ETAssert(eventPoster.postCount == 1, @"Four-finger shortcut should be sent when the four-finger binding triggers.");
    ETAssert(eventPoster.lastKeyCode == 0, @"Four-finger shortcut should send the recorded key.");
    ETAssert((eventPoster.lastFlags & flags) == flags, @"Four-finger shortcut should send the recorded modifiers.");
}

static void testShortcutChangeEntryUpdatesBoundThreeFingerShortcut(void) {
    ETSpyKeyboardEventPoster *eventPoster = [[ETSpyKeyboardEventPoster alloc] init];
    ETKeyboardShortcutSender *sender = [[ETKeyboardShortcutSender alloc] initWithEventPoster:eventPoster];
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];
    ETShortcutBindingControlsView *view = [[ETShortcutBindingControlsView alloc] initWithShortcutSender:sender recorder:recorder];
    ETThreeFingerTouchHandler *handler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:sender];
    CGEventFlags flags = kCGEventFlagMaskCommand | kCGEventFlagMaskShift;

    [view beginShortcutRecording:nil];
    BOOL consumed = [view handleShortcutKeyDownWithKeyCode:ETKeyCodeK flags:flags];
    [handler updateWithTouchingFingerCount:3];

    ETAssert(consumed, @"Shortcut binding UI should consume the recorded shortcut.");
    ETAssert(eventPoster.postCount == 1, @"Three-finger touch should send a shortcut after UI binding changes.");
    ETAssert(eventPoster.lastKeyCode == ETKeyCodeK, @"Shortcut binding UI should update the key sent by three-finger touch.");
    ETAssert((eventPoster.lastFlags & flags) == flags, @"Shortcut binding UI should update the modifiers sent by three-finger touch.");
    ETAssert([view.currentShortcutLabel.stringValue isEqualToString:@"Command+Shift+K"], @"Shortcut binding list should update the displayed three-finger shortcut.");
}

int main(void) {
    @autoreleasepool {
        testShortcutChangeEntryExists();
        testShortcutBindingListShowsCurrentThreeFingerShortcut();
        testShortcutBindingListAddsAndRemovesRowsInOrder();
        testShortcutBindingListRemovesSelectedRow();
        testShortcutBindingListRecordsFourFingerShortcut();
        testShortcutChangeEntryUpdatesBoundThreeFingerShortcut();
        puts("ShortcutBindingControlsViewTests passed");
    }
    return 0;
}
