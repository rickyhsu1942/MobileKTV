//
//  MixerViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/1.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
//-----View-----
#import "MixerViewController.h"
#import "WaveformImageVew.h"
#import "SaveStudioAlertViewController.h"
#import "ListenPlayerViewController.h"
#import "popoverTableViewController.h"
#import "FPPopoverController.h"
#import "FPPopoverKeyboardResponsiveController.h"
//-----Tool-----
#import "SQLiteDBTool.h"
#import "Mixer.h"
#import "TSLibraryImport.h"
#import "UIImage+animatedGIF.h"
//-----Object-----
#import "Production.h"
#import "GlobalData.h"
//-----UI-----
#import "UIViewController+MJPopupViewController.h"


//-----Define-----
#define FILE_SELECTION_TAG        10
#define VOLUME_SLIDER_TAG         20
#define PROGRESS_SLIDER_TAG       30
#define SINGER_TAG                50
#define LIGHT_BTN_TAG             60
#define Repeat_TAG                70
#define TRACK_NAME_TAG            80
#define TIME_LABEL_TAG            90
#define TRACK_IMAGE_TAG           110
#define TRACK_IMAGE2_TAG          120
#define ITUNEFILE_SELECTUIN_TAG   130
#define LimitTracks               4800
@interface MixerViewController () <UIActionSheetDelegate,MPMediaPickerControllerDelegate,FPPopoverControllerDelegate,popOverViewDelegate,AVAudioPlayerDelegate,MJSecondPopupDelegate>
{
    UIButton *currentBtn;
    UISlider *PasueSlider;
    BOOL trackIsSelected[3];
    BOOL trackIsLoad[3];
    NSMutableArray *trackIsLoadArray;
    BOOL needUpdate[3];
    NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification;
    BOOL isMix;
    BOOL isProductSaved;
    NSTimer *timer;
    Production *currentProduct;
    Production *alltracks[3];
    float trackTotalTime[3];
    NSInteger finishTrackCount;
    BOOL MixFileDone;
    CGSize ImageSizeBlack;
    int RemainTotleTrack;
    int FileSelectPlayerTrack;
    BOOL isSourceTrackChanged;
    
    AVAudioPlayer *ListenPlayer;
    NSTimer *timerListen;
    Float32 current,LimitTime;
    BOOL isFileDone;
    BOOL isFileChangeName;
    WaveformImageVew *waveImageView;
    NSString *CurrentFilePath;
    //flag indicate mixing or playing
    
    NSTimer *TimerCheckMic;
    
    NSNotificationCenter *notificationCenter;
    NSMutableArray *SaveCurrentTimeSliderValue;
    NSMutableArray *SaveCurrentVolumeValue;
    NSMutableArray *SaveCurrentTimeLabelValue;
    
    //A dictionary that help to indicate which track is belong to which bus
    NSMutableDictionary *viewToMixerDicArray;
    
    
    popoverTableViewController *popTable;
    FPPopoverKeyboardResponsiveController *FPpopover;
    //DBTool *database;
    SQLiteDBTool *database1;
    BOOL isGoto;
    BOOL isSaveDone;
    BOOL isExit;
    
    AVAudioPlayer *player;
    AVAudioPlayer *player1;
    AVAudioPlayer *player2;
    AVAudioPlayer *player3;
}

@property (nonatomic, retain) IBOutlet UILabel *track1Label;
@property (nonatomic, retain) IBOutlet UILabel *track2Label;
@property (nonatomic, retain) IBOutlet UILabel *track3Label;
@property (weak, nonatomic) IBOutlet UILabel *time1Label;
@property (weak, nonatomic) IBOutlet UILabel *time2Label;
@property (weak, nonatomic) IBOutlet UILabel *time3Label;

@property (nonatomic, retain) IBOutlet UIButton *track1Btn;
@property (nonatomic, retain) IBOutlet UIButton *track2Btn;
@property (nonatomic, retain) IBOutlet UIButton *track3Btn;

@property (weak, nonatomic) IBOutlet UIButton *btnListen;
@property (weak, nonatomic) IBOutlet UIButton *btnMixer;
@property (weak, nonatomic) IBOutlet UIButton *btnReset;
@property (weak, nonatomic) IBOutlet UIButton *btnSaveFile;
@property (weak, nonatomic) IBOutlet UISlider *SliderListenTrack;
@property (weak, nonatomic) IBOutlet UIButton *btnBarBG;
@property (nonatomic, retain) id detailItem;
@property (nonatomic, retain) Mixer *audioObject;
@property (weak, nonatomic) IBOutlet UILabel *lbListenTrack;
@property (weak, nonatomic) IBOutlet UITextField *txtTrack1;
@property (weak, nonatomic) IBOutlet UIImageView *ivLoading;

@end

@implementation MixerViewController

@synthesize track1Btn,track2Btn,track3Btn;
@synthesize track1Label,track2Label,track3Label;
@synthesize SliderListenTrack;
@synthesize btnListen,btnMixer,btnReset,btnSaveFile,btnBarBG;
@synthesize detailItem;
@synthesize audioObject;
@synthesize time1Label,time2Label,time3Label;
@synthesize lbListenTrack;
@synthesize txtTrack1;

