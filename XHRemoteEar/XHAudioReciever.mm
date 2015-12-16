//
//  XHAudioReciever.m
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/11/17.
//  Copyright © 2015年 XH. All rights reserved.
//

#import "XHAudioReciever.h"

struct AQPlayState{
    AudioStreamBasicDescription     mDataFormat;
    AudioQueueRef                   mQueue;
    AudioQueueBufferRef             mBuffers[3];
    AudioFileStreamID               mAudioFileStream;
    UInt32                          bufferByteSize;
    SInt64                          mCurrentPacket;
    UInt32                          mNumPacketsToRead;
    void const                      *auData;
    UInt32                          auNumBytes;
    UInt32                          auNumPackets;
    AudioStreamPacketDescription    *mPacketDescs;
    BOOL                            mIsRunning;
};

@implementation XHAudioReciever

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
        _aqData = new AQPlayState;
        //_rec = [[XHRemoteEarClient alloc]init];
    }
    return self;
}

static void handleOutputBuffer(
                                void *aqData,
                               AudioQueueRef inAQ,
                               AudioQueueBufferRef inBuffer){
    AQPlayState *pAqData = (AQPlayState *) aqData;
    //if (pAqData->mIsRunning == 0) return;
    UInt32 numPackets = pAqData->auNumPackets;
    
    memcpy(inBuffer->mAudioData, pAqData->auData, pAqData->auNumBytes);
    
    if (numPackets > 0) {
        inBuffer->mAudioDataByteSize = pAqData->auNumBytes;
        NSLog(@"Handle output buffer ~ The number of bytes : %d",(unsigned int)pAqData->auNumBytes);
        AudioQueueEnqueueBuffer (
                                 pAqData->mQueue,
                                 inBuffer,
                                 (pAqData->mPacketDescs ? numPackets : 0),
                                 pAqData->mPacketDescs
                                 );
        pAqData->mCurrentPacket += numPackets;
    } else {
        AudioQueueStop (
                        pAqData->mQueue,
                        false
                        );
        pAqData->mIsRunning = false;
        
    }
}

