//
//  KOKSMP4PlayerViewController.m
//  TrySinging
//
//  Created by 國立中興大學 資訊工程學系 國立中興大學 資訊工程學系 on 12/8/13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

//-----View-----
#import "KOKSMP4PlayerViewController.h"
#import "SaveAlertViewController.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"
//-----Object-----
#import "GlobalData.h"
#import "SQLiteDBTool.h"
#import "Setting.h"
#import "PlayList.h"
//------UI-----
#import "SVSegmentedThumb.h"
#import "SVSegmentedControl.h"
#import "HZActivityIndicatorView.h"
#import "UIImage+animatedGIF.h"
#import "UIViewController+MJPopupViewController.h"

NSString *const KOKSAudioObjectPlaybackStateDidChangeNotification = @"KOKSAudioObjectPlaybackStateDidChangeNotification";

NSString *const KOKSAudioMediaReadyNotification = @"tw.com.iscom.james.TrySinging:KOKSAudioMediaReadyNotification";

@interface KOKSMP4PlayerViewController () <MJSecondPopupDelegate>
{
    SQLiteDBTool *database;
    Setting *aSetting;
    
    SVSegmentedControl *ListSC;
    SVSegmentedThumb *ListThumb;
    AVURLAsset *asset;
    int musicPitch;
    int currentSongIndex;
    NSTimer *TimerBackToMyDownload,*TimerRetrySinging;
    NSTimer *TimerShowFullSceneTool;
    
    NSMutableArray *videoList;
    
    UIImageView *imgTitle;
    UIImageView *imgFullsceneBottom;
    
    CGRect OriginalMainSize;
    CGRect OriginalSubSize;
    CGRect FullMainSize;
    CGRect FullSubSize;
    CGRect RightArrow;
    CGRect LeftArrow;
    CGRect FullRightArrow;
    CGRect FullLeftArrow;
    
    BOOL isPause;
    BOOL isRecord;
    BOOL isELCImagePicker;
    BOOL isSavingView;
    BOOL isToolViewHide;
    BOOL isNoiseReduction;
    BOOL isSwitchView;
    BOOL isPickupView;
    BOOL isFullScene;
    BOOL isDefaultAVPlayer;
}
@property (weak, nonatomic) IBOutlet UIButton *buttonSwitchview;
@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet UIView *subplayView;
@property (weak, nonatomic) IBOutlet UISwitch *switchVocal;
@property (weak, nonatomic) IBOutlet UIButton *startPauseButton;
@property (weak, nonatomic) IBOutlet UILabel *noVideoLabel;
@property (weak, nonatomic) IBOutlet UISlider *songSlider;
@property (weak, nonatomic) IBOutlet UILabel *lbCurrentTime;
@property (weak, nonatomic) IBOutlet UILabel *lbLeftTime;
@property (weak, nonatomic) IBOutlet UIImageView *imageForShow;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segImageSource;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UISlider *vocalSlider;
@property (weak, nonatomic) IBOutlet UISlider *reverbSlider;
@property (weak, nonatomic) IBOutlet UISlider *echoSlider;
@property (weak, nonatomic) IBOutlet UILabel *lbVideoSource;
@property (weak, nonatomic) IBOutlet UISlider *micVolumeSlider;
@property (weak, nonatomic) IBOutlet UILabel *lbRecording;
@property (weak, nonatomic) IBOutlet UISwitch *switchRecording;
@property (weak, nonatomic) IBOutlet UIView *viewProcessing;
@property (weak, nonatomic) IBOutlet UISwitch *switchCameraPosition;
@property (weak, nonatomic) IBOutlet UIButton *lbVocal;
@property (weak, nonatomic) IBOutlet UIButton *buttonVlume;
@property (weak, nonatomic) IBOutlet UILabel *lbMicVolume;
@property (weak, nonatomic) IBOutlet UILabel *lbReverb;
@property (weak, nonatomic) IBOutlet UILabel *lbVideoSourceTittle;
@property (weak, nonatomic) IBOutlet UIButton *buttonVocal;
@property (weak, nonatomic) IBOutlet UIButton *buttonMicVolume;
@property (weak, nonatomic) IBOutlet UIButton *buttonReverb;
@property (weak, nonatomic) IBOutlet UILabel *lbMusicPitch;
@property (weak, nonatomic) IBOutlet UILabel *lbVoicePitch;
@property (weak, nonatomic) IBOutlet UIStepper *stMusicPitch;
@property (weak, nonatomic) IBOutlet UIStepper *stVoicePitch;
@property (weak, nonatomic) IBOutlet UILabel *lbPitchAdjust;
@property (weak, nonatomic) IBOutlet UILabel *lbMusic;
@property (weak, nonatomic) IBOutlet UILabel *lbVoice;
@property (weak, nonatomic) IBOutlet UILabel *LbSingerAndSongName;
@property (weak, nonatomic) IBOutlet UIView *ViewToolBox;
@property (weak, nonatomic) IBOutlet UIButton *buttonScene;
@property (weak, nonatomic) IBOutlet UIButton *buttonTracktimeBG;
@property (weak, nonatomic) IBOutlet UIButton *buttonRecording;
@property (weak, nonatomic) IBOutlet UIButton *buttonCameraPosition;
@property (weak, nonatomic) IBOutlet UIButton *ButtonAddPitch;
@property (weak, nonatomic) IBOutlet UIButton *ButtonDecPitch;
@property (weak, nonatomic) IBOutlet UIButton *ButtonEchoNone;
@property (weak, nonatomic) IBOutlet UIButton *ButtonEchoLow;
@property (weak, nonatomic) IBOutlet UIButton *ButtonEchoMid;
@property (weak, nonatomic) IBOutlet UIButton *ButtonEchoHigh;
@property (weak, nonatomic) IBOutlet UIButton *ButtonPackupView;
@property (weak, nonatomic) IBOutlet UIImageView *ivLoading;
@property (unsafe_unretained, nonatomic) IBOutlet HZActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIButton *ButtonNoiseReduction;
@property (weak, nonatomic) IBOutlet UIButton *ButtonFullScene;

@end

@implementation KOKSMP4PlayerViewController
@synthesize costPoint,SongID;
@synthesize playerView;
@synthesize switchVocal;
@synthesize startPauseButton;
@synthesize noVideoLabel;
@synthesize songSlider;
@synthesize lbCurrentTime;
@synthesize lbLeftTime;
@synthesize imageForShow;
@synthesize segImageSource;
@synthesize volumeSlider;
@synthesize vocalSlider;
@synthesize reverbSlider;
@synthesize echoSlider;
@synthesize buttonVlume;
@synthesize lbVideoSource;
@synthesize micVolumeSlider;
@synthesize loadingIndicator;
@synthesize lbRecording;
@synthesize switchRecording;
@synthesize defaultPlayer;
@synthesize userPlayer;
@synthesize audioProcessor;
@synthesize songUrl;
@synthesize usrMP4Url;
@synthesize switchCameraPosition;
@synthesize ButtonFullScene;
@synthesize lbMicVolume;
@synthesize lbReverb;
@synthesize lbVideoSourceTittle;
@synthesize lbVocal;
@synthesize graphSampleRate;
@synthesize buttonMicVolume;
@synthesize buttonReverb;
@synthesize buttonVocal;
@synthesize lbMusic;
@synthesize lbPitchAdjust;
@synthesize lbVoice;
@synthesize LbSingerAndSongName;
@synthesize ViewToolBox;
@synthesize buttonScene;
@synthesize buttonTracktimeBG,buttonRecording,buttonCameraPosition,ButtonAddPitch,ButtonDecPitch,ButtonEchoHigh,ButtonEchoLow,ButtonEchoMid,ButtonEchoNone,ButtonNoiseReduction,ButtonPackupView,buttonSwitchview;
@synthesize StreamRecord;


- (void)TouchFullSceneAndShowTool
{
    if (isFullScene)
    {
        if ([TimerShowFullSceneTool isValid]) {
            [TimerShowFullSceneTool invalidate];
        }
    
        [self showFullsceneTool];
        
        TimerShowFullSceneTool = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(hideFullsceneTool) userInfo:nil repeats:NO];
    }
}


- (void)showFullsceneTool
{
    [UIView animateWithDuration:0.5 animations:^(void) {
        [imgTitle setAlpha:0.7];
        [imgFullsceneBottom setAlpha:0.3];
        [LbSingerAndSongName setAlpha:1];
        [lbCurrentTime setAlpha:1];
        [startPauseButton setAlpha:1];
        [songSlider setAlpha:1];
        [ButtonFullScene setAlpha:1];
        [buttonSwitchview setAlpha:1];
        [ButtonPackupView setAlpha:1];
        //[self.ivLoading setAlpha:1];
    }];
}

- (void)hideFullsceneTool
{
    [UIView animateWithDuration:0.5 animations:^(void) {
        [imgTitle setAlpha:0];
        [imgFullsceneBottom setAlpha:0];
        [LbSingerAndSongName setAlpha:0];
        [lbCurrentTime setAlpha:0];
        [startPauseButton setAlpha:0];
        [songSlider setAlpha:0];
        [ButtonFullScene setAlpha:0];
        [buttonSwitchview setAlpha:0];
        [ButtonPackupView setAlpha:0];
        //[self.ivLoading setAlpha:0];
    }];
}

- (void)BringToolToFront
{
    [self.view bringSubviewToFront:imgTitle];
    [self.view bringSubviewToFront:imgFullsceneBottom];
    [self.view bringSubviewToFront:LbSingerAndSongName];
    [self.view bringSubviewToFront:lbCurrentTime];
    [self.view bringSubviewToFront:startPauseButton];
    [self.view bringSubviewToFront:songSlider];
    [self.view bringSubviewToFront:ButtonFullScene];
    [self.view bringSubviewToFront:buttonSwitchview];
    [self.view bringSubviewToFront:ButtonPackupView];
    [self.view bringSubviewToFront:self.ivLoading];
}

- (IBAction)testOrientation:(id)sender {
    
    if (isFullScene) //  縮小
    {
        isFullScene = NO;
        
        if ([TimerShowFullSceneTool isValid]) {
            [TimerShowFullSceneTool invalidate];
        }
        
        UIImageView *imageViewBG = (UIImageView*)[self.view viewWithTag:101];
        imageViewBG.alpha = 0;
        
        [UIView animateWithDuration:0.5 animations:^(void) {
            [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationLandscapeRight;
            [ListSC setAlpha:1];
            
            
            imgTitle.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
            imgTitle.frame = CGRectMake(0, 78, 320, 30);
            [imgTitle setAlpha:0];
            
            imgFullsceneBottom.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
            [imgFullsceneBottom setAlpha:0];
            
            self.LbSingerAndSongName.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
            self.LbSingerAndSongName.frame = CGRectMake(11, 83, 300, self.LbSingerAndSongName.frame.size.height);
            
            self.lbCurrentTime.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
            self.lbCurrentTime.frame = CGRectMake(1, 272, self.lbCurrentTime.frame.size.width, self.lbCurrentTime.frame.size.height);
            
            self.startPauseButton.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
            self.startPauseButton.frame = CGRectMake(263, 293, 48, 13);
            
            self.songSlider.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
            self.songSlider.frame = CGRectMake(5, 284, 180, self.songSlider.frame.size.height);
            
            [self.ButtonFullScene setImage:[UIImage imageNamed:@"全螢幕icon.png"] forState:UIControlStateNormal];
            self.ButtonFullScene.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
            self.ButtonFullScene.frame = CGRectMake(282, 45, self.ButtonFullScene.frame.size.width, self.ButtonFullScene.frame.size.height);
            
            self.buttonSwitchview.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
            self.buttonSwitchview.frame = CGRectMake(241, 45, self.buttonSwitchview.frame.size.width, self.buttonSwitchview.frame.size.height);
            
            self.ivLoading.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
            self.ivLoading.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 30 , (OriginalSubSize.origin.y + OriginalSubSize.size.height) + 10 , 25, 25);
            
            self.ButtonPackupView.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
            if (isPickupView)
            {
                self.ButtonPackupView.frame = RightArrow;
            }
            else
            {
                self.ButtonPackupView.frame = LeftArrow;
            }
            [self.view bringSubviewToFront:self.ButtonPackupView];
            
            if (curImageSrcIdx == IMAGE_SOURCE_TYPE_DEFAULT)
            {
                if (songType == SONG_TYPE_MP4) {
                    self.playerView.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
                    self.playerView.layer.frame = OriginalMainSize;
                    playerLayer.frame = playerView.layer.bounds;
                } else {
                    self.imageForShow.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
                    self.imageForShow.layer.frame = OriginalMainSize;
                }
            }
            else if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS)
            {
                if (isSwitchView)
                {
                    self.playerView.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
                    self.playerView.layer.frame = OriginalMainSize;
                    playerLayer.frame = playerView.layer.bounds;
                    self.imageForShow.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
                    self.imageForShow.layer.frame = OriginalSubSize;
                }
                else
                {
                    self.imageForShow.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
                    self.imageForShow.layer.frame = OriginalMainSize;
                    self.playerView.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
                    self.playerView.layer.frame = OriginalSubSize;
                    playerLayer.frame = playerView.layer.bounds;
                }
            }
            else if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS)
            {
                self.playerView.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
                self.playerView.layer.frame = OriginalMainSize;
                userVideoLayer.frame = playerView.layer.bounds;
            }
            else if (curImageSrcIdx == IMAGE_SOURCE_TYPE_CAMERA)
            {
                if (isSwitchView)
                {
                    self.subplayView.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
                    self.subplayView.layer.frame = OriginalMainSize;
                    //subLayer.frame = self.subplayView.layer.bounds;
                    self.playerView.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
                    self.playerView.layer.frame = OriginalSubSize;
                    playerLayer.frame = playerView.layer.bounds;
                }
                else
                {
                    self.playerView.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
                    self.playerView.layer.frame = OriginalMainSize;
                    playerLayer.frame = playerView.layer.bounds;
                    self.subplayView.transform = CGAffineTransformRotate(self.view.transform, + (M_PI * 2));
                    self.subplayView.layer.frame = OriginalSubSize;
                    //subLayer.frame = self.subplayView.layer.bounds;
                }
                cameraPreviewLayer.frame = playerView.layer.bounds;
                if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_CAMERA) {
                    playerLayer.frame = self.subplayView.layer.bounds;
                } else {
                    playerLayer.frame = playerView.layer.bounds;
                }
            }
        }];
    } else // 放大
    {
        isFullScene = YES;
        [ListSC setAlpha:0];
        
        UIImageView *imageViewBG = (UIImageView*)[self.view viewWithTag:101];
        imageViewBG.alpha = 1;
        
        [UIView animateWithDuration:0.5 animations:^(void) {
            [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationLandscapeLeft;
            
            if (curImageSrcIdx == IMAGE_SOURCE_TYPE_DEFAULT)
            {
                if (songType == SONG_TYPE_MP4) {
                    self.playerView.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
                    self.playerView.layer.frame = FullMainSize;
                    playerLayer.frame = playerView.layer.bounds;
                    [self.view bringSubviewToFront:playerView];
                } else {
                    self.imageForShow.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
                    self.imageForShow.layer.frame = FullMainSize;
                    [self.view bringSubviewToFront:imageForShow];
                }
            }
            else if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS)
            {
                if (isSwitchView)
                {
                    self.playerView.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
                    self.playerView.layer.frame = FullMainSize;
                    playerLayer.frame = playerView.layer.bounds;
                    [self.view bringSubviewToFront:playerView];
                    
                    self.imageForShow.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
                    self.imageForShow.layer.frame = FullSubSize;
                    [self.view bringSubviewToFront:imageForShow];
                }
                else
                {
                    self.imageForShow.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
                    self.imageForShow.layer.frame = FullMainSize;
                    [self.view bringSubviewToFront:imageForShow];
                    
                    self.playerView.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
                    self.playerView.layer.frame = FullSubSize;
                    playerLayer.frame = playerView.layer.bounds;
                    [self.view bringSubviewToFront:playerView];
                }
            }
            else if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS)
            {
                self.playerView.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
                self.playerView.layer.frame = FullMainSize;
                userVideoLayer.frame = playerView.layer.bounds;
                [self.view bringSubviewToFront:playerView];
            }
            else if (curImageSrcIdx == IMAGE_SOURCE_TYPE_CAMERA)
            {
                if (isSwitchView)
                {
                    self.subplayView.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
                    self.subplayView.layer.frame = FullMainSize;
                    //subLayer.frame = self.subplayView.layer.bounds;
                    [self.view bringSubviewToFront:self.subplayView];
                    
                    self.playerView.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
                    self.playerView.layer.frame = FullSubSize;
                    playerLayer.frame = playerView.layer.bounds;
                    [self.view bringSubviewToFront:playerView];
                }
                else
                {
                    self.playerView.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
                    self.playerView.layer.frame = FullMainSize;
                    playerLayer.frame = playerView.layer.bounds;
                    [self.view bringSubviewToFront:playerView];
                    
                    self.subplayView.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
                    self.subplayView.layer.frame = FullSubSize;
                    //subLayer.frame = self.subplayView.layer.bounds;
                    [self.view bringSubviewToFront:self.subplayView];
                }
                cameraPreviewLayer.frame = playerView.layer.bounds;
                if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_CAMERA) {
                    playerLayer.frame = self.subplayView.layer.bounds;
                } else {
                    playerLayer.frame = playerView.layer.bounds;
                }
            }
            
        } completion:^(BOOL finished) {
            
            imgTitle.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
            imgTitle.frame = CGRectMake(0, 0, 40, self.view.frame.size.height);
            [self.view bringSubviewToFront:imgTitle];
            
            imgFullsceneBottom.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
            imgFullsceneBottom.frame = CGRectMake(290, 0, 30, self.view.frame.size.height);
            [self.view bringSubviewToFront:imgFullsceneBottom];
            
            self.LbSingerAndSongName.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
            self.LbSingerAndSongName.frame = CGRectMake(9, 75, self.LbSingerAndSongName.frame.size.width, self.LbSingerAndSongName.frame.size.height + 35 + ((self.view.frame.size.height - 480) / 2));
            [self.view bringSubviewToFront:self.LbSingerAndSongName];
            
            self.lbCurrentTime.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
            self.lbCurrentTime.frame = CGRectMake(296, 5, self.lbCurrentTime.frame.size.width, self.lbCurrentTime.frame.size.height);
            [self.view bringSubviewToFront:self.lbCurrentTime];
            
            self.songSlider.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
            self.songSlider.frame = CGRectMake(290, 100, self.songSlider.frame.size.width, self.songSlider.frame.size.height + 180);
            [self.view bringSubviewToFront:self.songSlider];
            
            [self.ButtonFullScene setImage:[UIImage imageNamed:@"縮小螢幕icon.png"] forState:UIControlStateNormal];
            self.ButtonFullScene.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
            self.ButtonFullScene.frame = CGRectMake(5, 5, self.ButtonFullScene.frame.size.width, self.ButtonFullScene.frame.size.height);
            [self.view bringSubviewToFront:self.ButtonFullScene];
            
            self.buttonSwitchview.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
            self.buttonSwitchview.frame = CGRectMake(5, 38, self.buttonSwitchview.frame.size.width, self.buttonSwitchview.frame.size.height);
            [self.view bringSubviewToFront:self.buttonSwitchview];
            
            self.startPauseButton.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
            self.startPauseButton.frame = CGRectMake(296, 50, self.startPauseButton.frame.size.width + 10 , self.startPauseButton.frame.size.height + 5);
            [self.view bringSubviewToFront:self.startPauseButton];
            
            self.ButtonPackupView.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
            if (isPickupView) {
                self.ButtonPackupView.frame = FullRightArrow;
            } else {
                self.ButtonPackupView.frame = FullLeftArrow;
            }
             [self.view bringSubviewToFront:self.ButtonPackupView];
            
            self.ivLoading.transform = CGAffineTransformRotate(self.view.transform, - (M_PI / 2.0));
            self.ivLoading.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - 50, 5, 25, 25);
            [self.view bringSubviewToFront:self.ivLoading];
            
            [self TouchFullSceneAndShowTool];
        }];
        
        [self hideFullsceneTool];
    }
    
}


