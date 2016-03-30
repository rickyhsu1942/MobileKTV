//
//  RecorderViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/29.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
//-----View-----
#import "RecorderViewController.h"
#import "SaveStudioAlertViewController.h"
#import "ListenPlayerViewController.h"
#import "popoverTableViewController.h"
#import "iTuneVideoViewController.h"
//-----Tool-----
#import "SQLiteDBTool.h"
#import "recordAndPlay.h"
//-----Object-----
#import "Production.h"
#import "GlobalData.h"
//-----UI-----
#import "UIViewController+MJPopupViewController.h"
#import "F3BarGauge.h"
#import "RESwitch.h"
#import "FPPopoverController.h"
#import "ARCMacros.h"
#import "FPPopoverKeyboardResponsiveController.h"


#define F3BarGauge_TAG        10

@interface RecorderViewController () <recordAndPlayDelegate,MJSecondPopupDelegate,FPPopoverControllerDelegate,popOverViewDelegate,UIActionSheetDelegate,MPMediaPickerControllerDelegate>
{
    Production *currentProduct;
    SQLiteDBTool *database;
    FPPopoverKeyboardResponsiveController *popover;
    popoverTableViewController *popTable;
    BOOL isProductSaved,isFileDone;
    NSTimer *timerListen;
    NSString *UnSaveFileName;
    AVAudioPlayer *ListenPlayer;
    Float32 current,LimitTime;
    NSTimer *TimerCheckMic;
    recordAndPlay *machine;
    BOOL isPlaying;
    BOOL isPause;
    
    NSTimer *timer;
    NSTimer *timerF3Bar;
    double lowPassReslts1;
    double lowPassReslts2;
    double lowPassReslts3;
    double lowPassReslts4;
    double lowPassReslts5;
    double lowPassReslts6;
    
    RESwitch *SwitchBackgroundMusic;
}

@property (weak, nonatomic) IBOutlet UIButton *ButtonBackgroundMusic;
@property (weak, nonatomic) IBOutlet UIButton *ButtonStartRecording;
@property (weak, nonatomic) IBOutlet UILabel *LbRecordTime;
@property (weak, nonatomic) IBOutlet UIButton *ButtonListen;
@property (weak, nonatomic) IBOutlet UIButton *ButtonStop;
@property (weak, nonatomic) IBOutlet UIButton *ButtonRetry;
@property (weak, nonatomic) IBOutlet UIButton *ButtonSave;
@property (weak, nonatomic) IBOutlet F3BarGauge *customRangeBar1;
@property (weak, nonatomic) IBOutlet F3BarGauge *customRangeBar2;
@property (weak, nonatomic) IBOutlet F3BarGauge *customRangeBar3;
@property (weak, nonatomic) IBOutlet F3BarGauge *customRangeBar4;
@property (weak, nonatomic) IBOutlet F3BarGauge *customRangeBar5;
@property (weak, nonatomic) IBOutlet F3BarGauge *customRangeBar6;
@property (nonatomic, retain) id detailItem;
@end

@implementation RecorderViewController

#pragma mark -
#pragma mark - IBAction
- (IBAction)BackPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)StartRecording:(id)sender {
    
    //if machie is not exist, initialize it
    if (machine == nil) {
        machine  = [[recordAndPlay alloc] init];
    }
    machine.delegate = self;
    
    // 監聽開啟與舊的Wave
    //[self initSoundWaveVisualiser];
    
    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    
    AudioSessionSetActive(true);
    
    [_ButtonStartRecording setHidden:YES];
    [_LbRecordTime setHidden:NO];
    if (machine.bgFilePath == NULL)
        [SwitchBackgroundMusic setEnabled:NO];
    else
        [SwitchBackgroundMusic setEnabled:YES];
    isPause = NO;
    [_ButtonBackgroundMusic setEnabled:NO];
    [self StopButtonEnable:YES];
    
    [machine stopPlayVoice];
    
    //then start recording
    isPlaying = YES;
    [self time_count];
    _LbRecordTime.text = @"00:00";
    timer = [NSTimer scheduledTimerWithTimeInterval:1
                                             target:self
                                           selector:@selector(time_count)
                                           userInfo:nil
                                            repeats:YES];
    
    //before record generate file first
    [self createRecordedFile];
    
    machine.recordFilePath = currentProduct.ProductPath;
    //configure recordAndPlay first
    [machine useDefaultSetting];
    //then record and play
    [machine recordAndPlay];
    timerF3Bar = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(F3BarStart) userInfo:nil repeats:YES];
}