- (IBAction)Back:(id)sender {
    if ([audioObject isRecorded]) { // 如果還在混音，先停止混音
        isExit = YES;
        [self mix_Press:nil];
    }
    if (!isSaveDone) { // 如果沒有儲存，將錄音暫存檔案刪除
        NSError *error;
        NSFileManager *manger = [NSFileManager defaultManager];
        NSString *removedPath = currentProduct.ProductPath;
        if ([manger fileExistsAtPath:removedPath]) {
            [manger removeItemAtPath:removedPath // 刪除錄音檔案
                               error:&error];
            NSLog(@"%@>>>has been removed", removedPath);
        };
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark -
#pragma get corresponding mixer bus
// index: 0 ~ 3
- (short int)getCorrespondingMixerBus:(int)index
{
    NSString *mixerBus;
    if ( (mixerBus = [viewToMixerDicArray objectForKey:[NSString stringWithFormat:@"%d", index ]]) != nil)
        return [mixerBus integerValue];
    else
        return -1;
}

#pragma mark -
#pragma mark initailize to UI setting
- (void)initToUI
{
    //accroding to tracknamelabel set mixer input enable
    short int mixerBus = 0;
    //track 1
    mixerBus = [self getCorrespondingMixerBus:0];
    if ([track1Label.text compare:@""] != NSOrderedSame && trackIsSelected[0]) {
        if (mixerBus != -1)
            [audioObject enableMixerInput:mixerBus isOn:YES];
        trackIsLoad[0] = YES;
        needUpdate[0] = YES;
    }
    else
    {
        [audioObject enableMixerInput:mixerBus isOn:NO];
        needUpdate[0] = NO;
    }
    //track 2
    mixerBus = [self getCorrespondingMixerBus:1];
    if ([track2Label.text compare:@""] != NSOrderedSame && trackIsSelected[1]) {
        if (mixerBus != -1)
            [audioObject enableMixerInput:1 isOn:YES];
        trackIsLoad[1] = YES;
        needUpdate[1] = YES;
    }
    else
    {
        [audioObject enableMixerInput:1 isOn:NO];
        needUpdate[1] = NO;
    }
    //track3
    mixerBus = [self getCorrespondingMixerBus:2];
    if ([track3Label.text compare:@""] != NSOrderedSame && trackIsSelected[2]) {
        if (mixerBus != -1)
            [audioObject enableMixerInput:2 isOn:YES];
        trackIsLoad[2] = YES;
        needUpdate[2] = YES;
    }
    else
    {
        [audioObject enableMixerInput:2 isOn:NO];
        needUpdate[2] = NO;
    }
    
    //set time and volume accroding to UI
    for (int i = 0; i < 3; i++) {
        if (trackIsLoad[i]) {
            [self mixerInputGainChanged:(UISlider*)[self.view viewWithTag:i + VOLUME_SLIDER_TAG + 1]];
            [self seekToTime:(UISlider*)[self.view viewWithTag:i + PROGRESS_SLIDER_TAG + 1]];
        }
    }
}

#pragma mark -
#pragma mark display message
- (void)showMessageWithTitle:(NSString*)title Message:(NSString*)msg
{
    UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:title
                                                       message:msg
                                                      delegate:nil
                                             cancelButtonTitle:@"了解"
                                             otherButtonTitles:nil, nil];
    [msgAlert show];
}
#pragma mark -
#pragma mark uialert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[alertView viewWithTag:100] resignFirstResponder];
    if (1 == buttonIndex) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] compare:@"確定"] == NSOrderedSame) {
            
        }
        else if ([[alertView buttonTitleAtIndex:buttonIndex] compare:@"是"] == NSOrderedSame)
        {
            [btnListen setEnabled:NO];
            [btnMixer setEnabled:YES];
            [btnSaveFile setEnabled:NO];
            [btnListen setImage:[UIImage imageNamed:@"試聽icon-1.png"] forState:UIControlStateNormal];
            [btnMixer setImage:[UIImage imageNamed:@"混音icon.png"] forState:UIControlStateNormal];
            [btnSaveFile setImage:[UIImage imageNamed:@"儲存icon-1.png"] forState:UIControlStateNormal];
            for (int i = 0; i < 3; i++) {
                trackIsSelected[i] = NO;
                trackIsLoad[i] = NO;
                needUpdate[i] = NO;
                /*
                 comment by Jay, 2013/5/9
                 initialize alltracks
                 */
                alltracks[i] = nil;
                //end comment by Jay
                UISlider *TrackSlider = (UISlider *)[self.view viewWithTag:i + PROGRESS_SLIDER_TAG + 1];
                TrackSlider.value = 0;
                [TrackSlider setEnabled:NO];
                UISlider *VolumSlider = (UISlider *)[self.view viewWithTag:i + VOLUME_SLIDER_TAG + 1];
                VolumSlider.value = 0.5;
                [VolumSlider setEnabled:NO];
                UIImageView *imageView = (UIImageView *)[self.view viewWithTag:i + TRACK_IMAGE_TAG + 1];
                [imageView setImage:nil];

            }
            RemainTotleTrack = 4800;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MachineInit" object:nil];
            audioObject= nil;
            isMix = NO;
            isGoto = NO;
            MixFileDone = NO;
            isFileDone = YES;
            [btnMixer setTitle:@"混音" forState:UIControlStateNormal];
            [btnMixer setEnabled:YES];
            track1Label.text = @"";
            track2Label.text = @"";
            track3Label.text = @"";
            time1Label.text = @"00:00";
            time2Label.text = @"00:00";
            time3Label.text = @"00:00";
            [track1Btn setImage:[UIImage imageNamed:@"錄音燈-1.png"] forState:UIControlStateNormal];
            [track2Btn setImage:[UIImage imageNamed:@"錄音燈-1.png"] forState:UIControlStateNormal];
            [track3Btn setImage:[UIImage imageNamed:@"錄音燈-1.png"] forState:UIControlStateNormal];
            [track1Btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [track2Btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [track3Btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            if (!isFileChangeName) {
                NSError *error;
                NSFileManager *manger = [NSFileManager defaultManager];
                NSString *removedPath = currentProduct.ProductPath;
                if ([manger fileExistsAtPath:removedPath]) {
                    [manger removeItemAtPath:removedPath
                                       error:&error];
                    NSLog(@"%@>>>has been removed", removedPath);
                };
                [database1 deleteSongFromMyProduct:currentProduct];
            }
            return;
        }
        else if ([[alertView buttonTitleAtIndex:buttonIndex] compare:@"重新混音"] == NSOrderedSame)
        {
            [self mix_Press:nil];
        }
    }
    else if (0 == buttonIndex){
        if ([[alertView buttonTitleAtIndex:buttonIndex] compare:@"忽略變更"] == NSOrderedSame)
        {
            if ([[[alertView message] substringFromIndex:alertView.message.length - 2] isEqualToString:@"試聽"]) {
                [self ListenMixer:nil];
            } else if ([[[alertView message] substringFromIndex:alertView.message.length - 2] isEqualToString:@"儲存"]) {
                [self SaveMixer:nil];
            }
        }
    }
}
//更改名稱結束後，詢問是否要進入"我的作品"試聽結果
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    //    if (!isFileDone && [[alertView buttonTitleAtIndex:buttonIndex] compare:@"否"] !=  NSOrderedSame) {
    //        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"訊息"
    //                                                       message:@"成功儲存"
    //                                                      delegate:nil
    //                                             cancelButtonTitle:@"了解"
    //                                             otherButtonTitles:nil];
    //        [alert show];
    //        isFileDone = YES;
    //        [btnListen setEnabled:NO];
    //        [btnMixer setEnabled:NO];
    //        [btnSaveFile setEnabled:NO];
    //        [btnReset setEnabled:YES];
    //        [btnListen setImage:[UIImage imageNamed:@"試聽icon-1.png"] forState:UIControlStateNormal];
    //        [btnReset setImage:[UIImage imageNamed:@"重製icon.png"] forState:UIControlStateNormal];
    //        [btnSaveFile setImage:[UIImage imageNamed:@"儲存icon-1.png"] forState:UIControlStateNormal];
    //
    //    }
}
#pragma mark -
#pragma mark alert action
- (BOOL)rename_press:(id)sender
{
    isFileChangeName = YES;
    [self PrepListen];
    int minute = 0;
    int second = 0;
    minute = [ListenPlayer duration] / 60;
    second = [[NSString stringWithFormat:@"%f",[ListenPlayer duration]] intValue] % 60;
    currentProduct.ProductTracktime = [NSString stringWithFormat:@"%02d:%02d", minute, second];
    UIStoryboard *storyboard = self.storyboard;
    SaveStudioAlertViewController *SaveStudioAlertVC  = [storyboard instantiateViewControllerWithIdentifier:@"SaveStudioAlertVC"];
    [SaveStudioAlertVC setValue:self forKey:@"CheckMicDelegate"];
    [SaveStudioAlertVC setAProduction:currentProduct];
    [SaveStudioAlertVC setDelegate:self];
    [SaveStudioAlertVC setSourceMachine:@"Mixer"];
    [self presentPopupViewController:SaveStudioAlertVC animationType:MJPopupViewAnimationFade];
    return YES;
}

- (void)DoneSaving {
    currentProduct.ProductID = @"";
    audioObject= nil;
    [btnSaveFile setEnabled:NO];
    isSaveDone = YES;
}

- (void)GiveupSaving {
    for (int i = 0; i < 3; i++) {
        UISlider *TrackSlider = (UISlider *)[self.view viewWithTag:i + PROGRESS_SLIDER_TAG + 1];
        TrackSlider.value = [[SaveCurrentTimeSliderValue objectAtIndex:i] floatValue];
        UISlider *VolumSlider = (UISlider *)[self.view viewWithTag:i + VOLUME_SLIDER_TAG + 1];
        VolumSlider.value = [[SaveCurrentVolumeValue objectAtIndex:i] floatValue];
        UIImageView *ImageviewBlack = (UIImageView *)[self.view viewWithTag:i + TRACK_IMAGE2_TAG +1];
        ImageviewBlack.frame = CGRectMake(ImageviewBlack.frame.origin.x,
                                          ImageviewBlack.frame.origin.y,
                                          ImageSizeBlack.width * (TrackSlider.value * 1.010),
                                          ImageSizeBlack.height);
        int sliderIndex = i+1;
        switch (sliderIndex) {
            case 1:
                [player1 setCurrentTime:TrackSlider.value];
                if (player1) {
                    [player1 setVolume:VolumSlider.value];
                }
                time1Label.text = [SaveCurrentTimeLabelValue objectAtIndex:i];
                break;
            case 2:
                [player2 setCurrentTime:TrackSlider.value];
                if (player2) {
                    [player2 setVolume:VolumSlider.value];
                }
                time2Label.text = [SaveCurrentTimeLabelValue objectAtIndex:i];
                break;
            case 3:
                [player3 setCurrentTime:TrackSlider.value];
                if (player3) {
                    [player3 setVolume:VolumSlider.value];
                }
                time3Label.text = [SaveCurrentTimeLabelValue objectAtIndex:i];
                break;
            default:
                break;
        }
    }
    //time1Label.text = @"00:00";
    //time2Label.text = @"00:00";
    //time3Label.text = @"00:00";
    //time4Label.text = @"00:00";
    
}

-(void)AutoCheckMic {
    TimerCheckMic =[NSTimer scheduledTimerWithTimeInterval:0.5
                                                    target:self
                                                  selector:@selector (CheckMic)
                                                  userInfo:nil
                                                   repeats:NO];
}

-(void)CheckMic {
}


