#import "ETKeyboardShortcutSender.h"
#import <ApplicationServices/ApplicationServices.h>

static const CGKeyCode ETKeyCodeS = 1;

@implementation ETKeyboardShortcutSender

- (void)sendOptionS {
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
    CGEventRef keyDown = CGEventCreateKeyboardEvent(source, ETKeyCodeS, true);
    CGEventRef keyUp = CGEventCreateKeyboardEvent(source, ETKeyCodeS, false);

    CGEventSetFlags(keyDown, kCGEventFlagMaskAlternate);
    CGEventSetFlags(keyUp, kCGEventFlagMaskAlternate);

    CGEventPost(kCGHIDEventTap, keyDown);
    CGEventPost(kCGHIDEventTap, keyUp);

    if (keyDown != NULL) {
        CFRelease(keyDown);
    }
    if (keyUp != NULL) {
        CFRelease(keyUp);
    }
    if (source != NULL) {
        CFRelease(source);
    }
}

@end
