#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// Hook the standard iOS AVAudioSession activation call
__attribute__((constructor)) static void init_audio_interceptor() {
    @autoreleasepool {
        NSLog(@"[AudioFix] Interceptor loaded into HelloGuest execution space.");
        
        // Force standard hardware properties system-wide before the game engine can configure them
        NSError *error = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        [session setCategory:AVAudioSessionCategoryAmbient 
                 withOptions:AVAudioSessionCategoryOptionMixWithOthers 
                       error:&error];
        [session setPreferredSampleRate:44100.0 error:&error];
        [session setPreferredIOBufferDuration:0.0232 error:&error];
        [session setActive:YES error:&error];
        
        NSLog(@"[AudioFix] Global hardware session forced to legacy safe parameters.");
    }
}
