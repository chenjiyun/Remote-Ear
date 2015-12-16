//
//  XHSendAudio.h
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/10/25.
//  Copyright © 2015年 XH. All rights reserved.
//

#include <AudioToolbox/AudioToolbox.h>
#include <Foundation/Foundation.h>
#include "XHRemoteEarServer.h"


class XHSendAudio
{
public:
    XHSendAudio();
    ~XHSendAudio();
    
    void startSendAudio();
    void stopSendAudio();
    BOOL IsRunning () const	{ return mIsRunning; }
    UInt64	startTime;
    
    
    static void packetsProc (
                             void            *inClientData,
                             UInt32            inNumberBytes,
                             UInt32            inNumberPackets,
                             const void *inInputData,
                             AudioStreamPacketDescription *inPacketDescriptions
                             );
    
    static void propertyListenerProc (
                                      void *inClientData,
                                      AudioFileStreamID inAudioFileStream,
                                      AudioFileStreamPropertyID inPropertyID,
                                      UInt32 *ioFlags
                                      );
    
private:
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[3];
    AudioFileStreamID mAudioFileStream;
    UInt32 bufferByteSize;
    SInt64 mCurrentPacket;
    BOOL mIsRunning;
    static NSData *audioData;
    static XHRemoteEarServer *res;

    static void handleInputBuffer (
                                   void                                *aqData,             // 1
                                   AudioQueueRef                       inAQ,                // 2
                                   AudioQueueBufferRef                 inBuffer,            // 3
                                   const AudioTimeStamp                *inStartTime,        // 4
                                   UInt32                              inNumPackets,        // 5
                                   const AudioStreamPacketDescription  *inPacketDesc        // 6
    );

    void deriveBufferSize (
                           AudioQueueRef                audioQueue,                  // 1
                           AudioStreamBasicDescription  ASBDescription,             // 2
                           Float64                      seconds,                     // 3
                           UInt32                       *outBufferSize               // 4
    
    );
    
    

};