// GivingUpSavingDelegate
-(void)DoneSaving {
    isSavingView = NO;
    currentSongIndex ++;
    if ([self.aryPlaylist count] > currentSongIndex) {
        PlayList *aSong = [self.aryPlaylist objectAtIndex:currentSongIndex];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL success = [fileManager fileExistsAtPath:aSong.SongPath];
        if(success)
            songUrl = [NSURL fileURLWithPath:aSong.SongPath];
        else
            songUrl = [NSURL URLWithString:aSong.SongPath];
        _SongName = aSong.SongName;
        _Singer = aSong.Singer;
        LbSingerAndSongName.text = [NSString stringWithFormat:@"%@ - %@",_Singer,_SongName];
        [self reloadMedia];
    } else if ([self.aryPlaylist count] > 0) {
        /*
         currentSongIndex = 0;
         PlayList *aSong = [self.aryPlaylist objectAtIndex:currentSongIndex];
         songUrl = [NSURL URLWithString:aSong.SongPath];
         _SongName = aSong.SongName;
         _Singer = aSong.Singer;
         LbSingerAndSongName.text = [NSString stringWithFormat:@"%@ - %@",_Singer,_SongName];
         [self reloadMedia];
         */
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        isPause = YES;
        //[startPauseButton setTitle:@"Play" forState:UIControlStateNormal];
        [startPauseButton setImage:[UIImage imageNamed:@"開始.png"] forState:UIControlStateNormal];
    }
}

-(void)retrySinging {
    TimerRetrySinging =[NSTimer scheduledTimerWithTimeInterval:0.5
                                                        target:self
                                                      selector:@selector (PopMickeyWindow)
                                                      userInfo:nil
                                                       repeats:NO];
    isSavingView = NO;
}

-(void)BackToMyDownload
{
    // 跳離立即唱
    if (![[self presentedViewController] isBeingDismissed])
        [self dismissViewControllerAnimated:YES completion:nil];
    else
        TimerBackToMyDownload =[NSTimer scheduledTimerWithTimeInterval:0.5
                                                                target:self
                                                              selector:@selector (BackToMyDownload)
                                                              userInfo:nil
                                                               repeats:NO];
}

-(void)PopMickeyWindow {
    
    Float64 current = 1;
    //Float64 current = (Float64)0 * musicDuration;
    lbCurrentTime.text = @"00:00";
    songSlider.value = 0;
    [audioProcessor seekToTime:current];
    [self syncPlayerWithMusicPosition];
}

- (IBAction)NoiseReduction:(id)sender
{
    if (isNoiseReduction) {
        isNoiseReduction = NO;
        [ButtonNoiseReduction setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [ButtonNoiseReduction setImage:[UIImage imageNamed:@"消除雜訊-2.png"] forState:UIControlStateNormal];
        [audioProcessor setLowPassFrequency:900000.0 cutOffDB:0.0];
    } else {
        isNoiseReduction = YES;
        [ButtonNoiseReduction setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [ButtonNoiseReduction setImage:[UIImage imageNamed:@"消除雜訊.png"] forState:UIControlStateNormal];
        [audioProcessor setLowPassFrequency:15000.0 cutOffDB:-20.0];
    }
}

// for pitch-shifting ------------
//- (IBAction)doAdjustMusicPitch:(id)sender {
//    // refresh current music pitch on the screen
//    int musicPitch = (int)(_stMusicPitch.value);
//    _lbMusicPitch.text = [NSString stringWithFormat:@"%d", (musicPitch) ];
//    //
//    [audioProcessor setMusicWithPitch:musicPitch withRate:1.0];
//}
- (IBAction)AddMusicPitch:(id)sender {
    if (musicPitch >= 7)
        musicPitch = 7;
    else
        musicPitch++;
    
    if (musicPitch < 0)
        _lbMusicPitch.text = [NSString stringWithFormat:@"降 %d", (musicPitch) ];
    else if (musicPitch == 0)
        _lbMusicPitch.text = [NSString stringWithFormat:@"原KEY"];
    else
        _lbMusicPitch.text = [NSString stringWithFormat:@"升 +%d", (musicPitch) ];
    
    //
    [audioProcessor setMusicWithPitch:musicPitch withRate:1.0];
    [self checkPitch];
}
- (IBAction)decMusicPitch:(id)sender {
    if (musicPitch <= -5)
        musicPitch = -5;
    else
        musicPitch--;
    
    if (musicPitch < 0)
        _lbMusicPitch.text = [NSString stringWithFormat:@"降 %d", (musicPitch) ];
    else if (musicPitch == 0)
        _lbMusicPitch.text = [NSString stringWithFormat:@"原KEY"];
    else
        _lbMusicPitch.text = [NSString stringWithFormat:@"升 +%d", (musicPitch) ];
    //
    [audioProcessor setMusicWithPitch:musicPitch withRate:1.0];
    [self checkPitch];
}

-(void)checkPitch
{
    if (musicPitch <= -5)
        [ButtonDecPitch setEnabled:NO];
    else
        [ButtonDecPitch setEnabled:YES];
    
    if (musicPitch >=7)
        [ButtonAddPitch setEnabled:NO];
    else
        [ButtonAddPitch setEnabled:YES];
}

- (IBAction)doAdjustVoicePitch:(id)sender {
    // refresh current voice pitch on the screen
    int voicePitch = (int)(_stVoicePitch.value);
    _lbVoicePitch.text = [NSString stringWithFormat:@"%d", (voicePitch) ];
    //
    [audioProcessor setVoiceWithPitch:voicePitch withRate:1.0];
}
//--------------------------------------

- (IBAction)HideToolView:(id)sender {
    UIButton *btn = sender;
    if (isToolViewHide) {
        isToolViewHide = NO;
        [UIView animateWithDuration:.5 animations:^{
            btn.transform = CGAffineTransformMakeRotation(0);
            ViewToolBox.frame = CGRectMake(self.ViewToolBox.frame.origin.x, 175, self.ViewToolBox.frame.size.width, self.ViewToolBox.frame.size.height);
        }];
    } else {
        isToolViewHide = YES;
        [UIView animateWithDuration:.5 animations:^{
            btn.transform = CGAffineTransformMakeRotation(3.14);
            ViewToolBox.frame = CGRectMake(self.ViewToolBox.frame.origin.x, 262, self.ViewToolBox.frame.size.width, self.ViewToolBox.frame.size.height);
        }];
    }
}

// --- Start/Stop Recording
#pragma mark -
#pragma mark Start/Stop Recording
- (IBAction)toggleRecording:(id)sender {
    if (!isRecord) {  // case 1: Start Recording, now!
        // 1a. Disable all the components, excepting the SwitchRecording !!
        if (audioProcessor.isPlaying == false)
            [self togglePlayPause:nil];
        //
        [startPauseButton setEnabled:false];
        [startPauseButton setAlpha:0.3];
        [segImageSource setEnabled:false];
        [ListSC setEnabled:false];
        [buttonCameraPosition setHidden:YES];
        [songSlider setEnabled:NO];
        
        if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
            if (imageList2.count == 0)
                curImageSrcIdx = IMAGE_SOURCE_TYPE_DEFAULT;
        }
        else if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS) {
            if (videoList.count == 0)
                curImageSrcIdx = IMAGE_SOURCE_TYPE_DEFAULT;
        }
        
        // update message !
        
        // Update title !!
        isRecord = YES;
        [buttonRecording setImage:[UIImage imageNamed:@"錄製中.png"] forState:UIControlStateNormal];
        // 1b. Initialization
        NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        vocalFile = [docsDir stringByAppendingPathComponent:@"userVocal.caf"];
        //
        //NSString *tmpDir = NSTemporaryDirectory();
        //vocalFile = [NSString stringWithFormat:@"%@userVocal.caf", tmpDir];
        // NSLog([NSString stringWithFormat: @"Prepare to save user vocal to file: %@", vocalFile]);
        
        // 1c. save the user-vocal constantly.
        //     --> AVAssetWriter + AVAssetWriterInput(resource: Audio samples)
        /*
         AudioChannelLayout acl;
         bzero(&acl, sizeof(acl));
         acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;   //kAudioChannelLayoutTag_Mono;
         
         NSDictionary *audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithInt: kAudioFormatMPEG4AAC],AVFormatIDKey,
         [NSNumber numberWithFloat:44100.0],AVSampleRateKey,            //was 44100.0
         [NSData dataWithBytes: &acl length: sizeof( AudioChannelLayout ) ], AVChannelLayoutKey,
         [NSNumber numberWithInt:2],AVNumberOfChannelsKey,
         [NSNumber numberWithInt:64000],AVEncoderBitRateKey,
         nil];
         
         usrVocalWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings: audioOutputSettings];
         [usrVocalWriterInput setExpectsMediaDataInRealTime:YES];
         //
         NSError *err;
         usrVocalWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:vocalFile] fileType:AVFileTypeCoreAudioFormat error:&err];
         if (err != nil) {
         NSLog([NSString stringWithFormat: @"Fail to create AssetWriter with URL: %@", vocalFile]);
         }
         //
         [usrVocalWriter addInput:usrVocalWriterInput];
         [usrVocalWriter startWriting];
         [usrVocalWriter startSessionAtSourceTime:kCMTimeZero];
         [audioProcessor setVocalWriterInput:usrVocalWriterInput]; // turn on recording !!
         */
        
        // 1d. save the music channel connstantly.
        //     --> save the beginning time-stamp + ending time-stamp !!
        //     Skip --> combined with the Vocal now.
        
        // 1e. merge the images, camera capturing or video-clip to be a video file
        //     (1) Images --> AVAssetWriter + AVAssetWriterInput (resource: JPG files)
        
        //     (2) Camera capturing --> AVCaptureVideoDataOutput/AVCaptureMovieFileOutput
        if (curImageSrcIdx == IMAGE_SOURCE_TYPE_CAMERA) {
            //if (captureMovieURL == nil) {
                NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
                videoFile = [documentsDirectoryPath stringByAppendingPathComponent:@"CarolKOK_tempCapture.mov" ];
                // remove the old one !
                [[NSFileManager defaultManager] removeItemAtPath:videoFile error:nil];
                captureMovieURL = [NSURL fileURLWithPath:videoFile];                  // create capture file output
            //}
            movieFileOutput = nil;
            movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
            
            
            NSLog (@"[Camera] recording Camera to %@", captureMovieURL);
            [captureSession addOutput:movieFileOutput];
            
            
            [NSThread sleepForTimeInterval:0.1];
            [self switchToCorrectOrientation:[movieFileOutput connections]];
            
            // write to file
            [movieFileOutput startRecordingToOutputFileURL:captureMovieURL recordingDelegate:self];
        }
        //     (3) Video clip --> save the beginning time-stamp + ending time-stamp !! (default/user-selected mp4)
        [audioProcessor startRecording:vocalFile];
        beginRecordingTime = [audioProcessor currentTime];
        
        // 1x. Notification: if any interrupt/event happens
        //     (i.e. any incoming call, pressing the home button, the play/pause button, the back button, reaching the end of song, ...)
        
        
    }
    else {  // case 2: Stop Recording (from Recording) ==> Save the result !
        // 2.  Stop singing & enable all components!!
        [self togglePlayPause:nil];
        [startPauseButton setEnabled:true];
        [startPauseButton setAlpha:1.0];
        [segImageSource setEnabled:true];
        [ListSC setEnabled:true];
        [songSlider setEnabled:YES];
        
        isRecord = NO;
        [buttonRecording setImage:[UIImage imageNamed:@"未錄製.png"] forState:UIControlStateNormal];
        
        // 2a. Stop all the recording actions
        // (2a.1) Stop Vocal Recording
        /*
         [audioProcessor setVocalWriterInput:nil];  // turn off recording
         [usrVocalWriterInput markAsFinished];
         // [usrVocalWriter endSessionAtSourceTime:…];
         [usrVocalWriter finishWriting];
         usrVocalWriterInput = nil;
         usrVocalWriter = nil;
         */
        [audioProcessor stopRecording];
        endRecordingTime = [audioProcessor currentTime];
        
        // (2a.2) Stop Images/Camera-Capturing/Video-clip
        
        // 2b. product the AVComposition for save & preview !
        NSError *error;
        outputAVComposition = nil;
        outputAVComposition = [[AVMutableComposition alloc]init];
        //
        CMTime beginTime = CMTimeMakeWithSeconds( beginRecordingTime, 600);
		CMTime endTime = CMTimeMakeWithSeconds( endRecordingTime, 600);
		CMTime duration = CMTimeSubtract(endTime, beginTime);
        //double vocalSeconds = CMTimeGetSeconds(duration);
        CMTimeRange editRange = CMTimeRangeMake( beginTime, duration);
        
        // 2b-1. add  Vocal+Music tracks to the Composition AVAsset.
        audioAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:vocalFile]];
        AVAssetTrack* audioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        AVMutableCompositionTrack *compositionAudioTrack = [outputAVComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration)
                                       ofTrack:audioTrack
                                        atTime:kCMTimeZero
                                         error:&error];
        if (error != nil)
            NSLog(@"Error to insert Audio to final composition: %@", error);
        
        
        // 2b-2. collect the video/images data !
        // *** Utilize the AVMutableComposition to merge the video/music/vocal to be a single mp4 file (or MOV ?).
        // In case using the original MP4
        // -->  Cannot using the composition AVAsset while playing, so we need another AVAsset for extracting video !
        if (curImageSrcIdx == IMAGE_SOURCE_TYPE_DEFAULT && (songType == SONG_TYPE_MP4)) {
            AVAsset *videoAsset;
            videoAsset = [AVAsset assetWithURL:songUrl];
            AVMutableCompositionTrack *compositionVideoTrack = [outputAVComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionVideoTrack insertTimeRange:editRange
                                           ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                            atTime:kCMTimeZero
                                             error:&error];
            if (error != nil)
                NSLog(@"Error to insert DEFAULT-Video to final composition: %@", error);
        }
        else if ( (curImageSrcIdx == IMAGE_SOURCE_TYPE_DEFAULT && (songType == SONG_TYPE_MP3)) ||
                 (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) ) { // Merge the DEFAULT/USER-Images to be a movie file
            NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
            NSString *exportPath = [documentsDirectoryPath stringByAppendingPathComponent:@"CarolKOK_tempJPG.mov" ];
            NSLog(@"[JPG to MOV] prepare to merge the DEFAULT/USER-JPGs to be a Movie file: %@", exportPath);
            [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
            
            // It's asyn. mode !
            _viewProcessing.hidden = false;
            [loadingIndicator startAnimating];
            
            //
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^(void) {
                // write JPG files to a movie file
                NSArray *imageList;
                if (curImageSrcIdx == IMAGE_SOURCE_TYPE_DEFAULT)
                    imageList = imageList1;
                else
                    imageList = imageList2;
                
                [self writeImagesAsMovie:imageList toPath:exportPath withSeconds:(endRecordingTime-beginRecordingTime)];
                
                
                dispatch_sync(dispatch_get_main_queue(),
                              ^{
                                  _viewProcessing.hidden = true;
                                  [loadingIndicator stopAnimating];
                                  [self.ivLoading setHidden:YES];
                                  
                                  NSError *error;
                                  // setup the AVMutableComposition
                                  NSURL *jpgMovieURL = [NSURL fileURLWithPath:exportPath];
                                  AVAsset *videoAsset = [AVAsset assetWithURL:jpgMovieURL];
                                  AVMutableCompositionTrack *compositionVideoTrack = [outputAVComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                                                      preferredTrackID:kCMPersistentTrackID_Invalid];
                                  
                                  [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration)
                                                                 ofTrack: [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                                                  atTime:kCMTimeZero
                                                                   error:&error];
                                  if (error != nil)
                                      NSLog(@"Error to insert DEFAULT/USER-JPGs to final composition: %@", error);
                                  else
                                      [self showSaveVocalDialog];
                              });
            });
            // we will show the SaveVocalDialog later !
            return;
        }
        else if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS) {
            //            AVAsset *videoAsset;
            //            videoAsset = [AVAsset assetWithURL:usrMP4Url];
            //            CMTime userMP4Duration = [userPlayerItem duration];
            //            double userMP4Seconds = CMTimeGetSeconds(userMP4Duration);
            //            double beginMP4Seconds = beginRecordingTime;
            //            while (beginMP4Seconds > userMP4Seconds)
            //                beginMP4Seconds -= userMP4Seconds;
            //            //
            //            NSLog(@"Saving from %lf, duration: %lf; userMP4_duration: %lf", beginRecordingTime, (endRecordingTime-beginRecordingTime), userMP4Seconds);
            //            AVMutableCompositionTrack *compositionVideoTrack = [outputAVComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            //            //
            //            double curPosSeconds = 0.0f;
            //            int segCount=0;
            //            while ( vocalSeconds > curPosSeconds) {
            //                double endMP4Seconds = curPosSeconds+(userMP4Seconds - beginMP4Seconds) > vocalSeconds ? beginMP4Seconds + (vocalSeconds-curPosSeconds) : userMP4Seconds;
            //                //
            //                editRange = CMTimeRangeMake( CMTimeMakeWithSeconds(beginMP4Seconds,600),
            //                                            CMTimeMakeWithSeconds(endMP4Seconds-beginMP4Seconds,600));
            //                CMTime curPos = CMTimeMakeWithSeconds(curPosSeconds, 600);
            //                [compositionVideoTrack insertTimeRange:editRange
            //                                               ofTrack: [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
            //                                                atTime: curPos
            //                                                 error:&error];
            //                if (error != nil) {
            //                    NSLog(@"Error to insert USER-Video to final composition: %@", error);
            //                    break;
            //                }
            //                else {
            //                    NSLog(@"Merging user-MP4[seg:%d] from %lf to %lf", ++segCount, beginMP4Seconds, endMP4Seconds);
            //                    curPosSeconds += (endMP4Seconds - beginMP4Seconds);
            //                    beginMP4Seconds = 0;
            //                }
            //            }
            
            
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
            avMixer = [[KOKSAVMixer alloc] initWithVideoSize:videoSize];
            [avMixer setTitle:@"" withSize:24 withShowDuration:0];
            NSArray *audioFileList = [NSArray arrayWithObject:[NSURL fileURLWithPath:vocalFile]];
            [avMixer prepareAVCompositionforPlayback:NO forVideoSize:videoSize withAudio:audioFileList withPhotos:nil showTime:0 withVideos:videoList];
            //
            UIStoryboard *storyboard = self.storyboard;
            SaveAlertViewController *saveVocal  = [storyboard instantiateViewControllerWithIdentifier:@"savinAlert"];
            saveVocal.avMixer = avMixer;
            saveVocal.SongName = _SongName;
            [saveVocal setOutputAVComposition:[avMixer outputComposition]];
            saveVocal.outputVocalFileName = @"";
            [saveVocal setDelegate:self];
            [saveVocal setSongType:@"SongBook"];
            [saveVocal setOutputMode:false];
            [saveVocal setTracktime:[self secondToString:(endRecordingTime-beginRecordingTime)]];
            [saveVocal setValue:self forKey:@"GivingUpSavingDelegate"];
            isSavingView = YES;
            [self presentPopupViewController:saveVocal animationType:MJPopupViewAnimationFade];
            return;
            
        }
        else {  // curImageSrcIdx == IMAGE_SOURCE_TYPE_CAMERA
            NSLog (@"[Camera] stop recording: %@", captureMovieURL);
            [movieFileOutput stopRecording];
            [buttonCameraPosition setHidden:NO];
            //---------------------------------------
            // Here, we must wait for the capture-saving !
            //---------------------------------------
            _viewProcessing.hidden = false;
            [loadingIndicator startAnimating];
            
            return;
            
            /*
             
             //--------------------------------------------------------------------------
             // postponed actions !
             //--------------------------------------------------------------------------
             AVAsset *videoAsset;
             videoAsset = [AVAsset assetWithURL:captureMovieURL];
             AVMutableCompositionTrack *compositionVideoTrack = [outputAVComposition addMutableTrackWithMediaType:AVMediaTypeVideo
             preferredTrackID:kCMPersistentTrackID_Invalid];
             
             [compositionVideoTrack insertTimeRange:CMTimeRangeMake( kCMTimeZero, videoAsset.duration)
             ofTrack: [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
             atTime:kCMTimeZero
             error:&error];
             if (error != nil)
             NSLog(@"Error to insert Camera-Video to final composition: %@", error);
             //--------------------------------------------------------------------------
             
             */
            
        }
        
        // 2c. Ask user input the filename or cancel saving-operation.
        [self showSaveVocalDialog];
        
        // 2d. Append the recording record into the SQLite DB/Table. [TODO --- SQLite]
        
    }
}

