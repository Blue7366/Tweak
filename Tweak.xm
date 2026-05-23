#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <substrate.h>

// Define a function pointer signature matching the original InitDevice function
typedef bool (*InitDeviceFunc)(void* self);
static InitDeviceFunc orig_InitDevice = NULL;

// Our custom hook logic that replaces the original function
bool hooked_InitDevice(void* self) {
    // FORCE iOS into a backward-compatible standard audio state 
    // BEFORE Unreal Engine attempts to poll the hardware pointers.
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    @try {
        [session setCategory:AVAudioSessionCategoryAmbient 
                 withOptions:AVAudioSessionCategoryOptionMixWithOthers 
                       error:&error];
        
        [session setPreferredSampleRate:44100.0 error:&error];
        [session setPreferredIOBufferDuration:0.0232 error:&error];
        [session setActive:YES error:&error];
        
        NSLog(@"[AudioFix] Successfully reset AVAudioSession to legacy fallback parameters.");
    } @catch (NSException *exception) {
        NSLog(@"[AudioFix] Failed to safely configure AVAudioSession: %@", exception.reason);
    }

    // Call the original engine initialization code using our pointer
    bool result = false;
    if (orig_InitDevice) {
        result = orig_InitDevice(self);
    }
    
    // If the engine failed to init because it still found nothing, 
    // forcing true can prevent the Null Pointer crash downstream.
    if (!result) {
        NSLog(@"[AudioFix] Original InitDevice returned false. Forcing True to prevent crash.");
        return true; 
    }
    
    return result;
}

// Cydia Substrate initialization block
%ctl{init} {
    @autoreleasepool {
        // Look up the mangled C++ symbol dynamically at runtime using MSFindSymbol
        // This stops the compiler from throwing a linker error during compilation.
        void *symbol = MSFindSymbol(NULL, "_ZN15FIOSAudioDevice10InitDeviceEv");
        
        if (symbol) {
            NSLog(@"[AudioFix] Found FIOSAudioDevice::InitDevice symbol dynamically!");
            MSHookFunction(symbol, (void *)hooked_InitDevice, (void **)&orig_InitDevice);
        } else {
            NSLog(@"[AudioFix] Warning: Could not find the audio init symbol in the current image.");
        }
    }
}
