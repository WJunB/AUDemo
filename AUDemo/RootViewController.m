//
//  ViewController.m
//  AUDemo
//
//  Created by jun on 16/3/15.
//  Copyright © 2016年 jun. All rights reserved.
//



#import "RootViewController.h"
#import "udpsocket.h"
#import "package.h"
#define BUFFER_SIZE 2048
#define kChannels   1
#define kOutputBus  0
#define kInputBus   1
#define krOutputBus 2
#define krInputBus  3

extern udpsocket *udp;
extern NSMutableArray *audioQueue;

@interface RootViewController ()
@end


@implementation RootViewController
@synthesize frame_id;

- (id)init
{
    self = [super init];
    if (self) {
        isRecording=FALSE;
        isPlaying=FALSE;
        flag = FALSE;
        frame_id = 0;
    }
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
static void CheckError(OSStatus error,const char *operaton){
    if (error==noErr) {
        return;
    }
    char errorString[20]={};
    *(UInt32 *)(errorString+1)=CFSwapInt32HostToBig(error);
    if (isprint(errorString[1])&&isprint(errorString[2])&&isprint(errorString[3])&&isprint(errorString[4])) {
        errorString[0]=errorString[5]='\'';
        errorString[6]='\0';
    }else{
        sprintf(errorString, "%d",(int)error);
    }
    fprintf(stderr, "Error:%s (%s)\n",operaton,errorString);
    exit(1);
}
void audioInterruptionListener(void *inClientData,UInt32 inInterruptionState){
    printf("Interrupted! inInterruptionState=%ld\n",inInterruptionState);
    //RootViewController *appDelegate=(RootViewController *)inClientData;
    switch (inInterruptionState) {
        case kAudioSessionBeginInterruption:
            break;
        case kAudioSessionEndInterruption:
            /*
             CheckError(AudioSessionSetActive(true), "Couldn't set audio session active");
             CheckError(AudioUnitInitialize(appDelegate->mAudioUnit), "Couldn't initialize RIO unit");
             CheckError(AudioOutputUnitStart(appDelegate->mAudioUnit), "Couldn't start RIO unit");
             */
            break;
        default:
            break;
    }
}
void audioRouteChangeListener(  void                    *inClientData,
                              AudioSessionPropertyID    inID,
                              UInt32                    inDataSize,
                              const void                *inData){
    printf("audioRouteChangeListener");
    /*
     CFStringRef routeStr;
     UInt32 properSize=sizeof(routeStr);
     AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &properSize, &routeStr);
     NSString *routeNSStr=(NSString *)routeStr;
     NSLog(@"audioRouteChange::%@",routeNSStr);//none:ReceiverAndMicrophone ipod:HeadphonesAndMicrophone iphone:HeadsetInOut xiaomi:HeadsetInOut
     UIAlertView *alertView=[[UIAlertView alloc] initWithTitle:routeNSStr message:routeNSStr delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles:@"other", nil];
     [alertView show];
     [alertView release];
     */
}
OSStatus recordCallback(void                                        *inRefCon,
                        AudioUnitRenderActionFlags        *ioActionFlags,
                        const AudioTimeStamp              *inTimeStamp,
                        UInt32                            inBusNumber,
                        UInt32                            inNumberFrames,
                        AudioBufferList                   *ioData){
    printf("record::%u,",(unsigned int)inNumberFrames);
    //double timeInSeconds = inTimeStamp->mSampleTime / kSampleRate;
    //printf("\n%fs inBusNumber:%lu inNumberFrames:%lu", timeInSeconds, inBusNumber, inNumberFrames);
    
    AudioBufferList bufferList;
    UInt16 numSamples=inNumberFrames*kChannels;
    UInt16 samples[numSamples];
    memset (&samples, 0, sizeof (samples));
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = samples;
    bufferList.mBuffers[0].mNumberChannels = kChannels;
    bufferList.mBuffers[0].mDataByteSize = numSamples*sizeof(UInt16);
    RootViewController* THIS = (__bridge RootViewController *)inRefCon;
    CheckError(AudioUnitRender(THIS->mAudioUnit,
                               ioActionFlags,
                               inTimeStamp,
                               kInputBus,
                               inNumberFrames,
                               &bufferList),"AudioUnitRender failed");
    
    // Now, we have the samples we just read sitting in buffers in bufferList
//    ExtAudioFileWriteAsync(THIS->mAudioFileRef, inNumberFrames, &bufferList);
    
    char *frameBuffer = bufferList.mBuffers[0].mData;
    
//    UInt32 count=inNumberFrames;
    NSData *data;
//    for (int j = 0; j < count; j++){
        data = [[NSData alloc]initWithBytes:frameBuffer length:bufferList.mBuffers[0].mDataByteSize];
    THIS->frame_id++;
    [udp SendAudioByData:data frame_len:[data length] frame_id:THIS->frame_id];

//    }
    
    return noErr;
}
OSStatus playCallback(void                                      *inRefCon,
                      AudioUnitRenderActionFlags      *ioActionFlags,
                      const AudioTimeStamp            *inTimeStamp,
                      UInt32                          inBusNumber,
                      UInt32                          inNumberFrames,
                      AudioBufferList                 *ioData){
   
    RootViewController* this = (__bridge RootViewController *)inRefCon;
    
    /*
     UInt8 *frameBuffer = ioData->mBuffers[0].mData;
     UInt32 count=inNumberFrames*4;
     for (int j = 0; j < count; ){
     UInt32 packet=[this->inMemoryAudioFile getNextFrame];
     frameBuffer[j]=packet;
     frameBuffer[j+1]=packet>>8;
     //Above for the left channel, right channel following
     frameBuffer[j+2]=packet>>16;
     frameBuffer[j+3]=packet>>24;
     j+=4;
     }
     */
    /*
     UInt16 *frameBuffer = ioData->mBuffers[0].mData;
     UInt32 count=inNumberFrames*2;
     for (int j = 0; j < count; ){
     UInt32 packet=[this->inMemoryAudioFile getNextFrame];
     frameBuffer[j]=packet;//left channel
     frameBuffer[j+1]=packet>>16;//right channel
     j+=2;
     }
     */
   /* UInt32 *frameBuffer = ioData->mBuffers[0].mData;
//    while ([audioQueue count]<=30&&!this->flag) {
    while ([audioQueue count]<=30) {
//        [NSThread sleepForTimeInterval:0.3];
        return noErr;
    }
    this->flag = TRUE;

    UInt32 count=inNumberFrames;
    int j = 0;
//    while (j<count) {
    while ([[audioQueue firstObject] isKindOfClass:[NSData class]]) {
        [audioQueue removeObjectAtIndex:0];
    }

    
    NSData *data = [audioQueue firstObject];
    const int size = [data length];
    UInt32 *charData = (UInt32*)malloc(size*sizeof(UInt32));
    [data getBytes:charData length:size];
memcpy(frameBuffer,charData,size*sizeof(UInt32));//Stereo channels
    [audioQueue removeObjectAtIndex:0];
//    }

     
    
//    UInt32 *frameBuffer = ioData->mBuffers[0].mData;
//    UInt32 count=inNumberFrames;
//    for (int j = 0; j < count; j++){
//        frameBuffer[j] = [this->inMemoryAudioFile getNextPacket];//Stereo channels
//    }
    printf("play::%u,",inNumberFrames);
    return noErr;
    */
    UInt32 *frameBuffer = ioData->mBuffers[0].mData;
    
    while ([audioQueue count]<=30) {
//        [NSThread sleepForTimeInterval:0.3];
        memset(frameBuffer, 0, inNumberFrames*2);
        return noErr;
    }
    this->flag = TRUE;

    while (![[audioQueue objectAtIndex:0] isKindOfClass:[AUDIO_CACHE_OBJECT class]]) {
        [audioQueue removeObjectAtIndex:0];
    }
    AUDIO_CACHE_OBJECT *pack;
    //    = [[AUDIO_CACHE_OBJECT alloc]init];
    char *data = (char*)malloc(sizeof(char)*BUFFER_SIZE);;
    memset(data, 0, BUFFER_SIZE);
    pack = [audioQueue firstObject];
    int size = [pack datalen];

    memcpy(frameBuffer, [pack GetData], size);

    [audioQueue removeObjectAtIndex:0];

    printf("play::%u,",(unsigned int)inNumberFrames);
    return noErr;

}
-(void)configAudio{
    //Upon launch, the application automatically gets a singleton audio session.
    //Initialize a session and registering an interruption callback
    
    CheckError(AudioSessionInitialize(NULL, kCFRunLoopDefaultMode, audioInterruptionListener, (__bridge void *)(self)), "couldn't initialize the audio session");
    
    //Add a AudioRouteChange listener
    CheckError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListener, (__bridge void *)(self)),"couldn't add a route change listener");
    
    //Is there an audio input device available
    UInt32 inputAvailable;
    UInt32 propSize=sizeof(inputAvailable);
    CheckError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &propSize, &inputAvailable), "not available for the current input audio device");
    if (!inputAvailable) {
        /*
         UIAlertView *noInputAlert =[[UIAlertView alloc] initWithTitle:@"error" message:@"not available for the current input audio device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
         [noInputAlert show];
         [noInputAlert release];
         */
        return;
    }
    
    //Adjust audio hardware I/O buffer duration.If I/O latency is critical in your app, you can request a smaller duration.
    Float32 ioBufferDuration = .005;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(ioBufferDuration), &ioBufferDuration),"couldn't set the buffer duration on the audio session");
    
    //Set the audio category
    UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory), "couldn't set the category on the audio session");
    
    UInt32 override=true;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(override), &override);
    
    //Get hardware sample rate and setting the audio format
    Float64 sampleRate;
    UInt32 sampleRateSize=sizeof(sampleRate);
    CheckError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &sampleRateSize, &sampleRate), "Couldn't get hardware samplerate");
    mAudioFormat.mSampleRate         = 44100;
    mAudioFormat.mFormatID           = kAudioFormatLinearPCM;
    mAudioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    mAudioFormat.mFramesPerPacket    = 1;
    mAudioFormat.mChannelsPerFrame   = kChannels;
    mAudioFormat.mBitsPerChannel     = 16;
    mAudioFormat.mBytesPerFrame      = mAudioFormat.mBitsPerChannel*mAudioFormat.mChannelsPerFrame/8;
    mAudioFormat.mBytesPerPacket     = mAudioFormat.mBytesPerFrame*mAudioFormat.mFramesPerPacket;
    mAudioFormat.mReserved           = 0;
    