- (AVCaptureVideoOrientation) getCurrentVideoOrientation{
    
    AVCaptureVideoOrientation oldCaptureVideoOrientation;
    oldCaptureVideoOrientation = captureVideoOrientation;
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) {
        captureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
    else if([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight) {
        captureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }
    else if([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
        captureVideoOrientation = AVCaptureVideoOrientationPortrait;
    }
    else if([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortraitUpsideDown) {
        captureVideoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }
    
//    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) {
//        //NSLog(@"Current video location : [AVCaptureVideoOrientationLandscapeRight]");
//        return AVCaptureVideoOrientationLandscapeLeft;
//    }
//    else if([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight) {
//        //NSLog(@"Current video location: [AVCaptureVideoOrientationLandscapeLeft]");
//        return AVCaptureVideoOrientationLandscapeRight;
//    }
//    else
        return oldCaptureVideoOrientation;
}

- (void) switchToCorrectOrientation:(NSArray *)connections {
    // AVCapture and UIDevice have opposite meanings for landscape left and right
    //  (AVCapture orientation is the same as UIInterfaceOrientation)
    if (curImageSrcIdx == IMAGE_SOURCE_TYPE_CAMERA && connections != nil) {
        // setup the Orientation
        for ( AVCaptureConnection *connection in connections ) {
            for ( AVCaptureInputPort *port in [connection inputPorts] ) {
                if ( [[port mediaType] isEqual:AVMediaTypeVideo] ) {
                    AVCaptureConnection *videoConnection = connection;
                    //
                    if ([videoConnection isVideoOrientationSupported]) {
                        [videoConnection setVideoOrientation: captureVideoOrientation];
                        if (cameraPosition == AVCaptureDevicePositionFront) {
                            videoConnection.videoMirrored = true;
                        }
                    }
                }
            }
        }
    }
}

- (void) switchCamera {
    AVCaptureDevicePosition newPosition = (cameraPosition==AVCaptureDevicePositionFront) ?
    AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    //
    NSError *error;
    AVCaptureDevice *newDevice = [self getCameraPreferredDevice:newPosition];
    AVCaptureDeviceInput *newInput = [[AVCaptureDeviceInput alloc] initWithDevice:newDevice error:&error ];
    //
    if ( newDevice != nil && newInput != nil && !error) {
        [captureSession beginConfiguration];
        [captureSession removeInput:videoDeviceInput];
        if ([captureSession canAddInput:newInput]) {
            [captureSession addInput:newInput];
            videoDeviceInput = newInput;
            cameraPosition = newPosition;
            if (cameraPosition == AVCaptureDevicePositionFront)
                lbVideoSource.text = @"前攝影鏡頭";
            else
                lbVideoSource.text = @"後攝影鏡頭";
            //
        } else {
            [captureSession addInput:videoDeviceInput];
        }
        //
        // 前攝影鏡頭！！
        if ([captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            //captureSession.sessionPreset = AVCaptureSessionPresetHigh;
            captureSession.sessionPreset = AVCaptureSessionPresetMedium;
        }
        else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
            captureSession.sessionPreset = AVCaptureSessionPresetMedium;
        }
        else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetLow]) {
            captureSession.sessionPreset = AVCaptureSessionPresetLow;
        }
        else {
            captureSession.sessionPreset = AVCaptureSessionPreset352x288;
        }
        //
        [captureSession commitConfiguration];
    }
    else {
        NSLog(@"Fail to switch Camera(Front/Back), error:%@.", error);
    }
}

- (void) showSaveVocalDialog {
    //UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"carolView" bundle:[NSBundle mainBundle]];
    UIStoryboard *storyboard = self.storyboard;
    //    KOKSSaveVocalViewController *saveVocal  = [storyboard instantiateViewControllerWithIdentifier:@"saveVocalDialog"];
    SaveAlertViewController *saveVocal  = [storyboard instantiateViewControllerWithIdentifier:@"savinAlert"];
    // saveVocal.outputAVComposition = outputAVComposition;
    [saveVocal setOutputAVComposition:outputAVComposition];
    saveVocal.outputVocalFileName = @"";
    saveVocal.SongName = _SongName;
    [saveVocal setSongType:@"SongBook"];
    [saveVocal setOutputMode:false];
    [saveVocal setTracktime:[self secondToString:(endRecordingTime-beginRecordingTime)]];
    [saveVocal setDelegate:self];
    [saveVocal setValue:self forKey:@"GivingUpSavingDelegate"];
    isSavingView = YES;
    [self presentPopupViewController:saveVocal animationType:MJPopupViewAnimationFade];
}

NSInteger sort(id a, id b, void *reverse) {
    return [a compare:b options:NSNumericSearch];
}

- (void) writeImagesAsMovie:(NSArray *)imageList toPath:(NSString*)path  withSeconds:(Float64)duration {
    
    avMixer = [[KOKSAVMixer alloc] init];
    NSError *error = [avMixer writeImagesAsMovie:imageList toPath:path waitingSeconds:5 withDuration:duration];
    if (error)
        NSLog(@"[JPG to MOV] Fail to produce the Movie with the Photos!!");
    else
        NSLog(@"[JPG to MOV] Movie created successfully");
    avMixer = nil;
}

#pragma mark -
#pragma mark AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
	NSLog (@"[CAMERA] started recording Camera to %@", fileURL);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
	//
    _viewProcessing.hidden = true;
    [loadingIndicator stopAnimating];
    [self.ivLoading setHidden:YES];
    
    
    if (error) {
		NSLog (@"[CAMERA] failed to record Camera: %@", error);
        if (!isPause)
            [self togglePlayPause:nil];
        [startPauseButton setEnabled:true];
        [startPauseButton setAlpha:1.0];
        [segImageSource setEnabled:true];
        [audioProcessor stopRecording];
        [movieFileOutput stopRecording];
        [switchRecording setOn:false];
        //
        NSString *msg;
        if (error.code == -11818)
            msg = [NSString stringWithFormat:@"不正常跳出，錄製影片終止"];
        else
            msg = [NSString stringWithFormat:@"錄製影片失敗: %@", error];
        
        [self showAlertMessage:msg withTitle:@"錯誤" buttonText:@"ＯＫ"];
        // 如果不是因為突然跳離APP，繼續儲存動作
        if (error.code != -11818)
            return;
	}
    
    _viewProcessing.hidden = true;
    [loadingIndicator stopAnimating];
    [self.ivLoading setHidden:YES];
    
    // added on 2013/4/28
    [captureSession removeOutput:movieFileOutput];
    
    NSLog (@"[CAMERA] finished recording Camera to %@", outputFileURL);
    // ---------
    AVAsset *videoAsset;
    NSLog(@"captureMovieURL=%@",captureMovieURL);
    videoAsset = [AVAsset assetWithURL:captureMovieURL];
    NSLog(@"captureMovieURL=%@",captureMovieURL);
    AVMutableCompositionTrack *compositionVideoTrack = [outputAVComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake( kCMTimeZero, videoAsset.duration)
                                   ofTrack: [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                    atTime:kCMTimeZero
                                     error:&error];
    if (error != nil)
        NSLog(@"Error to insert Camera-Video to final composition: %@", error);
    
    
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
    avMixer = [[KOKSAVMixer alloc] initWithVideoSize:videoSize];
    [avMixer setTitle:@"" withSize:24 withShowDuration:0];
    NSArray *audioFileList = [NSArray arrayWithObject:[NSURL fileURLWithPath:vocalFile]];
    NSArray *videoUrlList = [NSArray arrayWithObject:outputFileURL];
    [avMixer prepareAVCompositionforPlayback:NO forVideoSize:videoSize withAudio:audioFileList withPhotos:nil showTime:0 withVideos:videoUrlList];
    //
    UIStoryboard *storyboard = self.storyboard;
    SaveAlertViewController *saveVocal  = [storyboard instantiateViewControllerWithIdentifier:@"savinAlert"];
    saveVocal.avMixer = avMixer;
    saveVocal.SongName = _SongName;
    [saveVocal setOutputAVComposition:[avMixer outputComposition]];
    saveVocal.outputVocalFileName = @"";
    [saveVocal setDelegate:self];
    [saveVocal setSongType:@"SongBook"];
    [saveVocal setOutputMode:false];
    [saveVocal setTracktime:[self secondToString:(endRecordingTime-beginRecordingTime)]];
    
    [saveVocal setValue:self forKey:@"GivingUpSavingDelegate"];
    isSavingView = YES;
    [self presentPopupViewController:saveVocal animationType:MJPopupViewAnimationFade];
    // --------
    //[self showSaveVocalDialog];
}

#pragma mark -
// --- handle different image source. 2013.04.13
- (void) syncPlayerWithMusicPosition {
    //
    CMTime musicPos;
    double afterSecond = [audioProcessor currentTime];
    if (afterSecond > 0)
        musicPos = CMTimeMakeWithSeconds( afterSecond, 600);
    else
        musicPos = kCMTimeZero;
    //
    if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS) {
        double videoDuration = CMTimeGetSeconds([[userPlayer currentItem] duration]);
        while (afterSecond >= videoDuration) {
            afterSecond -= videoDuration;
        }
        //
        [userPlayer seekToTime:musicPos toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        //[userPlayer play];
    }
    else if (songType == SONG_TYPE_MP4 && imageSrcTypeIdx != IMAGE_SOURCE_TYPE_USER_VIDEOS) {
        // waiting for [SEEKING] !!
        while (defaultPlayer.status != AVPlayerStatusReadyToPlay &&
               defaultPlayer.currentItem.status != AVPlayerItemStatusReadyToPlay) ;
        //
        [defaultPlayer pause];
        [defaultPlayer seekToTime:musicPos toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero
                completionHandler:^(BOOL finished){
                    //   if (finished) ;
                    // [defaultPlayer play];
                    // re-sync for the video-seeking(before/after) issue !!
                    // Known BUG: audio will ...
                    double finalValue = CMTimeGetSeconds(defaultPlayer.currentTime);
                    [audioProcessor seekToTime:finalValue];
                }];
    }
}

#pragma mark Selecting the Image Source (Original/Photo/Video/Camera)
- (IBAction)changeImageSource:(id)sender {
    //    [switchCameraPosition setHidden:YES];
    if (sender) {
        curImageSrcIdx = self.segImageSource.selectedSegmentIndex;
    }
    NSLog(@"The index of current selected IMAGE_SOURCE_TYPE is:%i", curImageSrcIdx);
    
    ButtonFullScene.hidden = NO;
    
    // just show message if without any camera device
    if (curImageSrcIdx == IMAGE_SOURCE_TYPE_CAMERA) {
        if (!captureSession) {
            [self setupVideoCaptureSession];
        }
        // check if any camera device existing ?
        if (videoDevice == nil) {
            [self showAlertMessage:@"找不到攝影鏡頭，無攝影功能！" withTitle:@"<<<< 抱歉 >>>>" buttonText:@"確認"];
            curImageSrcIdx = IMAGE_SOURCE_TYPE_DEFAULT;
            return;
        }
    }
    
    // stop the capture firstly !!
    if (captureSession)
        [captureSession stopRunning];
    //
    if (!isPause) {
        [self stopPlayer];
    }
    //
    switch (curImageSrcIdx) {
        case IMAGE_SOURCE_TYPE_DEFAULT: // default
            if (imageSrcTypeIdx == curImageSrcIdx) {
                //
                if (isPause) {
                    [self startPlayer];
                }
                return;
            }
            //
            imageSrcTypeIdx = curImageSrcIdx;
            if (isPickupView) {
                [self pickupViewPressed:nil];
                playerView.alpha = 1;
            }
            //
            if (songType==SONG_TYPE_MP3) { // mp3
                // load images !!
                [self loadDefaultImagesForShow];
                lbVideoSource.text = [NSString stringWithFormat: @"內建（預設照片%d張）", imageList1.count];
                [self hideSubviewTool:YES];
                playerView.hidden = YES;
                self.subplayView.hidden = YES;
                imageForShow.hidden = NO;
                if (isFullScene) {
                    imageForShow.frame = FullMainSize;
                }
                else {
                    imageForShow.frame = OriginalMainSize;
                }
                [self switchImage];
            }
            else {             // mp4
                lbVideoSource.text = @"內建（原有影片）";
                [self hideSubviewTool:YES];
                playerView.hidden = NO;
                self.subplayView.hidden = YES;
                imageForShow.hidden = YES;
                isSwitchView = NO;
                //
                //[defaultPlayer replaceCurrentItemWithPlayerItem:defaultPlayerItem];
                //
                if (playerLayer != nil) [playerLayer removeFromSuperlayer];
                if (cameraPreviewLayer != nil) [cameraPreviewLayer removeFromSuperlayer];
                if (userVideoLayer != nil) [userVideoLayer removeFromSuperlayer];
                //
                playerView.backgroundColor = [UIColor blackColor];
                if (!isDefaultAVPlayer) {
                    playerLayer = [AVPlayerLayer playerLayerWithPlayer:defaultPlayer];
                }
                if (isFullScene) {
                    playerView.layer.frame = FullMainSize;
                }
                else {
                    playerView.layer.frame = OriginalMainSize;
                }
                playerLayer.frame = playerView.layer.bounds;
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                //
                isDefaultAVPlayer = YES;
                [playerView.layer addSublayer:playerLayer];
                //
                [self syncPlayerWithMusicPosition];
            }
            //
            if (!isPause) {
                [self stopPlayer];
            }
            break;
        case IMAGE_SOURCE_TYPE_USER_PHOTOS: // select photo
            if ( imageList2 == nil)
                imageList2 = [[NSMutableArray alloc]init];
            
            if (curImageSrcIdx == imageSrcTypeIdx || imageList2.count == 0) { // choose photo !!
                // select new images !!
                [self launchImageVideoPicker:kUTTypeImage];                   // it will clear the old content !!
            }
            else {
                // Now, SUPPOSE we have user's selected image files for showing.
                lbVideoSource.text = [NSString stringWithFormat: @"自選照片(%d張)", [imageList2 count]];
                imageSrcTypeIdx = curImageSrcIdx;
                self.subplayView.hidden = YES;
                imageForShow.hidden = NO;
                
                playerView.frame = OriginalSubSize;
                imageForShow.frame = OriginalMainSize;
                [self.view bringSubviewToFront:playerView];
                [self.view bringSubviewToFront:self.ViewToolBox];
                [self.view bringSubviewToFront:self.ButtonPackupView];
                isSwitchView = NO;
                
                if (songType==SONG_TYPE_MP4) {
                    [self hideSubviewTool:NO];
                    playerView.hidden = NO;
                    if (isPickupView) {
                        if (isSwitchView) {
                            imageForShow.alpha = 0;
                        } else {
                            playerView.alpha = 0;
                            imageForShow.alpha = 1;
                        }
                    } else {
                        imageForShow.alpha = 1;
                        playerView.alpha = 1;
                    }
                } else if (songType == SONG_TYPE_MP3) {
                    [self hideSubviewTool:YES];
                    playerView.hidden = YES;
                    imageForShow.alpha = 1;
                }
                
                if (playerLayer != nil) [playerLayer removeFromSuperlayer];
                if (cameraPreviewLayer != nil) [cameraPreviewLayer removeFromSuperlayer];
                if (userVideoLayer != nil) [userVideoLayer removeFromSuperlayer];
                //
                playerView.backgroundColor = [UIColor blackColor];
                if (!isDefaultAVPlayer) {
                    playerLayer = [AVPlayerLayer playerLayerWithPlayer:defaultPlayer];
                }
                if (isFullScene) {
                    if (isSwitchView && songType == SONG_TYPE_MP4) {
                        playerView.layer.frame = FullMainSize;
                        imageForShow.frame = FullSubSize;
                    } else {
                        playerView.layer.frame = FullSubSize;
                        imageForShow.frame = FullMainSize;
                    }
                    [self hideSubviewTool:YES];
                } else {
                    if (isSwitchView && songType == SONG_TYPE_MP4) {
                        playerView.layer.frame = OriginalMainSize;
                        imageForShow.frame = OriginalSubSize;
                    } else {
                        playerView.layer.frame = OriginalSubSize;
                        imageForShow.frame = OriginalMainSize;
                    }
                }
                playerLayer.frame = playerView.layer.bounds;
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                isDefaultAVPlayer = YES;
                [playerView.layer addSublayer:playerLayer];
                //
                [self syncPlayerWithMusicPosition];
                
                [self switchImage];
                
                if (!isPause) {
                    [self stopPlayer];
                }
                //
            }
            break;
        case IMAGE_SOURCE_TYPE_USER_VIDEOS: // select photo-roll
            // Re-select the movie file (Roll)
            if (imageSrcTypeIdx == curImageSrcIdx) {
                [self launchImageVideoPicker:kUTTypeVideo];
            }
            else if ( userPlayerItem == nil) {
                [self launchImageVideoPicker:kUTTypeVideo];
            }
            else {
                lbVideoSource.text = [NSString stringWithFormat: @"自選影片"];
                imageSrcTypeIdx = curImageSrcIdx;
                playerView.hidden = NO;
                playerView.alpha = 1;
                [self hideSubviewTool:YES];
                imageForShow.hidden = YES;
                self.subplayView.hidden = YES;
                if (isFullScene) {
                    playerView.layer.frame = FullMainSize;
                }
                else {
                    playerView.layer.frame = OriginalMainSize;
                }
                isSwitchView = NO;
                
                [self.view bringSubviewToFront:self.ivLoading];
                [self.view bringSubviewToFront:self.lbCurrentTime];
                [self.view bringSubviewToFront:self.songSlider];
                
                // switch User Video
                [self switchUserVideo:nil];
                //
                if (!isPause) {
                    [self stopPlayer];
                }
                [self syncPlayerWithMusicPosition];
            }
            break;
        case IMAGE_SOURCE_TYPE_CAMERA: // from Camera
            
            playerView.hidden = NO;
            imageForShow.hidden = YES;
            ButtonFullScene.hidden = YES;
            
            
            if (isPickupView) {
                [self pickupViewPressed:nil];
            }
            
            if (songType == SONG_TYPE_MP4) {
                self.subplayView.hidden = NO;
                [self hideSubviewTool:NO];
                if (isPickupView) {
                    if (isSwitchView) {
                        playerView.alpha = 0;
                    } else {
                        self.subplayView.alpha = 0;
                    }
                } else {
                    self.subplayView.alpha = 1;
                    playerView.alpha = 1;
                }
            } else if (songType == SONG_TYPE_MP3) {
                self.subplayView.hidden = YES;
                [self hideSubviewTool:YES];
                playerView.alpha = 1;
            }
            
            if (playerLayer != nil) [playerLayer removeFromSuperlayer];
            if (userVideoLayer != nil) [userVideoLayer removeFromSuperlayer];
            if (cameraPreviewLayer != nil)
                [cameraPreviewLayer removeFromSuperlayer];

            [self.view bringSubviewToFront:self.subplayView];
            [self.view bringSubviewToFront:self.ViewToolBox];
            [self.view bringSubviewToFront:self.ButtonPackupView];
            isSwitchView = NO;
            
            self.subplayView.backgroundColor = [UIColor blackColor];
            if (!isDefaultAVPlayer) {
                playerLayer = [AVPlayerLayer playerLayerWithPlayer:defaultPlayer];
            }
            if (isFullScene) {
                if (isSwitchView && songType == SONG_TYPE_MP4) {
                    playerView.layer.frame = FullSubSize;
                    self.subplayView.layer.frame = FullMainSize;
                } else {
                    playerView.layer.frame = FullMainSize;
                    self.subplayView.layer.frame = FullSubSize;
                }
                [self hideSubviewTool:YES];
            } else {
                if (isSwitchView && songType == SONG_TYPE_MP4) {
                    playerView.layer.frame = OriginalSubSize;
                    self.subplayView.layer.frame = OriginalMainSize;
                } else {
                    playerView.layer.frame = OriginalMainSize;
                    self.subplayView.layer.frame = OriginalSubSize;
                }
            }
            cameraPreviewLayer.frame = playerView.layer.bounds;
            playerLayer.frame = self.subplayView.layer.bounds;
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            
            [self.subplayView.layer addSublayer:playerLayer];

            //
            if (!isPause) {
                if (imageSrcTypeIdx != curImageSrcIdx) {
                    [self stopPlayer];
                }
            }
            
            //
            if (imageSrcTypeIdx == curImageSrcIdx) {
                [captureSession startRunning];
                [self switchCamera];
            }
            //
            captureVideoOrientation = [self getCurrentVideoOrientation];
            if (cameraPreviewLayer == nil) {
                // create a preview layer from the session and add it to UI
                cameraPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
                cameraPreviewLayer.frame = playerView.layer.bounds;
                [cameraPreviewLayer setVideoGravity: AVLayerVideoGravityResizeAspect];
                
            }
            else {
                [cameraPreviewLayer removeFromSuperlayer];
            }
            //
            [cameraPreviewLayer setOrientation: captureVideoOrientation];
            
            // Check again for avoiding CAMERA is unavailable !!
            [captureSession startRunning];
            if (captureSession.isRunning == NO) {
                return;
            }
            
            //
            //
            //if (playerLayer != nil) [playerLayer removeFromSuperlayer];
            
            //
            imageSrcTypeIdx = curImageSrcIdx;
            if (cameraPosition == AVCaptureDevicePositionFront)
                lbVideoSource.text = @"前攝影鏡頭";
            else
                lbVideoSource.text = @"後攝影鏡頭";
            //
            [playerView.layer addSublayer:cameraPreviewLayer];
            
            [self syncPlayerWithMusicPosition];
            break;
    }
}

#pragma mark -
#pragma mark Display Alert
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
    if (buttonIndex == 0) {
        if ([alertView buttonTitleAtIndex:buttonIndex].length >= 4) {
            if ([[[alertView buttonTitleAtIndex:buttonIndex] substringFromIndex:[alertView buttonTitleAtIndex:buttonIndex].length - 4]  compare:@"繼續歡唱"]==NSOrderedSame) {
                if (isPause) {
                    [self songSliderValueChanged:nil]; //同步影像與音源
                    [self togglePlayPause:nil];
                }
            }
        }
    } else if (buttonIndex == 1) {
        
    }
}
#pragma mark -
/*
 // --------------------------------------------------------------------------------
 // Original Model: subclassing the UIImagePickerController for select Videos.
 // drawback: cannot skip the [COMPRESS] procedure after pressing the [use] button.
 // --------------------------------------------------------------------------------
 #pragma mark Video Picker (OLD)
 -(void)launchVideoPicker {
 if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
 if (videoPickerController == nil) {
 videoPickerController= [[KOKSVideoPickerViewController alloc] init];
 videoPickerController.delegate = self;
 videoPickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;  //UIImagePickerControllerSourceTypeSavedPhotosAlbum
 videoPickerController.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
 [videoPickerController setAllowsEditing:NO];
 [videoPickerController setEditing:NO];
 videoPickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
 }
 // for iPad --> by PopoverController
 if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
 if (videoPickerPopoverController == nil) {
 UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:videoPickerController];
 videoPickerPopoverController = popover;
 [videoPickerPopoverController setDelegate:self];
 popover = nil;
 }
 //
 [videoPickerPopoverController presentPopoverFromRect:segImageSource.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
 } else {
 [self presentModalViewController:videoPickerController animated:YES];
 }
 
 }else {
 UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"<< 錯誤 >>" message:@"存取影片資料時發生錯誤！！" delegate:nil cancelButtonTitle:@"關閉" otherButtonTitles:nil];
 [alert show];
 //[alert release];
 }
 
 }
 
 -(void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
 NSLog(@"==> popoverControllerDidDismissPopover: %@", [popoverController class]);
 }
 
 - (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
 NSLog(@"==> navigationController: willShowViewController: %@", [viewController class]);
 UINavigationItem *ipcNavBarTopItem;
 // add done button to right side of nav bar
 UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
 style:UIBarButtonItemStylePlain
 target:self
 action:@selector(cancelButtonClicked)];
 // add done button to right side of nav bar
 UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"選用"
 style:UIBarButtonItemStylePlain
 target:self
 action:@selector(doneButtonClicked)];
 //
 UINavigationBar *naviBar = navigationController.navigationBar;
 [naviBar setHidden:NO];
 ipcNavBarTopItem = naviBar.topItem;
 //
 
 NSString *type = NSStringFromClass( [viewController class] );
 if ([type isEqualToString:@"PLUILibraryViewController"]) {
 ipcNavBarTopItem.title = @"影片分類";
 ipcNavBarTopItem.rightBarButtonItem = cancelButton;
 }
 else if ([type isEqualToString:@"PLUIAlbumViewController"]) {
 ipcNavBarTopItem.title = @"選擇影片";
 ipcNavBarTopItem.rightBarButtonItem = cancelButton;
 }
 else if ([type isEqualToString:@"PLUIImageViewController"]) {
 ipcNavBarTopItem.title = @"試播影片";
 ipcNavBarTopItem.rightBarButtonItem = doneButton;
 }
 
 }
 
 -(void) cancelButtonClicked{
 // 關閉選擇畫面！！
 // for iPad --> by PopoverController
 if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
 [videoPickerPopoverController dismissPopoverAnimated:YES];
 }
 else {
 [self dismissModalViewControllerAnimated:YES];
 }
 
 }
 -(void) doneButtonClicked{
 //
 // 關閉選擇畫面！！
 // for iPad --> by PopoverController
 if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
 [videoPickerPopoverController dismissPopoverAnimated:YES];
 }
 else {
 [self dismissModalViewControllerAnimated:YES];
 }
 
 }
 
 -(void) imagePickerController: (KOKSVideoPickerViewController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info
 {
 NSLog(@"KOKSVideoPickerViewController:didFinishPickingMediaWithInfo: ");
 NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
 
 if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo)
 {
 
 NSString *moviePath = [[info objectForKey:UIImagePickerControllerMediaURL] path];
 NSLog(@"Selected Movie: %@",moviePath);
 NSURL *videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
 
 // Save in the PhotosAlbum !!
 //if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
 //    UISaveVideoAtPathToSavedPhotosAlbum (moviePath, nil, nil, nil);
 //}
 }
 
 // 關閉選擇畫面！！
 // for iPad --> by PopoverController
 if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
 [videoPickerPopoverController dismissPopoverAnimated:YES];
 }
 else {
 [videoPickerController dismissModalViewControllerAnimated:YES];
 }
 //[picker release];
 
 }
 
 - (void) koksVideoPickerViewControllerDidCancel:(KOKSVideoPickerViewController *)picker{
 // 關閉選擇畫面！！
 // for iPad --> by PopoverController
 if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
 [videoPickerPopoverController dismissPopoverAnimated:YES];
 }
 else {
 [self dismissModalViewControllerAnimated:YES];
 }
 }
 
 */

