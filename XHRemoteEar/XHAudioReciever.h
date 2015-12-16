//
//  XHAudioReciever.h
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/11/17.
//  Copyright © 2015年 XH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
//#import "XHRemoteEarClient.h"

struct AQPlayState;

@interface XHAudioReciever : NSObject

@property (nonatomic) AQPlayState *aqData;
@property (nonatomic) BOOL isRunning;
//@property (nonatomic) XHRemoteEarClient *rec;

-(void) openAudioFileStream;
-(void) parseBytes:(const void*)buf forLength:(UInt32)length;
-(void) stopRecieving;

-(BOOL)isRunning;
-(void)setIsRunning:(BOOL)isRunning;

@end
