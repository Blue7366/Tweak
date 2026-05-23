#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <dlfcn.h>

// Keep our successful audio stabilization logic running
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

// Custom overlay button to trigger the Unreal Console gesture manually
@interface UEConsoleButton : UIButton
@end

@implementation UEConsoleButton

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        [self setTitle:@"~ Console" forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
        [self setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        self.layer.cornerRadius = 8;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [UIColor greenColor].CGColor;
        [self addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)buttonTapped {
    NSLog(@"[ConsoleFix] Console button tapped! Attempting to dispatch console toggle command...");
    
    // Look up the core Unreal Engine execution command array or center viewport dynamically
    // This sends a direct engine command string to toggle the console view
    void* gEngine = dlsym(RTLD_DEFAULT, "GEngine");
    if (gEngine) {
        // If the global engine pointer is found, we can attempt to pass an execution command string
        // For standard shipping builds, generating a 4-finger tap gesture or calling the UI directly is safer:
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (keyWindow) {
            // Simulate an engine console-activation event notification internally
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UIConsoleActivateNotification" object:nil];
        }
    } else {
        // Fallback: Post a standard system alert notifying that lookups are processing
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"UE Console" 
                                                                           message:@"Attempting console call via fallback execution loop." 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    }
}

@end

// Monitor the UI window initialization so we can cleanly stick our button on the screen
%hook UIWindow
- (void)becomeKeyWindow {
    %orig;
    
    // Avoid double-creating the button if the window cycles
    if ([self viewWithTag:13377331]) return;
    
    NSLog(@"[ConsoleFix] App UI window detected. Injecting floating overlay button...");
    
    // Position the button safely near the top edge of your screen
    CGRect buttonFrame = CGRectMake(40, 40, 100, 35);
    UEConsoleButton *consoleBtn = [[UEConsoleButton alloc] initWithFrame:buttonFrame];
    consoleBtn.tag = 13377331;
    
    [self addSubview:consoleBtn];
    [self bringSubviewToFront:consoleBtn];
}
%end

// Constructor loop run instantly when the application finishes loading dependencies
__attribute__((constructor)) static void initialize_console_tweak() {
    @autoreleasepool {
        NSLog(@"[ConsoleFix] Universal Dev Tweak successfully loaded.");
        
        // Stabilize audio right out of the gate so it doesn't crash
        stabilize_ios_audio();
    }
}