- (IBAction)StopRecording:(id)sender {
    if (!isPause) {
        
        isPause = YES;
        [_ButtonStop setImage:[UIImage imageNamed:@"繼續錄音icon.png"] forState:UIControlStateNormal];
        [self StopButtonEnable:NO];
        if (machine.bgFilePath == NULL)
            [SwitchBackgroundMusic setEnabled:NO];
        else
            [SwitchBackgroundMusic setEnabled:YES];
        isPlaying = NO;
        
        [timer invalidate];
        
        //stop recorder and player
        [machine recordPause];
        [self prepListen];
        
        // 告知還未儲存
        NSDictionary* dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1]forKey:@"unsave"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RecordUnSaving" object:dict];
    }
    else if (isPause) {
        
        isPause = NO;
        [_ButtonStop setImage:[UIImage imageNamed:@"暫停icon.png"] forState:UIControlStateNormal];
        [self StopButtonEnable:YES];
        if (machine.bgFilePath == NULL)
            [SwitchBackgroundMusic setEnabled:NO];
        else
            [SwitchBackgroundMusic setEnabled:YES];
        [_ButtonBackgroundMusic setEnabled:NO];
        isPlaying = YES;
        [self time_count];
        timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                 target:self
                                               selector:@selector(time_count)
                                               userInfo:nil
                                                repeats:YES];
        [machine recordAndPlay];
        
        // 告知正在繼續，還無須儲存警告
        NSDictionary* dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0]forKey:@"unsave"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RecordUnSaving" object:dict];
    }
}

- (IBAction)RetryRecord:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                    message:@"是否重錄"
                                                   delegate:self
                                          cancelButtonTitle:@"否"
                                          otherButtonTitles:@"是",nil];
    [alert show];
}

- (IBAction)ListenRecordFile:(id)sender {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:UnSaveFileName];
    NSURL *ListenFileUrl = [NSURL fileURLWithPath:path];
    
    UIStoryboard *storyboard = self.storyboard;
    ListenPlayerViewController *ListenPlayerVC = [storyboard instantiateViewControllerWithIdentifier:@"ListenPlayerVC"];
    [ListenPlayerVC setSongUrl:ListenFileUrl];
    [ListenPlayerVC setDelegate:self];
    [self presentPopupViewController:ListenPlayerVC animationType:MJPopupViewAnimationFade];
}

- (IBAction)SaveFile:(id)sender {
    
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
    [SaveStudioAlertVC setSourceMachine:@"Recording"];
    [self presentPopupViewController:SaveStudioAlertVC animationType:MJPopupViewAnimationFade];
}

- (void)BackgroundMusic:(RESwitch *)switchView
{
    if ([SwitchBackgroundMusic isOn] == YES) {
        if (machine.bgFilePath != nil) {
            [machine setBgEnable:YES];
            
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                            message:@"請選擇音訊檔案"
                                                           delegate:nil
                                                  cancelButtonTitle:@"了解"
                                                  otherButtonTitles:nil];
            [alert show];
            [SwitchBackgroundMusic setOn:NO];
        }
    }
    else {
        [machine setBgEnable:NO];
    }
}

- (IBAction)PickBGMusic:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    [actionSheet addButtonWithTitle:@"本機音樂"];
    [actionSheet addButtonWithTitle:@"本機影片"];
    [actionSheet addButtonWithTitle:@"影音作品"];
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"取消"];
    actionSheet.delegate = self;
    [actionSheet showInView:self.view];
}

