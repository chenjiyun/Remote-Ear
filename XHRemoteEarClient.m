//
//  XHRemoteEarClient.m
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/11/17.
//  Copyright © 2015年 XH. All rights reserved.
//

#import "XHRemoteEarClient.h"

@implementation XHRemoteEarClient

long int byteIndex = 0;

-(instancetype)init{
    self = [super init];
    if (self) {
        _auRe = [[XHAudioReciever alloc]init];
    }
    return self;
}

-(void)connectToHost{
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    NSString *hostNum = @"192.168.1.10";
    CFStringRef host = (__bridge CFStringRef)hostNum;
    
    CFStreamCreatePairWithSocketToHost(NULL, host, 23457, &readStream, &writeStream);
    
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
    //NSLog(@"inputstream status : %lu  outputstream status : %lu",(unsigned long)self.inputStream.streamStatus,self.outputStream.streamStatus);
    if (self.inputStream.streamStatus == kCFStreamStatusOpening && self.outputStream.streamStatus == kCFStreamStatusOpening) {
        self.connectionFlag = YES;
        NSLog(@"Connected!");
    }else{
        self.connectionFlag = NO;
        NSLog(@"connected faied!");
    }
    
}

-(void)sendMessage:(NSString *)text{
    if (self.outputStream.streamStatus == kCFStreamStatusOpen) {
        if (!self.data) {
            self.data = [NSMutableData data];
        }
        NSData *d = [text dataUsingEncoding:NSASCIIStringEncoding];
        
        [self.data appendData:d];
        
        [self stream:self.outputStream handleEvent:NSStreamEventHasSpaceAvailable];
        
        
    }
    return;
    
}

-(void)stopStreams{
    [self stream:self.inputStream handleEvent:NSStreamEventEndEncountered];
    [self stream:self.outputStream handleEvent:NSStreamEventEndEncountered];
    if (self.inputStream.streamStatus == kCFStreamStatusClosed &&self.outputStream.streamStatus == kCFStreamStatusClosed) {
        self.connectionFlag = NO;
    }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    
    //long int byteIndex = 0;
    switch(eventCode) {
            //write to stream
        case NSStreamEventHasSpaceAvailable:
        {
            
            uint8_t *readBytes = (uint8_t *)[self.data mutableBytes];
            readBytes += byteIndex; // instance variable to move pointer
            int dataLen = [self.data length];
            if (dataLen - byteIndex <= 0) {
                break;
            }
            long int len = ((dataLen - byteIndex >= 1024) ?
                            1024 : (dataLen-byteIndex));
            uint8_t buf[len];
            (void)memcpy(buf, readBytes, len);
            [(NSOutputStream*)stream write:(const uint8_t *)buf maxLength:len];
            NSLog(@"sending status : %lu",(unsigned long)stream.streamStatus);
            byteIndex += len;
            break;
            
        }
            //read from stream
        case NSStreamEventHasBytesAvailable:
        {
            if(!self.data) {
                self.data = [NSMutableData data];
            }
            uint8_t buf[1024];
            int len = 0;
            len = [(NSInputStream*)stream read:buf maxLength:1024];
            if(len) {
                //[self.data appendBytes:(const void *)buf length:len];
                
                //byteIndex += len;
                //uint8_t *buff;
                //(void)memcpy(buff, buf, len);
                [self.auRe parseBytes:buf forLength:len];
                
                
            } else {
                NSLog(@"no buffer!");
            }
            break;
        }
            //close stream
        case NSStreamEventEndEncountered:
        {
            
            [stream close];
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
            stream = nil; // stream is ivar, so reinit it
            NSLog(@"end encountered");
            break;
        }
            
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"Error!!!");
            
        }
            
    }
}

@end
