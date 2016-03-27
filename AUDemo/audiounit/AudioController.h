//
//  AudioController.h
//  testtaskvoip
//
//  Created by Mykola on 6/2/15.
//  Copyright (c) 2015 The Kondratyuks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>


@protocol AudioControllerDelegate <NSObject>

- (void) sendVoIPPacketAfterRendering: (NSData *) packet;

@end




@interface AudioController : NSObject

@property (nonatomic, assign, readonly ) AudioUnit                    voiceIOUnit;

@property (nonatomic, assign           ) BOOL                         muteAudio;  // default value == NO

@property (nonatomic, weak             ) id <AudioControllerDelegate> delegate;

- (OSStatus)       startIOUnit;

- (OSStatus)       stopIOUnit;

- (double)         sessionSampleRate;


@end


// for hint :)


/*
    AudioUnitElement inputBus     = 1;

    AudioUnitElement outputBus    = 0;
 
    OSStatus err
*/


/*
  ObjC:
 struct AudioTimeStamp 
 {      Float64     mSampleTime;
        UInt64      mHostTime;
        Float64     mRateScalar;
        UInt64      mWordClockTime; 
        SMPTETime   mSMPTETime; 
        UInt32      mFlags; 
        UInt32      mReserved; 
 }
 
 typedef struct AudioTimeStamp AudioTimeStamp;
 
 struct AudioBufferList 
 {  
        UInt32          mNumberBuffers;
        AudioBuffer     mBuffers[1]; 
 };
 
 typedef struct AudioBufferList AudioBufferList;
 
 
 struct AudioBuffer
 {
        UInt32  mNumberChannels;
        UInt32  mDataByteSize;
        void*   mData;
 };

 
 
 */

/*
 struct AudioStreamBasicDescription
 {
        Float64             mSampleRate;
        AudioFormatID       mFormatID;
        AudioFormatFlags    mFormatFlags;
        UInt32              mBytesPerPacket;
        UInt32              mFramesPerPacket;
        UInt32              mBytesPerFrame;
        UInt32              mChannelsPerFrame;
        UInt32              mBitsPerChannel;
        UInt32              mReserved;
 };
 */

/*
 enum {
 kAudioFormatLinearPCM               = 'lpcm',
 kAudioFormatAC3                     = 'ac-3',
 kAudioFormat60958AC3                = 'cac3',
 kAudioFormatAppleIMA4               = 'ima4',
 kAudioFormatMPEG4AAC                = 'aac ',
 kAudioFormatMPEG4CELP               = 'celp',
 kAudioFormatMPEG4HVXC               = 'hvxc',
 kAudioFormatMPEG4TwinVQ             = 'twvq',
 kAudioFormatMACE3                   = 'MAC3',
 kAudioFormatMACE6                   = 'MAC6',
 kAudioFormatULaw                    = 'ulaw',
 kAudioFormatALaw                    = 'alaw',
 kAudioFormatQDesign                 = 'QDMC',
 kAudioFormatQDesign2                = 'QDM2',
 kAudioFormatQUALCOMM                = 'Qclp',
 kAudioFormatMPEGLayer1              = '.mp1',
 kAudioFormatMPEGLayer2              = '.mp2',
 kAudioFormatMPEGLayer3              = '.mp3',
 kAudioFormatTimeCode                = 'time',
 kAudioFormatMIDIStream              = 'midi',
 kAudioFormatParameterValueStream    = 'apvs',
 kAudioFormatAppleLossless           = 'alac'
 kAudioFormatMPEG4AAC_HE             = 'aach',
 kAudioFormatMPEG4AAC_LD             = 'aacl',
 kAudioFormatMPEG4AAC_ELD            = 'aace',
 kAudioFormatMPEG4AAC_ELD_SBR        = 'aacf',
 kAudioFormatMPEG4AAC_HE_V2          = 'aacp',
 kAudioFormatMPEG4AAC_Spatial        = 'aacs',
 kAudioFormatAMR                     = 'samr',
 kAudioFormatAudible                 = 'AUDB',
 kAudioFormatiLBC                    = 'ilbc',
 kAudioFormatDVIIntelIMA             = 0x6D730011,
 kAudioFormatMicrosoftGSM            = 0x6D730031,
 kAudioFormatAES3                    = 'aes3'
 };
 */


/*
 struct  AudioStreamPacketDescription
 {
 SInt64  mStartOffset;
 UInt32  mVariableFramesInPacket;
 UInt32  mDataByteSize;
 };
 */

//AudioStreamPacketDescription  ???
/*
 struct  AudioStreamPacketDescription
 {
 SInt64  mStartOffset;
 UInt32  mVariableFramesInPacket;
 UInt32  mDataByteSize;
 };
 */

/*!
 @typedef		AURenderCallback
 @discussion		This is the prototype for a function callback Proc that is used both with the
 AudioUnit render notification API and the render input callback. See
 kAudioUnitProperty_SetRenderCallback property or AudioUnitAddRenderNotify.
 This callback is part of the process of a call to AudioUnitRender. As a
 notification it is called either before or after the audio unit's render
 operations. As a render input callback, it is called to provide input data for
 the particular input bus the callback is attached too.
 
 @param			inRefCon
 The client data that is provided either with the AURenderCallbackStruct or as
 specified with the Add API call
 @param			ioActionFlags
 Flags used to describe more about the context of this call (pre or post in the
 notify case for instance)
 @param			inTimeStamp
 The times stamp associated with this call of audio unit render
 @param			inBusNumber
 The bus number associated with this call of audio unit render
 @param			inNumberFrames
 The number of sample frames that will be represented in the audio data in the
 provided ioData parameter
 @param			ioData
 The AudioBufferList that will be used to contain the rendered or provided
 audio data. These buffers will be aligned to 16 byte boundaries (which is
 normally what malloc will return).
 
 typedef OSStatus (*AURenderCallback)
 (	void *							inRefCon,
    AudioUnitRenderActionFlags *	ioActionFlags,
    const AudioTimeStamp *			inTimeStamp,
    UInt32							inBusNumber,
    UInt32							inNumberFrames,
    AudioBufferList *				ioData
 );
 
 
 */


