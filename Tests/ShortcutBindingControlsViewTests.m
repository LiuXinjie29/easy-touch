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

static void testShortcutChangeEntryExists(void) {
    ETSpyKeyboardEventPoster *eventPoster = [[ETSpyKeyboardEventPoster alloc] init];
    ETKeyboardShortcutSender *sender = [[ETKeyboardShortcutSender alloc] initWithEventPoster:eventPoster];
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];
    ETShortcutBindingControlsView *view = [[ETShortcutBindingControlsView alloc] initWithShortcutSender:sender recorder:recorder];

    ETAssert(view.changeShortcutButton != nil, @"Shortcut binding UI should expose a change shortcut button.");
    ETAssert([view.changeShortcutButton.target isEqual:view], @"Shortcut binding button should be wired to the controls view.");
    ETAssert(view.changeShortcutButton.action == @selector(beginShortcutRecording:), @"Shortcut binding button should start recording.");
    ETAssert([view.changeShortcutButton.accessibilityIdentifier isEqualToString:@"ChangeShortcutButton"], @"Shortcut binding button should be discoverable by UI tests.");
}

static void testShortcutBindingListShowsCurrentThreeFingerShortcut(void) {
    ETSpyKeyboardEventPoster *eventPoster = [[ETSpyKeyboardEventPoster alloc] init];
    ETKeyboardShortcutSender *sender = [[ETKeyboardShortcutSender alloc] initWithEventPoster:eventPoster];
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];
    ETShortcutBindingControlsView *view = [[ETShortcutBindingControlsView alloc] initWithShortcutSender:sender recorder:recorder];

    ETAssert(view.shortcutListView != nil, @"Shortcut binding UI should expose a list of touch shortcut bindings.");
    ETAssert([view.shortcutListView.accessibilityIdentifier isEqualToString:@"ShortcutBindingList"], @"Shortcut binding list should be discoverable by UI tests.");
    ETAssert([view.touchCountLabel.stringValue isEqualToString:@"3 Fingers"], @"Shortcut binding list should show the three-finger binding row.");
    ETAssert([view.currentShortcutLabel.stringValue isEqualToString:@"Option+S"], @"Shortcut binding list should show the current three-finger shortcut.");
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
        testShortcutChangeEntryUpdatesBoundThreeFingerShortcut();
        puts("ShortcutBindingControlsViewTests passed");
    }
    return 0;
}
