#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import "ETKeyboardShortcutSender.h"
#import "ETThreeFingerTouchHandler.h"

@interface ETAppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) NSWindow *window;
@end

@interface ETTouchCaptureView : NSView
- (instancetype)initWithTouchHandler:(ETThreeFingerTouchHandler *)touchHandler;
@end

@implementation ETAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;

    ETKeyboardShortcutSender *shortcutSender = [[ETKeyboardShortcutSender alloc] init];
    ETThreeFingerTouchHandler *touchHandler = [[ETThreeFingerTouchHandler alloc] initWithShortcutSender:shortcutSender];
    ETTouchCaptureView *contentView = [[ETTouchCaptureView alloc] initWithTouchHandler:touchHandler];

    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 520, 300)
                                             styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
    self.window.title = @"EasyTouch";
    self.window.contentView = contentView;
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];

    [NSApp activateIgnoringOtherApps:YES];
    [self requestAccessibilityPermissionIfNeeded];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return YES;
}

- (void)requestAccessibilityPermissionIfNeeded {
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
}

@end

@interface ETTouchCaptureView ()
@property (nonatomic, strong) ETThreeFingerTouchHandler *touchHandler;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSTextField *statusLabel;
@end

@implementation ETTouchCaptureView

- (instancetype)initWithTouchHandler:(ETThreeFingerTouchHandler *)touchHandler {
    self = [super initWithFrame:NSZeroRect];
    if (self != nil) {
        _touchHandler = touchHandler;
        self.allowedTouchTypes = NSTouchTypeMaskIndirect;
        self.wantsRestingTouches = YES;
        self.wantsLayer = YES;
        self.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;
        [self setupLabels];
    }
    return self;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [self.window makeFirstResponder:self];
}

- (void)touchesBeganWithEvent:(NSEvent *)event {
    [self updateTouchCountFromEvent:event];
}

- (void)touchesMovedWithEvent:(NSEvent *)event {
    [self updateTouchCountFromEvent:event];
}

- (void)touchesEndedWithEvent:(NSEvent *)event {
    [self updateTouchCountFromEvent:event];
}

- (void)touchesCancelledWithEvent:(NSEvent *)event {
    (void)event;
    [self.touchHandler reset];
    self.statusLabel.stringValue = @"Touch cancelled.";
}

- (void)setupLabels {
    self.titleLabel = [NSTextField labelWithString:@"EasyTouch"];
    self.titleLabel.font = [NSFont systemFontOfSize:28 weight:NSFontWeightSemibold];
    self.titleLabel.alignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.statusLabel = [NSTextField labelWithString:@"Touch the trackpad with three fingers to send Option+S."];
    self.statusLabel.font = [NSFont systemFontOfSize:15];
    self.statusLabel.textColor = NSColor.secondaryLabelColor;
    self.statusLabel.alignment = NSTextAlignmentCenter;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:self.titleLabel];
    [self addSubview:self.statusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-18],
        [self.statusLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12],
        [self.statusLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:24],
        [self.statusLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-24],
    ]];
}

- (void)updateTouchCountFromEvent:(NSEvent *)event {
    NSUInteger touchingCount = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self].count;
    [self.touchHandler updateWithTouchingFingerCount:touchingCount];

    if (touchingCount == 3) {
        self.statusLabel.stringValue = @"Sent Option+S.";
    } else {
        self.statusLabel.stringValue = [NSString stringWithFormat:@"%lu finger(s) touching.", touchingCount];
    }
}

@end

int main(int argc, const char *argv[]) {
    (void)argc;
    (void)argv;

    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        ETAppDelegate *delegate = [[ETAppDelegate alloc] init];
        application.delegate = delegate;
        [application setActivationPolicy:NSApplicationActivationPolicyRegular];
        [application run];
    }

    return 0;
}
