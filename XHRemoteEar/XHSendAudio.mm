//
//  XHSendAudio.m
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/10/25.
//  Copyright © 2015年 XH. All rights reserved.
//

#import "XHSendAudio.h"
//#import "XHRemoteEarServer.h"

XHSendAudio::XHSendAudio()
{
    mIsRunning = false;
    //audioData = [[NSData alloc] init];
    res = [[XHRemoteEarServer alloc] init];
    [res startListen];
}

XHSendAudio::~XHSendAudio()
{
    AudioQueueDispose(mQueue, TRUE);
}


void XHSendAudio::handleInputBuffer(void *aqData,
                                    AudioQueueRef inAQ,
                                    AudioQueueBufferRef inBuffer,
                                    const AudioTimeStamp *inStartTime,
                                    UInt32 inNumPackets,
                                    const AudioStreamPacketDescription *inPacketDesc){
    
    XHSendAudio *pAqData = (XHSendAudio *) aqData;
    if (inNumPackets == 0 &&                                             // 2
        pAqData->mDataFormat.mBytesPerPacket != 0)
        inNumPackets =
        inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    
    if(AudioFileStreamParseBytes(pAqData ->mAudioFileStream,
                                 inBuffer ->mAudioDataByteSize,
                                 inBuffer->mAudioData,
                                 kAudioFileStreamParseFlag_Discontinuity
                                 ) == noErr){
        pAqData->mCurrentPacket += inNumPackets;
    }
    if (pAqData->mIsRunning == 0)                                         // 5
        return;
    
    AudioQueueEnqueueBuffer (                                            // 6
                             pAqData->mQueue,
                             inBuffer,
                             0,
                             NULL
                             );
    
    
}

void XHSendAudio::deriveBufferSize (
                                     AudioQueueRef audioQueue,
                                     AudioStreamBasicDescription  ASBDescription,
                                     Float64                      seconds,
                                     UInt32                       *outBufferSize){
    static const int maxBufferSize = 0x50000;                 // 5
    
    int maxPacketSize = ASBDescription.mBytesPerPacket;       // 6
    if (maxPacketSize == 0) {                                 // 7
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
    
    Float64 numBytesForTime =
    ASBDescription.mSampleRate * maxPacketSize * seconds;
    *outBufferSize =
    UInt32 (numBytesForTime < maxBufferSize ?
            numBytesForTime : maxBufferSize);
    
    
}

void XHSendAudio::packetsProc(void *inClientData,
                              UInt32 inNumberBytes,
                              UInt32 inNumberPackets,
                              const void *inInputData,
                              AudioStreamPacketDescription *inPacketDescriptions){
    
    audioData = [[NSData alloc] initWithBytes:inInputData length:inNumberBytes];
    [res sendAudio:audioData];
}

void XHSendAudio::propertyListenerProc(void *inClientData,
                                       AudioFileStreamID inAudioFileStream,
                                       AudioFileStreamPropertyID inPropertyID,
                                       UInt32 *ioFlags){
    
    
    
}



void XHSendAudio::startSendAudio(){
    mDataFormat.mFormatID = kAudioFormatLinearPCM;
    mDataFormat.mSampleRate = 16000;
    mDataFormat.mChannelsPerFrame = 1;
    mDataFormat.mBitsPerChannel = 16;
    mDataFormat.mBytesPerPacket = mDataFormat.mBytesPerFrame = mDataFormat.mChannelsPerFrame * sizeof(SInt16);
    mDataFormat.mFramesPerPacket = 1;
    
    mDataFormat.mFormatFlags =
    kLinearPCMFormatFlagIsBigEndian
    | kLinearPCMFormatFlagIsSignedInteger
    | kLinearPCMFormatFlagIsPacked;
    
    //create  Audio Queue
    AudioQueueNewInput(&mDataFormat,
                       handleInputBuffer,
                       this,
                       NULL,
                       kCFRunLoopCommonModes,
                       0,
                       &mQueue);
    
    UInt32 dataFormatSize = sizeof (mDataFormat);
    
    //What if we don't use this?
    AudioQueueGetProperty (
                           mQueue,
                           kAudioQueueProperty_StreamDescription,
                           &mDataFormat,
                           &dataFormatSize
                           );
    
    AudioFileStreamOpen(NULL,
                        propertyListenerProc,
                        packetsProc,
                        0,
                        &mAudioFileStream);
    
    
    //calculate the buffer size
    deriveBufferSize (
                      mQueue,
                      mDataFormat,
                      0.5,
                      &bufferByteSize
                      );
    
    //allocate the buffers
    for (int i = 0; i < 3; ++i) {
        AudioQueueAllocateBuffer (
                                  mQueue,
                                  bufferByteSize,
                                  &mBuffers[i]
                                  );
        
        AudioQueueEnqueueBuffer (
                                 mQueue,
                                 mBuffers[i],
                                 0,
                                 NULL
                                 );
    }
    
    //start audio queue
    mCurrentPacket = 0;
    mIsRunning = true;
    
    AudioQueueStart (
                     mQueue,
                     NULL
                     );
    
}
