//
//  CH10_iOSBackgroundingToneAppDelegate.h
//  CH10_iOSBackgroundingTone
//
//  Created by hmkang on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface CH10_iOSBackgroundingToneAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, assign) AudioQueueRef audioQueue;
@property (nonatomic, assign) AudioStreamBasicDescription streamFormat;
@property (nonatomic, assign) UInt32 bufferSize;
@property (nonatomic, assign) double currentFrequency;
@property (nonatomic, assign) double startingFrameCount;

- (OSStatus) fillBuffer: (AudioQueueBufferRef) buffer;

@end