//    mAudioFormat.mSampleRate         =  44100;
//    //mRecordFormat.mFormatID           =  kAudioFormatMPEG4AAC;
//    mAudioFormat.mFormatFlags        =  0;
//    mAudioFormat.mFramesPerPacket    =  1024;
//    mAudioFormat.mChannelsPerFrame   =  2;
//    mAudioFormat.mBitsPerChannel     =  0;//表示这是一个压缩格式
//    mAudioFormat.mBytesPerPacket     =  0;//表示这是一个变比特率压缩
//    mAudioFormat.mBytesPerFrame      =  0;
//    mAudioFormat.mReserved           =  0;
//    //aqc.bufferByteSize                  =  2000;
    
    
    //Obtain a RemoteIO unit instance
    AudioComponentDescription acd;
//    acd.componentType = kAudioUnitType_Output;
//    acd.componentSubType = kAudioUnitSubType_RemoteIO;
//    acd.componentFlags = 0;
//    acd.componentFlagsMask = 0;
//    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
//    
    acd.componentType         = kAudioUnitType_Output;
    acd.componentSubType      = kAudioUnitSubType_VoiceProcessingIO;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    acd.componentFlags        = 0;
    acd.componentFlagsMask    = 0;
    
    
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &acd);
    CheckError(AudioComponentInstanceNew(inputComponent, &mAudioUnit), "Couldn't new AudioComponent instance");