void deriveBufferSize (
                       AudioStreamBasicDescription &ASBDesc,
                       UInt32                      maxPacketSize,
                       Float64                     seconds,
                       UInt32                      *outBufferSize,
                       UInt32                      *outNumPacketsToRead
                       ){
    static const int maxBufferSize = 0x50000;
    static const int minBufferSize = 0x4000;
    
    if (ASBDesc.mFramesPerPacket != 0) {
        Float64 numPacketsForTime =
        ASBDesc.mSampleRate / ASBDesc.mFramesPerPacket * seconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {
        *outBufferSize =
        maxBufferSize > maxPacketSize ?
        maxBufferSize : maxPacketSize;
    }
    
    if (
        *outBufferSize > maxBufferSize &&
        *outBufferSize > maxPacketSize
        )
        *outBufferSize = maxBufferSize;
    else {
        if (*outBufferSize < minBufferSize)
            *outBufferSize = minBufferSize;
    }
    
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;
    
}

void packetsProc(void *inClientData,
                 UInt32 inNumberBytes,
                 UInt32 inNumberPackets,
                 const void *inInputData,
                 AudioStreamPacketDescription *inPacketDescriptions
                 ){
    XHAudioReciever *THIS = (__bridge XHAudioReciever *)inClientData;
    THIS.aqData->auData = inInputData;
    THIS.aqData->auNumBytes = inNumberBytes;
    THIS.aqData->auNumPackets = inNumberPackets;
    

    NSLog(@"Packets Processed ~ The number of bytes:%d",(unsigned int)inNumberBytes);
    
}

void propertyListenerProc(void *inClientData,
                          AudioFileStreamID inAudioFileStream,
                          AudioFileStreamPropertyID inPropertyID,
                          UInt32 *ioFlags){
    XHAudioReciever *THIS = (__bridge XHAudioReciever *)inClientData;
    
    UInt32 dataFormatSize = sizeof (THIS.aqData->mDataFormat);
    AudioFileStreamGetProperty(
                               THIS.aqData->mAudioFileStream,
                               kAudioFileStreamProperty_DataFormat,
                               &dataFormatSize,
                               &THIS.aqData->mDataFormat
                               );

    AudioQueueNewOutput(&THIS.aqData->mDataFormat,
                        handleOutputBuffer,
                        THIS.aqData,
                        //CFRunLoopGetCurrent(),
                        NULL,
                        kCFRunLoopCommonModes,
                        0,
                        &THIS.aqData->mQueue);
    
    NSLog(@"Audio queue openned ~ ");
    //Compute the maxPacketSize
    UInt32 maxPacketSize;
    UInt32 propertySize = sizeof (maxPacketSize);
    AudioFileStreamGetProperty (THIS.aqData->mAudioFileStream,
                                kAudioFileStreamProperty_PacketSizeUpperBound,
                                &propertySize,
                                &maxPacketSize
                                );
    //derive the queue buffer size
    deriveBufferSize (
                      THIS.aqData->mDataFormat,
                      maxPacketSize,
                      0.5,
                      &THIS.aqData->bufferByteSize,
                      &THIS.aqData->mNumPacketsToRead
                      );
    
    THIS.aqData->mCurrentPacket = 0;
    
    for (int i = 0; i < 3; ++i) {
        AudioQueueAllocateBuffer (
                                  THIS.aqData->mQueue,
                                  THIS.aqData->bufferByteSize,
                                  &THIS.aqData->mBuffers[i]
                                  );
        
        handleOutputBuffer (
                            THIS.aqData,
                            THIS.aqData->mQueue,
                            THIS.aqData->mBuffers[i]
                            );
    }
    
    //set play volume
    Float32 gain = 1.0;
    AudioQueueSetParameter (
                            THIS.aqData->mQueue,
                            kAudioQueueParam_Volume,
                            gain
                            );
    
    THIS.aqData->mIsRunning = true;
    AudioQueueStart (
                     THIS.aqData->mQueue,
                     NULL
                     );
    
    do {
        CFRunLoopRunInMode (
                            kCFRunLoopDefaultMode,
                            0.25,
                            false
                            );
    } while (THIS.aqData->mIsRunning);
}

-(void)parseBytes:(const void*)buf forLength:(UInt32)length{
    
    OSStatus err =  AudioFileStreamParseBytes(self.aqData ->mAudioFileStream,
                                 length,
                                 buf,
                                 kAudioFileStreamParseFlag_Discontinuity
                                              );
    if (err == noErr){
        NSLog(@"Parse Bytes success!");
    }else{
        NSLog(@"Parse Bytes Failed : err = %d",(int)err);
    }
}

-(void)openAudioFileStream{
    
    
    AudioFileStreamOpen((__bridge void*)self,
                        propertyListenerProc,
                        packetsProc,
                        0,
                        &self.aqData->mAudioFileStream);
    NSLog(@"Audio file stream openned ~");
    /*
    //get the dataformat of the file to play
    UInt32 dataFormatSize = sizeof (self.aqData->mDataFormat);
    
    AudioFileStreamGetProperty(   self.aqData->mAudioFileStream,
                         kAudioFileStreamProperty_DataFormat,
                         &dataFormatSize,
                         &self.aqData->mDataFormat
                         );
    
    //Create Audio Queue
    AudioQueueNewOutput(&self.aqData->mDataFormat,
                        handleOutputBuffer,
                        self.aqData,
                        NULL,
                        kCFRunLoopCommonModes,
                        0,
                        &self.aqData->mQueue);
    
    //Compute the maxPacketSize
    UInt32 maxPacketSize;
    UInt32 propertySize = sizeof (maxPacketSize);
    AudioFileStreamGetProperty (self.aqData->mAudioFileStream,
                          kAudioFileStreamProperty_PacketSizeUpperBound,
                          &propertySize,
                          &maxPacketSize
                          );
    //derive the queue buffer size
    deriveBufferSize (
                      self.aqData->mDataFormat,
                      maxPacketSize,
                      0.5,
                      &self.aqData->bufferByteSize,
                      &self.aqData->mNumPacketsToRead
                      );
    */
    /*
    //decide mPacketDescs by VBR/CBR
    bool isFormatVBR = (
                        self.aqData->mDataFormat.mBytesPerPacket == 0 ||
                        self.aqData->mDataFormat.mFramesPerPacket == 0
                        );
    
    if (isFormatVBR) {
        self.aqData->mPacketDescs =
        (AudioStreamPacketDescription*) malloc (
                                                self.aqData->mNumPacketsToRead * sizeof (AudioStreamPacketDescription)
                                                );
    } else {
        self.aqData->mPacketDescs = NULL;
    }
    
    //Set magic cookie from the audio file if there is any
    UInt32 cookieSize = sizeof (UInt32);
    bool couldNotGetProperty =
    AudioFileStreamGetPropertyInfo (
                              self.aqData->mAudioFileStream,
                              kAudioFileStreamProperty_MagicCookieData,
                              &cookieSize,
                              NULL
                              );
    
    if (!couldNotGetProperty && cookieSize) {
        char* magicCookie =
        (char *) malloc (cookieSize);
        
        AudioFileStreamGetProperty (
                              self.aqData->mAudioFileStream,
                              kAudioFilePropertyMagicCookieData,
                              &cookieSize,
                              magicCookie
                              );
        
        AudioQueueSetProperty (
                               self.aqData->mQueue,
                               kAudioQueueProperty_MagicCookie,
                               magicCookie,
                               cookieSize
                               );
        
        free (magicCookie);
    }
     
     */
    /*
    //allocate and prime audio queue buffers
    self.aqData->mCurrentPacket = 0;
    
    for (int i = 0; i < 3; ++i) {
        AudioQueueAllocateBuffer (
                                  self.aqData->mQueue,
                                  self.aqData->bufferByteSize,
                                  &self.aqData->mBuffers[i]
                                  );
        
        handleOutputBuffer (
                            self.aqData,
                            self.aqData->mQueue,
                            self.aqData->mBuffers[i]
                            );
    }
    
    //set play volume
    Float32 gain = 1.0;
    AudioQueueSetParameter (
                            self.aqData->mQueue,
                            kAudioQueueParam_Volume,
                            gain
                            );
    
    //start to run the audio queue
    self.aqData->mIsRunning = true;
    AudioQueueStart (
                     self.aqData->mQueue,
                     NULL
                     );
    
    do {
        CFRunLoopRunInMode (
                            kCFRunLoopDefaultMode,
                            0.25,
                            false
                            );
    } while (self.aqData->mIsRunning);
    
    CFRunLoopRunInMode (
                        kCFRunLoopDefaultMode,
                        1,
                        false
                        );
    
    
    AudioQueueStop (
                    self.aqData->mQueue,
                    true
                    );
    
    AudioQueueDispose (
                       self.aqData->mQueue,
                       true
                       );
    
    AudioFileStreamClose (self.aqData->mAudioFileStream);
    free (self.aqData->mPacketDescs);
    
    self.aqData->mIsRunning = false;
    */
}

-(void)stopRecieving{
    AudioQueueStop (
                    self.aqData->mQueue,
                    true
                    );
    
    AudioQueueDispose (
                       self.aqData->mQueue,
                       true
                       );
    
    AudioFileStreamClose (self.aqData->mAudioFileStream);
    //free (self.aqData->mPacketDescs);
    
    self.aqData->mIsRunning = false;
}

@end