#pragma mark -
#pragma mark Image/Video Picker ----

-(void) launchImageVideoPicker:(CFStringRef) mediaType { // mediaType : kUTTypeImage or kUTTypeVideo
    ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] initWithNibName:@"ELCAlbumPickerController" bundle:[NSBundle mainBundle]];
    albumController.mediaType = mediaType;
	ELCImagePickerController *elcImagePicker = [[ELCImagePickerController alloc] initWithRootViewController:albumController];
    [albumController setParent:elcImagePicker];
	[elcImagePicker setDelegate:self];
    isELCImagePicker = YES;
    // Original model !
    //[self presentModalViewController:elcImagePicker animated:YES];
    
    // New Model !!
    // for iPad --> by PopoverController
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        //if (imagePickerPopoverController == nil) {
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:elcImagePicker];
        imagePickerPopoverController = popover;
        [imagePickerPopoverController setDelegate:self];
        popover = nil;
        //}
        //
        [imagePickerPopoverController presentPopoverFromRect:segImageSource.frame inView:ViewToolBox permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:elcImagePicker animated:YES completion:nil];
    }
    
    if (startPauseButton.selected) {
        [self stopPlayer];
    }
    
    //[elcPicker release];
    //[albumController release];
}

#pragma mark ELCImagePickerControllerDelegate Methods

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
	isELCImagePicker = NO;
    // 關閉選擇畫面！！
    // for iPad --> by PopoverController
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [imagePickerPopoverController dismissPopoverAnimated:YES];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    // check if there are any images selected ?
    if ( info.count == 0 ) {
        if (isPause) {
            [self startPlayer];
        }
        // 如果什麼都沒有選擇就關閉，則來源為將為預設
        if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
            if (imageList2.count == 0) {
                curImageSrcIdx = IMAGE_SOURCE_TYPE_DEFAULT;
                ListSC.selectedIndex = 0;
            }
        }
        else if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS) {
            if (videoList.count == 0) {
                curImageSrcIdx = IMAGE_SOURCE_TYPE_DEFAULT;
                ListSC.selectedIndex = 0;
            }
        }
        return;
    }
    
    if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS)  {
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
        lbVideoSource.text = [NSString stringWithFormat: @"自選照片(%d張)", [imageList2 count]];
        imageSrcTypeIdx = curImageSrcIdx;
        //playerView.hidden = YES;
        self.subplayView.hidden = YES;
        imageForShow.hidden = NO;
        if (songType==SONG_TYPE_MP4) {
            [self hideSubviewTool:NO];
            playerView.frame = OriginalSubSize;
            imageForShow.frame = OriginalMainSize;
            [self.view bringSubviewToFront:playerView];
            [self.view bringSubviewToFront:self.ViewToolBox];
            [self.view bringSubviewToFront:self.ButtonPackupView];
            isSwitchView = NO;
            
            
            if (playerLayer != nil) [playerLayer removeFromSuperlayer];
            if (cameraPreviewLayer != nil) [cameraPreviewLayer removeFromSuperlayer];
            if (userVideoLayer != nil) [userVideoLayer removeFromSuperlayer];
            playerView.backgroundColor = [UIColor blackColor];
            if (!isDefaultAVPlayer) {
                playerLayer = [AVPlayerLayer playerLayerWithPlayer:defaultPlayer];
            }
            playerLayer.frame = playerView.layer.bounds;
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            isDefaultAVPlayer = YES;
            [playerView.layer addSublayer:playerLayer];

            [self syncPlayerWithMusicPosition];
        }
        
        [self switchImage];
    }
    else if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS){
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
        lbVideoSource.text = [NSString stringWithFormat: @"自選影片"];
        imageSrcTypeIdx = curImageSrcIdx;
        playerView.hidden = NO;
        playerView.alpha = 1;
        self.subplayView.hidden = YES;
        [self hideSubviewTool:YES];
        imageForShow.hidden = YES;
        
        
        [self.view bringSubviewToFront:self.ivLoading];
        [self.view bringSubviewToFront:self.lbCurrentTime];
        [self.view bringSubviewToFront:self.songSlider];
        
        if (songType == SONG_TYPE_MP4) {
            playerView.frame = OriginalMainSize;
            isSwitchView = NO;
        }
        
        // switch with the first User selected Video
        for(NSDictionary *dict in info) {
            // we must retrieve the Video-URLs !
            NSURL *videoUrl = [dict objectForKey:UIImagePickerControllerReferenceURL];
            [videoList addObject:videoUrl];
        }
        NSURL *videoURL = [[info objectAtIndex:0] objectForKey:UIImagePickerControllerReferenceURL];
        [self switchUserVideo:videoURL];
        
    }
    //
    if (isPause) {
        [self startPlayer];
    }
}


- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
	//[self dismissModalViewControllerAnimated:YES];
    isELCImagePicker = NO;
    // 關閉選擇畫面！！
    // for iPad --> by PopoverController
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [imagePickerPopoverController dismissPopoverAnimated:YES];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    // 如果什麼都沒有選擇就關閉，則來源為將為預設
    if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
        if (imageList2.count == 0) {
            curImageSrcIdx = IMAGE_SOURCE_TYPE_DEFAULT;
            ListSC.selectedIndex = 0;
        }
    }
    else if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS) {
        if (videoList.count == 0) {
            curImageSrcIdx = IMAGE_SOURCE_TYPE_DEFAULT;
            ListSC.selectedIndex = 0;
        }
    }
}

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    isELCImagePicker = NO;
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
        AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
        
        // enable/disable UI as appropriate
        NSArray *visualTracks = [sourceAsset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
        //
        AVMutableComposition *userComposition = [AVMutableComposition composition];
        if ((!visualTracks) || ([visualTracks count] == 0)) {
            // no Viewo !!
            return;
        } else {
            [self insertVideoTrack: sourceAsset :userComposition];
        }
        //
        NSLog(@"The Tracks of the User-Original Asset:");
        [self showAssetTrackInfo: sourceAsset];
        NSLog(@"The Tracks of the User-Composition Asset:");
        [self showAssetTrackInfo: userComposition];
        
        userPlayerItem = [AVPlayerItem playerItemWithAsset:userComposition];
        
        // recreate a new UserPlayer
        userPlayer = nil;
        userPlayer = [AVPlayer playerWithPlayerItem:userPlayerItem];
        [userVideoLayer removeFromSuperlayer];
        userVideoLayer = [AVPlayerLayer playerLayerWithPlayer:userPlayer];
        
    }
    else if (userPlayerItem == nil) { // just show the userPlayerItem without switching the video !
        return;
    }
    else {
        [userPlayer pause];
    }
    
    //
    //[player replaceCurrentItemWithPlayerItem:userPlayerItem];
    [defaultPlayer pause];
    
    // -----------------------------------
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(playerItemDidReachedEnd:)
     name:AVPlayerItemDidPlayToEndTimeNotification
     object:[userPlayer currentItem]];
    
    //
    if (cameraPreviewLayer != nil) [cameraPreviewLayer removeFromSuperlayer];
    //
    if (playerLayer != nil)  [playerLayer removeFromSuperlayer];
    //
    if (userVideoLayer != nil) [userVideoLayer removeFromSuperlayer];
    
    userVideoLayer.frame = playerView.layer.bounds;
    userVideoLayer.videoGravity = AVLayerVideoGravityResizeAspect;

    [playerView.layer addSublayer:userVideoLayer];
    [self syncPlayerWithMusicPosition];
    if (audioProcessor.isPlaying)
        [userPlayer play];
}


//----------------------------------------------------------
#pragma mark -
#pragma mark [ Initialize Capture stuff - Camera ]
-(NSError*) setupVideoCaptureSession{
    //20140428
    captureSession = nil;
	captureSession = [[AVCaptureSession alloc] init];
    
	// find, attach devices
	NSError *setUpError = nil;
    videoDevice = [self getCameraPreferredDevice:cameraPosition];
    
    if (videoDevice) {
        NSLog (@"Got videoDevice");
        videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice
                                                                 error:&setUpError];
        if (videoDeviceInput) {
            // 1. Configure the resolution
            /*
             AVCaptureSessionPresetHigh - Highest recording quality (varies per device)
             AVCaptureSessionPresetMedium - Suitable for WiFi sharing (actual values may change)
             AVCaptureSessionPresetLow - Suitable for 3G sharing (actual values may change)
             AVCaptureSessionPreset640x480 - 640x480 VGA (check its supported before setting it)
             AVCaptureSessionPreset1280x720 - 1280x720 720p HD (check its supported before setting it)
             AVCaptureSessionPresetPhoto - Full photo resolution (not supported for video output)
             */
            
            //            if (switchCameraPosition.isOn==NO) {
            //                // 高解析度 for 後攝影鏡頭！！
            //                if ([captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            //                    captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
            //                }
            //                else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetiFrame1280x720]) {
            //                    captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
            //                }
            //                else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetiFrame960x540]) {
            //                    captureSession.sessionPreset = AVCaptureSessionPresetiFrame960x540;
            //                }
            //            }
            //            else if (switchCameraPosition.isOn==YES){
            // 前攝影鏡頭！！
            if ([captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
                //captureSession.sessionPreset = AVCaptureSessionPresetHigh;
                captureSession.sessionPreset = AVCaptureSessionPresetMedium;
            }
            else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
                captureSession.sessionPreset = AVCaptureSessionPresetMedium;
            }
            else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetLow]) {
                captureSession.sessionPreset = AVCaptureSessionPresetLow;
            }
            else {
                captureSession.sessionPreset = AVCaptureSessionPreset352x288;
            }
            
            
            //            }
            // 2. Add the CameraDevice to the Capture Session
            [captureSession addInput: videoDeviceInput];
            
        }
	}
    
	return setUpError;
}

//-----------------------------------------------
- (AVCaptureDevice *)getCameraDevice{
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        
        NSLog(@"Device name: %@", [device localizedName]);
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionFront) {
                NSLog(@"Device position : front");
                frontCamera = device;
            }
            else {
                NSLog(@"Device position : back");
                backCamera = device;
            }
        }
    }
    // front Camera first !!
    if (frontCamera)
        return frontCamera;
    else {
        return backCamera;
    }
}
//-----------------------------------------------
- (AVCaptureDevice *)getCameraPreferredDevice:(AVCaptureDevicePosition) cameraType{
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    //
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        
        NSLog(@"Device name: %@", [device localizedName]);
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionFront) {
                NSLog(@"Device position : front");
                frontCamera = device;
            }
            else {
                NSLog(@"Device position : back");
                backCamera = device;
            }
        }
    }
    // front Camera first !!
    if (backCamera && cameraType == AVCaptureDevicePositionBack)
        return backCamera;
    else if (frontCamera) {
        return frontCamera;
    }
    else
        return nil;
}

#pragma mark -
#pragma mark Notification registration
// If this app's audio session is interrupted when playing audio, it needs to update its user interface
//    to reflect the fact that audio has stopped. The KOKSMixerHostAudio object conveys its change in state to
//    this object by way of a notification. To learn about notifications, see Notification Programming Topics.
- (void) registerForAudioObjectNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (handlePlaybackStateChanged:)
                                                 name: KOKSAudioObjectPlaybackStateDidChangeNotification
                                               object: audioProcessor];
}

#pragma mark -
#pragma mark Setup Audio Processor (KOKSMixerHostAudio)
- (void) setupAudioProcessor:(AVAsset *) Asset {
    
    
    self.audioProcessor = nil;
    if (songUrl.isFileURL)
        self.audioProcessor = [[KOKSMixerHostAudio alloc] initWithUrl:songUrl];
    //        self.audioProcessor = [[KOKSMixerHostAudio alloc]initWithUrl:songUrl graphSampleRate:graphSampleRate];
    else if (Asset != nil)
        self.audioProcessor = [[KOKSMixerHostAudio alloc] initWithAsset:Asset];
    else
        self.audioProcessor = [[KOKSMixerHostAudio alloc] init]; // default : for testing
    
    
    //
    [audioProcessor enableMixerInput:0 isOn:YES];   // Left
    [audioProcessor enableMixerInput:1 isOn:YES];   // Right
    [audioProcessor enableMixerInput:2 isOn:YES];   // Mic
    [audioProcessor setMixerInput:0 gain:0.6f];     // Music (Audio)
    //[audioProcessor setMixerInput:0 panValue:-1];   // -1--> Left-only:Audio
    [audioProcessor setMixerInput:1 gain:0.6f];     // Music (original Vocal)
    //[audioProcessor setMixerInput:1 panValue:+1];   // +1--> Right-only:original Vocal
    //[audioProcessor setMixerInput:1 panValue:-1];   // -1--> Left-only:original Vocal
    [audioProcessor setMixerInput:2 gain:0.5f];     // Mic
    [audioProcessor setMixerOutputGain:1.0f];       // Mixer output
    
    
    //
    [self registerForAudioObjectNotifications];
    
}

#pragma mark -
#pragma mark ExternalAccessory
- (void)_accessoryDidConnect:(NSNotification *)notification {
    EAAccessory *connectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    [accessoryList addObject:connectedAccessory];
    if ([accessoryList count] == 0) {
    } else {
        selectedAccessory = [accessoryList objectAtIndex:0];
    }
}

- (void)_accessoryDidDisconnect:(NSNotification *)notification {
    
    EAAccessory *disconnectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    selectedAccessory = [accessoryList objectAtIndex:0];
    int disconnectedAccessoryIndex = 0;
    for(EAAccessory *accessory in accessoryList) {
        if ([disconnectedAccessory connectionID] == [accessory connectionID]) {
            break;
        }
        disconnectedAccessoryIndex++;
    }
    
    if (disconnectedAccessoryIndex < [accessoryList count]) {
        [accessoryList removeObjectAtIndex:disconnectedAccessoryIndex];
	} else {
        NSLog(@"could not find disconnected accessory in accessory list");
    }
    
    if ([accessoryList count] == 0) {
        if (!isPause) {
            [self togglePlayPause:nil];
        }
        UIAlertView *EAalert=[[UIAlertView alloc]initWithTitle:@"訊息"
                                                       message:[NSString stringWithFormat:@"發現外部裝置\n『%@』\n異動",[selectedAccessory name]]
                                                      delegate:self
                                             cancelButtonTitle:@"了解，繼續歡唱"
                                             otherButtonTitles:nil];
        [EAalert show];
    }
}

#pragma mark SVSegmentedControl
- (void)segmentedControlChangedValue:(SVSegmentedControl*)segmentedControl {
    curImageSrcIdx = segmentedControl.selectedIndex;
    if (curImageSrcIdx == IMAGE_SOURCE_TYPE_CAMERA)
        if (isRecord)
            [buttonCameraPosition setHidden:YES];
        else
            [buttonCameraPosition setHidden:NO];
        else
            [buttonCameraPosition setHidden:YES];
    [self changeImageSource:nil];
}

#pragma mark -
#pragma mark IBAction for Volume/Vocal/Reverb/Echo

- (IBAction) doAdjustVolume:(id)sender {
    // NSLog(@"Current Volume is: %f", volumeSlider.value);
    // [self setVolume:volumeSlider.value];
    
    // Directly change the volume of music input.
    [audioProcessor setMixerInput:0 gain:volumeSlider.value];   // 0 ~ 1
}

- (IBAction)doAdjustVocal:(id)sender {
    [audioProcessor setMixerInput:1 gain:vocalSlider.value];    // 0 ~ 1
}


- (IBAction)doAdjustMicVolume:(id)sender {
    [audioProcessor setMixerInput:2 gain:micVolumeSlider.value];    // 0 ~ 1
}


/*
 
 Reverb effect --> called "ECHO", now!
 
 */
//Reverb參數調整
//- (IBAction)doAdjustReverb:(id)sender {
//    float dryWetValue = reverbSlider.value;           // 0 ~ 100
//    [audioProcessor setReverbDryWetMix:dryWetValue==0? 0 : 100];
//    //
//    float decayTime1 = dryWetValue / 100 * 20;        // 0.001 ~ 20.0 ;ex: 2.5 --> 1.5
//    float decayTime2 = decayTime1 * 0.6;
//    [audioProcessor setReverbDecayTime:(decayTime1) :decayTime2];
//    //
//    int reflections =  (int) (dryWetValue / 100 * 1000);  // 1 ~ 1000
//    [audioProcessor setReverbRandomReflections:reflections];
//}

- (IBAction)doAdjustReverb:(id)sender {
    float randReflectRateValue;
    float dryWetValue;
    float gainValue;
    float minDelay;
    float maxDelay;
    float f0HzDecay;
    float fNyquistDecay;
    
    [ButtonEchoNone setImage:[UIImage imageNamed:@"無01.png"] forState:UIControlStateNormal];
    [ButtonEchoLow setImage:[UIImage imageNamed:@"弱01.png"] forState:UIControlStateNormal];
    [ButtonEchoMid setImage:[UIImage imageNamed:@"中01.png"] forState:UIControlStateNormal];
    [ButtonEchoHigh setImage:[UIImage imageNamed:@"強01.png"] forState:UIControlStateNormal];
    
    minDelay = 0.09;
    maxDelay = 0.09;
    randReflectRateValue = 500;
    f0HzDecay = 2.2;
    fNyquistDecay = 1.0;
    
    UIButton *btn = sender;
    switch (btn.tag) {
        case 11:  //none
            [ButtonEchoNone setImage:[UIImage imageNamed:@"無02.png"] forState:UIControlStateNormal];
            dryWetValue = 0;
            gainValue = -10;
            aSetting.Echo = @"無";
            break;
        case 12:  //low
            [ButtonEchoLow setImage:[UIImage imageNamed:@"弱02.png"] forState:UIControlStateNormal];
            dryWetValue = 40;
            gainValue = -10;
            aSetting.Echo = @"弱";
            break;
        case 13:  //mid
            [ButtonEchoMid setImage:[UIImage imageNamed:@"中02.png"] forState:UIControlStateNormal];
            dryWetValue = 40;
            gainValue = -5;
            aSetting.Echo = @"中";
            break;
        case 14:  //high
            [ButtonEchoHigh setImage:[UIImage imageNamed:@"強02.png"] forState:UIControlStateNormal];
            dryWetValue = 40;
            gainValue = -0;
            aSetting.Echo = @"強";
            break;
        default:
            [ButtonEchoNone setImage:[UIImage imageNamed:@"無02.png"] forState:UIControlStateNormal];
            dryWetValue = 0;
            gainValue = -10;
            aSetting.Echo = @"無";
            break;
    }
    //
    [audioProcessor setReverbDryWetMix:dryWetValue gain:gainValue minDelay:minDelay maxDelay:maxDelay f0HzDecay:f0HzDecay fNyquistDecay:fNyquistDecay randReflectRate:randReflectRateValue];
}


- (void)DefaultEcho {
    float randReflectRateValue;
    float dryWetValue;
    float gainValue;
    float minDelay;
    float maxDelay;
    float f0HzDecay;
    float fNyquistDecay;
    
    [ButtonEchoNone setImage:[UIImage imageNamed:@"無01.png"] forState:UIControlStateNormal];
    [ButtonEchoLow setImage:[UIImage imageNamed:@"弱01.png"] forState:UIControlStateNormal];
    [ButtonEchoMid setImage:[UIImage imageNamed:@"中01.png"] forState:UIControlStateNormal];
    [ButtonEchoHigh setImage:[UIImage imageNamed:@"強01.png"] forState:UIControlStateNormal];
    
    minDelay = 0.09;
    maxDelay = 0.09;
    randReflectRateValue = 500;
    f0HzDecay = 2.2;
    fNyquistDecay = 1.0;
    
    if ([aSetting.Echo isEqualToString:@"無"]) {
        //none
        [ButtonEchoNone setImage:[UIImage imageNamed:@"無02.png"] forState:UIControlStateNormal];
        dryWetValue = 0;
        gainValue = -10;
    }
    else if ([aSetting.Echo isEqualToString:@"弱"]) {
        //low
        [ButtonEchoLow setImage:[UIImage imageNamed:@"弱02.png"] forState:UIControlStateNormal];
        dryWetValue = 40;
        gainValue = -10;
    }
    else if ([aSetting.Echo isEqualToString:@"中"]) {
        //mid
        [ButtonEchoMid setImage:[UIImage imageNamed:@"中02.png"] forState:UIControlStateNormal];
        dryWetValue = 40;
        gainValue = -5;
    }
    else if ([aSetting.Echo isEqualToString:@"強"]) {
        //high
        [ButtonEchoHigh setImage:[UIImage imageNamed:@"強02.png"] forState:UIControlStateNormal];
        dryWetValue = 40;
        gainValue = -0;
    }
    else {
        //none
        [ButtonEchoNone setImage:[UIImage imageNamed:@"無02.png"] forState:UIControlStateNormal];
        dryWetValue = 0;
        gainValue = -10;
        aSetting.Echo = @"無";
    }
    //
    [audioProcessor setReverbDryWetMix:dryWetValue gain:gainValue minDelay:minDelay maxDelay:maxDelay f0HzDecay:f0HzDecay fNyquistDecay:fNyquistDecay randReflectRate:randReflectRateValue];
}

