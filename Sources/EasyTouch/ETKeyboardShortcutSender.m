#import "ETKeyboardShortcutSender.h"

static const CGKeyCode ETKeyCodeS = 1;

@interface ETCGKeyboardEventPoster : NSObject <ETKeyboardEventPosting>
@end

@implementation ETCGKeyboardEventPoster

- (void)postKeyPressWithKeyCode:(CGKeyCode)keyCode flags:(CGEventFlags)flags {
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
    CGEventRef keyDown = CGEventCreateKeyboardEvent(source, keyCode, true);
    CGEventRef keyUp = CGEventCreateKeyboardEvent(source, keyCode, false);

    if (keyDown != NULL && keyUp != NULL) {
        CGEventSetFlags(keyDown, flags);
        CGEventSetFlags(keyUp, flags);

        CGEventPost(kCGHIDEventTap, keyDown);
        CGEventPost(kCGHIDEventTap, keyUp);
    }

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

@interface ETKeyboardShortcutSender ()
@property (nonatomic, strong) id<ETKeyboardEventPosting> eventPoster;
@end

@implementation ETKeyboardShortcutSender

- (instancetype)init {
    return [self initWithEventPoster:[[ETCGKeyboardEventPoster alloc] init]];
}

- (instancetype)initWithEventPoster:(id<ETKeyboardEventPosting>)eventPoster {
    self = [super init];
    if (self != nil) {
        _eventPoster = eventPoster;
    }
    return self;
}

- (void)sendOptionS {
    [self.eventPoster postKeyPressWithKeyCode:ETKeyCodeS flags:kCGEventFlagMaskAlternate];
}

@end
