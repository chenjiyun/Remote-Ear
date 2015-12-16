//
//  XHAudioSender.h
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/11/2.
//  Copyright © 2015年 XH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "XHRemoteEarServer.h"

struct AQRecorderState;

@interface XHAudioSender : NSObject

@property (nonatomic) AQRecorderState *aqData;
@property (nonatomic) BOOL isRunning;
@property (nonatomic) NSData *audioData;
@property (nonatomic) XHRemoteEarServer *res;
-(void) startSendAudio;
-(void) stopSending;

-(BOOL)isRunning;
-(void)setIsRunning:(BOOL)isRunning;


@end