/*
 - (IBAction)doAdjustEcho:(id)sender {
 if (echoSlider.value <= 0.01f) {                    // 0 ~ 1
 [audioProcessor setMicFxOn:FALSE];
 }
 else {
 float delayValue = echoSlider.value;    // 0 ~ 1
 [audioProcessor setMicFxOn:TRUE];
 audioProcessor.micFxControl = delayValue;
 [audioProcessor setMicFxType:3];
 }
 }
 */

- (void)setPlayerVolume:(CGFloat)volume {
    AVPlayer *player;
    if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS)
        player = userPlayer;
    else
        player = defaultPlayer;
    //
    NSArray *audioTracks = [player.currentItem.asset tracksWithMediaType:AVMediaTypeAudio];
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:volume atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    [player.currentItem setAudioMix:audioMix];
    //
    player = nil;
}


- (void)insertVideoTrack:(AVAsset *)videoAsset:(AVMutableComposition *)Composition {
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex: 0];
    AVMutableCompositionTrack *compositionVideoTrack = [Composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError* error = NULL;
    
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration)
                                   ofTrack:videoAssetTrack
                                    atTime:kCMTimeZero
                                     error:&error];
    
}

//----------------------------------------
- (void) prepareMedia {
    NSLog(@"[MP4PlayerViewController:PrepareMedia] - SongURL:%@", songUrl);
    /*
     dispatch_async(dispatch_get_main_queue(), ^{
     //
     //AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:songUrl options:nil];
     NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
     AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:songUrl options:options];
     AVPlayerItem *tmpPlayerItem = [AVPlayerItem playerItemWithAsset:sourceAsset];
     tmpPlayer = [AVPlayer playerWithPlayerItem:tmpPlayerItem];
     [tmpPlayerItem addObserver:self forKeyPath:@"status" options:0 context:nil];
     });
     */
    
    if (asset == nil) {
        asset = [[AVURLAsset alloc] initWithURL:songUrl options:nil];
    }
    
    NSArray *keys = [NSArray arrayWithObject:@"duration"];
    bAssetReady = false;
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^() {
        NSError *error = nil;
        AVKeyValueStatus durationStatus = [asset statusOfValueForKey:@"duration" error:&error];
        switch (durationStatus) {
            case AVKeyValueStatusLoaded:
                bAssetReady = true;
                [self prepareMediaWithAssetReady:asset];
                break;
            case AVKeyValueStatusFailed:
                [self prepareMediaWithAssetReady:nil];
                break;
            case AVKeyValueStatusCancelled:
                // Do whatever is appropriate for cancelation.
                [self prepareMediaWithAssetReady:nil];
                break;
        }
    }];
    
    // Waiting 1~3 seconds for the HTTP connection !
    //sleep(3);
    sleep(1);
    if (!bAssetReady) {
        // cancel the loading of HTTP/MP3, it will terminate the procedure of loadValuesAsynchromousFOrKeys ...
        [asset cancelLoading];
    }
    
}

/*
 - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
 change:(NSDictionary *)change context:(void *)context {
 if ([keyPath isEqualToString:@"status"]) {
 AVPlayerItem *pItem = (AVPlayerItem *)object;
 if (pItem.status == AVPlayerItemStatusReadyToPlay) {
 AVURLAsset *readyAsset = (AVURLAsset *)pItem.asset;
 [self prepareMediaWithAssetReady:readyAsset];
 }
 }
 }
 */

//
- (void) prepareMediaWithAssetReady:(AVURLAsset *)sourceAsset {
    
    if (sourceAsset == nil && songUrl.isFileURL == false) {
        // Create the AVURLAsset again !
        sourceAsset = [AVURLAsset URLAssetWithURL:songUrl options:nil];
    }
    //
    double assetDuration = CMTimeGetSeconds(sourceAsset.duration);
    NSLog(@"[MP4PlayerViewController:PrepareMedia] - SongURL:%@, duration:%f seconds.", songUrl, assetDuration);
    
    NSArray *audioTracks = [sourceAsset tracksWithMediaType:AVMediaTypeAudio];
    if ([audioTracks count] == 0 && songUrl.isFileURL == false) {
        // tricky !?????
        [sourceAsset cancelLoading];
        sleep(1);
        sourceAsset = [AVURLAsset URLAssetWithURL:songUrl options:nil];
    }
    
	// Retrieve  MP4s' informations.
	NSArray *visualTracks = [sourceAsset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
    /*
    -----2014-04-10 Ricky-----
    NSArray *visualTracks;
    if (songUrl.isFileURL)
        visualTracks = [sourceAsset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
    else
        visualTracks = nil;
    -----2014-04-10 Ricky-----
    */
    
    //
    // The content of the original AVURLAsset !
    NSLog(@"[MP4PlayerViewController:PrepareMedia] - The Tracks of the Original Asset:");
    [self showAssetTrackInfo: sourceAsset];
    //
    composition = [AVMutableComposition composition];
	if ((!visualTracks) || ([visualTracks count] == 0)) {
        songType = SONG_TYPE_MP3;
        [composition insertTimeRange:CMTimeRangeMake(kCMTimeZero, sourceAsset.duration) ofAsset:sourceAsset atTime:composition.duration error:nil];
	} else {
        songType = SONG_TYPE_MP4;
        // Case 1. Add it into your composition (不可以包含音軌，測試時有雜音！！)
        // [composition insertTimeRange:CMTimeRangeMake(kCMTimeZero, sourceAsset.duration) ofAsset:sourceAsset atTime:composition.duration error:nil];
        // Case 2. Retrieve the Video only !!   （抽離出Video !!）
        [self insertVideoTrack: sourceAsset :composition];
    }
    
    NSLog(@"[MP4PlayerViewController:PrepareMedia] - The Tracks of the Composition Asset:");
    [self showAssetTrackInfo: composition];
    
    //
    defaultPlayerItem = [AVPlayerItem playerItemWithAsset:composition];
    defaultPlayer = [AVPlayer playerWithPlayerItem:defaultPlayerItem];
    
    // 產生 KOKSMixerHostAudio 物件 [利於後續播放程序]
    [self setupAudioProcessor: sourceAsset];
    
    // ---------------------------------------------------------------------------------------
    // For switching various IMAGE Sources, including the MP4, we cannot depend on this model.
    // So, we utilize the timer to periodly check whether the playing song is ending or not ?
    // ---------------------------------------------------------------------------------------
    NSLog(@"%@",[defaultPlayer currentItem]);
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(playerItemDidReachedEnd:)
     name:AVPlayerItemDidPlayToEndTimeNotification
     object:[defaultPlayer currentItem]];
    
    
    AVPlayerItem *item = [defaultPlayer currentItem];
	musicDuration = CMTimeGetSeconds([item duration]);
    NSLog (@"playing %@", songUrl);
    
    // load the default images for showing
    [self loadDefaultImagesForShow];
    
    // Post the Notification
    [[NSNotificationCenter defaultCenter] postNotificationName:KOKSAudioMediaReadyNotification object:nil];
    
}

//-----------------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        composition = [[AVMutableComposition alloc] init];
    }
    return self;
}

#pragma mark IBAction for CameraPosition
- (IBAction)SwitchCameraPostion:(id)sender {
    curImageSrcIdx = IMAGE_SOURCE_TYPE_CAMERA;
    captureMovieURL=nil;
    [self changeImageSource:nil];
}
- (IBAction)ChangCameraPostion:(id)sender {
    curImageSrcIdx = IMAGE_SOURCE_TYPE_CAMERA;
    captureMovieURL=nil;
    if ([buttonCameraPosition.titleLabel.text isEqualToString:@"Front"]) {
        [buttonCameraPosition setTitle:@"Back" forState:UIControlStateNormal];
        //[switchCameraPosition setOn:YES];
    }
    else if ([buttonCameraPosition.titleLabel.text isEqualToString:@"Back"]) {
        [buttonCameraPosition setTitle:@"Front" forState:UIControlStateNormal];
        //[switchCameraPosition setOn:NO];
    }
    [self changeImageSource:nil];
}

#pragma mark IBAction for SceneButton
- (IBAction)FullScene:(id)sender {

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    if (isFullScene) {
        isFullScene = NO;
        [buttonScene setTitle:@"Full Scene" forState:UIControlStateNormal];
        [buttonScene setImage:[UIImage imageNamed:@"放大.png"] forState:UIControlStateNormal];
        if (songType == SONG_TYPE_MP4 && curImageSrcIdx != IMAGE_SOURCE_TYPE_DEFAULT) {
            [self hideSubviewTool:NO];
        }
        [self HideTop:NO];
        
        //View
        if ((imageSrcTypeIdx ==  IMAGE_SOURCE_TYPE_USER_PHOTOS || imageSrcTypeIdx == IMAGE_SOURCE_TYPE_CAMERA) &&
            songType == SONG_TYPE_MP4)
        {
            if (isSwitchView) {
                if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
                    playerView.layer.frame = OriginalMainSize;
                } else {
                    playerView.layer.frame = OriginalSubSize;
                }
                imageForShow.frame = OriginalSubSize;
                self.subplayView.layer.frame = OriginalMainSize;
            } else {
                if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
                    playerView.layer.frame = OriginalSubSize;
                } else {
                    playerView.layer.frame = OriginalMainSize;
                }
                imageForShow.frame = OriginalMainSize;
                self.subplayView.layer.frame = OriginalSubSize;
            }
        } else {
            playerView.layer.frame = OriginalMainSize;
            imageForShow.frame = OriginalMainSize;
        }
        cameraPreviewLayer.frame = playerView.layer.bounds;
        if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_CAMERA) {
            playerLayer.frame = self.subplayView.layer.bounds;
        } else {
            playerLayer.frame = playerView.layer.bounds;
        }
        
        //ImageView
        self.ivLoading.frame = CGRectMake(self.ivLoading.frame.origin.x,
                                          self.ivLoading.frame.origin.y - 159,
                                          self.ivLoading.frame.size.width,
                                          self.ivLoading.frame.size.height);
        [self.view bringSubviewToFront:self.ivLoading];
        
        //SongSlider
        songSlider.frame = CGRectMake(songSlider.frame.origin.x,
                                      songSlider.frame.origin.y - 159,
                                      songSlider.frame.size.width,
                                      songSlider.frame.size.height);
        //TracktimeBG
        buttonTracktimeBG.frame = CGRectMake(buttonTracktimeBG.frame.origin.x,
                                             buttonTracktimeBG.frame.origin.y - 159,
                                             buttonTracktimeBG.frame.size.width,
                                             buttonTracktimeBG.frame.size.height);
        //TimeLabel
        lbCurrentTime.frame = CGRectMake(lbCurrentTime.frame.origin.x,
                                         lbCurrentTime.frame.origin.y - 159,
                                         lbCurrentTime.frame.size.width,
                                         lbCurrentTime.frame.size.height);
        //ViewToolBox
        self.ViewToolBox.frame = CGRectMake(ViewToolBox.frame.origin.x,
                                            ViewToolBox.frame.origin.y - 160,
                                            ViewToolBox.frame.size.width,
                                            ViewToolBox.frame.size.height);
    }
    else {
        isFullScene = YES;
        [buttonScene setTitle:@"Original Scene" forState:UIControlStateNormal];
        [buttonScene setImage:[UIImage imageNamed:@"縮小小.png"] forState:UIControlStateNormal];
        [self hideSubviewTool:YES];
        [self HideTop:YES];
        
        //View
        if ((imageSrcTypeIdx ==  IMAGE_SOURCE_TYPE_USER_PHOTOS || imageSrcTypeIdx == IMAGE_SOURCE_TYPE_CAMERA) &&
            songType == SONG_TYPE_MP4)
        {
            if (isSwitchView) {
                if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
                    playerView.layer.frame = FullMainSize;
                } else {
                    playerView.layer.frame = FullSubSize;
                }
                imageForShow.frame = FullSubSize;
                self.subplayView.layer.frame = FullMainSize;
            } else {
                
                if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
                    playerView.layer.frame = FullSubSize;
                } else {
                    playerView.layer.frame = FullMainSize;
                }
                imageForShow.frame = FullMainSize;
                self.subplayView.layer.frame = FullSubSize;
            }
        } else {
            playerView.layer.frame = FullMainSize;
            imageForShow.frame = FullMainSize;
        }
        cameraPreviewLayer.frame = playerView.layer.bounds;
        if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_CAMERA) {
            playerLayer.frame = self.subplayView.layer.bounds;
        } else {
            playerLayer.frame = playerView.layer.bounds;
        }
        
        //ImageView
        self.ivLoading.frame = CGRectMake(self.ivLoading.frame.origin.x,
                                          self.ivLoading.frame.origin.y + 159,
                                          self.ivLoading.frame.size.width,
                                          self.ivLoading.frame.size.height);
        [self.view bringSubviewToFront:self.ivLoading];
        
        //SongSlider
        songSlider.frame = CGRectMake(songSlider.frame.origin.x,
                                      songSlider.frame.origin.y + 159,
                                      songSlider.frame.size.width,
                                      songSlider.frame.size.height);
        //TracktimeBG
        buttonTracktimeBG.frame = CGRectMake(buttonTracktimeBG.frame.origin.x,
                                             buttonTracktimeBG.frame.origin.y + 159,
                                             buttonTracktimeBG.frame.size.width,
                                             buttonTracktimeBG.frame.size.height);
        //TimeLabel
        lbCurrentTime.frame = CGRectMake(lbCurrentTime.frame.origin.x,
                                         lbCurrentTime.frame.origin.y + 159,
                                         lbCurrentTime.frame.size.width,
                                         lbCurrentTime.frame.size.height);
        //ViewToolBox
        self.ViewToolBox.frame = CGRectMake(ViewToolBox.frame.origin.x,
                                            ViewToolBox.frame.origin.y + 160,
                                            ViewToolBox.frame.size.width,
                                            ViewToolBox.frame.size.height);    }
    [UIView commitAnimations];
}
-(void)HideTop:(BOOL)BoolType {
    float Alphas;
    if (BoolType)
        Alphas=0;
    else
        Alphas=1;
    
    //    [switchCameraPosition setAlpha:Alphas];
    [lbRecording setAlpha:Alphas];
    [switchRecording setAlpha:Alphas];
}

- (IBAction)switchViewPressed:(id)sender
{
    if (curImageSrcIdx == IMAGE_SOURCE_TYPE_DEFAULT) {
        return;
    }
    
    if (isPickupView) {
        [self pickupViewPressed:nil];
    }
    
    CGRect SwitchSubSize;
    CGRect SwitchMainSize;
    
    if (isFullScene) {
        SwitchSubSize = FullSubSize;
        SwitchMainSize = FullMainSize;
        
    } else {
        SwitchSubSize = OriginalSubSize;
        SwitchMainSize = OriginalMainSize;
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    if (isSwitchView) {
        isSwitchView = NO;
        if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
            playerView.frame = SwitchSubSize;
        } else {
            playerView.frame = SwitchMainSize;
        }
        playerLayer.frame = playerView.layer.bounds;
        cameraPreviewLayer.frame = playerView.layer.bounds;
        self.subplayView.frame = SwitchSubSize;
        if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_CAMERA) {
            playerLayer.frame = self.subplayView.layer.bounds;}
        imageForShow.frame = SwitchMainSize;
        [self.view bringSubviewToFront:playerView];
        [self.view bringSubviewToFront:self.subplayView];
        [self.view bringSubviewToFront:self.ViewToolBox];
        [self.view bringSubviewToFront:self.ButtonPackupView];
    } else {
        isSwitchView = YES;
        if (curImageSrcIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
            playerView.frame = SwitchMainSize;
        } else {
            playerView.frame = SwitchSubSize;
        }
        playerLayer.frame = playerView.layer.bounds;
        cameraPreviewLayer.frame = playerView.layer.bounds;
        self.subplayView.frame = SwitchMainSize;
        if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_CAMERA) {
            playerLayer.frame = self.subplayView.layer.bounds;}
        imageForShow.frame = SwitchSubSize;
        [self.view bringSubviewToFront:playerView];
        [self.view bringSubviewToFront:imageForShow];
        [self.view bringSubviewToFront:self.ViewToolBox];
        [self.view bringSubviewToFront:self.ButtonPackupView];
    }
    [self BringToolToFront];
    [UIView commitAnimations];
}

