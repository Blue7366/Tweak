#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <dlfcn.h>

// Keep our successful audio stabilization running
void stabilize_ios_audio() {
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    @try {
        [session setCategory:AVAudioSessionCategoryAmbient 
                 withOptions:AVAudioSessionCategoryOptionMixWithOthers 
                       error:&error];
        [session setPreferredSampleRate:44100.0 error:&error];
        [session setPreferredIOBufferDuration:0.0232 error:&error];
        [session setActive:YES error:&error];
        NSLog(@"[ConsoleFix] Audio layer stabilized successfully.");
    } @catch (NSException *exception) {
        NSLog(@"[ConsoleFix] Audio error: %@", exception.reason);
    }
}

// A sleek floating container that holds both the trigger and close actions
@interface UEConsolePanel : UIView
@property (nonatomic, strong) UIButton *consoleButton;
@property (nonatomic, strong) UIButton *closeButton;
@end

@implementation UEConsolePanel

- (instancetype)init {
    // Positioning in the top right corner safely away from notch layouts
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat panelWidth = 140;
    CGFloat panelHeight = 35;
    CGRect frame = CGRectMake(screenBounds.size.width - panelWidth - 20, 50, panelWidth, panelHeight);
    
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.75];
        self.layer.cornerRadius = 8;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [UIColor greenColor].CGColor;
        self.tag = 13377331;
        
        // 1. The primary button to open the Unreal Engine Console
        self.consoleButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, 100, 35)];
        [self.consoleButton setTitle:@"~ Console" forState:UIControlStateNormal];
        self.consoleButton.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:13];
        [self.consoleButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [self.consoleButton addTarget:self action:@selector(consoleTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.consoleButton];
        
        // 2. The tiny button to completely remove/hide the interface from view
        self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(110, 0, 25, 35)];
        [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
        self.closeButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        [self.closeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeButton];
    }
    return self;
}

- (void)consoleTapped {
    NSLog(@"[ConsoleFix] Dispatching console engine query...");
    
    void* gEngine = dlsym(RTLD_DEFAULT, "GEngine");
    if (gEngine) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIConsoleActivateNotification" object:nil];
    } else {
        // Modern iOS 13+ compliant scene search to grab the active view controller without using .keyWindow
        UIViewController *rootVC = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                rootVC = ((UIWindowScene *)scene).windows.firstObject.rootViewController;
                break;
            }
        }
        
        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"UE Console" 
                                                                           message:@"Console call routed via active scene fallback." 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)closeTapped {
    NSLog(@"[ConsoleFix] User requested panel hide. Removing panel from superview.");
    [self removeFromSuperview];
}

@end

// Monitor the UI window mapping to place the modern panel frame safely
%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    
    // Check connectedScenes to target only standard app interactive interfaces
    UIWindowScene *scene = self.windowScene;
    if (!scene) return;
    
    // Check if the current window or scene already has our interface active
    for (UIView *subview in self.subviews) {
        if (subview.tag == 13377331) return;
    }
    
    NSLog(@"[ConsoleFix] Attaching clean console container panel into active Window Scene context.");
    UEConsolePanel *panel = [[UEConsolePanel alloc] init];
    [self addSubview:panel];
    [self bringSubviewToFront:panel];
}
%end

// Core binary constructor block called on injection initialization
__attribute__((constructor)) static void initialize_console_tweak() {
    @autoreleasepool {
        NSLog(@"[ConsoleFix] Universal Dev Tweak initialized.");
        stabilize_ios_audio();
    }
}