#pragma mark -
#pragma mark ActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"本機音樂"])
    {
        MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
        picker.allowsPickingMultipleItems  = NO;
        picker.delegate                    = self;
        picker.prompt                      = NSLocalizedString(@"AddSongsPrompt", @"Prompt to user to choose some songs to play");
        [self presentViewController:picker animated:YES completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"本機影片"])
    {
        UIStoryboard *storyboard = self.storyboard;
        iTuneVideoViewController *iTuneVideoVC  = [storyboard instantiateViewControllerWithIdentifier:@"iTuneVideoVC"];
        [iTuneVideoVC setValue:self forKey:@"iTuneDelegate"];
        iTuneVideoVC.FromVC = @"AVMixer";
        iTuneVideoVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:iTuneVideoVC animated:YES completion:Nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"影音作品"])
    {
        //-----呼叫popoverTableViewController，以FPPopover顯示
        popTable = [[popoverTableViewController alloc] initWithNibName:@"popoverTableViewController" bundle:[NSBundle mainBundle]];
        popTable.delegate = self;
        popover = [[FPPopoverKeyboardResponsiveController alloc] initWithViewController:popTable];
        popover.tint = FPPopoverDefaultTint;
        
        //-----依照應體設備設定大小-----
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            popover.contentSize = CGSizeMake(300, 500);
        }
        else {
            popover.contentSize = CGSizeMake(200, 300);
        }
        
        //-----選擇跳出來的箭頭定位-----
        popover.arrowDirection = FPPopoverArrowDirectionAny;
        [popover presentPopoverFromView:self.ButtonBackgroundMusic];
    }
}

#pragma mark -
#pragma mark - iTuneDelegate
- (void)videoPicker:(NSMutableArray*)SelectedVideoItem
{
    for (MPMediaItem *anItem in SelectedVideoItem)
    {
        NSURL *assetURL = [anItem valueForProperty: MPMediaItemPropertyAssetURL];
        //if machie is not exist, initialize it
        machine  = [[recordAndPlay alloc] init];
        machine.delegate = self;
        
        [machine setBgFilePath:[NSString stringWithFormat:@"%@",assetURL]];
        [self.ButtonBackgroundMusic setTitle:[anItem valueForKey:MPMediaItemPropertyTitle] forState:UIControlStateNormal];
    }
}

#pragma mark -
#pragma mark - MPMediaPickerControllerDelegate
- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection
{
    MPMediaItem *anItem = [mediaItemCollection.items objectAtIndex:0];
    NSURL *assetURL = [anItem valueForProperty: MPMediaItemPropertyAssetURL];
    
    //if machie is not exist, initialize it
    machine  = [[recordAndPlay alloc] init];
    machine.delegate = self;
    
    [machine setBgFilePath:[NSString stringWithFormat:@"%@",assetURL]];
    [self.ButtonBackgroundMusic setTitle:[anItem valueForKey:MPMediaItemPropertyTitle] forState:UIControlStateNormal];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -
#pragma mark popovertableview delegate
- (void)FileSelected:(BOOL)isSelected
{
    if (isSelected) {
        //if machie is not exist, initialize it
        machine  = [[recordAndPlay alloc] init];
        machine.delegate = self;
        
        [self setDetailItem:popTable.detailItem];
        Production *aProduct = (Production*)_detailItem;
        [machine setBgFilePath:aProduct.ProductPath];
        [popover dismissPopoverAnimated:YES];
    }
}

- (void)setDetailItem:(id)newdetailItem
{
    if (_detailItem != newdetailItem) {
        _detailItem = newdetailItem;
        
        //VoiceFile *item = (VoiceFile *)detailItem;
        Production *aProduct = (Production*)_detailItem;
        [_ButtonBackgroundMusic setTitle:aProduct.ProductName forState:UIControlStateNormal];
        
        [machine setBgFilePath:aProduct.ProductPath];
        //[machine setBgEnable:YES];
        NSLog(@"detailItem is set");
    }
    if (popover != nil) {
        [popover dismissPopoverAnimated:YES];
    }
}

#pragma mark -
#pragma mark Alert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (buttonIndex == 1) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"是"] &&
            [alertView.message isEqualToString:@"是否重錄"]) {
            [self ReSetRecorder];
        }
        else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"儲存"] &&
                 [alertView.message isEqualToString:@"是否儲存錄音"]) {
            [self SaveFile:nil];
        }
    }
    else if (buttonIndex == 0) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"取消"]) {
            
        }
    }
}

