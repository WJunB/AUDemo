//
//  AudioController.m
//  testtaskvoip
//
//  Created by Mykola on 6/2/15.
//  Copyright (c) 2015 The Kondratyuks. All rights reserved.
//

#import "AudioController.h"

@interface AudioController (){
    AudioStreamBasicDescription mAudioFormat;
}

- (void) setupAudioChain;

- (void) setupAudioSession;
- (void) setupVoiceIOUnit;



@end



#pragma mark
#pragma mark       set callback struct (class where all members are public)

struct CallbackData
{
    AudioUnit                voiceIOUnit;
    AudioController        * theSelf;
    //BufferManager*          bufferManager;
    //DCRejectionFilter*      dcRejectionFilter;
    BOOL                   * muteAudio;
    BOOL                   * audioChainIsBeingReconstructed;
    
    CallbackData():
    voiceIOUnit(NULL),
    theSelf(NULL),
    //bufferManager(NULL),
    muteAudio(NULL),
    audioChainIsBeingReconstructed(NULL) {}
    
}   callbackData;

// Render callback function

#pragma mark
#pragma mark    Render callback function

static OSStatus	performRender (
                                void                        *inRefCon,
                                AudioUnitRenderActionFlags 	*ioActionFlags,
                                const AudioTimeStamp 		*inTimeStamp,
                                UInt32 						 inBusNumber,
                                UInt32 						 inNumberFrames,
                                AudioBufferList             *ioData
                              )
{
    NSLog(@"\ninRefCon: %@ \n\n\n", inRefCon);
    
    AudioController *theSelf = (__bridge AudioController *) inRefCon;
    
    OSStatus err = noErr;
    err = AudioUnitRender(
                            callbackData.voiceIOUnit,   // AudioUnit                   inUnit
                            ioActionFlags,              // AudioUnitRenderActionFlags *ioActionFlags
                            inTimeStamp,                // const AudioTimeStamp       *inTimeStamp
                            1,                          // UInt32                      inOutputBusNumber
                            inNumberFrames,             // UInt32                      inNumberFrames
                            ioData                      // AudioBufferList            *ioData
                          );
    
   
    //  check on consol the
    
    Float32         data            = *(Float32 *) ioData->mBuffers[0].mData;
    
    AudioBufferList audioBufferList = *ioData;
    UInt32          mNumberBuffers  = audioBufferList.mNumberBuffers;
    
    NSLog(@"\nioData->mBuffers[0].mData = %f\nioData->mNumberBuffers = %d  \ninNumberFrames = %u\ninTimeStamp->mSampleTime = %f \n\n\n", data, (unsigned int)mNumberBuffers, (unsigned int)inNumberFrames, inTimeStamp->mSampleTime);
    
    NSData *packetFloatValue = [NSData dataWithBytes: &data
                                              length: 4 ];
    [theSelf.delegate sendVoIPPacketAfterRendering: packetFloatValue];
    /*
    if (*callbackData.audioChainIsBeingReconstructed == NO)
    {
        // we are calling AudioUnitRender on the input bus of AURemoteIO
        // this will store the audio data captured by the microphone in ioData
        
        err = AudioUnitRender(
                                callbackData.voiceIOUnit,   // AudioUnit                   inUnit
                                ioActionFlags,              // AudioUnitRenderActionFlags *ioActionFlags
                                inTimeStamp,                // const AudioTimeStamp       *inTimeStamp
                                1,                          // UInt32                      inOutputBusNumber
                                inNumberFrames,             // UInt32                      inNumberFrames
                                ioData                      // AudioBufferList            *ioData
                             );
        
        
        // based on the current display mode, copy the required data to the buffer manager
        
        //        if (cd.bufferManager->GetDisplayMode() == aurioTouchDisplayModeOscilloscopeWaveform)
        //        {
        //            cd.bufferManager->CopyAudioDataToDrawBuffer(
        //                                                            (Float32*)ioData->mBuffers[0].mData,
        //                                                            inNumberFrames
        //                                                       );
        //        }
        //
        //        else if ((cd.bufferManager->GetDisplayMode() == aurioTouchDisplayModeSpectrum) || (cd.bufferManager->GetDisplayMode() == aurioTouchDisplayModeOscilloscopeFFT))
        //        {
        //            if (cd.bufferManager->NeedsNewFFTData())
        //                cd.bufferManager->CopyAudioDataToFFTInputBuffer((Float32*)ioData->mBuffers[0].mData, inNumberFrames);
        //        }
        
        // mute audio if needed
        
        //        if (*cd.muteAudio)
        //        {
        //            for (UInt32 i=0; i<ioData->mNumberBuffers; ++i)
        //                memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
        //        }
    }
    */
    return err;
}