//    AUNode remoteIONode;
//    
//    CheckError(NewAUGraph(&graph), "newAUGraph failed");
//    CheckError(AUGraphAddNode(graph, &acd, &remoteIONode), "AUGraphAddNode failed");
//    CheckError(AUGraphOpen(graph), "AUGraphopen failed");
//    CheckError(AUGraphNodeInfo(graph,remoteIONode, &acd, &mAudioUnit), "AUGraphNodeinfo failed");
    //The Remote I/O unit, by default, has output enabled and input disabled
    //Enable input scope of input bus for recording.
    UInt32 enable = 1;
    UInt32 disable=0;
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    kInputBus,
                                    &enable,
                                    sizeof(enable))
               , "kAudioOutputUnitProperty_EnableIO::kAudioUnitScope_Input::kInputBus");
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output,
                                    kOutputBus,
                                    &enable,
                                    sizeof(enable))
               , "kAudioOutputUnitProperty_EnableIO::kAudioUnitScope_output::koutBus");
//    CheckError(AudioUnitSetProperty(mAudioUnit,
//                                    kAudioOutputUnitProperty_EnableIO,
//                                    kAudioUnitScope_Input,
//                                    krInputBus,
//                                    &enable,
//                                    sizeof(enable))
//               , "kAudioOutputUnitProperty_EnableIO::kAudioUnitScope_Input::kInputBus");
//    CheckError(AudioUnitSetProperty(mAudioUnit,
//                                    kAudioOutputUnitProperty_EnableIO,
//                                    kAudioUnitScope_Output,
//                                    krOutputBus,
//                                    &enable,
//                                    sizeof(enable))
//               , "kAudioOutputUnitProperty_EnableIO::kAudioUnitScope_output::koutBus");
    //Apply format to output scope of input bus for recording.
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    kInputBus,
                                    &mAudioFormat,
                                    sizeof(mAudioFormat))
               , "kAudioUnitProperty_StreamFormat::kAudioUnitScope_Output::kInputBus");
    //Applying format to input scope of output bus for playing
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    kOutputBus,
                                    &mAudioFormat,
                                    sizeof(mAudioFormat)), "kAudioUnitProperty_StreamFormat::kAudioUnitScope_Input::kOutputBus");
    //Disable buffer allocation for recording(optional)
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioUnitProperty_ShouldAllocateBuffer,
                                    kAudioUnitScope_Output,
                                    kInputBus,
                                    &disable,
                                    sizeof(disable))
               , "kAudioUnitProperty_ShouldAllocateBuffer::kAudioUnitScope_Output::kInputBus");
    

    
