//
//  AVMixerViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/4.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreText/CoreText.h>
//-----View-----
#import "AVMixerViewController.h"
#import "ColorSettingViewController.h"
#import "SavingFileViewController.h"
#import "SaveStudioAlertViewController.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"
#import "KOKSAudioPickerViewController.h"
#import "iTuneVideoViewController.h"
//-----Tool-----
#import "KOKSAVMixer.h"
#import "SQLiteDBTool.h"
//-----Object-----
#import "GlobalData.h"
#import "Setting.h"
//-----UI-----
#import "UIViewController+MJPopupViewController.h"
#import "HZActivityIndicatorView.h"
//-----Define
#define defaultAVMixFileName @"Carol_AVMixerResult.mp4"
#define MIXER_IMAGE_SOURCE_TYPE_USER_PHOTOS       0
#define MIXER_IMAGE_SOURCE_TYPE_USER_VIDEOS       1

#define DEFAULT_TITLE_FONT_SIZE                   80

#define SONG_TYPE_MP3                       0
#define SONG_TYPE_MP4                       1

@interface AVMixerViewController () <UIActionSheetDelegate,ELCImagePickerControllerDelegate,MJSecondPopupDelegate, KOKSAudioPickerViewControllerDelegate,UITextFieldDelegate>
{
    UInt32          curImageSrcIdx;
    UIPopoverController *imageVideoPopupPicker;
    UIPopoverController *audioFilePopover;
    KOKSAVMixer     *avMixer;
    NSArray         *selectedAudioFiles;
    Float64         audioDuration;
    AVPlayerItem    *userPlayerItem;        // User's selected Movie
    AVPlayer        *userPlayer;
    AVPlayerLayer   *playerLayer;
    NSMutableArray  *imageList2;            // User's Photo List
    NSMutableArray  *videoList;
    NSURL           *usrMP4Url;
    AVURLAsset      *movieAsset;
    Float32         fontSize;               // fixed: 80
    CALayer         *currentTitleLayer;
    id              sliderUpdater;
    
    
    int     songType;       // 0 : mp3; 1: mp4
    AVPlayerItem                  *defaultPlayerItem;   // The Original movie
    
    
    float TitleShowDuration;
    float PresentDuration;
    NSString *FilePath;
    NSString *ListenPath;
    NSString *OldadjustVideoTime;
    BOOL isSettingChanged;
    SQLiteDBTool *database;
    
    NSString * strRed;
    NSString * strGreen;
    NSString * strBlue;
    
    AVMutableComposition *composition;
    Float32 musicDuration;
    NSTimer *ListenTimer;
}

@property (nonatomic, strong) AVPlayer *defaultPlayer;
@property (weak, nonatomic) IBOutlet UIView *ViewMixSetting;
@property (weak, nonatomic) IBOutlet UITextField *TextFieldMovieTitle;
@property (weak, nonatomic) IBOutlet UIButton *BtnSelectAudio;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIImageView *ImageViewPicture;
@property (weak, nonatomic) IBOutlet UISlider *SliderTracktime;
@property (weak, nonatomic) IBOutlet UILabel *LBTracktime;
@property (weak, nonatomic) IBOutlet UIButton *BtnListen;
@property (weak, nonatomic) IBOutlet UIButton *BtnMix;
@property (weak, nonatomic) IBOutlet UIButton *BtnReset;
@property (weak, nonatomic) IBOutlet UIButton *BtnSave;
@property (weak, nonatomic) IBOutlet UITextField *TextFieldTitlesec;
@property (weak, nonatomic) IBOutlet UITextField *TextFieldPictrueSec;
@property (weak, nonatomic) IBOutlet UILabel *LBMusicFileName;
@property (weak, nonatomic) IBOutlet UILabel *LBVideoInfo;
@property (weak, nonatomic) IBOutlet UIView *ViewProcessing;
@property (unsafe_unretained, nonatomic) IBOutlet HZActivityIndicatorView *ActivityProcessing;
@property (weak, nonatomic) IBOutlet UISlider *SliderFontsize;
@property (weak, nonatomic) IBOutlet UIButton *BtnSelectVideo;
@end

@implementation AVMixerViewController
@synthesize ViewMixSetting,previewView,ViewProcessing;
@synthesize ActivityProcessing;
@synthesize TextFieldMovieTitle,TextFieldPictrueSec,TextFieldTitlesec;
@synthesize ImageViewPicture;
@synthesize SliderTracktime,SliderFontsize;
@synthesize LBTracktime,LBMusicFileName,LBVideoInfo;
@synthesize BtnListen,BtnMix,BtnReset,BtnSave,BtnSelectAudio,BtnSelectVideo;
@synthesize defaultPlayer;

#pragma mark -
#pragma mark IBAction
- (IBAction)BackPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)Color:(id)sender {
    [TextFieldMovieTitle resignFirstResponder];
    [TextFieldPictrueSec resignFirstResponder];
    [TextFieldTitlesec resignFirstResponder];
    UIStoryboard *storybord = self.storyboard;
    ColorSettingViewController *colorSettingVC = [storybord instantiateViewControllerWithIdentifier:@"ColorSettingVC"];
    colorSettingVC.delegate = self;
    
    [colorSettingVC setStrRed:strRed];
    [colorSettingVC setStrGreen:strGreen];
    [colorSettingVC setStrBlue:strBlue];
    [colorSettingVC setValue:self forKey:@"ColorvalueDelegate"];
    
    // saveVocal.outputAVComposition = outputAVComposition;
    [self presentPopupViewController:colorSettingVC animationType:MJPopupViewAnimationFade];
    
    isSettingChanged = YES;
}