#pragma mark
#pragma mark    implementation AudioController

@implementation AudioController

#pragma mark
#pragma mark    designated initializer

- (id)init
{
    if (self = [super init])
    {
        _muteAudio         = NO;
        
        [self setupAudioChain];
    }
    return self;
}


#pragma mark
#pragma mark   internal methods for setup needed values

- (void)setupAudioChain
{
    [self setupAudioSession];
    [self setupVoiceIOUnit];
}


- (void)setupAudioSession
{
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        
    // we are going to play and record so we pick that category
    NSError *error = nil;
    [sessionInstance setCategory: AVAudioSessionCategoryPlayAndRecord
                           error: &error];
   // ZAssert((OSStatus)error.code, @"couldn't set session's audio category\n\n\n");
        
    // set the buffer duration to 5 ms
    //NSTimeInterval bufferDuration = .005;
    //[sessionInstance setPreferredIOBufferDuration: bufferDuration
    //                                        error: &error];
    //ZAssert((OSStatus)error.code, @"couldn't set session's I/O buffer duration\n\n\n");
        
    // set the session's sample rate
    //[sessionInstance setPreferredSampleRate: 44100
    //                                  error: &error];
    //ZAssert((OSStatus)error.code, @"couldn't set session's preferred sample rate\n\n\n");
        
    // add interruption handler
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleAVAudioSessionInterruptionNotification:)
                                                 name: AVAudioSessionInterruptionNotification
                                               object: sessionInstance];
        
    // ? route change notification
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleAVAudioSessionRouteChangeNotification:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: sessionInstance];
        
    // if media services are reset, we need to rebuild our audio chain
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleAVAudioSessionMediaServicesWereResetNotification:)                                                      name: AVAudioSessionMediaServicesWereResetNotification
                                               object: sessionInstance];
        
    // activate the audio session
    [[AVAudioSession sharedInstance] setActive: YES
                                         error: &error];
    //ZAssert((OSStatus)error.code, @"couldn't set session active\n\n\n");
    
    return;
}

- (void) handleAVAudioSessionInterruptionNotification: (NSNotification *) notification
{
    NSLog(@"\n\n\n");
    AVAudioSessionInterruptionType theInterruptionType = (AVAudioSessionInterruptionType) [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
        
    NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
        
    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan)
    {
        [self stopIOUnit];
    }
        
    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded)
    {
        // make sure to activate the session
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setActive: YES
                                             error: &error];
        if (nil != error)
        {
            NSLog(@"AVAudioSession set active failed with error: %@", error);
        }
        
        [self startIOUnit];
    }
    
}


