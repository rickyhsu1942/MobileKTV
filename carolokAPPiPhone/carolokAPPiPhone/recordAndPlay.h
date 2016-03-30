//
//  recordAndPlay.h
//  isRecorder
//
//  Created by 國立中興大學 資訊工程學系 國立中興大學 資訊工程學系 on 12/6/19.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SQLiteDBTool.h"

@protocol recordAndPlayDelegate <NSObject>

- (void)finishPlay:(BOOL)isFinish;

@end

@interface recordAndPlay : NSObject
<AVAudioPlayerDelegate>
{
    AVAudioPlayer   *player;
    AVAudioRecorder *recorder;
    SQLiteDBTool *database1;
    NSString *recordFilePath;
    NSString *bgFilePath;
    BOOL isBgEnable;
}

@property (weak)                       id<recordAndPlayDelegate> delegate;
@property (nonatomic, retain) IBOutlet NSString *recordFilePath;
@property (nonatomic, retain) IBOutlet NSString *bgFilePath;
@property (readwrite)                  BOOL     isPlaying;
@property (readwrite)                  BOOL     CleanImageWave;
@property (nonatomic, retain) IBOutlet AVAudioPlayer   *player;
@property (nonatomic, retain) IBOutlet AVAudioRecorder *recorder;
//recoder and player init
- (id)init;
- (void)useDefaultSetting;
//record and play simultaneously
- (void)recordAndPlay;
- (void)recordPause;

//play record result
- (void)playVoice:(NSString *)resultPath;
- (void)stopPlayVoice;
- (void)playOrStopBgVoice;

- (void)setBgEnable:(BOOL)isOn;
- (BOOL)getBgEnable;

- (void)setPlayerVolumn:(float)value;

//PeakPower
-(UIImage *) RecordPeakpower;
@end