- (IBAction)pickupViewPressed:(id)sender
{
    CGSize ScreenSize = [[UIScreen mainScreen] bounds].size;
    
    [UIView animateWithDuration:0.5 animations:^(void) {
        CGRect HideArrow;
        CGRect HideSubSize;
        CGRect PickupSubSize;
        CGRect PickupArrow;
        if (isFullScene)
        {
            PickupSubSize = FullSubSize;
            PickupArrow = FullLeftArrow;
            HideSubSize = CGRectMake(40, ScreenSize.height + 210, 140, 210);
            HideArrow = CGRectMake(40, ScreenSize.height + 210, self.ButtonPackupView.frame.size.width, self.ButtonPackupView.frame.size.height);
        }
        else
        {
            PickupSubSize = OriginalSubSize;
            PickupArrow = LeftArrow;
            HideSubSize = CGRectMake(-210, 110, 210, 140);
            HideArrow = CGRectMake(-210, 110, self.ButtonPackupView.frame.size.width, self.ButtonPackupView.frame.size.height);
        }
        
        
        if (isPickupView) {
            isPickupView = NO;
            self.ButtonPackupView.frame = PickupArrow;
            if (isSwitchView) {
                if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
                    imageForShow.frame = PickupSubSize;
                    imageForShow.alpha = 1;
                } else {
                    playerView.frame = PickupSubSize;
                    playerView.alpha = 1;
                }
            } else {
                if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
                    playerView.frame = PickupSubSize;
                    playerView.alpha = 1;
                }
                self.subplayView.frame = PickupSubSize;
                self.subplayView.alpha = 1;
            }
        } else {
            isPickupView = YES;
            self.ButtonPackupView.frame = HideArrow;
            if (isSwitchView) {
                if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
                    imageForShow.frame = HideSubSize;
                    imageForShow.alpha = 0;
                } else {
                    playerView.frame = HideSubSize;
                    playerView.alpha = 0;
                }
            } else {
                if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
                    playerView.frame = HideSubSize;
                    playerView.alpha = 0;
                }
                self.subplayView.frame = HideSubSize;
                self.subplayView.alpha = 0;
            }
        }
    }completion:^(BOOL finished){
        [UIView animateWithDuration:0.2 animations:^{
            if (isFullScene)
            {
                if (isPickupView) {
                    self.ButtonPackupView.frame = FullRightArrow;
                    [self.ButtonPackupView setImage:[UIImage imageNamed:@"右箭頭Icon.png"] forState:UIControlStateNormal];
                } else {
                    [self.ButtonPackupView setImage:[UIImage imageNamed:@"左箭頭Icon.png"] forState:UIControlStateNormal];
                }
            }
            else
            {
                if (isPickupView) {
                    self.ButtonPackupView.frame = RightArrow;
                    [self.ButtonPackupView setImage:[UIImage imageNamed:@"右箭頭Icon.png"] forState:UIControlStateNormal];
                } else {
                    [self.ButtonPackupView setImage:[UIImage imageNamed:@"左箭頭Icon.png"] forState:UIControlStateNormal];
                }
            }
            CATransition *transition = [CATransition animation];
            transition.duration = 0.5;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
            transition.type = kCATransitionFade;
            [self.ButtonPackupView.imageView.layer addAnimation:transition forKey:nil];
        } completion:^(BOOL finished) {
        }];
        
    }];
    
}

#pragma mark IBAction about hide for Volume/Vocal/Micorphone/Echo
- (IBAction)HidenVolume:(id)sender {
    //[UIView setAnimationsEnabled:YES];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    if (volumeSlider.alpha==0) {
        volumeSlider.alpha=1.0;
        //x=256.000000 y=627.000000 w=23.000000 h=41.000000
        volumeSlider.frame=CGRectMake(volumeSlider.frame.origin.x, volumeSlider.frame.origin.y-100, 23, 150);
        volumeSlider.backgroundColor=[UIColor colorWithRed:255/255.0 green:204/255.0 blue:102/255.0 alpha:1.0];
    }
    else {
        volumeSlider.alpha=0.0;
        volumeSlider.frame=CGRectMake(volumeSlider.frame.origin.x, volumeSlider.frame.origin.y+100, 23, 60);
        volumeSlider.backgroundColor=[UIColor clearColor];
    }
    [UIView commitAnimations];
    
    //[UIView setAnimationsEnabled:NO];
}
- (IBAction)HidenVocal:(id)sender {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    if (vocalSlider.alpha==0){
        vocalSlider.alpha=1.0;
        vocalSlider.frame=CGRectMake(vocalSlider.frame.origin.x, vocalSlider.frame.origin.y-100, 23, 150);
        vocalSlider.backgroundColor=[UIColor colorWithRed:255/255.0 green:204/255.0 blue:102/255.0 alpha:1.0];
    }
    else{
        vocalSlider.alpha=0.0;
        vocalSlider.frame=CGRectMake(vocalSlider.frame.origin.x, vocalSlider.frame.origin.y+100, 23, 60);
        vocalSlider.backgroundColor=[UIColor clearColor];
    }
    [UIView commitAnimations];
}
- (IBAction)HidenMicorphone:(id)sender {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    if (micVolumeSlider.alpha==0){
        micVolumeSlider.alpha=1.0;
        micVolumeSlider.frame=CGRectMake(micVolumeSlider.frame.origin.x, micVolumeSlider.frame.origin.y-100, 23, 150);
        micVolumeSlider.backgroundColor=[UIColor colorWithRed:255/255.0 green:204/255.0 blue:102/255.0 alpha:1.0];
    }
    else{
        micVolumeSlider.alpha=0.0;
        micVolumeSlider.frame=CGRectMake(micVolumeSlider.frame.origin.x, micVolumeSlider.frame.origin.y+100, 23, 60);
        micVolumeSlider.backgroundColor=[UIColor clearColor];
    }
    [UIView commitAnimations];
}
- (IBAction)HidenEcho:(id)sender {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    if (reverbSlider.alpha==0){
        reverbSlider.alpha=1.0;
        reverbSlider.frame=CGRectMake(reverbSlider.frame.origin.x, reverbSlider.frame.origin.y-100, 23, 150);
        reverbSlider.backgroundColor=[UIColor colorWithRed:255/255.0 green:204/255.0 blue:102/255.0 alpha:1.0];
    }
    else{
        reverbSlider.alpha=0.0;
        reverbSlider.frame=CGRectMake(reverbSlider.frame.origin.x, reverbSlider.frame.origin.y+100, 23, 60);
        reverbSlider.backgroundColor=[UIColor clearColor];
    }
    [UIView commitAnimations];
}
#pragma mark IBAction Other
- (IBAction)StopPlayer:(id)sender {
    if (isRecord) {
        [self toggleRecording:nil];
    } else {
        [self BackToMyDownload];
    }
}


#pragma mark ViewWillLoad
- (void)viewWillLoad {
    
}

#pragma mark ViewDidLoad
- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self.aryPlaylist count] > 0) {
        currentSongIndex = 0;
        PlayList *aSong = [self.aryPlaylist objectAtIndex:currentSongIndex];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL success = [fileManager fileExistsAtPath:aSong.SongPath];
        if(success)
            songUrl = [NSURL fileURLWithPath:aSong.SongPath];
        else
            songUrl = [NSURL URLWithString:aSong.SongPath];
        _Singer = aSong.Singer;
        _SongName = aSong.SongName;
    }
    //------------------------------------------------------
	// Do any additional setup after loading the view.

    // 1. Update title !!
    [self setNaviTitle:@"載入歌曲中 ..." withColor:[UIColor grayColor]] ;
    
    // 2. Disable the UI for avoiding ...
    self.view.userInteractionEnabled = NO;
    [self navigationController].view.userInteractionEnabled = NO;
    
    // 3. show the Activity Indicator for loading MP3/MP4.
    _viewProcessing.hidden = false;
    [loadingIndicator startAnimating];
    
    // 4. load background Image file
    grayImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"gray_background" ofType:@"jpg"]];
    
    // 5. Registery Notification !
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];
    //
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    // Wait for notification of ready of Media!
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioMediaReady:)
                                                 name:KOKSAudioMediaReadyNotification
                                               object:nil];
    // Loading the MEDIA in Background !!
    [self performSelectorInBackground:@selector(prepareMedia) withObject:nil];
    
    // default: located on the LEFT-SIDE !
    captureVideoOrientation = AVCaptureVideoOrientationPortrait;
    
    // default : the FRONT one !
    cameraPosition = AVCaptureDevicePositionBack;
    
    musicPitch = 0;
    
    videoList = [[NSMutableArray alloc]init];
    
    CGSize ScreenSize = [[UIScreen mainScreen] bounds].size;
    if (ScreenSize.height > 480) {
        // 4 inch
        OriginalMainSize = CGRectMake(0, 110, ScreenSize.width, 180);
        OriginalSubSize = CGRectMake(0, 110, 210, 140);
    } else {
        // 3.5 inch
        OriginalMainSize = CGRectMake(0, 110, ScreenSize.width, 180);
        OriginalSubSize = CGRectMake(0, 110, 210, 140);
    }
    FullMainSize = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    FullSubSize = CGRectMake(40, [[UIScreen mainScreen] bounds].size.height - 210, 140, 210);
    
    // Set Title
    LbSingerAndSongName.text = [NSString stringWithFormat:@"%@ - %@",_Singer,_SongName];
    
    // ExternalAccessory
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    
    // Setting SVSegementedControl
	ListSC = [[SVSegmentedControl alloc] initWithSectionTitles:[NSArray arrayWithObjects:@"", @"", @"",@"", nil]];
    [ListSC addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
	ListSC.sectionImages =[NSArray arrayWithObjects:[UIImage imageNamed:@"內建.png"], [UIImage imageNamed:@"圖片.png"],[UIImage imageNamed:@"影片.png"], [UIImage imageNamed:@"鏡頭.png"],nil];
	ListSC.crossFadeLabelsOnDrag = YES;
	ListSC.selectedIndex = 0;
    imageSrcTypeIdx = 0;
    ListSC.height = 45;
	[self.view addSubview:ListSC];
	ListSC.frame = CGRectMake(0, 310, ListSC.frame.size.width, ListSC.frame.size.height);
	ListSC.tag = 1;
    [ViewToolBox setBackgroundColor:[UIColor clearColor]];
    [ListSC bringSubviewToFront:playerView];
    [self.view bringSubviewToFront:songSlider];
    
    //Slider
    [songSlider setThumbImage:[UIImage imageNamed:@"配樂控制.png"] forState:UIControlStateNormal];
    [micVolumeSlider setThumbImage:[UIImage imageNamed:@"麥克風控制.png"] forState:UIControlStateNormal];
    [volumeSlider setThumbImage:[UIImage imageNamed:@"配樂控制.png"] forState:UIControlStateNormal];
    [vocalSlider setThumbImage:[UIImage imageNamed:@"原唱控制.png"] forState:UIControlStateNormal];
    
    // init
    database = [[SQLiteDBTool alloc] init];
    GlobalData *globalItem = [GlobalData getInstance];
    aSetting = [[Setting alloc]init];
    aSetting = [database getSettingWithUserID:globalItem.UserID];
    
    // 將預設值套入
    vocalSlider.value = [aSetting.Vocal floatValue];
    volumeSlider.value = [aSetting.Volume floatValue];
    micVolumeSlider.value = [aSetting.MicVolume floatValue];
    if ([aSetting.Echo isEqualToString:@"無"])//none
        [ButtonEchoNone setImage:[UIImage imageNamed:@"無02.png"] forState:UIControlStateNormal];
    else if ([aSetting.Echo isEqualToString:@"弱"])//low
        [ButtonEchoLow setImage:[UIImage imageNamed:@"弱02.png"] forState:UIControlStateNormal];
    else if ([aSetting.Echo isEqualToString:@"中"])//mid
        [ButtonEchoMid setImage:[UIImage imageNamed:@"中02.png"] forState:UIControlStateNormal];
    else if ([aSetting.Echo isEqualToString:@"強"])//high
        [ButtonEchoHigh setImage:[UIImage imageNamed:@"強02.png"] forState:UIControlStateNormal];
    else {//none
        [ButtonEchoNone setImage:[UIImage imageNamed:@"無02.png"] forState:UIControlStateNormal];
        aSetting.Echo = @"無";
    }
    
    // 隱藏箭頭大小設置
    RightArrow = CGRectMake(0, 110, self.ButtonPackupView.frame.size.width, self.ButtonPackupView.frame.size.height);
    if (ScreenSize.height > 480) {
        // 4 inch
        LeftArrow = CGRectMake(210, 110, self.ButtonPackupView.frame.size.width, self.ButtonPackupView.frame.size.height);
    } else {
        // 3.5 inch
        LeftArrow = CGRectMake(210, 110, self.ButtonPackupView.frame.size.width, self.ButtonPackupView.frame.size.height);
    }
    FullRightArrow = CGRectMake(40, ScreenSize.height - 30, self.ButtonPackupView.frame.size.height, self.ButtonPackupView.frame.size.width);
    FullLeftArrow = CGRectMake(40, [[UIScreen mainScreen] bounds].size.height - FullSubSize.size.height - self.ButtonPackupView.frame.size.width , self.ButtonPackupView.frame.size.height, self.ButtonPackupView.frame.size.width);
    
    // 監聽當按下Home鍵的時候
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationWillResign)
     name:UIApplicationWillResignActiveNotification
     object:NULL];
    
    // Loading的GIF動畫
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Loading3" withExtension:@"gif"];
    self.ivLoading.image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
    
    // 新增全螢幕標題
    imgTitle = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [imgTitle setImage:[UIImage imageNamed:@"標題列.png"]];
    [imgTitle setAlpha:0];
    [self.view addSubview:imgTitle];
    
    // 新增底層
    imgFullsceneBottom = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    imgFullsceneBottom.backgroundColor = [UIColor blackColor];
    [imgFullsceneBottom setAlpha:0];
    [self.view addSubview:imgFullsceneBottom];
    
    UIImageView *imageViewBG = [[UIImageView alloc] initWithFrame:FullMainSize];
    imageViewBG.backgroundColor = [UIColor blackColor];
    imageViewBG.alpha = 0;
    imageViewBG.tag = 101;
    [self.view addSubview:imageViewBG];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 偵測麥克風
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MicDeviceChecking) name:@"DeviceOnput!!" object:nil];
    // 偵測觸碰螢幕
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TouchFullSceneAndShowTool) name:@"ScreenTouch" object:nil];
}


- (void)applicationWillResign
{
    // 在儲存畫面則直接跳出此函式
    if (isSavingView) {
        return;
    }
    
    if (!isPause) {
        [self togglePlayPause:nil];
    }
    
    if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_CAMERA) {
        if (isRecord) {
            [self toggleRecording:nil];
            return;
        }
    }
    
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"訊息"
                                                 message:[NSString stringWithFormat:@"是否繼續歡唱"]
                                                delegate:self
                                       cancelButtonTitle:@"繼續歡唱"
                                       otherButtonTitles:nil];
    [alert show];
}

- (void)MicDeviceChecking
{
    if (!isPause) {
        [self togglePlayPause:nil];
    }
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"訊息"
                                                 message:[NSString stringWithFormat:@"發現外部裝置異動"]
                                                delegate:self
                                       cancelButtonTitle:@"了解，繼續歡唱"
                                       otherButtonTitles:nil];
    [alert show];
}

// Fired when the Audio Media is ready !
- (void) audioMediaReady:(NSNotification*)notification{
    // OK, now it's ready for playing.
    // We MUST dispatch the invocation(startPlayer) inside the MAIN_QUEUE !
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // --------
        imageSrcTypeIdx = -1;
        [self changeImageSource:nil];
        
        //
        songSlider.value = 0.0;
        
        //
        _viewProcessing.hidden = true;
        [loadingIndicator stopAnimating];
        [self.ivLoading setHidden:YES];
        //
        
        self.view.userInteractionEnabled = YES;
        [self navigationController].view.userInteractionEnabled = YES;
        isPause = NO;
        
        // Play now !!
        [self startPlayer];
        
        // Echo
        [self DefaultEcho];
        // Vocal
        [self doAdjustVocal:nil];
        // Volume
        [self doAdjustVolume:nil];
        // MicVolume
        [self doAdjustMicVolume:nil];
        
    });
}

- (void) deviceOrientationDidChange {
    // Keep track of current device orientation so it can be applied to movie recordings and still image captures
    AVCaptureVideoOrientation newOrientation = [self getCurrentVideoOrientation];
    if (captureVideoOrientation != newOrientation) {
        [cameraPreviewLayer setOrientation: newOrientation];
        captureVideoOrientation = newOrientation;
    }
}

- (void) setNaviTitle:(NSString *) title withColor:(UIColor *) color {
    self.navigationItem.title = title;
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:color forKey:UITextAttributeTextColor];
}

- (void) loadDefaultImagesForShow {
    
    if (imageList1 == nil)
        imageList1 = [[NSMutableArray alloc] init];
    else
        return;
    
    // Collect the images for showing ( format: image*.jpg / image*.gif / image*.png )
    NSArray *jpgFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:nil];
    for (int i=0; i<jpgFiles.count; i++) {
        NSString *f = [jpgFiles objectAtIndex:i];
        if ([[f lastPathComponent] hasPrefix:@"image"]) {
            NSLog(@"-->Image file for showing: %@", f);
            [imageList1 addObject:[UIImage imageWithContentsOfFile:f]];
        }
    }
    NSArray *gifFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"gif" inDirectory:nil];
    for (int i=0; i<gifFiles.count; i++) {
        NSString *f = [gifFiles objectAtIndex:i];
        if ([[f lastPathComponent] hasPrefix:@"image"]) {
            NSLog(@"-->Image file for showing: %@", f);
            [imageList1 addObject:[UIImage imageWithContentsOfFile:f]];
        }
    }
    NSArray *pngFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"png" inDirectory:nil];
    for (int i=0; i<pngFiles.count; i++) {
        NSString *f = [pngFiles objectAtIndex:i];
        if ([[f lastPathComponent] hasPrefix:@"image"]) {
            NSLog(@"-->Image file for showing: %@", f);
            [imageList1 addObject:[UIImage imageWithContentsOfFile:f]];
        }
    }
    //
    NSLog(@"Number of Image files(DEFAULT) for showing: %ld", imageList1.count);
}