- (IBAction)changeImageSource:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    [actionSheet addButtonWithTitle:@"照片"];
    [actionSheet addButtonWithTitle:@"錄影檔"];
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"取消"];
    actionSheet.delegate = self;
    [actionSheet showInView:self.view];
}

- (IBAction)adjustTitleFontEnd:(id)sender {
    // 判斷currentTitleLayer有無資料
    if ([currentTitleLayer.sublayers count] < 1) {
        return;
    }
    // 如果當CurrentTitleLayer中的標題字型寬度超過400做出警告
    CALayer *titleFontLayer = [currentTitleLayer.sublayers objectAtIndex:0];
    if (titleFontLayer.preferredFrameSize.width > 220) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                        message:@"標題已經超過銀幕大小，建議縮小字型大小或減少字的數量"
                                                       delegate:nil
                                              cancelButtonTitle:@"了解"
                                              otherButtonTitles:nil];
        [alert show];
    }
    isSettingChanged = YES;
}
- (IBAction)adjustTitleFontEndOutside:(id)sender {
    // 判斷currentTitleLayer有無資料
    if ([currentTitleLayer.sublayers count] < 1) {
        return;
    }
    // 如果當CurrentTitleLayer中的標題字型寬度超過400做出警告
    CALayer *titleFontLayer = [currentTitleLayer.sublayers objectAtIndex:0];
    if (titleFontLayer.preferredFrameSize.width > 220) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                        message:@"標題已經超過銀幕大小，建議縮小字型大小或減少字的數量"
                                                       delegate:nil
                                              cancelButtonTitle:@"了解"
                                              otherButtonTitles:nil];
        [alert show];
    }
    isSettingChanged = YES;
}

- (IBAction)adjustTitleEnd:(id)sender {
    if (currentTitleLayer != nil)
        [currentTitleLayer removeFromSuperlayer];
    
    [avMixer setTitle:TextFieldMovieTitle.text withSize:fontSize withShowDuration:TitleShowDuration];
    CGSize showSize = previewView.bounds.size;
    if (userPlayerItem != nil) {
        CGSize preSize = userPlayerItem.presentationSize;
        Float32 wRatio = preSize.width / showSize.width;
        Float32 hRatio = preSize.height / showSize.height;
        if (wRatio > hRatio)
            showSize.height = preSize.height / wRatio;
        else
            showSize.width = preSize.width / hRatio;
    }
    
    currentTitleLayer = [avMixer getTitleLayerForVideoSize:showSize forOutput:false];
    //
    //[previewView.layer addSublayer:currentTitleLayer];
    [avMixer resetAVComposition];
    // 判斷currentTitleLayer有無資料
    if ([currentTitleLayer.sublayers count] < 1) {
        return;
    }
    // 如果當CurrentTitleLayer中的標題字型寬度超過400做出警告
    CALayer *titleFontLayer = [currentTitleLayer.sublayers objectAtIndex:0];
    if (titleFontLayer.preferredFrameSize.width > 220) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                        message:@"標題已經超過銀幕大小，建議縮小字型大小或減少字的數量"
                                                       delegate:nil
                                              cancelButtonTitle:@"了解"
                                              otherButtonTitles:nil];
        [alert show];
    }
    isSettingChanged = YES;
}

- (IBAction)adjustTitleTime:(id)sender {
    if (![TextFieldTitlesec.text integerValue]) {
        [self showAlertMessage:@"請輸入數字" withTitle:@"訊息" buttonText:@"了解"];
        TextFieldTitlesec.text = @"5";
        return;
    }
    TitleShowDuration = [TextFieldTitlesec.text floatValue];
    // fontSize = stepperFontSize.value;
    //fontSize = DEFAULT_TITLE_FONT_SIZE   ; // fixed size !!
    fontSize = SliderFontsize.value;
    
    // textTitleFontSize.text = [NSString stringWithFormat:@"%.0f", (fontSize) ];
    // change the size of Text
    if (currentTitleLayer != nil)
        [currentTitleLayer removeFromSuperlayer];
    //
    [avMixer setTitle:TextFieldMovieTitle.text withSize:fontSize withShowDuration:TitleShowDuration];
    CGSize showSize = previewView.bounds.size;
    if (userPlayerItem != nil) {
        CGSize preSize = userPlayerItem.presentationSize;
        Float32 wRatio = preSize.width / showSize.width;
        Float32 hRatio = preSize.height / showSize.height;
        if (wRatio > hRatio)
            showSize.height = preSize.height / wRatio;
        else
            showSize.width = preSize.width / hRatio;
    }
    
    currentTitleLayer = [avMixer getTitleLayerForVideoSize:showSize forOutput:false];
    //
    //[previewView.layer addSublayer:currentTitleLayer];
    [avMixer resetAVComposition];
    isSettingChanged = YES;
}

- (IBAction)adjustVideoTimeBegin:(id)sender {
    OldadjustVideoTime = TextFieldPictrueSec.text;
    TextFieldPictrueSec.text = [NSString stringWithFormat:@"%@%@%@"
                                ,[TextFieldPictrueSec.text substringToIndex:2]
                                ,[TextFieldPictrueSec.text substringWithRange:NSMakeRange(3, 2)]
                                ,[TextFieldPictrueSec.text substringFromIndex:TextFieldPictrueSec.text.length - 2]];
}