//    UInt32 echoCancellation;
//    UInt32 echoSize = sizeof(echoCancellation);
//    CheckError(AudioUnitSetProperty(mAudioUnit,
//                                    kAUVoiceIOProperty_BypassVoiceProcessing,
//                                    kAudioUnitScope_Global,
//                                    kOutputBus,
//                                    &echoCancellation,
//                                    echoSize)
//               , "kAudioOutputUnitProperty_EnableIO::kAudioUnitScope_Input::kInputBus");
//    
//
//    CheckError(AUGraphInitialize(graph),"AUGraphInitialize failed");
//    CheckError(AUGraphStart(graph), "AUGraphStart Failed");
    //AudioUnitInitialize
   
}
-(void)startToRecord{
    //Add a callback for recording
    AURenderCallbackStruct recorderStruct;
    recorderStruct.inputProc = recordCallback;
    recorderStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Input,
                                    kInputBus,
                                    &recorderStruct,
                                    sizeof(recorderStruct))
               , "kAudioOutputUnitProperty_SetInputCallback::kAudioUnitScope_Input::kInputBus");
    //Remove a callback for playing
    AURenderCallbackStruct playStruct;
    playStruct.inputProc=0;
    playStruct.inputProcRefCon=0;
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioUnitProperty_SetRenderCallback,
                                    kAudioUnitScope_Input,
                                    kOutputBus,
                                    &playStruct,
                                    sizeof(playStruct)), "kAudioUnitProperty_SetRenderCallback::kAudioUnitScope_Input::kOutputBus");
 CheckError(AudioUnitInitialize(mAudioUnit), "AudioUnitInitialize");
    AudioOutputUnitStart(mAudioUnit);
}
-(void)stopToRecord{
    AudioOutputUnitStop(mAudioUnit);
    //Dispose the audio file
//        inMemoryAudioFile=nil;
//    CheckError(ExtAudioFileDispose(mAudioFileRef),"ExtAudioFileDispose failed");
}
-(void)startToPlay{
    AURenderCallbackStruct recorderStruct;
    recorderStruct.inputProc = 0;
    recorderStruct.inputProcRefCon = 0;
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Input,
                                    kInputBus,
                                    &recorderStruct,
                                    sizeof(recorderStruct))
               , "kAudioOutputUnitProperty_SetInputCallback::kAudioUnitScope_Input::kInputBus");
    //Add a callback for playing
    AURenderCallbackStruct playStruct;
    playStruct.inputProc=playCallback;
    playStruct.inputProcRefCon=(__bridge void * _Nullable)(self);
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioUnitProperty_SetRenderCallback,
                                    kAudioUnitScope_Input,
                                    kOutputBus,
                                    &playStruct,
                                    sizeof(playStruct)), "kAudioUnitProperty_SetRenderCallback::kAudioUnitScope_Input::kOutputBus");
 CheckError(AudioUnitInitialize(mAudioUnit), "AudioUnitInitialize");
    AudioOutputUnitStart(mAudioUnit);
}
-(void)stopToPlay{
    AudioOutputUnitStop(mAudioUnit);
//    [inMemoryAudioFile release],
//    inMemoryAudioFile=nil;
//     CheckError(ExtAudioFileDispose(mAudioFileRef),"ExtAudioFileDispose failed");
}
- (IBAction)method:(id)sender {
    UIButton *thisButton = (UIButton *) sender;
    NSLog(@"\n\n\n");
    
    if ([thisButton.currentTitle isEqualToString: @"method"])
    {
        if (_audioController == nil)
        {
            self.audioController = [[AudioController alloc] init];
        }
        
        [_audioController startIOUnit];
        
        //MDLog(@"AudioController: %@ \n\n\n", self.audioController);
        

        [thisButton setTitle: @"End"
                    forState: UIControlStateNormal] ;
        
        [thisButton setTitleColor:[UIColor redColor]
                         forState:UIControlStateNormal] ;
    }
    else
    {
        [_audioController stopIOUnit];
        

        
        [thisButton setTitle: @"method"
                    forState: UIControlStateNormal] ;
        
        [thisButton setTitleColor:[UIColor blueColor]
                         forState:UIControlStateNormal] ;
        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configAudio];
    
    UIButton *button1=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    button1.frame=CGRectMake(100, 100, 80, 30);
    button1.tag=1;
    [button1 setTitle:@"开始录音" forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    UIButton *button2=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    button2.frame=CGRectMake(100, 200, 80, 30);
    button2.tag=2;
    [button2 setTitle:@"开始放音" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
}
- (IBAction)touch:(id)sender {
    AURenderCallbackStruct recorderStruct;
    recorderStruct.inputProc = recordCallback;
    recorderStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Input,
                                    kInputBus,
                                    &recorderStruct,
                                    sizeof(recorderStruct))
               , "kAudioOutputUnitProperty_SetInputCallback::kAudioUnitScope_Input::kInputBus");
    AURenderCallbackStruct playStruct;
    playStruct.inputProc=playCallback;
    playStruct.inputProcRefCon=(__bridge void * _Nullable)(self);
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioUnitProperty_SetRenderCallback,
                                    kAudioUnitScope_Input,
                                    kOutputBus,
                                    &playStruct,
                                    sizeof(playStruct)), "kAudioUnitProperty_SetRenderCallback::kAudioUnitScope_Input::kOutputBus");
    CheckError(AudioUnitInitialize(mAudioUnit), "AudioUnitInitialize");
        sleep(1);
    CheckError(AudioOutputUnitStart(mAudioUnit),"audiounitstart");
  