- (void)handleAVAudioSessionRouteChangeNotification: (NSNotification *) notification
{
    NSLog(@"\n\n\n");
    AVAudioSessionRouteChangeReason reasonValue =  (AVAudioSessionRouteChangeReason)[[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey: AVAudioSessionRouteChangePreviousRouteKey];
    /*
    typedef NS_ENUM(NSUInteger, AVAudioSessionRouteChangeReason)
    {
        AVAudioSessionRouteChangeReasonUnknown = 0,
        AVAudioSessionRouteChangeReasonNewDeviceAvailable = 1,
        AVAudioSessionRouteChangeReasonOldDeviceUnavailable = 2,
        AVAudioSessionRouteChangeReasonCategoryChange = 3,
        AVAudioSessionRouteChangeReasonOverride = 4,
        AVAudioSessionRouteChangeReasonWakeFromSleep = 6,
        AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory = 7,
        AVAudioSessionRouteChangeReasonRouteConfigurationChange NS_ENUM_AVAILABLE_IOS(7_0) = 8
    } NS_AVAILABLE_IOS(6_0);
    */
    
    switch (reasonValue)
    {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
    
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        
        case AVAudioSessionRouteChangeReasonRouteConfigurationChange:
            NSLog(@"     RouteConfigurationChange");
            break;
            
        case AVAudioSessionRouteChangeReasonUnknown:
            NSLog(@"     ReasonUnknown");
            break;
    }
    
    NSLog(@"%@", routeDescription);
}

- (void) handleAVAudioSessionMediaServicesWereResetNotification: (NSNotification *)notification
{
    NSLog(@"Media server has reset\n\n\n");
    
    // rebuild the audio chain
    
    [self setupAudioChain];
    [self startIOUnit];
    
}

- (void) setupVoiceIOUnit
{
    NSLog(@"\n\n\n");
    
    // Create a new instance of AURemoteIO
        
    AudioComponentDescription desc;
    
    desc.componentType         = kAudioUnitType_Output;
    desc.componentSubType      = kAudioUnitSubType_VoiceProcessingIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags        = 0;
    desc.componentFlagsMask    = 0;
    
    AudioComponent comp = AudioComponentFindNext (
                                                    NULL,  //       AudioComponent                inComponent,
                                                    &desc  // const AudioComponentDescription *   inDesc
                                                 );
    OSStatus err = AudioComponentInstanceNew (
                                                comp,           // AudioComponent                  inComponent
                                                &_voiceIOUnit   // AudioComponentInstance *        outInstance
                                             );
//    ZAssert(err, @"couldn't create a new instance of Voice-Processing I/O unit\n\n\n");
    if (err)
    {
        sleep(0);
    }
        
    //  Enable input and output on Voice-Processing I/O unit
    //  Input  is enabled on the input  scope of the input element
    //  Output is enabled on the output scope of the output element
    
    UInt32           enableInput = 1;    // to enable input
    AudioUnitElement inputBus    = 1;
    err = AudioUnitSetProperty(
                                _voiceIOUnit,                           //  AudioUnit				inUnit
                                kAudioOutputUnitProperty_EnableIO,      //  AudioUnitPropertyID		inID
                                kAudioUnitScope_Input,                  //  AudioUnitScope			inScope
                                inputBus,                               //  AudioUnitElement		inElement
                                &enableInput,                           //  const void *			inData
                                sizeof (enableInput)                    //  UInt32					inDataSize
                              );
    //ZAssert(err, @"could not enable input on Voice-Processing I/O unit\n\n\n");
    if (err)
    {
        sleep(0);
    }

    
    UInt32           enableOutput = 1;    // to enable output explicit, by default it set to this value
    AudioUnitElement outputBus    = 0;

    err = AudioUnitSetProperty(
                                _voiceIOUnit,                           //  AudioUnit				inUnit
                                kAudioOutputUnitProperty_EnableIO,      //  AudioUnitPropertyID		inID
                                kAudioUnitScope_Output,                 //  AudioUnitScope			inScope
                                outputBus,                              //  AudioUnitElement		inElement
                                &enableOutput,                          //  const void *			inData
                                sizeof(enableOutput)                    //  UInt32					inDataSize
                              );
    //ZAssert(err, @"could not enable output on Voice-Processing I/O unit\n\n\n");
    if (err)
    {
        sleep(0);
    }
    Float64 sampleRate = [[AVAudioSession sharedInstance] sampleRate];

    //, "Couldn't get hardware samplerate");
    NSInteger kChannels = [[AVAudioSession sharedInstance] inputNumberOfChannels];

    
    mAudioFormat.mSampleRate         = sampleRate;
    mAudioFormat.mFormatID           = kAudioFormatLinearPCM;
    mAudioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    mAudioFormat.mFramesPerPacket    = 1;
    mAudioFormat.mChannelsPerFrame   = (UInt32)kChannels;
    mAudioFormat.mBitsPerChannel     = 16;
    mAudioFormat.mBytesPerFrame      = mAudioFormat.mBitsPerChannel*mAudioFormat.mChannelsPerFrame/8;
    mAudioFormat.mBytesPerPacket     = mAudioFormat.mBytesPerFrame*mAudioFormat.mFramesPerPacket;
    mAudioFormat.mReserved           = 0;
    //, "kAudioUnitProperty_StreamFormat::kAudioUnitScope_Output::kInputBus");
    err = AudioUnitSetProperty(_voiceIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    inputBus,
                                    &mAudioFormat,
                               sizeof(mAudioFormat));
    if (err) {
        sleep(0);
    }
    kChannels = [[AVAudioSession sharedInstance] outputNumberOfChannels];
        mAudioFormat.mChannelsPerFrame   = (UInt32)kChannels;
    //, "kAudioUnitProperty_StreamFormat::kAudioUnitScope_Input::kOutputBus")
    err = AudioUnitSetProperty(_voiceIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    outputBus,
                                    &mAudioFormat,
                                    sizeof(mAudioFormat));
    if (err) {
        sleep(0);
    }
//    UInt32 maxFramesPerSlice = 0;
//    UInt32 propSize = sizeof(UInt32);
    
//    err = AudioUnitGetProperty(
//                                _voiceIOUnit,
//                                kAudioUnitProperty_MaximumFramesPerSlice,
//                                kAudioUnitScope_Global,
//                                0,
//                                &maxFramesPerSlice,
//                                &propSize
//                              );
//    
//    if (err)
//    {
//        sleep(0);
//    }

//    NSLog(@"\nmax frames per slice = %d  in voice IO Unit\n\n\n", (unsigned int) maxFramesPerSlice);
    //_bufferManager = new BufferManager(maxFramesPerSlice);
    
    //
    // We need references to certain data in the render callback struct CallbackData
    //
    
    callbackData.voiceIOUnit                    = _voiceIOUnit;
    //cd.bufferManager                          = _bufferManager;
    //cd.dcRejectionFilter                      = _dcRejectionFilter;
    callbackData.muteAudio                      = &_muteAudio;
    //callbackData.audioChainIsBeingReconstructed = &audioChainIsBeingReconstructed;

    // Set the render callback on AU RemoteIO
    AURenderCallbackStruct                renderCallbackStruct;
    renderCallbackStruct.inputProc       = performRender;
    renderCallbackStruct.inputProcRefCon = (__bridge void *)self;
    
    OSStatus errorSetRenderCallback = 0;
    errorSetRenderCallback = AudioUnitSetProperty (
                                                    _voiceIOUnit,
                                                    kAudioUnitProperty_SetRenderCallback,
                                                    kAudioUnitScope_Input,
                                                    outputBus,
                                                    & renderCallbackStruct ,
                                                    sizeof(renderCallbackStruct)
                                                 );
    if (errorSetRenderCallback)
    {
        sleep(0);
    }
    
    
    // The audio data stream format for an audio unit input or output element (also called bus).
    
    // Initialize the AURemoteIO instance
    err = AudioUnitInitialize(_voiceIOUnit);
    //ZAssert(err, @"couldn't initialize AURemoteIO instance");
    
    if (err)
    {
        sleep(0);
    }

    
    //  Get & print the property AudioStreamBasicDescription (short as ASBD) value for input bus from instance of Voice-Processing I/O unit.
    //  AudioStreamBasicDescription  kAudioUnitProperty_StreamFormat
    
    AudioStreamBasicDescription inputBusASBD     = {0};
    UInt32                      inputBusASBD_Size = sizeof(inputBusASBD);
    err = AudioUnitGetProperty (
                                    _voiceIOUnit,                       //  AudioUnit           inUnit,
                                    kAudioUnitProperty_StreamFormat,    //  AudioUnitPropertyID inID,
                                    kAudioUnitScope_Input,              //  AudioUnitScope      inScope,
                                    inputBus,                           //  AudioUnitElement    inElement,
                                    & inputBusASBD,                     //  void                *outData,
                                    & inputBusASBD_Size                 //  UInt32              *ioDataSize
                                );
    
    if (err)
    {
        sleep(0);
    }

    [self  printASBD: inputBusASBD];
    
    //  Get & print the property AudioStreamBasicDescription value for output bus from instance of Voice-Processing I/O unit.
    //  AudioStreamBasicDescription  kAudioUnitProperty_StreamFormat
    
    AudioStreamBasicDescription outputBusASBD      = {0};
    UInt32                      outputBusASBD_Size = sizeof(outputBusASBD);
    err = AudioUnitGetProperty (
                                    _voiceIOUnit,                       //  AudioUnit           inUnit,
                                    kAudioUnitProperty_StreamFormat,    //  AudioUnitPropertyID inID,
                                    kAudioUnitScope_Output,             //  AudioUnitScope      inScope,
                                    outputBus,                          //  AudioUnitElement    inElement,
                                    & outputBusASBD,                    //  void                *outData,
                                    & outputBusASBD_Size                //  UInt32              *ioDataSize
                                );
    
    if (err)
    {
        sleep(0);
    }

    [self  printASBD: outputBusASBD];
    
    
    
    
}

#pragma mark
#pragma mark        external methods


- (OSStatus) startIOUnit
{
    NSLog(@" ");
    
    OSStatus err = AudioOutputUnitStart(_voiceIOUnit);
    
    if (err)
    {
        NSLog(@"couldn't start voiceIOUnit: %d", (int)err);
    }
    
    return err;
}

- (OSStatus) stopIOUnit
{
    OSStatus err = AudioOutputUnitStop(_voiceIOUnit);
    
    if (err)
    {
        NSLog(@"couldn't stop voiceIOUnit: %d", (int)err);
    }
    
    return err;
}


- (double)sessionSampleRate
{
    return [[AVAudioSession sharedInstance] sampleRate];
}



#pragma mark
#pragma mark    clear

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}