- (IBAction)adjustVideoTime:(id)sender {
    if (![TextFieldPictrueSec.text integerValue]) {
        [self showAlertMessage:@"請輸入數字" withTitle:@"訊息" buttonText:@"了解"];
        TextFieldPictrueSec.text = OldadjustVideoTime;
        return;
    }
    else if (TextFieldPictrueSec.text.length != 6) {
        [self showAlertMessage:@"請依照6碼數字分別為「時」「分」「秒」進行輸入" withTitle:@"訊息" buttonText:@"了解"];
        TextFieldPictrueSec.text = OldadjustVideoTime;
        return;
    }
    TextFieldPictrueSec.text = [NSString stringWithFormat:@"%@:%@:%@"
                                ,[TextFieldPictrueSec.text substringToIndex:2]
                                ,[TextFieldPictrueSec.text substringWithRange:NSMakeRange(2, 2)]
                                ,[TextFieldPictrueSec.text substringFromIndex:TextFieldPictrueSec.text.length - 2]];
    // 計算總共秒數
    int hour = [[TextFieldPictrueSec.text substringToIndex:2] intValue];
    int min = [[TextFieldPictrueSec.text substringWithRange:NSMakeRange(3, 2)] intValue];
    int sec = [[TextFieldPictrueSec.text substringFromIndex:TextFieldPictrueSec.text.length - 2] intValue];
    float totalTime = hour * 3600 + min * 60 + sec;
    
    PresentDuration = totalTime;
    [avMixer resetAVComposition];
    isSettingChanged = YES;
}

- (IBAction)changeTrackStart:(id)sender {
    [userPlayer pause];
    [defaultPlayer pause];
}

- (IBAction)changeTrackPosition:(id)sender {
    [userPlayer pause];
    [defaultPlayer pause];
    Float64 current = SliderTracktime.value;
    [defaultPlayer seekToTime:CMTimeMakeWithSeconds(current, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero ];
    
    //
    //    if (BtnListen.selected)
    //        [defaultPlayer play];
    [SliderTracktime setEnabled:YES];
}
- (IBAction)changeTrackEnd:(id)sender {
    [defaultPlayer play];
}

- (IBAction)Listen:(id)sender {
    if (!BtnListen.isSelected) {
        // 檢查是否有異動到設定
        if (isSettingChanged) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                            message:@"發現影音設定在合成後有變更，請重新合成或忽略變更進行試聽"
                                                           delegate:self
                                                  cancelButtonTitle:@"忽略變更"
                                                  otherButtonTitles:@"重新合成", nil];
            [alert show];
            return;
        }
        // (A) check if the audio/video is missed !?
        if (selectedAudioFiles.count == 0) {
            [self showAlertMessage:@"請先選擇語音檔案，再開始播放！" withTitle:@"訊息" buttonText:@"確認"];
            return;
        }
        // (B) missing something !
        if ( (curImageSrcIdx == MIXER_IMAGE_SOURCE_TYPE_USER_PHOTOS && imageList2.count == 0) ||
            (curImageSrcIdx == MIXER_IMAGE_SOURCE_TYPE_USER_VIDEOS && userPlayerItem == nil)) {
            [self showAlertMessage:@"請選擇要合成的圖片或影片，再開始播放！" withTitle:@"訊息" buttonText:@"確認"];
            return;
        }
        
        //檢查檔案是否存在
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL success = [fileManager fileExistsAtPath:ListenPath];
        if(!success) {
            [self showAlertMessage:@"訊息" withTitle:@"音訊檔案不存在" buttonText:@"了解"];
            return;
        }
        
        
        [self prepareMedia];
    }
    else {
        [self stopPlaying];
    }
}

- (IBAction)AudioPressed:(id)sender
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
        if ([database getMyProductCount] > 0)
        {
            UIStoryboard *storyboard = self.storyboard;
            KOKSAudioPickerViewController *KOKSAudioPickerVC = [storyboard instantiateViewControllerWithIdentifier:@"audioPicker"];
            KOKSAudioPickerVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            KOKSAudioPickerVC.delegate = self;
            [self presentViewController:KOKSAudioPickerVC animated:YES completion:nil];
        } else {
            [self showAlertMessage:@"無作品可以選取" withTitle:@"訊息" buttonText:@"了解"];
        }
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"照片"])
    {
        ImageViewPicture.hidden = true;
        curImageSrcIdx = MIXER_IMAGE_SOURCE_TYPE_USER_PHOTOS;
        [self launchImageVideoPicker:kUTTypeImage];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"錄影檔"])
    {
        ImageViewPicture.hidden = true;
        curImageSrcIdx = MIXER_IMAGE_SOURCE_TYPE_USER_VIDEOS;
        [self launchImageVideoPicker:kUTTypeVideo];
    }
}

#pragma mark -
#pragma mark - iTuneDelegate
- (void)videoPicker:(NSMutableArray*)SelectedVideoItem
{
    for (MPMediaItem *anItem in SelectedVideoItem)
    {
        NSURL *assetURL = [anItem valueForProperty: MPMediaItemPropertyAssetURL];
        selectedAudioFiles = [NSArray arrayWithObject:assetURL];
        LBMusicFileName.text = [anItem valueForKey:MPMediaItemPropertyTitle];
        AVURLAsset *audioAsset = [AVAsset assetWithURL:assetURL];
        audioDuration = CMTimeGetSeconds(audioAsset.duration);
        [SliderTracktime setMaximumValue:audioDuration];
        [SliderTracktime setValue:0.0];
        [self updateSlider:kCMTimeZero];
        [avMixer resetAVComposition];
        isSettingChanged = YES;
    }
}