//    isRecording=!isRecording;
    
}
- (void) record{
    AURenderCallbackStruct recorderStruct;
    recorderStruct.inputProc = recordCallback;
    recorderStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Input,
                                    kInputBus,
                                    &recorderStruct,
                                    sizeof(recorderStruct))
               , "kAudioOutputUnitProperty_SetInputCallback::kAudioUnitScope_Input::kInputBus");
}
- (void) play{
    AURenderCallbackStruct playStruct;
    playStruct.inputProc=playCallback;
    playStruct.inputProcRefCon=(__bridge void * _Nullable)(self);
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioUnitProperty_SetRenderCallback,
                                    kAudioUnitScope_Input,
                                    kOutputBus,
                                    &playStruct,
                                    sizeof(playStruct)), "kAudioUnitProperty_SetRenderCallback::kAudioUnitScope_Input::kOutputBus");
    

    
}

-(void)buttonAction:(UIButton *)button{
    if (button.tag==1) {
        UIButton *other=(UIButton *)[button.superview viewWithTag:2];
        if (isRecording) {
            other.enabled=YES;
            [self stopToRecord];
            [button setTitle:@"开始录音" forState:UIControlStateNormal];
            printf("stop record\n");
        }else{
            other.enabled=NO;
            [self startToRecord];
            [button setTitle:@"停止录音" forState:UIControlStateNormal];
            printf("start  record\n");
        }
        isRecording=!isRecording;
    }else if(button.tag==2){
        UIButton *other=(UIButton *)[button.superview viewWithTag:1];
        if (isPlaying) {
            other.enabled=YES;
            [self stopToPlay];
            [button setTitle:@"开始放音" forState:UIControlStateNormal];
            printf("stop play\n");
        }else{
            other.enabled=NO;
            [self startToPlay];
            [button setTitle:@"停止放音" forState:UIControlStateNormal];
            printf("start  play\n");
        }
        isPlaying=!isPlaying;
    }
}
- (void)dealloc{
    CheckError(AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListener, (__bridge void *)(self)),"couldn't remove a route change listener");
    AudioUnitUninitialize(mAudioUnit);
//    if (inMemoryAudioFile!=nil) {
////        [inMemoryAudioFile release],
//        inMemoryAudioFile=nil;
//    }
//    [super dealloc];
}

@end