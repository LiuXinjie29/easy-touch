#import <Foundation/Foundation.h>
#import "ETShortcutBindingRecorder.h"

static const CGKeyCode ETKeyCode4 = 21;
static const CGKeyCode ETKeyCodeS = 1;

static void ETAssert(BOOL condition, NSString *message) {
    if (!condition) {
        [NSException raise:@"ETTestFailure" format:@"%@", message];
    }
}

static void testRecordingConsumesScreenshotShortcutBeforeOtherAppsCanUseIt(void) {
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];
    CGEventFlags screenshotFlags = kCGEventFlagMaskCommand | kCGEventFlagMaskShift;

    [recorder beginRecording];
    BOOL consumed = [recorder handleKeyDownWithKeyCode:ETKeyCode4 flags:screenshotFlags];

    ETAssert(consumed, @"Binding recorder should consume the screenshot shortcut while recording so other apps cannot trigger it first.");
    ETAssert(!recorder.isRecording, @"Binding recorder should stop recording after capturing a shortcut.");
    ETAssert(recorder.recordedBinding.keyCode == ETKeyCode4, @"Binding recorder should save the pressed screenshot key.");
    ETAssert((recorder.recordedBinding.flags & screenshotFlags) == screenshotFlags, @"Binding recorder should save the screenshot modifiers.");
}

static void testRecordingCompletionReceivesCapturedShortcut(void) {
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];
    __block ETShortcutBinding *completedBinding = nil;
    CGEventFlags flags = kCGEventFlagMaskAlternate | kCGEventFlagMaskCommand;

    [recorder beginRecordingWithCompletion:^(ETShortcutBinding *binding) {
        completedBinding = binding;
    }];
    BOOL consumed = [recorder handleKeyDownWithKeyCode:ETKeyCodeS flags:flags];

    ETAssert(consumed, @"Binding recorder should consume the captured shortcut.");
    ETAssert(completedBinding != nil, @"Binding recorder should call completion after capturing a shortcut.");
    ETAssert(completedBinding.keyCode == ETKeyCodeS, @"Binding recorder completion should receive the captured key.");
    ETAssert((completedBinding.flags & flags) == flags, @"Binding recorder completion should receive the captured modifiers.");
}

static void testCancelRecordingStopsSystemEventTapState(void) {
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];

    [recorder beginRecording];
    [recorder cancelRecording];

    ETAssert(!recorder.isRecording, @"Cancelling should stop recording.");
    ETAssert(!recorder.isSystemEventTapActive, @"Cancelling should stop the temporary system event tap.");
}

static void testShortcutIsNotConsumedWhenRecorderIsInactive(void) {
    ETShortcutBindingRecorder *recorder = [[ETShortcutBindingRecorder alloc] init];

    BOOL consumed = [recorder handleKeyDownWithKeyCode:ETKeyCodeS flags:kCGEventFlagMaskAlternate];

    ETAssert(!consumed, @"Binding recorder should not consume shortcuts when it is inactive.");
    ETAssert(recorder.recordedBinding == nil, @"Inactive binding recorder should not save shortcuts.");
}

int main(void) {
    @autoreleasepool {
        testRecordingConsumesScreenshotShortcutBeforeOtherAppsCanUseIt();
        testRecordingCompletionReceivesCapturedShortcut();
        testCancelRecordingStopsSystemEventTapState();
        testShortcutIsNotConsumedWhenRecorderIsInactive();
        puts("ShortcutBindingRecorderTests passed");
    }
    return 0;
}