#pragma mark -
#pragma mark - MPMediaPickerControllerDelegate
- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection
{
    MPMediaItem *anItem = [mediaItemCollection.items objectAtIndex:0];
    NSURL *assetURL = [anItem valueForProperty: MPMediaItemPropertyAssetURL];
    selectedAudioFiles = [NSArray arrayWithObject:assetURL];
    LBMusicFileName.text = [anItem valueForKey:MPMediaItemPropertyTitle];
    AVURLAsset *audioAsset = [AVAsset assetWithURL:assetURL];
    audioDuration = CMTimeGetSeconds(audioAsset.duration);
    [SliderTracktime setMaximumValue:audioDuration];
    [SliderTracktime setValue:0.0];
    [self updateSlider:kCMTimeZero];
    [avMixer resetAVComposition];
    isSettingChanged = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Subcode Media
-(void)prepareMedia {
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:ListenPath] options:nil];
    
	// enable/disable UI as appropriate
	NSArray *visualTracks = [sourceAsset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
    composition = [AVMutableComposition composition];
    if ((!visualTracks) || ([visualTracks count] == 0)) {
        songType = SONG_TYPE_MP3;
        [composition insertTimeRange:CMTimeRangeMake(kCMTimeZero, sourceAsset.duration) ofAsset:sourceAsset atTime:composition.duration error:nil];
	}else {
        songType = SONG_TYPE_MP4;
        // Case 1. Add it into your composition (不可以包含音軌，測試時有雜音！！)
        [composition insertTimeRange:CMTimeRangeMake(kCMTimeZero, sourceAsset.duration) ofAsset:sourceAsset atTime:composition.duration error:nil];
        // Case 2. Retrieve the Video only !!   （抽離出Video !!）
        //[self insertVideoTrack: sourceAsset :composition];
    }
    
    NSLog(@"The Tracks of the Original Asset:");
    [self showAssetTrackInfo: sourceAsset];
    NSLog(@"The Tracks of the Composition Asset:");
    [self showAssetTrackInfo: composition];
    
    defaultPlayerItem = [AVPlayerItem playerItemWithAsset:composition];
    defaultPlayer = [AVPlayer playerWithPlayerItem:defaultPlayerItem];
    
    
    if (playerLayer != nil) {
        playerLayer.player = nil;
        [playerLayer removeFromSuperlayer];
    }
    
    if (songType==1) {
        [previewView setHidden:NO];
        [ImageViewPicture setHidden:YES];
        [previewView setBackgroundColor:[UIColor blackColor]];
        playerLayer = [AVPlayerLayer playerLayerWithPlayer:defaultPlayer];
        playerLayer.frame = previewView.layer.bounds;
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [previewView.layer addSublayer:playerLayer];
    }
    
    AVPlayerItem *item = [defaultPlayer currentItem];
	musicDuration = CMTimeGetSeconds([item duration]);
    
    NSLog (@"playing %@", ListenPath);
    
    //
    ImageViewPicture.hidden = true;
    [SliderTracktime setEnabled:YES];
    // disable button
    BtnSelectAudio.enabled = false;
    BtnSelectAudio.alpha   = 0.3;
    BtnSelectVideo.enabled = false;
    TextFieldPictrueSec.enabled = false;
    TextFieldPictrueSec.alpha = 0.3;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        BtnListen.selected = YES;
        [BtnListen setTitle:@"停止試播" forState:UIControlStateNormal];
        [BtnListen setImage:[UIImage imageNamed:@"停止試聽.png"] forState:UIControlStateNormal];
        ListenTimer=[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(upDateMusicTime) userInfo:nil repeats:YES];
        [defaultPlayer play];
    });
}

- (IBAction)MixVideo:(id)sender {
    
    // stop playing firstly!
    if (BtnListen.selected)
        [self stopPlaying];
    [SliderTracktime setEnabled:NO];
    // (A) check if the audio/video is missed !?
    if (selectedAudioFiles.count == 0) {
        [self showAlertMessage:@"請先選擇語音檔案，再進行儲存！" withTitle:@"訊息" buttonText:@"確認"];
        return;
    }
    // (B) missing something !
    if ((curImageSrcIdx == MIXER_IMAGE_SOURCE_TYPE_USER_PHOTOS && imageList2.count == 0) ||
        (curImageSrcIdx == MIXER_IMAGE_SOURCE_TYPE_USER_VIDEOS && videoList.count == 0 )) {
        [self showAlertMessage:@"請選擇要合成的圖片或影片，再進行儲存！" withTitle:@"訊息" buttonText:@"確認"];
        return;
    }
    //檢查檔案是否存在
    if (![[NSString stringWithFormat:@"%@",[selectedAudioFiles objectAtIndex:0]] hasPrefix:@"ipod-library"])
    {
        //因為編碼問題，暫且拿除
    }
    
    isSettingChanged = NO;
    ViewProcessing.hidden = false;
    BtnReset.enabled = NO;
    [BtnReset setImage:[UIImage imageNamed:@"重製-反灰.png"] forState:UIControlStateNormal];
    BtnMix.enabled = NO;
    [BtnMix setImage:[UIImage imageNamed:@"合成-反灰.png"] forState:UIControlStateNormal];
    ViewMixSetting.userInteractionEnabled = NO;
    [ActivityProcessing startAnimating];
    
    //
    [self performSelectorInBackground:@selector(prepareOutputComposition) withObject:nil];
    
}

- (IBAction)reset:(id)sender {
    if (BtnListen.selected)
        [self stopPlaying];
    [SliderTracktime setEnabled:NO];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                    message:@"是否重置"
                                                   delegate:self
                                          cancelButtonTitle:@"否"
                                          otherButtonTitles:@"是", nil];
    [alert show];
}

