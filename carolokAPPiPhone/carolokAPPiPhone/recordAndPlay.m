//
//  recordAndPlay.m
//  isRecorder
//
//  Created by 國立中興大學 資訊工程學系 國立中興大學 資訊工程學系 on 12/6/19.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
#import "recordAndPlay.h"
#import "Production.h"

@implementation recordAndPlay
{
    double lowPassResults;
    BOOL BOOLwave;
    CGContextRef context;
    int WaveFormPosition;
}
@synthesize recordFilePath, bgFilePath;
@synthesize isPlaying;
@synthesize delegate;
@synthesize recorder, player;
@synthesize CleanImageWave;
/*
 initialize player and recorder
 */
- (id)init
{
    self = [super init];
    if (!self) return nil;
    isBgEnable = NO;
    [self setAudioSession];
    return self;
}

- (void)setPlayerVolumn:(float)value
{
    player.volume = value;
}

/*
 when finish, then do something
 */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag) {
        NSLog(@"bg Finish play");
        isPlaying = NO;
        [delegate finishPlay:YES];
    }
}

- (void)useDefaultSetting
{
    //20130712 修改聲道
    NSDictionary *recorderSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                     [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                     [NSNumber numberWithInt:2],AVNumberOfChannelsKey,
                                     [NSNumber numberWithInt:AVAudioQualityMin],AVEncoderAudioQualityKey,
                                     nil];
    
    NSURL *recordFileUrl = [NSURL fileURLWithPath:recordFilePath];
    NSLog(@">>>%@", recordFilePath);
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:recordFileUrl settings:recorderSetting error:&error];
    NSLog(@"recorder error>>>>>>%@", error);
    [self.recorder prepareToRecord];
    
    if (bgFilePath != NULL)
    {
        NSLog(@">>>%@", recordFilePath);
        NSURL *bgFileUrl = [NSURL fileURLWithPath:bgFilePath];
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:bgFileUrl error:&error];
        [player prepareToPlay];
        NSLog(@"player error>>>>>>%@", error);
    }
}
- (void)setBgEnable:(BOOL)isOn
{
    if (isOn) {
        isBgEnable = YES;
        NSLog(@"bg enable.");
        if ([self.recorder isRecording] && bgFilePath !=NULL) {
            [player play];
        }
    }
    else {
        isBgEnable = NO;
        NSLog(@"bg disable.");
        if ([self.recorder isRecording] && bgFilePath !=NULL) {
            if (player.currentTime == player.duration) {
                [player stop];
                [player setCurrentTime:0.0];
            } else {
                [player pause];
            }
        }
    }
}

- (BOOL)getBgEnable
{
    return isBgEnable;
}
/*
 set the confiquration as record and play simultanously
 */
- (void)setAudioSession
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
    //kAudioSessionProperty_OverrideAudioRoute
    AudioSessionSetProperty (kAudioSessionOverrideAudioRoute_None,
                             sizeof (audioRouteOverride),&audioRouteOverride);
    [session setActive:YES error:&error];
}

/*
 record and play
 */
- (void)recordAndPlay
{
    if (!self.recorder.isRecording) {
        //鎖死螢幕與禁能設定按鈕
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LockView" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SettingUnenable" object:nil];
        
        
        [self.recorder record];
        self.recorder.meteringEnabled=YES;
        if (CleanImageWave)
            [self preptoDrawingWaveform];
        if (isBgEnable)
            [player play];
        else
            [player stop];
    }
    else {
        //解鎖螢幕與智能設定按鈕
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UnLockView" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SettingEnable" object:nil];
        
        [self.recorder pause];
        self.recorder.meteringEnabled=NO;
        if (isBgEnable) {
            [player stop];
            //            [player stop];
            //            [player setCurrentTime:0.0];
        }
    }
}

-(void)recordPause
{
    //解鎖螢幕與智能設定按鈕
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UnLockView" object:nil];
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"SettingEnable" object:nil];
    if (self.recorder.isRecording) {
        [self.recorder pause];
        if (isBgEnable) {
            [player pause];
        }
    }
}
/*
 play record result
 */

- (void)playVoice:(NSString *)resultPath
{
    //    NSArray *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    //    NSString *documentDirectory = [path objectAtIndex:0];
    //    NSString *destinationFilePath = [[NSString alloc] initWithFormat:@"%@/output.caf",
    //                                     documentDirectory];
    //    NSLog(@">>>%@", destinationFilePath);
    //    NSURL *url = [NSURL fileURLWithPath:destinationFilePath];
    NSLog(@">>>%@", resultPath);
    NSURL *url = [NSURL fileURLWithPath:resultPath];
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    [player setDelegate:self];
    player.volume = 1.0;
    NSLog(@"error code is %d",[error code]);
    if ( noErr == [error code]) {
        [player play];
        self.isPlaying = YES;
    }
    else {
        NSLog(@"error happen");
    }
}

- (void)stopPlayVoice
{
    [player stop];
    [player setCurrentTime:0.0];
    self.isPlaying = NO;
}
- (void)playOrStopBgVoice
{
    if (!isPlaying) {
        NSLog(@">>>%@", bgFilePath);
        [self playVoice:bgFilePath];
    }
    else {
        [self stopPlayVoice];
    }
}
#pragma mark file process
- (void)createRecordedFile
{
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [path objectAtIndex:0];
    NSDate *now = [NSDate date];
    NSString *fileName = [NSString stringWithFormat:@"output%@.caf", now];
    NSString *destinationFilePath = [[NSString alloc] initWithFormat:@"%@/%@",
                                     documentDirectory,
                                     fileName];
    NSLog(@">>>%@", destinationFilePath);
    
    Production *aProduct = [[Production alloc] init];
    
    aProduct.ProductName = fileName;
    aProduct.ProductCreateTime = now;
    aProduct.ProductPath = destinationFilePath;
    [database1 addSongToMyProduction:aProduct];
    
    NSLog(@"insert date OK!");
}

#pragma mark - peakPowerWaveform
-(void)preptoDrawingWaveform{
    UIGraphicsBeginImageContext(CGSizeMake(152, 655));
    context = UIGraphicsGetCurrentContext();
    WaveFormPosition=0;
    
    CGRect rect;
    rect.size = CGSizeMake(152, 655);
    rect.origin.x = 0;
    rect.origin.y = 0;
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, rect);
}


-(UIImage *) RecordPeakpower{
    [self.recorder updateMeters];
    float Peakpower=[self.recorder peakPowerForChannel:0];
    const double ALPHA = 0.05;
    double peakPowerForChannel = pow(10, (0.03 * Peakpower));
    lowPassResults = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * lowPassResults;
    
    
    WaveFormPosition++;
    
    //    CGSize imageSize = CGSizeMake(300, 200);
    
    CGContextSetAlpha(context,1.0);
    
    
    CGContextSetLineWidth(context, 4);
    
    CGContextMoveToPoint(context, WaveFormPosition, 300-peakPowerForChannel*125);
    CGContextAddLineToPoint(context, WaveFormPosition,300+peakPowerForChannel*125);
    
    CGContextSetStrokeColorWithColor(context, [[UIColor redColor]CGColor]);
    CGContextStrokePath(context);
    
    
    // Create new image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    // Tidy up
    if (WaveFormPosition>152) {
        
        UIGraphicsEndImageContext();
        [self preptoDrawingWaveform];
    }
    return newImage;
}

@end
