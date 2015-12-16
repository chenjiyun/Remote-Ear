//
//  XHRemoteEarClient.h
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/11/17.
//  Copyright © 2015年 XH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XHAudioReciever.h"

@interface XHRemoteEarClient : NSObject <NSStreamDelegate>

@property (nonatomic,strong) NSMutableData *data;
@property (nonatomic,strong) NSOutputStream *outputStream;
@property (nonatomic,strong) NSInputStream *inputStream;
@property (nonatomic) BOOL connectionFlag;
@property (nonatomic) XHAudioReciever *auRe;

-(void)connectToHost;
-(void)sendMessage:(NSString *)text;
-(void)stopStreams;

@end