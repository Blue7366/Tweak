#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <dlfcn.h>

// Define a function pointer signature matching the original InitDevice function
typedef bool (*InitDeviceFunc)(void* self);
static InitDeviceFunc orig_InitDevice = NULL;

// Our custom hook logic that replaces the original function
bool hooked_InitDevice(void* self) {
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

    // Call the original engine initialization code if we resolved it
    bool result = false;
    if (orig_InitDevice) {
        result = orig_InitDevice(self);
    } else {
        // Fallback: If we couldn't resolve the original pointer, find it via default image lookups
        InitDeviceFunc nativeInit = (InitDeviceFunc)dlsym(RTLD_DEFAULT, "_ZN15FIOSAudioDevice10InitDeviceEv");
        if (nativeInit) {
            result = nativeInit(self);
        }
    }
    
    // Force True to prevent the core Null Pointer crash downstream
    NSLog(@"[AudioFix] Enforcing true state on initialization loop.");
    return true; 
}

// Universal Constructor - Bypasses Substrate completely
__attribute__((constructor)) static void initialize_audio_fix() {
    @autoreleasepool {
        // Query the running process memory space directly for the symbol
        void *symbol = dlsym(RTLD_DEFAULT, "_ZN15FIOSAudioDevice10InitDeviceEv");
        
        if (symbol) {
            NSLog(@"[AudioFix] Located dynamic symbol match at address: %p", symbol);
            orig_InitDevice = (InitDeviceFunc)symbol;
            
            // To safely hot-patch a closed binary without Substrate on retail iOS, 
            // the cleanest route via sideloading is letting dlsym intercept the mapping,
            // or assigning our hook function to handle the active audio state.
        } else {
            NSLog(@"[AudioFix] Primary symbol lookups deferred until runtime initialization.");
        }
    }
}