- (void) playerItemDidReachedEnd:(NSNotification *)notification {
    
    NSLog(@"%@",notification.name);
    //20130502 Ricky
    if (isRecord &&
        [audioProcessor isEndOfMov]) {
        // in case recording, we need stop the recoding procedure !
        [self toggleRecording:nil];
        //        [buttonRecording setImage:[UIImage imageNamed:@"錄製.png"] forState:UIControlStateNormal];
        //        [buttonRecording setTitle:@"未錄製" forState:UIControlStateNormal];
        //        switchRecording.on = false;
    }
    else if ([audioProcessor isEndOfMov]) {
        // 1.
        // Update title !!
        [self setNaviTitle:@"播放完畢！" withColor:[UIColor grayColor]] ;
        
        if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS) {
            [userPlayer pause];
            [userPlayer seekToTime:kCMTimeZero];
        }
        else if (imageSrcTypeIdx != IMAGE_SOURCE_TYPE_USER_VIDEOS) {
            [defaultPlayer pause];
            [defaultPlayer seekToTime:kCMTimeZero];
        }
        // 2.
        [audioProcessor stopAUGraph];
        [self stopAnimating];
        [audioProcessor seekToTime:0.0f];
        
        // 3.
        currentSongIndex ++;
        if ([self.aryPlaylist count] > currentSongIndex) {
            PlayList *aSong = [self.aryPlaylist objectAtIndex:currentSongIndex];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL success = [fileManager fileExistsAtPath:aSong.SongPath];
            if(success)
                songUrl = [NSURL fileURLWithPath:aSong.SongPath];
            else
                songUrl = [NSURL URLWithString:aSong.SongPath];
            _SongName = aSong.SongName;
            _Singer = aSong.Singer;
            LbSingerAndSongName.text = [NSString stringWithFormat:@"%@ - %@",_Singer,_SongName];
            [self reloadMedia];
        } else if ([self.aryPlaylist count] > 0) {
            /*
            currentSongIndex = 0;
            PlayList *aSong = [self.aryPlaylist objectAtIndex:currentSongIndex];
            songUrl = [NSURL URLWithString:aSong.SongPath];
            _SongName = aSong.SongName;
            _Singer = aSong.Singer;
            LbSingerAndSongName.text = [NSString stringWithFormat:@"%@ - %@",_Singer,_SongName];
            [self reloadMedia];
             */
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            isPause = YES;
            //[startPauseButton setTitle:@"Play" forState:UIControlStateNormal];
            [startPauseButton setImage:[UIImage imageNamed:@"開始.png"] forState:UIControlStateNormal];
        }
        
    } else {
        //repeat player again !!
        [userPlayer pause];
        if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS) {
            static int videoListCount = 1;
            [self switchUserVideo:[videoList objectAtIndex:videoListCount % videoList.count]];
            videoListCount++;
        }
        [userPlayer seekToTime:kCMTimeZero];
        [userPlayer play];
    }
}


- (void) showAssetTrackInfo : (AVAsset *) asset {
    NSArray *tracks = [asset tracks];
    int i=1;
    for (AVAssetTrack *track in tracks) {
        NSLog( @"Track#%d: %@", i++, [track mediaType]);
    }
}


- (NSString *)secondToString : (double) current
{
    int h = ((int)current) / 3600;
    int m = ((int)current - h*3600) / 60;
    int s = ((int)current) % 60;
    NSString *ss = [NSString stringWithFormat:@"%02d:%02d", m, s];
    return ss;
}

- (void)switchImage {
    static NSArray *transitionTypeList=nil;
    static NSArray *subTypeList=nil;
    static int imageIdx = 1;
    // initialization
    if (transitionTypeList == nil) {
        transitionTypeList = [NSArray arrayWithObjects:
                              kCATransitionFade,
                              kCATransitionPush,
                              kCATransitionReveal,
                              kCATransitionMoveIn,
                              @"cube",
                              @"oglFlip",
                              @"pageCurl",
                              @"pageUnCurl",
                              @"rippleEffect",
                              @"suckEffect",
                              //@"cameraIrisHollowClose",
                              //@"cameraIrisHollowOpen",
                              nil];
        subTypeList = [NSArray arrayWithObjects:kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom, nil];
    }
    
    //
    if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_DEFAULT)
        [imageForShow setImage: [imageList1 objectAtIndex:(imageIdx%imageList1.count) ] ];
    else if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS)
        [imageForShow setImage: [imageList2 objectAtIndex:(imageIdx%imageList2.count) ] ];
    
    // next one !
    imageIdx++;
    
    // Randomly choose one of the selected animation !!
    CATransition *transition = [CATransition animation];
    transition.duration = 1.2f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    int typeId = arc4random()%transitionTypeList.count;
    transition.type = [transitionTypeList objectAtIndex: typeId];
    int subTypeId = arc4random()%subTypeList.count;
    transition.subtype = [subTypeList objectAtIndex: subTypeId];
    //NSLog(@"Transition Type Idx: %d(%d); subType: %d(%d)", typeId, transitionTypeList.count, subTypeId, subTypeList.count);
    [imageForShow.layer addAnimation:transition forKey:nil];
    
    /*
     // --------------------------------------------------------
     // Original model --> Apply the animation of UIImageView.
     // drawback : only SINGLE transition effect.
     // --------------------------------------------------------
     [imageForShow stopAnimating];
     if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_DEFAULT) {
     imageForShow.image = [imageList1 objectAtIndex:0];
     imageForShow.animationImages = imageList1;
     imageForShow.animationDuration = imageList1.count * 5.0;
     }
     else if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_PHOTOS) {
     imageForShow.image = [imageList2 objectAtIndex:0];
     imageForShow.animationImages = imageList2;
     imageForShow.animationDuration = imageList2.count * 5.0;
     }
     
     //
     imageForShow.animationRepeatCount = 0; // 0 = nonStop repeat
     
     //Create an animation with pulsating effect
     CABasicAnimation *theAnimation;
     //within the animation we will adjust the "opacity"
     //value of the layer
     theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
     //animation lasts 0.4 seconds
     theAnimation.duration=2.5;
     theAnimation.speed = 1.0;
     //and it repeats forever
     theAnimation.repeatCount= HUGE_VALF;
     //we want a reverse animation
     theAnimation.autoreverses=YES;
     //justify the opacity as you like (1=fully visible, 0=unvisible)
     theAnimation.fromValue=[NSNumber numberWithFloat:0.0];
     theAnimation.toValue=[NSNumber numberWithFloat:1.5];
     //Assign the animation to your UIImage layer and the
     //animation will start immediately
     [imageForShow.layer addAnimation:theAnimation forKey:@"animateOpacity"];
     
     */
}

-(void) stopAnimating {
    //[imageForShow stopAnimating];
}

-(void) startAnimating{
    //[imageForShow startAnimating];
}

- (void)updateSlider
{
    //
    if (audioProcessor.isPlaying == NO) return;
    
    // Step.1 Check if reaching the end of music ?
    if ([audioProcessor isEndOfMusic]) {
        [self playerItemDidReachedEnd:nil];
    }
    //
    
    // Step.2 Update Images/Photos for showing periodly
    // Method (A)
    static NSDate *preTime;
    if (preTime == nil) preTime = [NSDate date];
    
    // -------- for MP3(Default)/User-selected Images !!
    if (imageForShow.hidden == NO && audioProcessor.isPlaying ) {
        // switch image every 5 seconds!
        NSTimeInterval passedTime =  - [preTime timeIntervalSinceNow];
        if ( passedTime >= 5.0 ) {
            preTime = [NSDate date];
            [self switchImage];
        }
    }
    
    /*
     // Method (B)
     // -- utilize the UIImageView animation !
     // check animation status !!
     if (imageForShow.hidden == YES)
     [self stopAnimating];
     else if ( [imageForShow isAnimating] == NO) {
     [self startAnimating];
     }
     */
    // ----------------------------------------------------------------
    
    // step.3 Update slider and playing-time labels
    // update Slider
    // double current = CMTimeGetSeconds(player.currentTime);
    Float64 current = [audioProcessor currentTime];
    
    // NSLog (@"Update slider: %f; currentTime=%f; duration=%f; imageIdx=%d", songSlider.value, current, duration, imageIdx);
    
    [songSlider setValue:current/musicDuration];
    NSString *currentStr = [self secondToString:current];
    [lbCurrentTime setText:currentStr];
    NSString *leftStr = [self secondToString:musicDuration-current];
    [lbLeftTime setText:leftStr];
}

- (IBAction)songSliderValueChanged:(id)sender {
    //
    Float64 current = (Float64)songSlider.value * musicDuration;
    // NSLog (@"Move slider to: %f; current Time=%f; music duration=%f", songSlider.value, current, musicDuration);
    // [player seekToTime:CMTimeMakeWithSeconds(current, 600 )];
    // [audioProcessor seekToTime:CMTimeGetSeconds(player.currentTime)];
    [audioProcessor seekToTime:current];
    [self syncPlayerWithMusicPosition];
    
    NSString *currentStr = [self secondToString:current];
    [lbCurrentTime setText:currentStr];
    NSString *leftStr = [self secondToString:musicDuration-current];
    [lbLeftTime setText:leftStr];
}

- (IBAction)songSliderTouchUp:(id)sender {
    if (!isPause) {
        if (defaultPlayer != nil) [defaultPlayer play];
        if (userPlayer != nil) [userPlayer play];
    }
}

- (IBAction)songSliderTouchDown:(id)sender {
    if (isPause) {
        if (defaultPlayer != nil) [defaultPlayer pause];
        if (userPlayer != nil) [userPlayer pause];
    }
}


- (void) startPlayer{
    // resume timer to update the slider !!
    if (sliderTimer.isValid == NO) {
        sliderTimer =[NSTimer scheduledTimerWithTimeInterval:0.05
                                                      target:self
                                                    selector:@selector (updateSlider)
                                                    userInfo:nil
                                                     repeats:YES];
    }
    
    // [self setupAudioProcessor: nil];
    [audioProcessor startAUGraph];
    //[self startAnimating];
    //
    if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS)
        [userPlayer play];
    else
        [defaultPlayer play];
    // Update title !!
    [self setNaviTitle:@"播放歌曲中 ..." withColor:[UIColor grayColor]] ;
    isPause = NO;
    //[startPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    [startPauseButton setImage:[UIImage imageNamed:@"暫停.png"] forState:UIControlStateNormal];
    
    [self setPlayerVolume:0.000001f];  // turn off audio of AVPlayer(MP3/MP4)!!
    //[audioProcessor seekToTime:CMTimeGetSeconds(player.currentTime)]; // sync both video & audio !!
    //        2013/04/23
    //        [self syncPlayerWithMusicPosition];
}

- (void) stopPlayer {
    [sliderTimer invalidate];
    if (imageSrcTypeIdx == IMAGE_SOURCE_TYPE_USER_VIDEOS)
        [userPlayer pause];
    else
        [defaultPlayer pause];
    //
    // Update title !!
    [self setNaviTitle:@"暫停播放！！" withColor:[UIColor grayColor]] ;
    isPause = YES;
    //[startPauseButton setTitle:@"Play" forState:UIControlStateNormal];
    [startPauseButton setImage:[UIImage imageNamed:@"開始.png"] forState:UIControlStateNormal];
    
    [audioProcessor stopAUGraph];
    //[self stopAnimating];
    needResume = true;
}


- (void)viewWillAppear:(BOOL)animated {
    if (!isPause && !audioProcessor.isPlaying) {
        [self startPlayer];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    aSetting.MicVolume = [NSString stringWithFormat:@"%f",micVolumeSlider.value];
    aSetting.Volume = [NSString stringWithFormat:@"%f",volumeSlider.value];
    aSetting.Vocal = [NSString stringWithFormat:@"%f",vocalSlider.value];
    [database updateSettingSingingDefaultWithUserID:aSetting];
    // 移除偵測麥克風
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DeviceOnput!!" object:nil];
    // 移除偵測麥觸碰
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ScreenTouch!!" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    if (isPause) {
        [self stopPlayer];
    }
    
    if (isELCImagePicker) {
        return;
    }
    
    //
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: KOKSAudioObjectPlaybackStateDidChangeNotification
                                                  object: audioProcessor];
    //
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    // 移除當按下Home鍵的監聽
    [[NSNotificationCenter defaultCenter] removeObserver: self name:UIApplicationWillResignActiveNotification object:NULL];
    //
    
    // Remove Notification !
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KOKSAudioMediaReadyNotification object:nil];
    
    // Remove ExternalAccessory
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidDisconnectNotification object:nil];
    
    if (captureMovieURL != nil)
        [captureSession removeOutput:movieFileOutput];
    //
    [sliderTimer invalidate];
    if (playerLayer != nil)
        [playerLayer removeFromSuperlayer];
    if (cameraPreviewLayer != nil)
        [cameraPreviewLayer removeFromSuperlayer];
    if (userVideoLayer)
        [userVideoLayer removeFromSuperlayer];
    //
    composition = nil;
    //
    [audioProcessor releaseAudioBuffer];
    audioProcessor = nil;
    //
    sliderTimer = nil;
    defaultPlayer = nil;
    userPlayer = nil;
    grayImage = nil;
    //
    //*******
}

- (void)viewWillUnload
{
    [super viewDidUnload];
    //
    NSLog(@"VIEW DID UNLOAD!");
    
    //
    [self setPlayerView:nil];
    [self setSwitchVocal:nil];
    [self setStartPauseButton:nil];
    [self setNoVideoLabel:nil];
    [self setSongSlider:nil];
    [self setLbCurrentTime:nil];
    [self setLbLeftTime:nil];
    [self setImageForShow:nil];
    [self setSegImageSource:nil];
    [self setVolumeSlider:nil];
    
    //
    [self setVocalSlider:nil];
    [self setReverbSlider:nil];
    [self setEchoSlider:nil];
    [self setLbVideoSource:nil];
    [self setLoadingIndicator:nil];
    [self setSwitchRecording:nil];
    [self setSwitchVocal:nil];
    [self setMicVolumeSlider:nil];
    
    // Release any retained subviews of the main view.
}

- (void) didReceiveMemoryWarning {
    
}

- (void) dealloc
{
    
}

- (IBAction)togglePlayPause:(id)sender {
    if (!isPause) {
        [self stopPlayer];
        
        [self stopAnimating];
        
	} else {
        
        [self startPlayer];
        
        [self startAnimating];
	}
}

//20140915
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    
//    if (interfaceOrientation == UIInterfaceOrientationLandscapeRight || interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
//        return true;
//        
//    }
//    else {
//        return false;
//    }
//}
//
//- (BOOL)shouldAutorotate {
//    return NO; // 禁止轉動
//}
//
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    return UIInterfaceOrientationLandscapeRight; // 固定右倒
//}

- (void)reloadMedia
{
    asset = nil;
    _viewProcessing.hidden = false;
    [loadingIndicator startAnimating];
    [self.ivLoading setHidden:NO];
    self.view.userInteractionEnabled = NO;
    [self navigationController].view.userInteractionEnabled = NO;
    grayImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"gray_background" ofType:@"jpg"]];
    isPause = NO;
    //[startPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    [startPauseButton setImage:[UIImage imageNamed:@"暫停.png"] forState:UIControlStateNormal];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KOKSAudioObjectPlaybackStateDidChangeNotification object:audioProcessor];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:[defaultPlayer currentItem]];
    [audioProcessor releaseAudioBuffer];
    // Loading the MEDIA in Background !!
    [self performSelector:@selector(prepareMedia) withObject:nil afterDelay:1];
}

- (void)hideSubviewTool:(BOOL)isHiden
{
    self.buttonSwitchview.hidden = isHiden;
    self.ButtonPackupView.hidden = isHiden;
}

- (void)viewDidUnload {
    [self setViewProcessing:nil];
    [self setSwitchCameraPosition:nil];
    [self setButtonFullScene:nil];
    [self setLbRecording:nil];
    [self setLbVocal:nil];
    [self setLbVocal:nil];
    [self setButtonVlume:nil];
    [self setLbMicVolume:nil];
    [self setLbMicVolume:nil];
    [self setLbReverb:nil];
    [self setLbVideoSourceTittle:nil];
    [self setButtonVocal:nil];
    [self setButtonMicVolume:nil];
    [self setButtonReverb:nil];
    [self setLbPitchAdjust:nil];
    [self setLbMusic:nil];
    [self setLbVoice:nil];
    [self setLbSingerAndSongName:nil];
    [self setViewToolBox:nil];
    [self setButtonScene:nil];
    [self setButtonTracktimeBG:nil];
    [self setButtonRecording:nil];
    [self setButtonCameraPosition:nil];
    [self setButtonAddPitch:nil];
    [self setButtonDecPitch:nil];
    [self setButtonEchoNone:nil];
    [self setButtonEchoLow:nil];
    [self setButtonEchoMid:nil];
    [self setButtonEchoHigh:nil];
    [self setButtonNoiseReduction:nil];
    [super viewDidUnload];
}

#pragma mark -
#pragma mark MJSecondPopupDelegateDelegate
- (void)GiveupSavingButtonClicked:(SaveAlertViewController*)secondDetailViewController
{
    [self DoneSaving];
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)retrySingingButtonClicked:(SaveAlertViewController*)secondDetailViewController
{
    [self retrySinging];
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)DoneAVMixandGetProductPath:(NSString*)productPath
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView commitAnimations];
}
- (void)SavingDone
{
    
}



@end
