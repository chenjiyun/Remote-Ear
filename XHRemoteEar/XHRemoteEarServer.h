//
//  XHRemoteServer.h
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/10/24.
//  Copyright © 2015年 XH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XHRemoteEarServer : NSObject <NSStreamDelegate>

@property (nonatomic,strong) NSOutputStream *serverOutputStream;
@property (nonatomic,strong) NSInputStream *serverInputStream;
@property (nonatomic)CFSocketRef myipv4cfsock;
@property (nonatomic)CFRunLoopSourceRef socketsource;
@property (nonatomic,strong)  NSMutableData *data;
@property (nonatomic,copy) void (^displayMessageBlock)(NSData *dat);
@property (nonatomic) BOOL connectFlag;


-(void)startListen;

-(void)sendMessage:(NSString *)text;

-(void)sendAudio:(NSData *)d;
-(void)stopListen;

@end
