//
//  XHAudioSender.m
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/11/2.
//  Copyright © 2015年 XH. All rights reserved.
//

#import "XHAudioSender.h"

struct AQRecorderState{
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[3];
    AudioFileStreamID mAudioFileStream;
    NSOutputStream *outStream;
    UInt32 bufferByteSize;
    SInt64 mCurrentPacket;
    BOOL mIsRunning;
};

@implementation XHAudioSender

-(BOOL)isRunning{
    return self.aqData->mIsRunning;
}

-(void)setIsRunning:(BOOL)isRunning
{
    self.aqData->mIsRunning = isRunning;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        _aqData = new AQRecorderState;
        _res = [[XHRemoteEarServer alloc] init];
    }
    return self;
}

static void handleInputBuffer (
                                void                                  *aqData,
                                AudioQueueRef                         inAQ,
                                AudioQueueBufferRef                   inBuffer,
                                const AudioTimeStamp                  *inStartTime,
                                UInt32                                inNumPackets,
                                const AudioStreamPacketDescription    *inPacketDesc){
    
    AQRecorderState *pAqData = (AQRecorderState *)aqData;
    if (inNumPackets == 0 && pAqData->mDataFormat.mBytesPerPacket !=0){
        inNumPackets = inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    }
    
    /*
    NSLog(@"int size : %lu",sizeof(int));
    NSLog(@"long int size : %lu",sizeof(long int));
    NSLog(@"uint32_t size : %lu",sizeof(uint32_t));
    NSLog(@"uint8_t size : %lu",sizeof(uint8_t));
    NSLog(@"sint16 size : %lu",sizeof(SInt16));
    NSLog(@"Buffer AudioDataByteSize : %u",(unsigned int)inBuffer -> mAudioDataByteSize);
    NSLog(@"Buffer AudioDataBytesCapacity : %lu",inBuffer -> mAudioDataBytesCapacity);
    */
    
        NSLog(@"inNumberPackets = %u.",(unsigned int)inNumPackets);
    
    int num = [pAqData->outStream write:(uint8_t *)inBuffer->mAudioData
                                 maxLength:inBuffer->mAudioDataByteSize];
    NSLog(@"The value of num is :::: %d .NSError streamError ::: %@",num,pAqData->outStream);
    
    
    if(num){
        pAqData->mCurrentPacket += inNumPackets;
        NSLog(@"Number of Bytes Actually Written : %d",num);
    }
    
    /*
    if(AudioFileStreamParseBytes(pAqData ->mAudioFileStream,
                                 inBuffer ->mAudioDataByteSize,
                                 inBuffer ->mAudioData,
                                 kAudioFileStreamParseFlag_Discontinuity
                                 ) == noErr){
        pAqData->mCurrentPacket += inNumPackets;
        NSLog(@"Parse Bytes success!");
    }
     */
    if (pAqData->mIsRunning == 0)
        return;
    
    AudioQueueEnqueueBuffer (
                             pAqData->mQueue,
                             inBuffer,
                             0,
                             NULL
                             );
}

void deriveBufferSize (
                       AudioQueueRef                audioQueue,
                       AudioStreamBasicDescription  ASBDescription,
                       Float64                      seconds,
                       UInt32                      *outBufferSize){
    static const int maxBufferSize = 0x50000;
    
    int maxPacketSize = ASBDescription.mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty (
                               audioQueue,
                               kAudioQueueProperty_MaximumOutputPacketSize,
                               // in Mac OS X v10.5, instead use
                               //   kAudioConverterPropertyMaximumOutputPacketSize
                               &maxPacketSize,
                               &maxVBRPacketSize
                               );
    }
    
    Float64 numBytesForTime = ASBDescription.mSampleRate * maxPacketSize * seconds;
    *outBufferSize = UInt32 (numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize);
}

/*
void packetsProc(void *inClientData,
                              UInt32 inNumberBytes,
                              UInt32 inNumberPackets,
                              const void *inInputData,
                              AudioStreamPacketDescription *inPacketDescriptions){
    XHAudioSender *THIS = (__bridge XHAudioSender *)inClientData;
    NSData *audioData = [[NSData alloc] initWithBytes:inInputData length:inNumberBytes];
    [THIS.res sendAudio:audioData];
    NSLog(@"Send Audio Data ::::: %u",(unsigned int)inNumberBytes);
    
}

void propertyListenerProc(void *inClientData,
                                       AudioFileStreamID inAudioFileStream,
                                       AudioFileStreamPropertyID inPropertyID,
                                       UInt32 *ioFlags){
    if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        NSLog(@"Ready To Produce Packets !");
    }
    
    
}
*/


-(void) startSendAudio{
    
    self.aqData-> mDataFormat.mFormatID = kAudioFormatLinearPCM;
    self.aqData-> mDataFormat.mSampleRate = 16000;
    self.aqData-> mDataFormat.mChannelsPerFrame = 1;
    self.aqData-> mDataFormat.mBitsPerChannel = 16;
    self.aqData-> mDataFormat.mBytesPerPacket = self.aqData-> mDataFormat.mBytesPerFrame = self.aqData-> mDataFormat.mChannelsPerFrame * sizeof(SInt16);
    self.aqData-> mDataFormat.mFramesPerPacket = 1;
    
    self.aqData-> mDataFormat.mFormatFlags =
    kLinearPCMFormatFlagIsBigEndian
    | kLinearPCMFormatFlagIsSignedInteger
    | kLinearPCMFormatFlagIsPacked;
    
    //create  Audio Queue
    if(AudioQueueNewInput(&self.aqData->mDataFormat,
                          handleInputBuffer,
                          self.aqData,
                          NULL,
                          kCFRunLoopCommonModes,
                          0,
                          &self.aqData->mQueue) != noErr){
        NSLog(@"Open Audio Queue Error!");
        return;
    };
    
    UInt32 dataFormatSize = sizeof (self.aqData->mDataFormat);
    
    //What if we don't use this?
    AudioQueueGetProperty (
                           self.aqData->mQueue,
                           kAudioQueueProperty_StreamDescription,
                           &self.aqData->mDataFormat,
                           &dataFormatSize
                           );
    /*
    AudioFileStreamOpen((__bridge void*)self,
                        propertyListenerProc,
                        packetsProc,
                        0,
                        &self.aqData->mAudioFileStream);
    */
    
    self.aqData->outStream = self.res.serverOutputStream;
    
    //calculate the buffer size
    deriveBufferSize (
                      self.aqData->mQueue,
                      self.aqData->mDataFormat,
                      0.5,
                      &self.aqData->bufferByteSize
                      );
    
    //allocate the buffers
    for (int i = 0; i < 3; ++i) {
        AudioQueueAllocateBuffer (
                                  self.aqData->mQueue,
                                  self.aqData->bufferByteSize,
                                  &self.aqData->mBuffers[i]
                                  );
        
        AudioQueueEnqueueBuffer (
                                 self.aqData->mQueue,
                                 self.aqData->mBuffers[i],
                                 0,
                                 NULL
                                 );
    }
    
    //start audio queue
    self.aqData->mCurrentPacket = 0;
    self.aqData->mIsRunning = true;
    
    AudioQueueStart (
                     self.aqData->mQueue,
                     NULL
                     );
    
    
}

-(void) stopSending{
    AudioQueueStop(self.aqData->mQueue,
                   true
                   );
    self.aqData->mIsRunning = false;
    AudioQueueDispose(self.aqData->mQueue,
                      true
                      );
    AudioFileStreamClose(self.aqData->mAudioFileStream);
}
@end