#pragma mark -
#pragma mark seekTime
- (IBAction)seekToTime:(UISlider *)sender
{
    // 黑屏影像與時間軸同步
    UIImageView *ImageviewBlack = (UIImageView *)[self.view viewWithTag:TRACK_IMAGE2_TAG + (sender.tag - PROGRESS_SLIDER_TAG)];
    ImageviewBlack.frame = CGRectMake(ImageviewBlack.frame.origin.x,
                                      ImageviewBlack.frame.origin.y,
                                      ImageSizeBlack.width * (sender.value * 1.010),
                                      ImageviewBlack.frame.size.height);
    //mixing audios
    if (isMix) {
        short int mixerBus = [self getCorrespondingMixerBus:sender.tag - PROGRESS_SLIDER_TAG - 1];
        switch (mixerBus) {
            case 0:
                [notificationCenter addObserver: self
                                       selector: @selector (handleTrackFinished:)
                                           name: @"Bus0FinishedPlay"
                                         object: nil];
                break;
            case 1:
                [notificationCenter addObserver: self
                                       selector: @selector (handleTrackFinished:)
                                           name: @"Bus1FinishedPlay"
                                         object: nil];
                break;
            case 2:
                [notificationCenter addObserver: self
                                       selector: @selector (handleTrackFinished:)
                                           name: @"Bus2FinishedPlay"
                                         object: nil];
                break;
            case 3:
                [notificationCenter addObserver: self
                                       selector: @selector (handleTrackFinished:)
                                           name: @"Bus3FinishedPlay"
                                         object: nil];
                break;
            default:
                break;
        }
        [audioObject enableMixerInput:mixerBus isOn:YES];
        [audioObject mixerInput:mixerBus seekTime:sender.value];
        needUpdate[sender.tag - PROGRESS_SLIDER_TAG - 1] = YES;
    }
    //play audios
    else
    {
        short int sliderIndex = sender.tag - PROGRESS_SLIDER_TAG;
        
        switch (sliderIndex) {
            case 1:
                [player1 setCurrentTime:(player1.duration) * sender.value];
                break;
            case 2:
                [player2 setCurrentTime:(player2.duration) * sender.value];
                break;
            case 3:
                [player3 setCurrentTime:(player3.duration) * sender.value];
                break;
            default:
                break;
        }
    }
    [self setTimeLabel:sender.tag - PROGRESS_SLIDER_TAG Ratio:sender.value];
}

- (IBAction)seekToTimeTouchDown:(UISlider *)sender {
    PasueSlider = sender;
    int sliderIndex = sender.tag - PROGRESS_SLIDER_TAG;
    UInt32 inputBus = [self getCorrespondingMixerBus:sliderIndex -1]; // 抓出哪個音軌
    [audioObject setMixerInput: (UInt32) inputBus gain: (AudioUnitParameterValue) 0]; // 靜音
}
- (IBAction)seekToTimeTouchUp:(UISlider *)sender {
    PasueSlider = nil;
    int sliderIndex = sender.tag - PROGRESS_SLIDER_TAG;
    if (![timer isValid] && isMix) { // 判斷計時器是否取消
        timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                 target:self
                                               selector:@selector(seekBarChange)
                                               userInfo:nil
                                                repeats:YES]; // 開始播放
    }
    UISlider *SliderVolume = (UISlider *)[self.view viewWithTag:VOLUME_SLIDER_TAG + sliderIndex];
    UInt32 inputBus = [self getCorrespondingMixerBus:sliderIndex -1]; // 用回原本的音量
    //set mixer volume
    [audioObject setMixerInput: (UInt32) inputBus gain: (AudioUnitParameterValue) SliderVolume.value]; // 調整原本音量
    
    short int mixerBus = [self getCorrespondingMixerBus:sender.tag - PROGRESS_SLIDER_TAG - 1];
    [audioObject enableMixerInput:mixerBus isOn:YES]; // 智能
    [audioObject mixerInput:mixerBus seekTime:sender.value]; // 到達此位置
    needUpdate[sender.tag - PROGRESS_SLIDER_TAG - 1] = YES; // 更新
}


- (void)seekBarChange
{
    UISlider *slider;
    UILabel  *trackRemainingTimeLB;
    UILabel  *trackTimeLB;
    UIImageView *ImageviewBlack;
    
    double currentDuration = 0;
    double remainingTime = 0;
    int minute = 0;
    int second = 0;
    int millisecond = 0;
    
    
    Float64 ratio;
    for (int i = 1; i <= 3; i++) {
        if (needUpdate[i - 1]) {
            //get track progress, time label, remaining time label
            //get object instance with tag
            slider = (UISlider *)[self.view viewWithTag: i + PROGRESS_SLIDER_TAG];
            trackRemainingTimeLB = (UILabel*)[self.view viewWithTag: 2 * i + TIME_LABEL_TAG];
            trackTimeLB = (UILabel*)[self.view viewWithTag: 2 * i - 1 + TIME_LABEL_TAG];
            
            if (PasueSlider.tag == slider.tag) {
                continue;
            }
            
            //get corresponding mixer bus from dic.
            int mixerBus = [[viewToMixerDicArray objectForKey:[NSString stringWithFormat:@"%d", i - 1]] integerValue];
            //get current track progress from mixer
            
            ratio = [audioObject mixerInputGetCurrentProgress:mixerBus];
            //set track progress
            [slider setValue:ratio  animated:YES];
            
            //set time and remaining time label
            currentDuration = (double)(trackTotalTime[i - 1] * ratio);
            remainingTime = (double)(trackTotalTime[i - 1] * (1 - ratio));
            minute = (int)currentDuration / 60;
            second = (int)currentDuration % 60;
            millisecond = (currentDuration - minute * 60 - second) * 100;
            [trackTimeLB setText:[NSString stringWithFormat:@"%02d:%02d.%02d", minute, second, millisecond]];
            minute = (int)remainingTime / 60;
            second = (int)remainingTime % 60;
            millisecond = (remainingTime - minute * 60 - second) * 100;
            [trackRemainingTimeLB setText:[NSString stringWithFormat:@"%02d:%02d.%02d", minute, second, millisecond]];
            
            // 黑屏影像與時間軸同步
            ImageviewBlack = (UIImageView *)[self.view viewWithTag:TRACK_IMAGE2_TAG + i];
            ImageviewBlack.frame = CGRectMake(ImageviewBlack.frame.origin.x,
                                              ImageviewBlack.frame.origin.y,
                                              ImageSizeBlack.width * (slider.value * 1.010),
                                              ImageviewBlack.frame.size.height);
            if (ratio == 1.0) {
                needUpdate[i - 1] = NO;
            }
        }
    }
}

//set progress time label with ratio
- (void)setTimeLabel:(int)btnIndex Ratio:(double)ratio
{
    UISlider *slider;
    UILabel  *trackRemainingTimeLB;
    UILabel  *trackTimeLB;
    
    
    //int btnIndex = currentBtn.tag - FILE_SELECTION_TAG;
    
    double currentDuration = 0;
    double remainingTime = 0;
    int minute = 0;
    int second = 0;
    int millisecond = 0;
    
    //float ratio;
    //get track progress, time label, remaining time label
    //get object instance with tag
    slider = (UISlider *)[self.view viewWithTag:btnIndex + PROGRESS_SLIDER_TAG];
    trackRemainingTimeLB = (UILabel*)[self.view viewWithTag: 2 * btnIndex + TIME_LABEL_TAG];
    trackTimeLB = (UILabel*)[self.view viewWithTag:2 * btnIndex - 1 + TIME_LABEL_TAG];
    
    //get current track progress
    //ratio = 0;
    
    //set track progress
    [slider setValue:ratio animated:YES];
    
    //set time and remaining time label
    currentDuration = (double)(trackTotalTime[btnIndex - 1] * ratio);
    remainingTime = (double)(trackTotalTime[btnIndex - 1] * (1 - ratio));
    minute = (int)currentDuration / 60;
    second = (int)currentDuration % 60;
    millisecond = (currentDuration - minute * 60 - second) * 100;
    [trackTimeLB setText:[NSString stringWithFormat:@"%02d:%02d.%02d", minute, second, millisecond]];
    minute = (int)remainingTime / 60;
    second = (int)remainingTime % 60;
    millisecond = (remainingTime - minute * 60 - second) * 100;
    [trackRemainingTimeLB setText:[NSString stringWithFormat:@"%02d:%02d.%02d", minute, second, millisecond]];
}

//function for slide bar
- (void)slideSeekBar
{
    if (player1.isPlaying) {
        UISlider *slider1 = (UISlider *)[self.view viewWithTag:1 + PROGRESS_SLIDER_TAG];
        float ratio = (float)player1.currentTime / (float)player1.duration;
        [slider1 setValue:ratio animated:YES];
        [self setTimeLabel:1 Ratio:ratio];
    }
    if (player2.isPlaying) {
        UISlider *slider2 = (UISlider *)[self.view viewWithTag:2 + PROGRESS_SLIDER_TAG];
        float ratio = (float)player2.currentTime / (float)player2.duration;
        [slider2 setValue:ratio animated:YES];
        [self setTimeLabel:2 Ratio:ratio];
    }
    if (player3.isPlaying) {
        UISlider *slider3 = (UISlider *)[self.view viewWithTag:3 + PROGRESS_SLIDER_TAG];
        float ratio = (float)player3.currentTime / (float)player3.duration;
        [slider3 setValue:ratio animated:YES];
        [self setTimeLabel:3 Ratio:ratio];
    }
}