- (IBAction)SaveFile:(id)sender {
    
    // 檢查是否有異動到設定
    if (isSettingChanged) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                        message:@"發現影音設定在合成後有變更，請重新合成或忽略變更進行儲存"
                                                       delegate:self
                                              cancelButtonTitle:@"忽略變更"
                                              otherButtonTitles:@"重新合成", nil];
        [alert show];
        return;
    }
    
    // 儲存目錄
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [path objectAtIndex:0];
    
    // 運用yyyyMMdd形式建立檔案
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
    [formatter1 setDateFormat:@"yyyyMMdd"];
    NSString *valuestr = [formatter1 stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"%@(1).mp4",valuestr];
    
    // 運用括弧流水號
    NSFileManager *manger = [NSFileManager defaultManager];
    NSString *CheckFilePath = [[NSString alloc] initWithFormat:@"%@/%@",documentDirectory,fileName];
    NSString *OldPath = CheckFilePath;
    CheckFilePath = [[OldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    //if file exist at new path, appending number
    NSInteger count = 0;
    while ([manger fileExistsAtPath:CheckFilePath])
    {
        count++;
        fileName = [NSString stringWithFormat:@"%@(%d).mp4", valuestr, count];
        CheckFilePath = [[OldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    }
    GlobalData *globalItem = [GlobalData getInstance];
    NSDate *now = [NSDate date];
    Production *item = [[Production alloc] init];
    item.ProductName = fileName;
    item.ProductPath = ListenPath;
    item.Producer = globalItem.UserNickname;
    item.ProductCreateTime = now;
    item.ProductRight = @"私人";
    item.ProductType = @"影片";
    item.ProductTracktime = [self secondToString:audioDuration];
    item.userID = [globalItem.currentUser compare:@"-2"] == NSOrderedSame ? @"guest": globalItem.UserID;
    
    // 運行儲存視窗
    UIStoryboard *storyboard = self.storyboard;
    SaveStudioAlertViewController *SaveStudioAlertVC  = [storyboard instantiateViewControllerWithIdentifier:@"SaveStudioAlertVC"];
    [SaveStudioAlertVC setAProduction:item];
    SaveStudioAlertVC.delegate = self;
    [SaveStudioAlertVC setSourceMachine:@"AVMixer"];
    [SaveStudioAlertVC setValue:self forKey:@"CheckMicDelegate"];
    [self presentPopupViewController:SaveStudioAlertVC animationType:MJPopupViewAnimationFade];
}


#pragma mark -
#pragma mark prepareOutputComposition
- (void) prepareOutputComposition {
    //CGSize outputSize = {1024,768};
    Setting *aSetting = [[Setting alloc]init];
    GlobalData *globalItem = [GlobalData getInstance];
    aSetting = [database getSettingWithUserID:globalItem.UserID];
    CGSize outputSize;
    NSArray *ResolutiontArray = [aSetting.Resolution componentsSeparatedByString:@"*"];
    if ([ResolutiontArray count] > 1) {
        outputSize.width = [[ResolutiontArray objectAtIndex:0] intValue];
        outputSize.height = [[ResolutiontArray objectAtIndex:1] intValue];
    }
    else {
        outputSize.width = 400;
        outputSize.height = 300;
    }
    //    CGSize outputSize = {400, 300};
    
    // 1. prepare the Title
    [avMixer setTitle:TextFieldMovieTitle.text withSize:fontSize withShowDuration:TitleShowDuration];
    currentTitleLayer = [avMixer getTitleLayerForVideoSize:outputSize forOutput:false];
    [avMixer resetAVComposition];
    //
    if (avMixer.outputComposition == nil) {
        if (curImageSrcIdx == MIXER_IMAGE_SOURCE_TYPE_USER_PHOTOS)
            [avMixer prepareAVCompositionforPlayback:NO forVideoSize:outputSize withAudio:selectedAudioFiles withPhotos:imageList2 showTime:PresentDuration withVideos:nil];
        else
            [avMixer prepareAVCompositionforPlayback:NO forVideoSize:outputSize withAudio:selectedAudioFiles withPhotos:nil showTime:0 withVideos:videoList];
    }
    //
    if (avMixer.outputComposition == nil)
        return;
    
    ViewProcessing.hidden = true;
    BtnReset.enabled = YES;
    [BtnReset setImage:[UIImage imageNamed:@"重製icon.png"] forState:UIControlStateNormal];
    BtnMix.enabled = YES;
    [BtnMix setImage:[UIImage imageNamed:@"合成.png"] forState:UIControlStateNormal];
    ViewMixSetting.userInteractionEnabled = YES;
    [ActivityProcessing stopAnimating];
    
    // 儲存目錄
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [path objectAtIndex:0];
    
    
    NSString *fileName = defaultAVMixFileName;
    // 運用括弧流水號
    NSFileManager *manger = [NSFileManager defaultManager];
    FilePath = [[NSString alloc] initWithFormat:@"%@/%@",documentDirectory,fileName];
    NSString *OldPath = FilePath;
    FilePath = [[OldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    //if file exist at new path, appending number
    if ([manger fileExistsAtPath:FilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:FilePath error:nil];
    }
    
    // setup the AVMutableComposition
    UIStoryboard *storyboard = self.storyboard;
    SavingFileViewController *savinFileVC  = [storyboard instantiateViewControllerWithIdentifier:@"savinFile"];
    savinFileVC.avMixer = avMixer;
    // saveVocal.outputAVComposition = avMixer.outputComposition;
    [savinFileVC setOutputAVComposition: avMixer.outputComposition];
    savinFileVC.outputVocalFileName = fileName;
    savinFileVC.delegate = self;
    [savinFileVC setSongType:@"AVMixer"];
    [savinFileVC setValue:self forKey:@"SavingFileVCDelegate"];
    [savinFileVC setTracktime:[self secondToString:audioDuration]];
    // 影音合成！
    [savinFileVC setOutputMode:true];
    
    [self presentPopupViewController:savinFileVC animationType:MJPopupViewAnimationFade];
}

-(void) stopPlaying {
    [defaultPlayer pause];
    [ListenTimer invalidate];
    [SliderTracktime setEnabled:NO];
    BtnListen.selected = NO;
    [BtnListen setTitle:@"試播" forState:UIControlStateNormal];
    [BtnListen setImage:[UIImage imageNamed:@"試聽icon.png"] forState:UIControlStateNormal];
    
    
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // remove updader
    if (sliderUpdater)
    {
        [userPlayer removeTimeObserver:sliderUpdater];
        sliderUpdater = nil;
    }
    // enable button
    BtnSelectAudio.enabled = true;
    BtnSelectAudio.alpha   = 1.0;
    BtnSelectVideo.enabled = true;
    TextFieldPictrueSec.enabled = true;
    TextFieldPictrueSec.alpha = 1.0;
    //
}

#pragma mark -
#pragma mark Image/Video Picker

-(void) launchImageVideoPicker:(CFStringRef) mediaType { // mediaType : kUTTypeImage or kUTTypeVideo
    ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] initWithNibName:@"ELCAlbumPickerController" bundle:[NSBundle mainBundle]];
    albumController.mediaType = mediaType;
	ELCImagePickerController *elcImagePicker = [[ELCImagePickerController alloc] initWithRootViewController:albumController];
    [albumController setParent:elcImagePicker];
	[elcImagePicker setDelegate:self];
    
    // New Model !!
    // for iPad --> by PopoverController
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
    } else {
        [self presentViewController:elcImagePicker animated:YES completion:nil];
    }
}

#pragma -
#pragma subcode Slider
- (void)updateSlider:(CMTime) curTime
{
    // step.1 Update slider and playing-time labels
    // update Slider
    // double current = CMTimeGetSeconds(player.currentTime);
    Float64 current;
    if (userPlayer == nil || userPlayerItem == nil)
        current = 0;
    else
        current = CMTimeGetSeconds(curTime);
    
    // NSLog (@"Update slider: %f; currentTime=%f; duration=%f; imageIdx=%d", songSlider.value, current, duration, imageIdx);
    
    [SliderTracktime setValue:current];
    NSString *currentStr = [self secondToString:current];
    [LBTracktime setText:currentStr];
    //[lbLeftTime setText:leftStr];
}

-(void)upDateMusicTime {
    float current = CMTimeGetSeconds([[defaultPlayer currentItem] currentTime]);
    SliderTracktime.value=current;
    LBTracktime.text = [self secondToString:current];
    if (current >= musicDuration)
        [self stopPlaying];
}


- (NSString *)secondToString : (double) current
{
    int h = ((int)current) / 3600;
    int m = ((int)current - h*3600) / 60;
    int s = ((int)current) % 60;
    NSString *ss = [NSString stringWithFormat:@"%02d:%02d", m, s];
    return ss;
}
#pragma mark -
#pragma mark Video or Picture Delegate
#pragma mark ELCImagePickerControllerDelegate Methods
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
    
    // 關閉選擇畫面！！
    // for iPad --> by PopoverController
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [imageVideoPopupPicker dismissPopoverAnimated:YES];
    }
    else {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    
    // check if there are any images selected ?
    if ( info.count == 0 )
        return;
    
    if (defaultPlayerItem != nil) {
        defaultPlayerItem = nil;
    }
    
    if (curImageSrcIdx == MIXER_IMAGE_SOURCE_TYPE_USER_PHOTOS)  {
        // clear the original images !
        [imageList2 removeAllObjects];
        for(NSDictionary *dict in info) {
            // we must retrieve the UIImage objects !!
            [imageList2 addObject:[dict objectForKey:UIImagePickerControllerOriginalImage]];
        }
        NSLog(@"Number of Image files(User's Selection) for showing: %d", imageList2.count);
        
        // --- delay updating !! -------------------------------------------------------------
        // if nothing selected --> keep the original selection.
        if ([imageList2 count] == 0) return;
        
        // Now, SUPPOSE we have user's selected image files for showing.
        LBVideoInfo.text = [NSString stringWithFormat: @" 照片 (%d張)", [imageList2 count]];
        [playerLayer removeFromSuperlayer];
        ImageViewPicture.image = [imageList2 objectAtIndex:0];
        ImageViewPicture.hidden = FALSE;
        
        // 智能TextFieldPictrueSec
        [TextFieldPictrueSec setEnabled:YES];
    }
    else if (curImageSrcIdx == MIXER_IMAGE_SOURCE_TYPE_USER_VIDEOS){
        // clear the original videos !
        [videoList removeAllObjects];
        // for Debugging only !!
        for(NSDictionary *dict in info) {
            // we must retrieve the NSURL object for accessing the viewo files!!
            NSURL *videoURL = [dict objectForKey:UIImagePickerControllerReferenceURL];
            NSLog(@"Selected Video for showing: %@", videoURL);
        }
        // --- delay updating !! -------------------------------------------------------------
        // Now, SUPPOSE we have user's selected video files for showing.
        NSString *videoInfo = [NSString stringWithFormat: @" 影片 (%d個檔案)", info.count];
        // switch with the first User selected Video
        for(NSDictionary *dict in info) {
            // we must retrieve the Video-URLs !
            NSURL *videoUrl = [dict objectForKey:UIImagePickerControllerReferenceURL];
            [videoList addObject:videoUrl];
        }
        LBVideoInfo.text = videoInfo;
        NSURL *videoURL = [[info objectAtIndex:0] objectForKey:UIImagePickerControllerReferenceURL];
        if (playerLayer != nil) [playerLayer removeFromSuperlayer];
        [self switchUserVideo:videoURL];
        ImageViewPicture.hidden = TRUE;
        
        // 把選擇的影片總時間寫入TextFieldPictrueSec，並禁能
        [TextFieldPictrueSec setEnabled:NO];
        int seconds = 0;
        for (NSURL *videoURL in videoList) {
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoURL];
            CMTime duration = playerItem.duration;
            seconds += CMTimeGetSeconds(duration);
        }
        NSString *hour = [NSString stringWithFormat:@"00%d",seconds / 3600];
        NSString *min = [NSString stringWithFormat:@"00%d",seconds / 60];
        NSString *sec = [NSString stringWithFormat:@"00%d",seconds % 60];
        TextFieldPictrueSec.text = [NSString stringWithFormat:@"%@:%@:%@"
                                    ,[hour substringFromIndex:[hour length] - 2]
                                    ,[min substringFromIndex:[min length] - 2]
                                    ,[sec substringFromIndex:[sec length] - 2]];
    }
    //
    [avMixer resetAVComposition];
    isSettingChanged = YES;
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
	//[self dismissModalViewControllerAnimated:YES];
    
    // 關閉選擇畫面！！
    // for iPad --> by PopoverController
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [imageVideoPopupPicker dismissPopoverAnimated:YES];
    }
    else {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self elcImagePickerControllerDidCancel:nil];
}

