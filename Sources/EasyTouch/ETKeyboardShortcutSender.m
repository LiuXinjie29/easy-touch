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
@property (nonatomic, strong, readwrite, nullable) ETShortcutBinding *shortcutBinding;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, ETShortcutBinding *> *shortcutBindingsByFingerCount;
@end

@implementation ETKeyboardShortcutSender

- (instancetype)init {
    return [self initWithEventPoster:[[ETCGKeyboardEventPoster alloc] init]];
}

- (instancetype)initWithEventPoster:(id<ETKeyboardEventPosting>)eventPoster {
    self = [super init];
    if (self != nil) {
        _eventPoster = eventPoster;
        _shortcutBinding = [[ETShortcutBinding alloc] initWithKeyCode:ETKeyCodeS flags:kCGEventFlagMaskAlternate];
        _shortcutBindingsByFingerCount = [@{@3: _shortcutBinding} mutableCopy];
    }
    return self;
}

- (void)updateShortcutBinding:(ETShortcutBinding *)shortcutBinding {
    [self updateShortcutBinding:shortcutBinding forFingerCount:3];
}

- (void)updateShortcutBinding:(ETShortcutBinding *)shortcutBinding forFingerCount:(NSUInteger)fingerCount {
    self.shortcutBindingsByFingerCount[@(fingerCount)] = shortcutBinding;
    if (fingerCount == 3) {
        self.shortcutBinding = shortcutBinding;
    }
}

- (void)removeShortcutBindingForFingerCount:(NSUInteger)fingerCount {
    [self.shortcutBindingsByFingerCount removeObjectForKey:@(fingerCount)];
    if (fingerCount == 3) {
        self.shortcutBinding = nil;
    }
}

- (nullable ETShortcutBinding *)shortcutBindingForFingerCount:(NSUInteger)fingerCount {
    return self.shortcutBindingsByFingerCount[@(fingerCount)];
}

- (void)sendShortcut {
    [self sendShortcutForFingerCount:3];
}

- (BOOL)sendShortcutForFingerCount:(NSUInteger)fingerCount {
    ETShortcutBinding *binding = [self shortcutBindingForFingerCount:fingerCount];
    if (binding == nil) {
        return NO;
    }

    [self.eventPoster postKeyPressWithKeyCode:binding.keyCode flags:binding.flags];
    return YES;
}

@end