#pragma mark - 
#pragma mark - view life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    //-----初始化-----
    database = [[SQLiteDBTool alloc] init];
    [self initCustomRangeBar:_customRangeBar1];
    [self initCustomRangeBar:_customRangeBar2];
    [self initCustomRangeBar:_customRangeBar3];
    [self initCustomRangeBar:_customRangeBar4];
    [self initCustomRangeBar:_customRangeBar5];
    [self initCustomRangeBar:_customRangeBar6];
    
    //-----介面-----
    [_LbRecordTime setHidden:YES];
    [_ButtonListen setEnabled:NO];
    [_ButtonStop setEnabled:NO];
    [_ButtonRetry setEnabled:NO];
    [_ButtonSave setEnabled:NO];
    SwitchBackgroundMusic = [[RESwitch alloc] initWithFrame:CGRectMake(245, self.ButtonBackgroundMusic.frame.origin.y , 60, 31)];
    [SwitchBackgroundMusic setBackgroundImage:[UIImage imageNamed:@"on_off"]];
    [SwitchBackgroundMusic setKnobImage:[UIImage imageNamed:@"拉把"]];
    [SwitchBackgroundMusic setOverlayImage:nil];
    [SwitchBackgroundMusic setHighlightedKnobImage:nil];
    [SwitchBackgroundMusic setCornerRadius:0];
    [SwitchBackgroundMusic setKnobOffset:CGSizeMake(0, 0)];
    [SwitchBackgroundMusic setTextShadowOffset:CGSizeMake(0, 0)];
    [SwitchBackgroundMusic setFont:[UIFont boldSystemFontOfSize:14]];
    [SwitchBackgroundMusic setTextOffset:CGSizeMake(0, 2) forLabel:RESwitchLabelOn];
    [SwitchBackgroundMusic setTextOffset:CGSizeMake(3, 2) forLabel:RESwitchLabelOff];
    [SwitchBackgroundMusic setTextColor:[UIColor clearColor] forLabel:RESwitchLabelOn];
    [SwitchBackgroundMusic setTextColor:[UIColor clearColor] forLabel:RESwitchLabelOff];
    [self.view addSubview:SwitchBackgroundMusic];
    [SwitchBackgroundMusic addTarget:self action:@selector(BackgroundMusic:) forControlEvents:UIControlEventValueChanged];
    [SwitchBackgroundMusic setOn:NO];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    //-----宣告錄音Session-----
    AVAudioSession *session = [AVAudioSession sharedInstance];
    //-----Register for Route Change notifications-----
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleRouteChange:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: session];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleInterruption:)
                                                 name: AVAudioSessionInterruptionNotification
                                               object: session];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleMediaServicesWereReset:)
                                                 name: AVAudioSessionMediaServicesWereResetNotification
                                               object: session];
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    //-----Clean Register for Route Change notifications-----
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVAudioSessionRouteChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVAudioSessionInterruptionNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVAudioSessionMediaServicesWereResetNotification" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - Notification
-(void)handleRouteChange:(NSNotification*)notification
{
    AVAudioSession *session = [ AVAudioSession sharedInstance ];
    NSString* seccReason = @"";
    NSInteger  reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    //  AVAudioSessionRouteDescription* prevRoute = [[notification userInfo] objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    switch (reason) {
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            seccReason = @"The route changed because no suitable route is now available for the specified category.";
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            seccReason = @"The route changed when the device woke up from sleep.";
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            seccReason = @"The output route was overridden by the app.";
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            seccReason = @"The category of the session object changed.";
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            seccReason = @"The previous audio output path is no longer available.";
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            seccReason = @"A preferred new audio output path is now available.";
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
        default:
            seccReason = @"The reason for the change is unknown.";
            break;
    }
    AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count]?session.currentRoute.inputs:nil objectAtIndex:0];
    if (input.portType == AVAudioSessionPortHeadsetMic) {
        
    }
}