- (void) setTrackFinishedWithIndex:(NSInteger)index
{
    UISlider *slider;
    UILabel  *trackRemainingTimeLB;
    UILabel  *trackTimeLB;
    
    int currentDuration = 0;
    int remainingTime = 0;
    int minute = 0;
    int second = 0;
    
    
    float ratio = 1.0;
    //get track progress, time label, remaining time label
    //get object instance with tag
    slider = (UISlider *)[self.view viewWithTag:index + PROGRESS_SLIDER_TAG];
    trackRemainingTimeLB = (UILabel*)[self.view viewWithTag: 2 * index + TIME_LABEL_TAG];
    trackTimeLB = (UILabel*)[self.view viewWithTag:2 * index - 1 + TIME_LABEL_TAG];
    
    //set track progress
    [slider setValue:ratio];
    
    //set time and remaining time label
    currentDuration = (int)(trackTotalTime[index - 1] * ratio);
    remainingTime = (int)(trackTotalTime[index - 1] * (1 - ratio));
    minute = currentDuration / 60;
    second = currentDuration % 60;
    [trackTimeLB setText:[NSString stringWithFormat:@"%02d:%02d", minute, second]];
    minute = remainingTime / 60;
    second = remainingTime % 60;
    [trackRemainingTimeLB setText:[NSString stringWithFormat:@"%02d:%02d", minute, second]];
}
//indicate that file is selected
#pragma mark -
#pragma mark popovertableview delegate
- (void)FileSelected:(BOOL)isSelected
{
    if (isSelected) {
        [self showLoadingView:YES];
        [self performSelector:@selector(StartLoadingFileFetailItem) withObject:nil afterDelay:1];
    }
}

- (void)StartLoadingFileFetailItem
{
    [self setDetailItem:popTable.detailItem];
}

#pragma mark -
#pragma mark - popoverview delegate
- (void)setDetailItem:(id)newdetailItem
{
    if (detailItem != newdetailItem) {
        detailItem = newdetailItem;
        NSLog(@"new detailItem is set");
    }
    
    //VoiceFile *item = (VoiceFile *)detailItem;
    Production *aProduct = (Production *)detailItem;
    //show selected file name to specific label
    NSLog(@"%ld", currentBtn.tag);
    
    //get which index path
    long int index = currentBtn.tag - FILE_SELECTION_TAG;
    
    //get and set file name to label,
    //get total time from player,
    //then set player ready to play file
    NSError *error;
    NSURL *fileUrl;
    UIImageView *image = (UIImageView*)[self.view viewWithTag:TRACK_IMAGE_TAG + index];
    AVURLAsset *sourceAsset;
    switch (index) {
        case 1:
            alltracks[0] = aProduct;
            track1Label.text = [NSString stringWithFormat:@"%@ - %@",aProduct.ProductName,aProduct.Producer];
            //[track1Btn setTitle:aProduct.ProductName forState:UIControlStateNormal];
            
            if (![aProduct.ProductPath hasPrefix:@"ipod-library"])
                fileUrl = [NSURL fileURLWithPath:aProduct.ProductPath];
            else
                fileUrl = [NSURL URLWithString:aProduct.ProductPath];
            
            player1 = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
            if (error) {
                [error localizedDescription];
            }
            trackTotalTime[0] = player1.duration;
            [player1 setDelegate:self];
            [player1 prepareToPlay];
            sourceAsset = [AVURLAsset URLAssetWithURL:fileUrl options:nil];
            [image setImage:[UIImage imageWithData:[waveImageView renderPNGAudioPictogramLogForAssett:sourceAsset]]];
            break;
        case 2:
            alltracks[1] = aProduct;
            track2Label.text = [NSString stringWithFormat:@"%@ - %@",aProduct.Producer,aProduct.ProductName];
            //[track2Btn setTitle:aProduct.ProductName forState:UIControlStateNormal];
            
            if (![aProduct.ProductPath hasPrefix:@"ipod-library"])
                fileUrl = [NSURL fileURLWithPath:aProduct.ProductPath];
            else
                fileUrl = [NSURL URLWithString:aProduct.ProductPath];
            
            player2 = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
            if (error) {
                [error localizedDescription];
            }
            trackTotalTime[1] = player2.duration;
            [player2 setDelegate:self];
            [player2 prepareToPlay];
            sourceAsset = [AVURLAsset URLAssetWithURL:fileUrl options:nil];
            [image setImage:[UIImage imageWithData:[waveImageView renderPNGAudioPictogramLogForAssett:sourceAsset]]];
            break;
        case 3:
            alltracks[2] = aProduct;
            track3Label.text = [NSString stringWithFormat:@"%@ - %@",aProduct.Producer,aProduct.ProductName];
            //[track3Btn setTitle:aProduct.ProductName forState:UIControlStateNormal];
            
            if (![aProduct.ProductPath hasPrefix:@"ipod-library"])
                fileUrl = [NSURL fileURLWithPath:aProduct.ProductPath];
            else
                fileUrl = [NSURL URLWithString:aProduct.ProductPath];
            
            player3 = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
            if (error) {
                [error localizedDescription];
            }
            trackTotalTime[2] = player3.duration;
            [player3 setDelegate:self];
            [player3 prepareToPlay];
            sourceAsset = [AVURLAsset URLAssetWithURL:fileUrl options:nil];
            [image setImage:[UIImage imageWithData:[waveImageView renderPNGAudioPictogramLogForAssett:sourceAsset]]];
            break;
        default:
            break;
    }
    //get each track duration
    //NSError *error;
    //fileUrl = [NSURL fileURLWithPath:alltracks[index - 1].ProductPath];
    //player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
    //trackTotalTime[index - 1] = player.duration;
    
    isFileChangeName = YES;
    
    [self setTimeLabel:index Ratio:0.0];
    
    // 計算剩餘時間
    RemainTotleTrack = LimitTracks - player1.duration - player2.duration - player3.duration;
    NSLog(@"RemainTotleTrack=%d",RemainTotleTrack);
    
    //set path to specific index
    //[audioObject setSourcePathwithIndex:(index - 1) value:aProduct.ProductPath];
    
    //set # of track is load
    trackIsLoad[index - 1] = YES;
    //[trackIsLoadArray replaceObjectAtIndex:index - 1 withObject:[NSNumber numberWithBool:YES]];
    if (FPpopover != nil) {
        [FPpopover dismissPopoverAnimated:YES];
    }
    [self showLoadingView:NO];
}

- (IBAction)fileSelect_Press:(id)sender
{
    [self enableTrackEditbyBtn:sender];
    currentBtn = (UIButton *)sender;
    
    
    int index = currentBtn.tag - FILE_SELECTION_TAG;
    
    switch (index) {
        case 1:
            FileSelectPlayerTrack = player1.duration;
            break;
        case 2:
            FileSelectPlayerTrack = player2.duration;
            break;
        case 3:
            FileSelectPlayerTrack = player3.duration;
            break;
        default:
            break;
    }
    
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    [actionSheet addButtonWithTitle:@"本機音樂"];
    [actionSheet addButtonWithTitle:@"影音作品"];
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"取消"];
    actionSheet.delegate = self;
    [actionSheet showInView:self.view];
}

