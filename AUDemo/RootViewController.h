//
//  ViewController.h
//  AUDemo
//
//  Created by jun on 16/3/15.
//  Copyright © 2016年 jun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "InMemoryAudioFile.h"
#import "AudioController.h"
@interface RootViewController : UIViewController<AVAudioPlayerDelegate>{
    AudioStreamBasicDescription mAudioFormat;
    AudioComponentInstance      mAudioUnit;
//    ExtAudioFileRef             mAudioFileRef;
    Boolean                     isRecording;
    Boolean                     isPlaying;
    Boolean                     flag;
    AUGraph                     graph;

//    InMemoryAudioFile           *inMemoryAudioFile;
}


@property (nonatomic, strong) AudioController        *audioController;
@property (nonatomic)int                             frame_id;

@end