- (void) switchUserVideo: (NSURL *) videoURL {
    // Check whether we need switch to the NEW selected one !
    if (videoURL != nil) {
        if (userPlayerItem != nil)
            //
            userPlayerItem = nil;
        //
        usrMP4Url = videoURL;
        movieAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
        NSLog(@"The Tracks of the User-Original Asset:");
        //[self showAssetTrackInfo: movieAsset];
        
        userPlayerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        // recreate a new UserPlayer
        userPlayer = nil;
        userPlayer = [AVPlayer playerWithPlayerItem:userPlayerItem];
        
    }
    else {
        userPlayerItem =nil;
    }
    //
    if (playerLayer != nil) {
        playerLayer.player = nil;
        [playerLayer removeFromSuperlayer];
    }
    //
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:userPlayer];
    playerLayer.frame = previewView.layer.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [previewView.layer addSublayer:playerLayer];
}

- (void) showAssetTrackInfo : (AVAsset *) asset {
    NSArray *tracks = [asset tracks];
    int i=1;
    for (AVAssetTrack *track in tracks) {
        NSLog( @"Track#%d: %@", i++, [track mediaType]);
    }
}

#pragma mark -
#pragma mark MJSecondPopupDelegateDelegate
- (void)dismissSavingView:(SaveStudioAlertViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)dismissColorSettingView:(ColorSettingViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)dismissSavingFileView:(SavingFileViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

#pragma mark -
#pragma mark Music popoverDelegate
/*
 - (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 if ([segue.identifier isEqualToString:@"selectAudioFile"]) {
 KOKSAudioPickerViewController * selectAudioFileVC = (KOKSAudioPickerViewController *)(segue.destinationViewController);
 selectAudioFileVC.delegate = self;
 audioFilePopover = [(UIStoryboardPopoverSegue *)segue popoverController];
 }
 }
 */
-(void) setAudioFilename:(NSArray *) filenames ProductName:(NSString *) productname {
    selectedAudioFiles = [NSArray arrayWithArray: filenames];
    LBMusicFileName.text = productname;
    AVURLAsset *audioAsset = [AVAsset assetWithURL:[selectedAudioFiles objectAtIndex:0]];
    audioDuration = CMTimeGetSeconds(audioAsset.duration);
    [SliderTracktime setMaximumValue:audioDuration];
    [SliderTracktime setValue:0.0];
    [self updateSlider:kCMTimeZero];
    //
    [avMixer resetAVComposition];
    isSettingChanged = YES;
}

-(void) dismissAudioFilePopover {
    [audioFilePopover dismissPopoverAnimated:NO];
}

#pragma mark -
#pragma mark Delegate
// -----ColorDelegate-----
-(void)Color_RedValue:(NSString *)RedValue Green:(NSString*)GreenValue Blue:(NSString*)BlueValue
{
    strRed = RedValue;
    strGreen = GreenValue;
    strBlue = BlueValue;
    [avMixer setTitlecolorRed:[RedValue floatValue]/255.0];
    [avMixer setTitlecolorGreen:[GreenValue floatValue]/255.0];
    [avMixer setTitlecolorBlue:[BlueValue floatValue]/255.0];
}
// -----SavingDelegate-----
- (void)DoneSavingAndGetSongPath:(NSString*)ProductPath {
    [BtnSave setImage:[UIImage imageNamed:@"儲存icon-1.png"] forState:UIControlStateNormal];
    [BtnSave setEnabled:NO];
    ListenPath = ProductPath;
}
// -----MixerDelegate-----
- (void)DoneAVMixandGetProductPath:(NSString*)productPath {
    [BtnListen setImage:[UIImage imageNamed:@"試聽icon.png"] forState:UIControlStateNormal];
    [BtnListen setEnabled:YES];
    [BtnSave setImage:[UIImage imageNamed:@"儲存icon.png"] forState:UIControlStateNormal];
    [BtnSave setEnabled:YES];
    ListenPath = productPath;
}

#pragma mark -
#pragma mark - Textfield Delegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark AlertMessage
-(void) showAlertMessage:(NSString *) message withTitle:(NSString *)title buttonText:(NSString *) btnCancelText {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: title
                          message:message
                          delegate:nil
                          cancelButtonTitle: btnCancelText
                          otherButtonTitles: nil];
    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (1 == buttonIndex) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] compare:@"是"] == NSOrderedSame) {
            SliderTracktime.value = 0;
            LBTracktime.text = @"00:00";
            selectedAudioFiles = nil;
            [imageList2 removeAllObjects];
            [videoList removeAllObjects];
            userPlayerItem = nil;
            defaultPlayerItem = nil;
            curImageSrcIdx = nil;
            [TextFieldMovieTitle setText:@""];
            [TextFieldPictrueSec setText:@"00:00:05"];
            [TextFieldTitlesec setText:@"5"];
            TitleShowDuration = 5;
            PresentDuration = 5;
            [LBMusicFileName setText:@""];
            [LBVideoInfo setText:@""];
            strRed = [NSString stringWithFormat:@"0"];
            strGreen = [NSString stringWithFormat:@"0"];
            strBlue = [NSString stringWithFormat:@"0"];
            [avMixer setTitlecolorRed:[strRed floatValue]/255.0];
            [avMixer setTitlecolorGreen:[strGreen floatValue]/255.0];
            [avMixer setTitlecolorBlue:[strBlue floatValue]/255.0];
            [ImageViewPicture setImage:nil];
            ImageViewPicture.hidden = true;
            [BtnListen setImage:[UIImage imageNamed:@"試聽icon-1.png"] forState:UIControlStateNormal];
            [BtnListen setEnabled:NO];
            [BtnSave setImage:[UIImage imageNamed:@"儲存icon-1.png"] forState:UIControlStateNormal];
            [BtnSave setEnabled:NO];
            [playerLayer removeFromSuperlayer];
            [currentTitleLayer removeFromSuperlayer];
        } else if ([[alertView buttonTitleAtIndex:buttonIndex] compare:@"重新合成"] == NSOrderedSame) {
            [self MixVideo:nil];
        }
    } else if (0 == buttonIndex) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] compare:@"忽略變更"] == NSOrderedSame) {
            isSettingChanged = NO;
            if ([[[alertView message] substringFromIndex:alertView.message.length - 2] isEqualToString:@"試聽"]) {
                [self Listen:nil];
            } else if ([[[alertView message] substringFromIndex:alertView.message.length - 2] isEqualToString:@"儲存"]) {
                [self SaveFile:nil];
            }
        }
    }
}