#pragma mark -
#pragma mark ActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"影音作品"])
    {
        
        if (FPpopover == nil) {
            popTable = [[popoverTableViewController alloc]
                     initWithNibName:@"popoverTableViewController"
                     bundle:[NSBundle mainBundle]];
            //use for dismiss when select an item from table
            popTable.delegate = self;
            FPpopover = [[FPPopoverKeyboardResponsiveController alloc] initWithViewController:popTable];
            FPpopover.tint = FPPopoverDefaultTint;
            [popTable getRemainTrack:RemainTotleTrack + FileSelectPlayerTrack];
            [popTable SourceController:@"Mixer"];
        }
        else {
            [popTable getRemainTrack:RemainTotleTrack + FileSelectPlayerTrack];
            [popTable SourceController:@"Mixer"];
            [popTable renewData];
        }
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            FPpopover.contentSize = CGSizeMake(300, 500);
        }
        else {
            FPpopover.contentSize = CGSizeMake(200, 300);
        }
        //sender is the UIButton view
        FPpopover.arrowDirection = FPPopoverArrowDirectionAny;
        [FPpopover presentPopoverFromView:currentBtn];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"本機音樂"])
    {
        MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
        picker.delegate                    = self;
        picker.allowsPickingMultipleItems  = NO;
        picker.prompt                      = NSLocalizedString(@"AddSongsPrompt", @"Prompt to user to choose some songs to play");
        [self presentViewController:picker animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark - MPMediaPickerControllerDelegate
- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection
{
    if (mediaItemCollection.items.count == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    //-----將音訊檔案資訊寫入Production物件中-----
    MPMediaItem *aMediaItem = [mediaItemCollection.items objectAtIndex:0];
    NSString* urlTitle = [NSString stringWithFormat:@"MixerBufferFile%d",currentBtn.tag - FILE_SELECTION_TAG];
    NSURL* assetURL = [aMediaItem valueForProperty:MPMediaItemPropertyAssetURL];
    Production *aMediaProduction = [[Production alloc] init];
    aMediaProduction.ProductName = [aMediaItem valueForKey:MPMediaItemPropertyTitle];
    aMediaProduction.Producer = [aMediaItem valueForKey:MPMediaItemPropertyArtist];
    int minute = [[aMediaItem valueForKey:MPMediaItemPropertyPlaybackDuration] floatValue] / 60;
    int second = [[NSString stringWithFormat:@"%f",[[aMediaItem valueForKey:MPMediaItemPropertyPlaybackDuration] floatValue]] intValue] % 60;
    aMediaProduction.ProductTracktime  = [NSString stringWithFormat:@"%02d:%02d", minute, second];
    //-----當iTune的路徑發生錯誤-----
    if (nil == assetURL) {
        NSLog(@"can't find Media's url");
        return;
    }
    //-----開始Loading動畫----
    [self showLoadingView:YES];
    //-----匯出iTune檔案-----
    [self exportAssetAtURL:assetURL withTitle:urlTitle withProductionInfo:aMediaProduction];
    //-----退出iTune視窗-----
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark - TSLibraryImport
- (void)exportAssetAtURL:(NSURL*)assetURL withTitle:(NSString*)title withProductionInfo:(Production*)aMediaProduction {
	//-----產生新的路徑存入本機音樂-----
	NSString* ext = [TSLibraryImport extensionForAssetURL:assetURL];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSURL* outURL = [[NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:title]] URLByAppendingPathExtension:ext];
    aMediaProduction.ProductPath = [[NSString stringWithFormat:@"%@",outURL] substringFromIndex:7];
	//-----確保不會有重複的檔案-----
	[[NSFileManager defaultManager] removeItemAtURL:outURL error:nil];
	//-----初始化TSLibraryImport-----
	TSLibraryImport* import = [[TSLibraryImport alloc] init];
    NSLog(@"%@",[NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:title]]);
    NSLog(@"%@\n%@",assetURL,outURL);
    //-----開始匯出音訊-----
	[import importAsset:assetURL toURL:outURL completionBlock:^(TSLibraryImport* import) {
        
        //-----當發生錯誤-----
        if (import.status == AVAssetExportSessionStatusUnknown) {
            [self showMessageWithTitle:@"警告" Message:@"匯入音軌出現不明錯誤"];
        }
		else if (import.status != AVAssetExportSessionStatusCompleted) {
			NSLog(@"Error importing: %@", import.error);
            [self showMessageWithTitle:@"訊息" Message:@"匯入音軌錯誤"];
			import = nil;
            //-----停止Loading動畫-----
            [self showLoadingView:NO];
			return;
		}
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL success = [fileManager fileExistsAtPath:aMediaProduction.ProductPath];
        NSLog(@"%@",aMediaProduction.ProductPath);
        if (success) {
            NSLog(@"here!!!");
        }
        //-----匯入到音軌中-----
        id NewiTuneItem = aMediaProduction;
        [self setDetailItem:NewiTuneItem];
        //-----釋放TSLibraryImport-----
		import = nil;
	}];
}

#pragma mark -
#pragma mark count number of loaded file
- (int)getReadyTrackNumber
{
    int readyCount = 0;
    UISwitch *aSwitch;
    //accroding to tracknamelabel set mixer input enable
    //track 1
    if ([track1Btn.titleLabel.text compare:@"Track 1"] != NSOrderedSame || [track1Label.text compare:@""] != NSOrderedSame)
    {
        aSwitch = (UISwitch *)[self.view viewWithTag:1];
        if (aSwitch.isOn) {
            readyCount++;
        }
    }
    //track 2
    if ([track2Btn.titleLabel.text compare:@"Track 2"] != NSOrderedSame || [track2Label.text compare:@""] != NSOrderedSame)
    {
        aSwitch = (UISwitch *)[self.view viewWithTag:2];
        if (aSwitch.isOn) {
            readyCount++;
        }
    }
    //track3
    if ([track3Btn.titleLabel.text compare:@"Track 3"] != NSOrderedSame || [track3Label.text compare:@""] != NSOrderedSame)
    {
        aSwitch = (UISwitch *)[self.view viewWithTag:3];
        if (aSwitch.isOn) {
            readyCount++;
        }
    }
    
    return readyCount;
}
- (int)getReadyTrackNumberforBtns
{
    int readyCount = 0;
    //accroding to tracknamelabel set mixer input enable
    //track 1
    if ([track1Btn.titleLabel.text compare:@"Track 1"] != NSOrderedSame && [track1Label.text compare:@""] != NSOrderedSame)
    {
        //if(trackIsSelected[0])
        readyCount++;
    }
    //track 2
    if ([track2Btn.titleLabel.text compare:@"Track 2"] != NSOrderedSame && [track2Label.text compare:@""] != NSOrderedSame)
    {
        //if(trackIsSelected[1])
        readyCount++;
    }
    //track3
    if ([track3Btn.titleLabel.text compare:@"Track 3"] != NSOrderedSame && [track3Label.text compare:@""] != NSOrderedSame)
    {
        //if(trackIsSelected[2])
        readyCount++;
    }
    
    return readyCount;
}
#pragma mark -
#pragma mark check function
- (BOOL) checkAllTrackFinished
{
    for (int i = 1; i < [self getReadyTrackNumberforBtns]; i++)
    {
        float progressValue = [audioObject mixerInputGetCurrentProgress:i - 1];
        //get slider instance
        if (progressValue != 1.0)
            return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark mixer function
- (void) prepareForMixerStartWithSave:(BOOL)isSave
{
    //set flag isMix
    isMix = YES;
    //set # of finished track to 0
    finishTrackCount = 0;
    //set haven't visited Production page
    isGoto = NO;
    //check if product save
    //start mix should not have saved
    isProductSaved = NO;
    //set number of bus
    [audioObject setBusCount:[self getReadyTrackNumberforBtns]];
    //save mix file
    [audioObject setIsRecorded:isSave];
    //initialization
    [audioObject initialToReady];
    isSaveDone = NO;
    
    //set mixer setting accroding to ui
    [self initToUI];
}
- (void) startMixer
{
    //start mix
    [audioObject startAUGraph];
    
    if ([track1Btn.titleLabel.text isEqualToString:@"N"]) {
        [audioObject enableMixerInput:[self getCorrespondingMixerBus:0] isOn:NO];
        needUpdate[0] = NO;
    }
    if ([track2Btn.titleLabel.text isEqualToString:@"N"]) {
        [audioObject enableMixerInput:[self getCorrespondingMixerBus:1] isOn:NO];
        needUpdate[1] = NO;
    }
    if ([track3Btn.titleLabel.text isEqualToString:@"N"]) {
        [audioObject enableMixerInput:[self getCorrespondingMixerBus:2] isOn:NO];
        needUpdate[2] = NO;
    }
    
    NSLog(@"mixer start!");
    NSLog(@"add finished mix note.");
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                             target:self
                                           selector:@selector(seekBarChange)
                                           userInfo:nil
                                            repeats:YES];
    [timer fire];
}
- (void) stopMixer
{
    [audioObject stopAUGraph];
    [timer invalidate];
    NSLog(@"mixer stop");
    isMix = NO;
    isGoto = NO;
}

#pragma mark -
#pragma mark btn IBAction for mixer
//listen to mix result, but do not save mix file
- (IBAction)play_Press:(id)sender
{
    //UIImage *stop = [UIImage imageNamed:@"Stop_icon.png"];
    //UIImage *play = [UIImage imageNamed:@"Play_icon.png"];
    
    currentBtn = (UIButton*)sender;
    int readtCount = [self getReadyTrackNumberforBtns];
    
    if (readtCount >= 2) {
        if (!isMix) {
            //prepare for mix, don't save mix file
            [self prepareForMixerStartWithSave:NO];
            //start mix, if all track still have time
            if (![self checkAllTrackFinished]) {
                [self startMixer];
            }
            //if all track have no time, set flag not Mixing
            else
            {
                isMix = NO;
                [self showMessageWithTitle:@"警告" Message:@"所有音軌已播放完畢"];
            }
        }
        else
        {
            //stop mix
            //[self stopMixer];
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"警告"
                                                        message:@"你必須選擇兩首以上的音軌"
                                                       delegate:nil
                                              cancelButtonTitle:@"了解"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

//mix press: begin to mix

- (IBAction)mix_Press:(id)sender
{
    if ([btnMixer.titleLabel.text compare:@"混音"] == NSOrderedSame) {
        currentBtn = (UIButton*)sender;
        isFileChangeName = NO;
        // 如果再次混音，把上個混音刪除
        if (![currentProduct.ProductID isEqualToString:@""]) {
            NSError *error;
            NSFileManager *manger = [NSFileManager defaultManager];
            NSString *removedPath = currentProduct.ProductPath;
            if ([manger fileExistsAtPath:removedPath]) {
                [manger removeItemAtPath:removedPath
                                   error:&error];
                NSLog(@"%@>>>has been removed", removedPath);
            };
            [database1 deleteSongFromMyProduct:currentProduct];
        }
        
        
        int readtCount = [self getReadyTrackNumberforBtns];
        
        if (readtCount >= 2) {
            
            // 儲存目前Tracktime與音量的位置
            SaveCurrentTimeSliderValue = [[NSMutableArray alloc] init];
            SaveCurrentVolumeValue = [[NSMutableArray alloc] init];
            SaveCurrentTimeLabelValue = [[NSMutableArray alloc] init];
            int NumberOfEndTrack = 0;
            
            for (int i=1; i <= 3; i++) {
                UISlider *tracktime = (UISlider *)[self.view viewWithTag:i + PROGRESS_SLIDER_TAG];
                UISlider *volume = (UISlider *)[self.view viewWithTag:i + VOLUME_SLIDER_TAG];
                UILabel *tracktime_Label = (UILabel *)[self.view viewWithTag:2 * i - 1 + TIME_LABEL_TAG];
                [SaveCurrentTimeSliderValue addObject:[NSString stringWithFormat:@"%f",tracktime.value]];
                [SaveCurrentVolumeValue addObject:[NSString stringWithFormat:@"%f",volume.value]];
                [SaveCurrentTimeLabelValue addObject:tracktime_Label.text];
                
                // 禁能未有檔案的按鈕
                UILabel *trackLB = (UILabel *)[self.view viewWithTag:i + TRACK_NAME_TAG];
                UIButton *lightBtn = (UIButton *)[self.view viewWithTag:i + LIGHT_BTN_TAG];
                UIButton *fileBtn = (UIButton *)[self.view viewWithTag:i + FILE_SELECTION_TAG];
                [fileBtn setEnabled:NO];
                if ([trackLB.text compare:@""] == NSOrderedSame) {
                    [lightBtn setEnabled:NO];
                    [tracktime setEnabled:NO];
                    [volume setEnabled:NO];
                }
                
                // 查看有𠽤時間是否到底
                if (tracktime.value == 1) {
                    NumberOfEndTrack ++;
                }
            }
            
            // 如果混音都播放完畢，給于警視窗並跳出
            if (NumberOfEndTrack >= readtCount) {
                [self showMessageWithTitle:@"訊息" Message:@"混音各個項目皆播放完畢"];
                return;
            }
            
            [btnMixer setTitle:@"停止" forState:UIControlStateNormal];
            [btnMixer setImage:[UIImage imageNamed:@"停止icon.png"] forState:UIControlStateNormal];
            [btnSaveFile setEnabled:NO];
            [btnListen setEnabled:NO];
            [btnReset setEnabled:NO];
            [btnListen setImage:[UIImage imageNamed:@"試聽icon-1.png"] forState:UIControlStateNormal];
            [btnReset setImage:[UIImage imageNamed:@"重錄icon-1.png"] forState:UIControlStateNormal];
            [btnSaveFile setImage:[UIImage imageNamed:@"儲存icon-1.png"] forState:UIControlStateNormal];
            if (!isMix) {
                /*
                 comment by Jay, 2013/5/9
                 [Function Update]
                 1. do not need load track sequetially
                 2. move mixer initialization from fileSelect_Press to mix_press
                 */
                
                Mixer *newAudioObject = [[Mixer alloc] init];
                audioObject = newAudioObject;
                [self registerForAudioObjectNotifications];
                
                //current index of file
                int fileCount = 0;
                
                //a dic. for record track to mixer bus
                viewToMixerDicArray = [[NSMutableDictionary alloc] init];
                
                //count avalible file and record information that which track is corresponding to mixer bus in dic..
                for (int i = 0; i < 3; i++) {
                    if ([alltracks[i].ProductPath compare:@" "] != NSOrderedSame) {
                        fileCount++;
                        [viewToMixerDicArray setObject:[NSString stringWithFormat:@"%d",fileCount - 1] forKey:[NSString stringWithFormat:@"%d",i]];
                    }
                }
                
                //show dic. content (for test)
                NSString *temp;
                for (int i = 0; i < 3; i++) {
                    temp = [viewToMixerDicArray objectForKey:[NSString stringWithFormat:@"%d",i]];
                    NSLog(@"index:%d wtih mixer index:%@ path:%@", i, temp, alltracks[i].ProductPath);
                    [audioObject setSourcePathwithIndex:[temp integerValue] value:alltracks[i].ProductPath];
                }
                //end comment by Jay
                
                //prepare for mix
                [self prepareForMixerStartWithSave:YES];
                [self startMixer];
            }
            else
            {
                MixFileDone = YES;
            }
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"警告"
                                                            message:@"你必須選擇兩首以上的音軌"
                                                           delegate:nil
                                                  cancelButtonTitle:@"了解"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    else if ([btnMixer.titleLabel.text compare:@"停止"] == NSOrderedSame) {
        if (!isExit) { // 判斷有無離開
            [self showMessageWithTitle:@"訊息" Message:@"混音完成"]; //顯示混音完成警視窗
        }
        //解鎖螢幕與智能設定按鈕
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UnLockView" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SettingEnable" object:nil];
        
        for (int i=1; i <= 3; i++) {
            //智能檔案與錄音燈的按鈕
            UIButton *lightBtn = (UIButton *)[self.view viewWithTag:i + LIGHT_BTN_TAG];
            UIButton *fileBtn = (UIButton *)[self.view viewWithTag:i + FILE_SELECTION_TAG];
            [lightBtn setEnabled:YES];
            [fileBtn setEnabled:YES];
        }
        
        [btnMixer setTitle:@"混音" forState:UIControlStateNormal];
        //[btnMixer setEnabled:NO];
        [btnListen setEnabled:YES];
        [btnReset setEnabled:YES];
        [btnSaveFile setEnabled:YES];
        
        [btnListen setImage:[UIImage imageNamed:@"試聽icon.png"] forState:UIControlStateNormal];
        [btnMixer setImage:[UIImage imageNamed:@"混音icon.png"] forState:UIControlStateNormal];
        [btnReset setImage:[UIImage imageNamed:@"重製icon.png"] forState:UIControlStateNormal];
        [btnSaveFile setImage:[UIImage imageNamed:@"儲存icon.png"] forState:UIControlStateNormal];
        
        isFileChangeName = NO;
        [self PrepListen];
        if (isMix) {
            [self stopMixer];
            //[self showMessageWithTitle:@"訊息" Message:@"已完成混音"];
        }
        MixFileDone = YES;
        audioObject= nil;
    }
}

- (IBAction)ListenMixer:(id)sender {
    UIStoryboard *storyboard = self.storyboard;
    ListenPlayerViewController *ListenPlayerVC = [storyboard instantiateViewControllerWithIdentifier:@"ListenPlayerVC"];
    [ListenPlayerVC setSongUrl:[NSURL fileURLWithPath:currentProduct.ProductPath]];
    [ListenPlayerVC setDelegate:self];
    [self presentPopupViewController:ListenPlayerVC animationType:MJPopupViewAnimationFade];
}

- (IBAction)RetryMixer:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                    message:@"是否要重製"
                                                   delegate:self
                                          cancelButtonTitle:@"否"
                                          otherButtonTitles:@"是", nil];
    [alert show];
}

- (IBAction)SaveMixer:(id)sender {
    // 如果來源有變化
    if (isFileChangeName) {
        isFileChangeName = NO;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                        message:@"發現混音音訊來源有變更，請重新混音或忽略變更進行儲存"
                                                       delegate:self
                                              cancelButtonTitle:@"忽略變更"
                                              otherButtonTitles:@"重新混音", nil];
        [alert show];
        return;
    }
    // ask whether rename action is need or not
    [self rename_press:nil];
}

- (void)GetMixerWorkInfo:(NSNotification *)notification
{
    currentProduct = [[Production alloc] init];
    currentProduct = [notification.object objectForKey:@"MixerWorkInfo"];
    NSLog(@">>>>>%@",currentProduct.ProductPath);
}

-(void)PrepListen
{
    //currentProduct = [database1 getLastObjectFromMyProduction];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:currentProduct.ProductName];
    NSLog(@"^^^^%@",path);
    NSURL *bgFileUrl = [NSURL fileURLWithPath:path];
    ListenPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:bgFileUrl error:&error];
    [ListenPlayer prepareToPlay];
}

-(void)updateTracktime
{
    LimitTime = [ListenPlayer duration];
    current = [ListenPlayer currentTime];
    [self time_Change:current];
    SliderListenTrack.value = current/LimitTime;
    if (current>=LimitTime) {
        [ListenPlayer stop];
        [self ListenMixer:nil];
    }
}

- (void)time_Change : (double)currTime
{
    int second = (int)currTime % 60;
    
    int minute = (int)currTime / 60;
    
    //int millisecond = (currTime - minute * 60 - second) * 100;
    
    lbListenTrack.text = [NSString stringWithFormat:@"%02d:%02d", minute, second];
}
#pragma mark -
#pragma mark all btn function
- (IBAction)enableTrackEditbyBtn:(id)sender
{
    UIImage *trackImg = [UIImage imageNamed:@"錄音燈-2.png"];
    UILabel *trackLB;
    //NSString *trackName;
    //UIImage *trackNoneImg = [UIImage imageNamed:@"錄音燈-2.png"];
    UIButton *aBtn = (UIButton *)sender;
    int btnIndex = aBtn.tag % 10 - 1;
    UIButton *lightBtn = (UIButton *)[self.view viewWithTag:btnIndex + 61];
    //UIColor *aColor;
    //int btnIndex = aBtn.tag - 11;
    NSLog(@"btn index: %d", btnIndex);
    
    //設定只能依順序選取track
    //    BOOL isSeq = YES;
    //    for (int i = btnIndex - 1;  i >= 0 ; i--) {
    //        if (!trackIsSelected[i]) {
    //            isSeq = NO;
    //        }
    //    }
    
    //if (isSeq) {
    if (!trackIsSelected[btnIndex]) {
        
        //set track need update or not
        //according to track name change
        int trackTag = btnIndex + 1 + TRACK_NAME_TAG;
        trackLB = (UILabel*)[self.view viewWithTag:trackTag];
        //trackName = [NSString stringWithFormat:@"Track %d", btnIndex+1];
        if ([trackLB.text  compare:@""] != NSOrderedSame) {
            [audioObject enableMixerInput:[self getCorrespondingMixerBus:btnIndex] isOn:YES];
            needUpdate[btnIndex] = YES;
        }
        
        trackIsSelected[btnIndex] = YES;
        NSLog(@"Track %d is enable", btnIndex);
        
        //set color for name label text and set image for switch btn
        UISlider *sliderTrack = (UISlider *)[self.view viewWithTag:PROGRESS_SLIDER_TAG + btnIndex + 1];
        UISlider *sliderVolume = (UISlider *)[self.view viewWithTag:VOLUME_SLIDER_TAG + btnIndex + 1];
        [self seekToTime:sliderTrack];
        [sliderTrack setEnabled:YES];
        [sliderVolume setEnabled:YES];
        switch (btnIndex) {
            case 0:
                [track1Btn setImage:[UIImage imageNamed:@"錄音燈-2.png"] forState:UIControlStateNormal];
                [track1Btn setTitle:@"Y" forState:UIControlStateNormal];
                break;
            case 1:
                [track2Btn setImage:[UIImage imageNamed:@"錄音燈-2.png"] forState:UIControlStateNormal];
                [track2Btn setTitle:@"Y" forState:UIControlStateNormal];
                break;
            case 2:
                [track3Btn setImage:[UIImage imageNamed:@"錄音燈-2.png"] forState:UIControlStateNormal];
                [track3Btn setTitle:@"Y" forState:UIControlStateNormal];
                break;
            default:
                break;
        }
        [lightBtn setImage:trackImg forState:UIControlStateNormal];
    }
    else if(trackIsSelected[btnIndex] && aBtn.tag >= 61 && aBtn.tag <= 64)
    {
        trackIsSelected[btnIndex] = NO;
        NSLog(@"Track %d is disable", btnIndex);
        needUpdate[btnIndex] = NO;
        //[lightBtn setImage:trackNoneImg forState:UIControlStateNormal];
        UISlider *sliderTrack = (UISlider*)[self.view viewWithTag:PROGRESS_SLIDER_TAG + btnIndex+1];
        UISlider *sliderVolume = (UISlider *)[self.view viewWithTag:VOLUME_SLIDER_TAG + btnIndex + 1];
        [sliderTrack setEnabled:NO];
        [sliderVolume setEnabled:NO];
        [audioObject enableMixerInput:[self getCorrespondingMixerBus:btnIndex] isOn:NO];
        switch (btnIndex) {
            case 0:
                [track1Btn setImage:[UIImage imageNamed:@"錄音燈-1.png"] forState:UIControlStateNormal];
                [track1Btn setTitle:@"N" forState:UIControlStateNormal];
                break;
            case 1:
                [track2Btn setImage:[UIImage imageNamed:@"錄音燈-1.png"] forState:UIControlStateNormal];
                [track2Btn setTitle:@"N" forState:UIControlStateNormal];
                break;
            case 2:
                [track3Btn setImage:[UIImage imageNamed:@"錄音燈-1.png"] forState:UIControlStateNormal];
                [track3Btn setTitle:@"N" forState:UIControlStateNormal];
                break;
            default:
                break;
        }
    }
    if (isMix) {
        NSLog(@"%d",trackIsSelected[btnIndex]);
        [audioObject enableMixerInput:[self getCorrespondingMixerBus:btnIndex] isOn:trackIsSelected[btnIndex]];
    }
}
//using btn for uiswitch for ui purpose
- (void) handleAlltrackfinished
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"MixerDidFinishedPlaying"
                                                  object:nil];
    NSLog(@"remove finished mix note.");
    
    //UIImage *play = [UIImage imageNamed:@"Play_icon.png"];
    //UIImage *mix = [UIImage imageNamed:@"mix_icon.png"];
    //    2013/04/26 Ricky
    //    [audioObject stopAUGraph];
    //    [timer invalidate];
    //    NSLog(@"stop!");
    //    isMix = NO;
    //    [self mix_Press:nil];
    if (currentBtn.tag == 8) {
        //[currentBtn setImage:play forState:UIControlStateNormal];
        //[currentBtn setTitle:@"混音試聽" forState:UIControlStateNormal];
    }
    else if (currentBtn.tag == 9)
    {
        //[currentBtn setImage:mix forState:UIControlStateNormal];
        //[currentBtn setTitle:@"錄製混音" forState:UIControlStateNormal];
        //[self rename_press:nil];
    }
    
}

// handle the event which track is finished play
- (void) handleTrackFinished: (id) notification {
    
    NSLog(@"track end.");
    NSNotification *note = (NSNotification *)notification;
    
    /*
     commney by Jay 2013/5/9
     comment needUpdate to solve slider bar can't move to the end
     */
    NSArray *keys = [viewToMixerDicArray allKeys];
    NSString *object;
    
    //UISwitch *aswitch;
    if ([note.name compare:@"Bus0FinishedPlay"] == NSOrderedSame){
        [notificationCenter removeObserver:self name:@"Bus0FinishedPlay" object:nil];
        //        [self setTrackFinishedWithIndex:1];
        [audioObject enableMixerInput:0 isOn:NO];
        for (id key in  keys) {
            object = [viewToMixerDicArray objectForKey:key];
            if ([object integerValue] == 0) {
                NSLog(@"Track %d finished.", [key integerValue] + 1);
            }
        }
        //aswitch = (UISwitch*)[self.view viewWithTag:1];
        //        if (needUpdate[0]) {
        //            finishTrackCount++;
        //        }
        //if (isMix) {
        //UISlider *progressSld = (UISlider*)[self.view viewWithTag:PROGRESS_SLIDER_TAG + 1];
        //[progressSld setValue:1.0 animated:YES];
        //needUpdate[0] = NO;
        //}
        /*
         comment by Jay 2013/5/9
         move slider to the end when track finished playing
         */
    }
    else if ([note.name compare:@"Bus1FinishedPlay"] == NSOrderedSame){
        [notificationCenter removeObserver:self name:@"Bus1FinishedPlay" object:nil];
        //        [self setTrackFinishedWithIndex:2];
        [audioObject enableMixerInput:1 isOn:NO];
        for (id key in  keys) {
            object = [viewToMixerDicArray objectForKey:key];
            if ([object integerValue] == 1) {
                NSLog(@"Track %d finished.", [key integerValue] + 1);
            }
        }
        //aswitch = (UISwitch*)[self.view viewWithTag:2];
        //        if (needUpdate[1]) {
        //            finishTrackCount++;
        //        }
        //if (isMix) {
        //UISlider *progressSld = (UISlider*)[self.view viewWithTag:PROGRESS_SLIDER_TAG + 2];
        //[progressSld setValue:1.0 animated:YES];
        //needUpdate[1] = NO;
        //}
    }
    else if ([note.name compare:@"Bus2FinishedPlay"] == NSOrderedSame){
        [notificationCenter removeObserver:self name:@"Bus2FinishedPlay" object:nil];
        //        [self setTrackFinishedWithIndex:3];
        [audioObject enableMixerInput:2 isOn:NO];
        for (id key in  keys) {
            object = [viewToMixerDicArray objectForKey:key];
            if ([object integerValue] == 2) {
                NSLog(@"Track %d finished.", [key integerValue] + 1);
            }
        }
        //aswitch = (UISwitch*)[self.view viewWithTag:3];
        //        if (needUpdate[2]) {
        //            finishTrackCount++;
        //        }
        //if (isMix) {
        //UISlider *progressSld = (UISlider*)[self.view viewWithTag:PROGRESS_SLIDER_TAG + 3];
        //[progressSld setValue:1.0 animated:YES];
        //needUpdate[2] = NO;
        //}
    }
    else if ([note.name compare:@"Bus3FinishedPlay"] == NSOrderedSame){
        [notificationCenter removeObserver:self name:@"Bus3FinishedPlay" object:nil];
        //        [self setTrackFinishedWithIndex:4];
        [audioObject enableMixerInput:3 isOn:NO];
        for (id key in  keys) {
            object = [viewToMixerDicArray objectForKey:key];
            if ([object integerValue] == 3) {
                NSLog(@"Track %d finished.", [key integerValue] + 1);
            }
        }
    }
}

//when interrupt or event happened, stop current play
- (void) handlePlaybackStateChanged: (id) notification {
    
    NSLog(@"audio file end.");
    if (audioObject.playing) {
        [self play_Press:nil];
    }
    else {
        [self play_Press:nil];
    }
}

// Handle a change in a mixer input gain slider. The "tag" value of the slider lets this
//    method distinguish between the two channels.
- (IBAction) mixerInputGainChanged: (UISlider *) sender {
    
    UInt32 inputBus = [self getCorrespondingMixerBus:sender.tag - VOLUME_SLIDER_TAG -1];
    
    //set player volume
    switch (inputBus) {
        case 0:
            if (player1) {
                [player1 setVolume: sender.value];
            }
            break;
        case 1:
            if (player2) {
                [player2 setVolume: sender.value];
            }
            break;
        case 2:
            if (player3) {
                [player3 setVolume: sender.value];
            }
            break;
        default:
            break;
    }
    
    //set mixer volume
    [audioObject setMixerInput: (UInt32) inputBus gain: (AudioUnitParameterValue) sender.value];
}

#pragma mark -
#pragma mark Remote-control event handling
// Respond to remote control events
- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if (audioObject.playing) {
                    [self play_Press:nil];
                }
                else {
                    [self play_Press:nil];
                }
                break;
                
            default:
                break;
        }
    }
}