-(void)handleInterruption:(NSNotification*)notification
{
    NSInteger reason = 0;
    NSString* reasonStr=@"";
    if ([notification.name isEqualToString:@"AVAudioSessionInterruptionNotification"]) {
        //Posted when an audio interruption occurs.
        reason = [[[notification userInfo] objectForKey:@" AVAudioSessionInterruptionTypeKey"] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan) {
            //       Audio has stopped, already inactive
            //       Change state of UI, etc., to reflect non-playing state
        }
        
        if (reason == AVAudioSessionInterruptionTypeEnded) {
            //       Make session active
            //       Update user interface
            //       AVAudioSessionInterruptionOptionShouldResume option
            reasonStr = @"AVAudioSessionInterruptionTypeEnded";
            NSNumber* seccondReason = [[notification userInfo] objectForKey:@"AVAudioSessionInterruptionOptionKey"] ;
            switch ([seccondReason integerValue]) {
                case AVAudioSessionInterruptionOptionShouldResume:
                    //          Indicates that the audio session is active and immediately ready to be used. Your app can resume the audio operation that was interrupted.
                    break;
                default:
                    break;
            }
        }
        
        
        if ([notification.name isEqualToString:@"AVAudioSessionDidBeginInterruptionNotification"]) {
            //      Posted after an interruption in your audio session occurs.
            //      This notification is posted on the main thread of your app. There is no userInfo dictionary.
        }
        if ([notification.name isEqualToString:@"AVAudioSessionDidEndInterruptionNotification"]) {
            //      Posted after an interruption in your audio session ends.
            //      This notification is posted on the main thread of your app. There is no userInfo dictionary.
        }
        if ([notification.name isEqualToString:@"AVAudioSessionInputDidBecomeAvailableNotification"]) {
            //      Posted when an input to the audio session becomes available.
            //      This notification is posted on the main thread of your app. There is no userInfo dictionary.
        }
        if ([notification.name isEqualToString:@"AVAudioSessionInputDidBecomeUnavailableNotification"]) {
            //      Posted when an input to the audio session becomes unavailable.
            //      This notification is posted on the main thread of your app. There is no userInfo dictionary.
        }
        
    };
    NSLog(@"handleInterruption: %@ reason %@",[notification name],reasonStr);
}

