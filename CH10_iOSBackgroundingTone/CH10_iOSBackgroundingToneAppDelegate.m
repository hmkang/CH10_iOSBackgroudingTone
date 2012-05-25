//
//  CH10_iOSBackgroundingToneAppDelegate.m
//  CH10_iOSBackgroundingTone
//
//  Created by hmkang on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CH10_iOSBackgroundingToneAppDelegate.h"

#define FOREGROUND_FREQUENCY 880.0
#define BACKGROUND_FREQUENCY 523.25
#define BUFFER_COUNT 3
#define BUFFER_DURATION 0.5

@implementation CH10_iOSBackgroundingToneAppDelegate

@synthesize window = _window;
@synthesize streamFormat = _streamFormat;
@synthesize audioQueue, bufferSize, currentFrequency, startingFrameCount;

static void CheckError(OSStatus error, const char *operation) {
    if(error == noErr) return;
    char errorString[20];
    *(UInt32 *)(errorString+1)=CFSwapInt32HostToBig(error);
    if(isprint(errorString[1]) && isprint(errorString[2]) &&
       isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else {
        sprintf(errorString, "%d", (int)error);
    }
    
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

- (OSStatus) fillBuffer:(AudioQueueBufferRef)buffer {
    double j = self.startingFrameCount;
    double cycleLength = 44100. / self.currentFrequency;
    int frame = 0;
    double frameCount = bufferSize / self.streamFormat.mBytesPerFrame;
    for(frame=0; frame<frameCount; frame++) {
        SInt16 *data = (SInt16 *)buffer->mAudioData;
        (data)[frame] = (SInt16) (sin (2*M_PI * (j/cycleLength)) * 0x8000);
        j+=1.0;
        if(j>cycleLength) {
            j-=cycleLength;
        }
    }
    self.startingFrameCount = j;
    buffer->mAudioDataByteSize = bufferSize;
    return noErr;
}
static void MyAQOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer)
{
    CH10_iOSBackgroundingToneAppDelegate *appDelegate = (__bridge CH10_iOSBackgroundingToneAppDelegate*)inUserData;
    CheckError([appDelegate fillBuffer: inCompleteAQBuffer], "can't refill buffer");
    CheckError(AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, 0, NULL), "Couldn't enqueue the buffer (refill)");
    
}
void MyInterruptionListener(void *inUserData, UInt32 inInterruptionState) {
    printf("Interrupted! inInterruptionState=%ld\n", inInterruptionState);
    CH10_iOSBackgroundingToneAppDelegate *appDelegate = (__bridge CH10_iOSBackgroundingToneAppDelegate *)inUserData;
    switch(inInterruptionState) {
        case kAudioSessionBeginInterruption:
            break;
        case kAudioSessionEndInterruption:
            CheckError(AudioQueueStart(appDelegate.audioQueue, 0), "Couldn't restart the audio queue");
            break;
        default:
            break;
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CheckError(AudioSessionInitialize(NULL, kCFRunLoopDefaultMode, MyInterruptionListener, (__bridge void *)self),
               "Couldn't initialize the audio session");
    UInt32 category = kAudioSessionCategory_MediaPlayback;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category), "Couldn't set category on audio session");
    
    self.currentFrequency = FOREGROUND_FREQUENCY;
    _streamFormat.mSampleRate = 44100.0;
    _streamFormat.mFormatID = kAudioFormatLinearPCM;
    _streamFormat.mFormatFlags = kAudioFormatFlagsCanonical;
    _streamFormat.mChannelsPerFrame = 1;
    _streamFormat.mFramesPerPacket = 1;
    _streamFormat.mBitsPerChannel = 16;
    _streamFormat.mBytesPerFrame = 2;
    _streamFormat.mBytesPerPacket = 2;
    
    CheckError(AudioQueueNewOutput(&_streamFormat, MyAQOutputCallback, (__bridge void *)self, NULL, kCFRunLoopCommonModes, 0, &audioQueue), "Couldn't create the output AudioQeueue");
    
    AudioQueueBufferRef buffers [BUFFER_COUNT];
    bufferSize = BUFFER_DURATION * self.streamFormat.mSampleRate * self.streamFormat.mBytesPerFrame;
    NSLog(@"bufferSize is %ld", bufferSize);
    for(int i=0; i<BUFFER_COUNT; i++) {
        CheckError(AudioQueueAllocateBuffer(audioQueue, bufferSize, &buffers[i]), "Couldn't allocate the Audio Queue buffer");
        CheckError([self fillBuffer:buffers[i]], "Couldn't fill buffer (priming)");
        CheckError(AudioQueueEnqueueBuffer(audioQueue, buffers[i], 0, NULL), "Couldn't enqueue buffer (priming)");
    }
    
    CheckError(AudioQueueStart(audioQueue, NULL), "Couldn't start the AudioQueue");
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    self.currentFrequency = BACKGROUND_FREQUENCY;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    CheckError(AudioSessionSetActive(true), "Couldn't re-set audio session active");
    CheckError(AudioQueueStart(self.audioQueue, 0), "Couldn't restart audio queue");
    self.currentFrequency = FOREGROUND_FREQUENCY;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