#pragma mark -
#pragma mark Notification registration
// If this app's audio session is interrupted when playing audio, it needs to update its user interface
//    to reflect the fact that audio has stopped. The MixerHostAudio object conveys its change in state to
//    this object by way of a notification. To learn about notifications, see Notification Programming Topics.
- (void) registerForAudioObjectNotifications {
    NSLog(@"Register Audio Noti..");
    notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver: self
                           selector: @selector (handlePlaybackStateChanged:)
                               name: MixerHostAudioObjectPlaybackStateDidChangeNotification
                             object: audioObject];
    
    //when track finished or mix finished, push event into nsnotifacation center
    [notificationCenter addObserver: self
                           selector: @selector (handleTrackFinished:)
                               name: @"Bus0FinishedPlay"
                             object: nil];
    [notificationCenter addObserver: self
                           selector: @selector (handleTrackFinished:)
                               name: @"Bus1FinishedPlay"
                             object: nil];
    [notificationCenter addObserver: self
                           selector: @selector (handleTrackFinished:)
                               name: @"Bus2FinishedPlay"
                             object: nil];
    [notificationCenter addObserver: self
                           selector: @selector (handleTrackFinished:)
                               name: @"Bus3FinishedPlay"
                             object: nil];
}

#pragma mark -
#pragma mark MJSecondPopupDelegateDelegate
- (void)dismissSavingView:(SaveStudioAlertViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)dismissListenView:(ListenPlayerViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

#pragma mark -
#pragma mark - View Life Cycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //set image volume slider bar tumb
    UIImage *VolumeTumbImage = [UIImage imageNamed:@"音量控制.png"];
    UIImage *progressTumbImage = [UIImage imageNamed:@"音軌控制.png"];
//    UIImage *volumeBgImage = [UIImage imageNamed:@"06紅-1.png"];
//    UIImage *sliderRed = [UIImage imageNamed:@"06紅-2.png"];
//    UIImage *sliderBlue = [UIImage imageNamed:@"06藍-2.png"];
//    UIImage *trackBgImage = [UIImage imageNamed:@"06藍-1.png"];
    
    RemainTotleTrack = 4800;
    isSaveDone = YES;
    UISlider *tempSlider;
    for (int i = 21; i <= 23; i++) {
        tempSlider = (UISlider*)[self.view viewWithTag:i];
        [tempSlider setThumbImage:VolumeTumbImage forState:UIControlStateNormal];
        //[tempSlider setMaximumTrackImage:volumeBgImage forState:UIControlStateNormal];
        //[tempSlider setMinimumTrackImage:[sliderRed stretchableImageWithLeftCapWidth:15.0 topCapHeight:0.0] forState:UIControlStateNormal];
    }
    //set image track slider bar tumb
    for (int i = 31; i <= 33; i++) {
        tempSlider = (UISlider*)[self.view viewWithTag:i];
        [tempSlider setThumbImage:progressTumbImage forState:UIControlStateNormal];
        //[tempSlider setMaximumTrackImage:trackBgImage forState:UIControlStateNormal];
        //[tempSlider setMinimumTrackImage:[sliderBlue stretchableImageWithLeftCapWidth:15.0 topCapHeight:0.0] forState:UIControlStateNormal];
    }
    
    
//    UIImage *ListenMinBar = [UIImage imageNamed:@"05試聽bar.png"];
//    UIImage *ListenMaxBar = [UIImage imageNamed:@"05bar-1.png"];
//    UIImage *ListenThumb = [UIImage imageNamed:@"05試聽thum2.png"];
//    
//    [SliderListenTrack setThumbImage:ListenThumb forState:UIControlStateNormal];
//    [SliderListenTrack setMaximumTrackImage:ListenMaxBar forState:UIControlStateNormal];
//    [SliderListenTrack setMinimumTrackImage:ListenMinBar forState:UIControlStateNormal];
    
    track1Label.adjustsFontSizeToFitWidth = YES;
    track2Label.adjustsFontSizeToFitWidth = YES;
    track3Label.adjustsFontSizeToFitWidth = YES;
    
    //database = [[DBTool alloc] init];
    database1 = [[SQLiteDBTool alloc] init];
    MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";
    
    isMix = NO;
    isGoto = NO;
    MixFileDone = NO;
    waveImageView = [[WaveformImageVew alloc]init];
    [btnListen setEnabled:NO];
    [btnSaveFile setEnabled:NO];
    //initail flag indicate track is loaded or not
    //using NSNumber type for save object with bool type
    //trackIsLoadArray = [[NSMutableArray alloc] initWithObjects: [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], nil];
    
    // 創造遮住圖片的透明黑色遮色圖(用來辨認使用者混音在哪邊)
    UIImageView *ImageViewMixer = (UIImageView*)[self.view viewWithTag:TRACK_IMAGE_TAG +1];
    [self CreatBlackAlpha:0.7 imageSize:CGSizeMake(ImageViewMixer.frame.size.width, ImageViewMixer.frame.size.height)];
    
    //-----設定Loading的GIF動畫-----
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Loading3" withExtension:@"gif"];
    self.ivLoading.image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(GetMixerWorkInfo:) name:@"GetMixerWorkInfo" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GetMixerWorkInfo" object:nil];
}