-(void)handleMediaServicesWereReset:(NSNotification*)notification
{
    //  If the media server resets for any reason, handle this notification to reconfigure audio or do any housekeeping, if necessary
    //    • No userInfo dictionary for this notification
    //      • Audio streaming objects are invalidated (zombies)
    //      • Handle this notification by fully reconfiguring audio
    NSLog(@"handleMediaServicesWereReset: %@ ",[notification name]);
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
#pragma mark - MySubCode
- (void)initCustomRangeBar:(F3BarGauge*)customRangeBar
{
    customRangeBar.numBars = 11;
    customRangeBar.minLimit = 0.05;
    customRangeBar.maxLimit = 1.00;
    customRangeBar.holdPeak = NO;
    customRangeBar.litEffect = NO;
    
    customRangeBar.normalBarColor = [UIColor blueColor];
    customRangeBar.warningBarColor = [UIColor yellowColor];;
    customRangeBar.dangerBarColor = [UIColor redColor];;
    customRangeBar.backgroundColor = [UIColor blackColor];
    customRangeBar.outerBorderColor = [UIColor clearColor];
    customRangeBar.innerBorderColor = [UIColor clearColor];
}

- (void)F3BarStart
{
    [machine.recorder updateMeters];
    
    F3BarGauge *customRangeBar;
    
    const double ALPHA = 1.05;
    const double ALPHA1 = 1.15;
    const double ALPHA2 = 1.10;
    
	double averagePowerForChannel = pow(10, (0.05 * [machine.recorder averagePowerForChannel:0]));
    averagePowerForChannel = averagePowerForChannel * 6.8;
    double averagePowerForChannel1 = pow(10, (0.05 * [machine.recorder averagePowerForChannel:0]));
    averagePowerForChannel1 = averagePowerForChannel1 * 6;
	lowPassReslts1 = ALPHA * averagePowerForChannel1 + (1.0 - ALPHA) * lowPassReslts4;
	lowPassReslts2 = ALPHA * averagePowerForChannel1 + (1.0 - ALPHA) * lowPassReslts1;
	lowPassReslts3 = ALPHA * averagePowerForChannel1 + (1.0 - ALPHA) * lowPassReslts2;
	lowPassReslts4 = ALPHA * averagePowerForChannel1 + (1.0 - ALPHA) * lowPassReslts3;
	lowPassReslts5 = ALPHA1 * averagePowerForChannel + (1.0 - ALPHA1) * lowPassReslts5;
	lowPassReslts6 = ALPHA2 * averagePowerForChannel + (1.0 - ALPHA2) * lowPassReslts1;
    
    //F3BarGauge *customRangeBar;
    for (int i=1; i<=6; i++) {
        customRangeBar = (F3BarGauge*)[self.view viewWithTag:i + F3BarGauge_TAG];
        switch (i) {
            case 1:
                customRangeBar.value = lowPassReslts1;
                break;
            case 2:
                customRangeBar.value = lowPassReslts2;
                break;
            case 3:
                customRangeBar.value = lowPassReslts3;
                break;
            case 4:
                customRangeBar.value = lowPassReslts4;
                break;
            case 5:
                customRangeBar.value = lowPassReslts5;
                break;
            case 6:
                customRangeBar.value = lowPassReslts6;
                break;
                
            default:
                break;
        }
    }
}


-(void)StopButtonEnable:(BOOL)BoolValue
{
    BOOL otherBoolValue;
    if (BoolValue)
        otherBoolValue=NO;
    else
        otherBoolValue=YES;
    
    if (!isPause) {
        [_ButtonStop setEnabled:BoolValue];
        [_ButtonStop setImage:[UIImage imageNamed:@"暫停icon.png"] forState:UIControlStateNormal];
    }
    else if (isPause) {
        [_ButtonStop setEnabled:otherBoolValue];
        [_ButtonStop setImage:[UIImage imageNamed:@"繼續錄音icon.png"] forState:UIControlStateNormal];
    }
    
    [_ButtonListen setEnabled:otherBoolValue];
    [_ButtonRetry setEnabled:otherBoolValue];
    [_ButtonSave setEnabled:otherBoolValue];
    
    if (otherBoolValue) {
        [_ButtonListen setImage:[UIImage imageNamed:@"試聽icon.png"] forState:UIControlStateNormal];
        [_ButtonRetry setImage:[UIImage imageNamed:@"重錄icon.png"] forState:UIControlStateNormal];
        [_ButtonSave setImage:[UIImage imageNamed:@"儲存icon.png"] forState:UIControlStateNormal];
    }
    else {
        [_ButtonListen setImage:[UIImage imageNamed:@"試聽icon-1.png"] forState:UIControlStateNormal];
        [_ButtonRetry setImage:[UIImage imageNamed:@"重錄icon-1.png"] forState:UIControlStateNormal];
        [_ButtonSave setImage:[UIImage imageNamed:@"儲存icon-1.png"] forState:UIControlStateNormal];
    }
}

- (void)time_count
{
    int minute = machine.recorder.currentTime / 60;
    int second = (int)machine.recorder.currentTime % 60;
    _LbRecordTime.text = [NSString stringWithFormat:@"%02d:%02d",minute,second];
}

- (void)createRecordedFile
{
    GlobalData *globalItem = [GlobalData getInstance];
    //get document path
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [path objectAtIndex:0];
    NSDate *now = [NSDate date];
    
    // 運用yyyyMMdd形式建立檔案
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
    //[formatter1 setDateFormat:@"yyyyMMddHHmmss"];
    [formatter1 setDateFormat:@"yyyyMMdd"];
    NSString *valuestr = [formatter1 stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"%@(1).caf",valuestr];
    
    // 運用括弧流水號
    //    NSError *error;
    NSFileManager *manger = [NSFileManager defaultManager];
    NSString *FilePath = [[NSString alloc] initWithFormat:@"%@/%@",documentDirectory,fileName];
    NSString *OldPath = FilePath;
    FilePath = [[OldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    //if file exist at new path, appending number
    NSInteger count = 0;
    while ([manger fileExistsAtPath:FilePath])
    {
        count++;
        fileName = [NSString stringWithFormat:@"%@(%d).caf", valuestr, count];
        FilePath = [[OldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    }
    
    
    UnSaveFileName = fileName;
    NSLog(@">>>%@", FilePath);
    
    isProductSaved = NO;
    //save product inf. into table myproduction
    currentProduct = [[Production alloc] init];
    
    currentProduct.ProductName = fileName;
    currentProduct.ProductCreateTime = now;
    currentProduct.ProductPath = FilePath;
    currentProduct.ProductRight = @"私人";
    currentProduct.ProductType = @"聲音";
    currentProduct.userID = ([globalItem.currentUser compare:@""] == NSOrderedSame) ? @"-1" : globalItem.UserID;
    
    NSLog(@"insert date OK!");
}

-(void)prepListen {
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:UnSaveFileName];
    NSURL *bgFileUrl = [NSURL fileURLWithPath:path];
    ListenPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:bgFileUrl error:&error];
    [ListenPlayer prepareToPlay];
}

- (void)SavingDidEnd:(BOOL)isGiveUp {
    if (isGiveUp) {
        // 放棄儲存
        // doNothing
    }
    else {
        // 已經儲存錄音檔案
        [_ButtonStop setImage:[UIImage imageNamed:@"暫停icon.png"] forState:UIControlStateNormal];
        [_ButtonStartRecording setHidden:NO];
        [_ButtonListen setEnabled:NO];
        [_ButtonListen setImage:[UIImage imageNamed:@"試聽icon-1.png"] forState:UIControlStateNormal];
        [_ButtonStop setEnabled:NO];
        [_ButtonStop setImage:[UIImage imageNamed:@"暫停icon-1.png"] forState:UIControlStateNormal];
        [_ButtonRetry setEnabled:NO];
        [_ButtonRetry setImage:[UIImage imageNamed:@"重錄icon-1.png"] forState:UIControlStateNormal];
        [_ButtonSave setEnabled:NO];
        [_ButtonSave setImage:[UIImage imageNamed:@"儲存icon-1.png"] forState:UIControlStateNormal];
        [_LbRecordTime setHidden:YES];
        [SwitchBackgroundMusic setEnabled:YES];
        [_ButtonBackgroundMusic setEnabled:YES];
        [machine setBgFilePath:nil];
        [machine setBgEnable:NO];
        [SwitchBackgroundMusic setOn:NO];
        [_ButtonBackgroundMusic setTitle:@"" forState:UIControlStateNormal];
        [timerF3Bar invalidate];
        //解鎖螢幕與智能設定按鈕
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UnLockView" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SettingEnable" object:nil];
        // 告知已儲存
        NSDictionary* dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0]forKey:@"unsave"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RecordUnSaving" object:dict];
    }
}

- (void)ReSetRecorder {
    
    if (isPlaying)
        return;
    NSError *error;
    NSFileManager *manger = [NSFileManager defaultManager];
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [path objectAtIndex:0];
    NSString *CheckSongPath = [documentDirectory stringByAppendingPathComponent:currentProduct.ProductName];
    NSString *removedPath = CheckSongPath;
    if ([manger fileExistsAtPath:removedPath]) {
        [manger removeItemAtPath:removedPath
                           error:&error];
        NSLog(@"%@>>>has been removed", removedPath);
    };
    
    [_ButtonStop setImage:[UIImage imageNamed:@"暫停icon.png"] forState:UIControlStateNormal];
    [_ButtonStartRecording setHidden:NO];
    [_ButtonListen setEnabled:NO];
    [_ButtonListen setImage:[UIImage imageNamed:@"試聽icon-1.png"] forState:UIControlStateNormal];
    [_ButtonStop setEnabled:NO];
    [_ButtonStop setImage:[UIImage imageNamed:@"暫停icon-1.png"] forState:UIControlStateNormal];
    [_ButtonRetry setEnabled:NO];
    [_ButtonRetry setImage:[UIImage imageNamed:@"重錄icon-1.png"] forState:UIControlStateNormal];
    [_ButtonSave setEnabled:NO];
    [_ButtonSave setImage:[UIImage imageNamed:@"儲存icon-1.png"] forState:UIControlStateNormal];
    [_LbRecordTime setHidden:YES];
    [SwitchBackgroundMusic setEnabled:YES];
    [_ButtonBackgroundMusic setEnabled:YES];
    [machine setBgFilePath:nil];
    [machine setBgEnable:NO];
    [SwitchBackgroundMusic setOn:NO];
    [_ButtonBackgroundMusic setTitle:@"" forState:UIControlStateNormal];
    [timerF3Bar invalidate];
    // 解鎖螢幕與智能設定按鈕
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UnLockView" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SettingEnable" object:nil];
    // 告知已儲存
    NSDictionary* dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0]forKey:@"unsave"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RecordUnSaving" object:dict];
}

-(void)AutoCheckMic {
    //Do Nothing now but don't delete it.
}


@end