#pragma mark
#pragma mark     service for debug





- (void) printASBD: (AudioStreamBasicDescription) asbd
{
    NSLog(@" ");
    char formatIDString[5];
    // uint32_t CFSwapInt32HostToBig ( uint32_t arg ); -> Network data is big endian. Clients may be big endian (e.g. PowerPC Mac)
    // or little endian (e.g. x86 Mac). For printing in NSLog make our
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    
    bcopy (
            &formatID,
            formatIDString,
            4
          );
    
    formatIDString[4] = '\0';
    
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10X",    (unsigned int)asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10d",    (unsigned int)asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10d",    (unsigned int)asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10d",    (unsigned int)asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10d",    (unsigned int)asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10d",    (unsigned int)asbd.mBitsPerChannel);
    NSLog (@" \n\n\n");
    
}


- (void) printASPD: (AudioStreamPacketDescription) aspd
{
    NSLog(@" ");
    
    NSLog (@"  Start Offset:                 %lldl",                  aspd.mStartOffset);

    NSLog (@"  Variable Frames In Packet:    %10d",    (unsigned int) aspd.mVariableFramesInPacket);
    NSLog (@"  Data Byte Size:               %10d",    (unsigned int) aspd.mDataByteSize);
   
    NSLog (@" \n\n\n");
    
}

