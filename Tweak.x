#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// Declare the Unreal Engine C++ functions we want to hook
// UE4 uses mangled or standard C symbols depending on the build
extern "C" bool _ZN15FIOSAudioDevice10InitDeviceEv(void* self); 

// Hooking the native C++ initialization of the iOS Audio Device in Unreal
%hookf(bool, _ZN15FIOSAudioDevice10InitDeviceEv, void* self) {
    
    // FORCE iOS into a backward-compatible standard audio state 
    // BEFORE Unreal Engine attempts to poll the hardware pointers.
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    @try {
        // Use Ambient category so it doesn't strictly lock the hardware pipeline
        [session setCategory:AVAudioSessionCategoryAmbient 
                 withOptions:AVAudioSessionCategoryOptionMixWithOthers 
                       error:&error];
        
        // Legacy games usually expect a hardcoded 44.1kHz sample rate. 
        // Modern iOS 26 defaults to variable rates or 48kHz, which causes the pointer mismatch.
        [session setPreferredSampleRate:44100.0 error:&error];
        
        // Force a standard buffer size (1024 samples) to prevent buffer underflow null pointers
        [session setPreferredIOBufferDuration:0.0232 error:&error];
        
        [session setActive:YES error:&error];
        
        NSLog(@"[AudioFix] Successfully reset AVAudioSession to legacy fallback parameters.");
    } @catch (NSException *exception) {
        NSLog(@"[AudioFix] Failed to safely configure AVAudioSession: %@", exception.reason);
    }

    // Execute the original engine initialization code
    bool result = %orig(self);
    
    // If the engine failed to init because it still found nothing, 
    // returning true can sometimes force the engine loop to stay alive instead of throwing a null crash.
    if (!result) {
        NSLog(@"[AudioFix] Original InitDevice returned false. Forcing True to prevent crash.");
        return true; 
    }
    
    return result;
}

// Safety fallback: Intercept system interruptions that might clear the memory address mid-game
%hook UnityAppController // Often acts as a baseline if UE4 uses standard lifecycle delegates
-(void)audioSessionInterruption:(NSNotification*)notification {
    NSDictionary *interruptionDict = notification.userInfo;
    NSInteger interruptionType = [[interruptionDict valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        // Prevent the OS from aggressively tearing down the audio engine immediately
        NSLog(@"[AudioFix] Intercepted audio interruption to protect mixer thread.");
        return;
    }
    %orig;
}
%end