- (void)CreatBlackAlpha:(float)Alpha imageSize:(CGSize)imageSize
{
    ImageSizeBlack = imageSize;
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:31/255.0 green:32/255.0 blue:35/255.0 alpha:1].CGColor);
    CGContextSetAlpha(context,Alpha);
    CGRect rect;
    rect.size = imageSize;
    rect.origin.x = 0;
    rect.origin.y = 0;
    CGContextFillRect(context, rect);
    // Create new image
    UIImage *BlackImage = UIGraphicsGetImageFromCurrentImageContext();
    
    for (int i=0; i <3; i++) {
        UIImageView *ImageviewBlack = (UIImageView *)[self.view viewWithTag:TRACK_IMAGE2_TAG + i + 1];
        [ImageviewBlack setImage:BlackImage];
    }
}

- (void)viewDidUnload
{
    [self setSliderListenTrack:nil];
    [self setBtnListen:nil];
    [self setBtnMixer:nil];
    [self setBtnReset:nil];
    [self setBtnSaveFile:nil];
    [self setBtnBarBG:nil];
    [self setTime1Label:nil];
    [self setTime2Label:nil];
    [self setTime3Label:nil];
    [self setLbListenTrack:nil];
    [self setTxtTrack1:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MixerHostAudioObjectPlaybackStateDidChangeNotification
                                                  object: audioObject];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"MixerDidFinishedPlaying"
                                                  object: nil];
    self.audioObject            = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MixerHostAudioObjectPlaybackStateDidChangeNotification
                                                  object: audioObject];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (void)showLoadingView:(BOOL)isHiden
{
    [self.ivLoading setHidden:!isHiden];
}

@end