#pragma mark -
#pragma mark viewDidLoad
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    strRed = [NSString stringWithFormat:@"0"];
    strGreen = [NSString stringWithFormat:@"0"];
    strBlue = [NSString stringWithFormat:@"0"];
    TitleShowDuration = 5;
    PresentDuration = 5;
    
    TextFieldMovieTitle.delegate = self;
    TextFieldPictrueSec.delegate = self;
    TextFieldTitlesec.delegate = self;
    
    // Do any additional setup after loading the view.
    imageList2 = [[NSMutableArray alloc] init];
    videoList = [[NSMutableArray alloc] init];
    //    CGSize videoSize = {1024, 768};
    database = [[SQLiteDBTool alloc]init];
    Setting *aSetting = [[Setting alloc]init];
    GlobalData *globalItem = [GlobalData getInstance];
    aSetting = [database getSettingWithUserID:globalItem.UserID];
    CGSize videoSize;
    NSArray *ResolutiontArray = [aSetting.Resolution componentsSeparatedByString:@"*"];
    if ([ResolutiontArray count] > 1) {
        videoSize.width = [[ResolutiontArray objectAtIndex:0] intValue];
        videoSize.height = [[ResolutiontArray objectAtIndex:1] intValue];
    }
    else {
        videoSize.width = 400;
        videoSize.height = 300;
    }
    //    CGSize videoSize = {400, 300};
    avMixer = [[KOKSAVMixer alloc] initWithVideoSize:videoSize];
    //default title
    fontSize = DEFAULT_TITLE_FONT_SIZE   ; // fixed size !!
    
    [avMixer setTitle:TextFieldMovieTitle.text withSize:fontSize withShowDuration:[TextFieldTitlesec.text intValue]];
    currentTitleLayer = [avMixer getTitleLayerForVideoSize:previewView.bounds.size forOutput:false];
    
    // SliderTracktime
    [SliderTracktime setEnabled:NO];
    // SliderFontsize
    [SliderFontsize setThumbImage:[UIImage imageNamed:@"音軌控制.png"] forState:UIControlStateNormal];
}

- (void)viewDidUnload {
    [self setViewMixSetting:nil];
    [self setTextFieldMovieTitle:nil];
    [self setBtnSelectAudio:nil];
    [self setPreviewView:nil];
    [self setImageViewPicture:nil];
    [self setSliderTracktime:nil];
    [self setLBTracktime:nil];
    [self setBtnListen:nil];
    [self setBtnMix:nil];
    [self setBtnReset:nil];
    [self setBtnSave:nil];
    [self setTextFieldTitlesec:nil];
    [self setTextFieldPictrueSec:nil];
    [self setLBMusicFileName:nil];
    [self setLBVideoInfo:nil];
    [self setViewProcessing:nil];
    [self setActivityProcessing:nil];
    [self setSliderFontsize:nil];
    [super viewDidUnload];
}
@end
