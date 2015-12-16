//
//  XHRemoteServer.m
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/10/24.
//  Copyright © 2015年 XH. All rights reserved.
//


#import "XHRemoteEarServer.h"
#import <sys/socket.h>
#import <netinet/in.h>


@implementation XHRemoteEarServer

uint8_t sByteIndex = 0;

-(void)startListen{
    CFSocketContext CTX = {0, (__bridge void*)self, NULL, NULL, NULL};
    self.myipv4cfsock = CFSocketCreate(kCFAllocatorDefault,
                                       PF_INET,
                                       SOCK_STREAM,
                                       IPPROTO_TCP,
                                       kCFSocketAcceptCallBack,
                                       handleConnect,
                                       &CTX);
    
    struct   sockaddr_in  addr;
    memset(&addr , 0,sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(23457);
    addr.sin_addr.s_addr =INADDR_ANY;
    
    CFDataRef sincfd = CFDataCreate(
                                    kCFAllocatorDefault,
                                    (UInt8 *)&addr,
                                    sizeof(addr));
    
    if (kCFSocketSuccess != CFSocketSetAddress(self.myipv4cfsock, sincfd)){
        NSLog(@"Bind to address failed !");
        if (self.myipv4cfsock)
            CFRelease(self.myipv4cfsock);
        self.myipv4cfsock = NULL;
    };
    
    CFRelease(sincfd);
    
    if (!self.socketsource) {
        self.socketsource = CFSocketCreateRunLoopSource(
                                                        kCFAllocatorDefault,
                                                        self.myipv4cfsock,
                                                        0);
    }
    
    
    CFRunLoopAddSource(
                       CFRunLoopGetCurrent(),
                       self.socketsource,
                       kCFRunLoopDefaultMode);
    
    if (CFRunLoopContainsSource(CFRunLoopGetCurrent(),
                                self.socketsource,
                                kCFRunLoopDefaultMode)){
        NSLog(@"Runloop contains the source : socketsource");
        self.connectFlag = YES;
        
    }
    
}


void handleConnect ( CFSocketRef s,
                    CFSocketCallBackType callbackType,
                    CFDataRef address,
                    const void *data,
                    void *info ){
    XHRemoteEarServer *THIS = (__bridge XHRemoteEarServer *)info;
    if (callbackType == kCFSocketAcceptCallBack) {
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocket(NULL,
                                     *(CFSocketNativeHandle*)data,
                                     &readStream,
                                     &writeStream);
        
        THIS.serverInputStream = (__bridge_transfer NSInputStream *)readStream;
        THIS.serverOutputStream = (__bridge_transfer NSOutputStream *)writeStream;
        
        [THIS.serverInputStream setDelegate:THIS];
        [THIS.serverOutputStream setDelegate:THIS];
        
        [THIS.serverInputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [THIS.serverOutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [THIS.serverInputStream open];
        [THIS.serverOutputStream open];
    }
    

}


- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    
    switch(eventCode) {
            //write to stream
        case NSStreamEventHasSpaceAvailable:
        {
            NSLog(@">>>>>>>>>>>>>>>");
            uint8_t *readBytes = (uint8_t *)[self.data mutableBytes];
            readBytes += sByteIndex; // instance variable to move pointer
            uint8_t dataLen = [self.data length];
            if (dataLen - sByteIndex <= 0) {
                break;
            }
            long int len = ((dataLen - sByteIndex >= 1024) ?
                            1024 : (dataLen-sByteIndex));
            uint8_t buf[len];
            (void)memcpy(buf, readBytes, len);
            [(NSOutputStream*)stream write:(const uint8_t *)buf maxLength:len];
            NSLog(@"sending status : %lu",(unsigned long)stream.streamStatus);
            sByteIndex += len;
            break;
            
        }
            //read from stream
        case NSStreamEventHasBytesAvailable:
        {
            if(!self.data) {
                self.data = [NSMutableData data];
            }
            uint8_t buf[1024];
            long int len = 0;
            len = [(NSInputStream*)stream read:buf maxLength:1024];
            if(len) {
                [self.data appendBytes:(const void *)buf length:len];
                // bytesRead is an instance variable of type NSNumber.
                //[bytesRead setIntValue:[bytesRead intValue]+len];
                sByteIndex += len;
                
                //call the display message block
                if(self.displayMessageBlock){
                    self.displayMessageBlock(self.data);
                }
                
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

-(void)sendMessage:(NSString *)text{
    if (!self.data) {
        self.data = [NSMutableData data];
    }
    NSData *d = [text dataUsingEncoding:NSASCIIStringEncoding];
    
    [self.data appendData:d];
    
    [self stream:self.serverOutputStream handleEvent:NSStreamEventHasSpaceAvailable];
}

-(void)sendAudio:(NSData *)d{
    if (!self.data) {
        self.data = [NSMutableData data];
    }
    [self.data appendData:d];
    
    [self stream:self.serverOutputStream handleEvent:NSStreamEventHasSpaceAvailable];

}

-(void)stopListen{
    [self stream:self.serverInputStream handleEvent:NSStreamEventEndEncountered];
    [self stream:self.serverOutputStream handleEvent:NSStreamEventEndEncountered];
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(),
                          self.socketsource,
                          kCFRunLoopDefaultMode);
    if(!CFRunLoopContainsSource(CFRunLoopGetCurrent(),
                                self.socketsource,
                                kCFRunLoopDefaultMode)){
        NSLog(@"socketsource remove from Runloop successfully.");
        self.connectFlag = NO;
    }else{
        NSLog(@"socketsource still on the runloop!");
    }
    //CFRelease(self.myipv4cfsock);
    //self.socketsource = NULL;
    
}


@end