#pragma mark
#pragma mark NSObject protocol conforming


- (NSString *) description

{
    AudioUnitElement inputBus     = 1;
    AudioUnitElement outputBus    = 0;
    OSStatus err = 0;

    
    AudioStreamBasicDescription inputBusASBD     = {0};
    UInt32                      inputBusASBD_Size = sizeof(inputBusASBD);
    err = AudioUnitGetProperty (
                                _voiceIOUnit,                       //  AudioUnit           inUnit,
                                kAudioUnitProperty_StreamFormat,    //  AudioUnitPropertyID inID,
                                kAudioUnitScope_Input,              //  AudioUnitScope      inScope,
                                inputBus,                           //  AudioUnitElement    inElement,
                                & inputBusASBD,                     //  void                *outData,
                                & inputBusASBD_Size                 //  UInt32              *ioDataSize
                                );
    if (err)
    {
        sleep(0);
    }
    
    [self  printASBD: inputBusASBD];
    
    AudioStreamBasicDescription outputBusASBD      = {0};
    UInt32                      outputBusASBD_Size = sizeof(outputBusASBD);
    err = AudioUnitGetProperty (
                                _voiceIOUnit,                       //  AudioUnit           inUnit,
                                kAudioUnitProperty_StreamFormat,    //  AudioUnitPropertyID inID,
                                kAudioUnitScope_Output,             //  AudioUnitScope      inScope,
                                outputBus,                          //  AudioUnitElement    inElement,
                                & outputBusASBD,                    //  void                *outData,
                                & outputBusASBD_Size                //  UInt32              *ioDataSize
                                );
    if (err)
    {
        sleep(0);
    }
    
    [self  printASBD: outputBusASBD];
    
    
    NSMutableString* result = [NSMutableString string];
    
   // [result appendFormat: @"owner: %@\n", self.voiceIOUnit];
    [result appendFormat: @"mute audio: %@\n", self.muteAudio ? @"Yes" : @"NO"];
    
    return [result copy];
}



@end
