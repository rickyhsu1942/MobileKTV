//
//  ListenPlayerViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/30.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

//-----View-----
#import "ListenPlayerViewController.h"

@interface ListenPlayerViewController ()
{
    BOOL isPause;
    NSTimer *MusicTimer;
}
@property (weak, nonatomic) IBOutlet UISlider *SliderTracktime;
@property (weak, nonatomic) IBOutlet UILabel *LbTracktime;
@property (weak, nonatomic) IBOutlet UIView *ViewPlayer;
@property (weak, nonatomic) IBOutlet UIImageView *ImageViewWave;
@property (weak, nonatomic) IBOutlet UIButton *ButtonPlay;

@end

@implementation ListenPlayerViewController
@synthesize SongUrl;
@synthesize defaultPlayer;
@synthesize SliderTracktime;
@synthesize LbTracktime;
@synthesize ViewPlayer;
@synthesize ImageViewWave;
@synthesize ButtonPlay;


#pragma mark -
#pragma mark IBAction
- (IBAction)PlayAndPauseMusic:(id)sender {
    if (isPause) {
        [ButtonPlay setTitle:@"Pause" forState:UIControlStateNormal];
        [ButtonPlay setImage:[UIImage imageNamed:@"暫停灰底.png"] forState:UIControlStateNormal];
        MusicTimer=[NSTimer scheduledTimerWithTimeInterval:.05 target:self selector:@selector(upDateMusicTime) userInfo:nil repeats:YES];
        isPause = NO;
        [defaultPlayer play];
    }
    else if (!isPause) {
        [ButtonPlay setTitle:@"Play" forState:UIControlStateNormal];
        [ButtonPlay setImage:[UIImage imageNamed:@"播放灰底.png"] forState:UIControlStateNormal];
        isPause = YES;
        [defaultPlayer pause];
    }
}

- (IBAction)StopMusic:(id)sender {
    [self MusicStop];
    [MusicTimer invalidate];
    MusicTimer=nil;
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissListenView:)]) {
        [self.delegate dismissListenView:self];
    }
}

- (IBAction)TracktimeBegin:(id)sender {
    [defaultPlayer pause];
}

- (IBAction)TracktimeChanged:(id)sender {
    CMTime newTime = CMTimeMakeWithSeconds(SliderTracktime.value * musicDuration, defaultPlayer.currentTime.timescale);
    [self.defaultPlayer seekToTime:newTime];
}

- (IBAction)TracktimeEnd:(id)sender {
    [defaultPlayer play];
}

#pragma mark -
#pragma mark Subcode Media
-(void)prepareMedia {
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:SongUrl options:nil];
    
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
    
    defaultPlayerItem = [AVPlayerItem playerItemWithAsset:sourceAsset];
    defaultPlayer = [AVPlayer playerWithPlayerItem:defaultPlayerItem];
    
    if (songType==1) {
        [ViewPlayer setHidden:NO];
        [ImageViewWave setHidden:YES];
        [ViewPlayer setBackgroundColor:[UIColor blackColor]];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:defaultPlayer];
        playerLayer.frame = ViewPlayer.layer.bounds;
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [ViewPlayer.layer addSublayer:playerLayer];
    }
    else
    {
        [ViewPlayer setHidden:YES];
        [ImageViewWave setHidden:NO];
        //        [_ImageviewNotvedio setImage:[UIImage imageNamed:@"image01.jpg"]];
        [ImageViewWave setImage:[UIImage imageNamed:@"影音播放頁面-default畫面.jpg"]];
        
    }
    
    
    AVPlayerItem *item = [defaultPlayer currentItem];
	musicDuration = CMTimeGetSeconds([item duration]);
    
    NSLog (@"playing %@", SongUrl);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self PlayAndPauseMusic:nil];
    });
    
}

- (void) showAssetTrackInfo : (AVAsset *) asset {
    NSArray *tracks = [asset tracks];
    int i=1;
    for (AVAssetTrack *track in tracks) {
        NSLog( @"Track#%d: %@", i++, [track mediaType]);
    }
}


-(void)upDateMusicTime {
    current = CMTimeGetSeconds([[defaultPlayer currentItem] currentTime]);
    SliderTracktime.value=current/musicDuration;
    LbTracktime.text = [self secondToString:current];
    if (current >= musicDuration)
        [self MusicStop];
}

-(void)MusicStop {
    CMTime StopTime = CMTimeMakeWithSeconds(0, defaultPlayer.currentTime.timescale);
    [self.defaultPlayer seekToTime:StopTime];
    SliderTracktime.value=0;
    isPause = YES;
    [defaultPlayer pause];
    [ButtonPlay setTitle:@"Play" forState:UIControlStateNormal];
    [ButtonPlay setImage:[UIImage imageNamed:@"播放灰底.png"] forState:UIControlStateNormal];
}

- (NSString *)secondToString:(double) currents
{
    int h = ((int)currents) / 3600;
    int m = ((int)currents - h*3600) / 60;
    int s = ((int)currents) % 60;
    NSString *ss = [NSString stringWithFormat:@"%02d:%02d", m, s];
    return ss;
}

- (void)applicationWillResign {
    // 發現裝置異動時先暫停歌曲
    if (!isPause) {
        [self PlayAndPauseMusic:nil];
    }
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"訊息"
                                                 message:[NSString stringWithFormat:@"偵測跳出App，是否繼續播放"]
                                                delegate:self
                                       cancelButtonTitle:@"繼續播放"
                                       otherButtonTitles:nil];
    [alert show];
}

- (void)MicDeviceChecking
{
    // 發現裝置異動時先暫停歌曲
    if (!isPause) {
        [self PlayAndPauseMusic:nil];
    }
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"訊息"
                                                 message:[NSString stringWithFormat:@"發現外部裝置異動"]
                                                delegate:self
                                       cancelButtonTitle:@"了解，繼續播放"
                                       otherButtonTitles:nil];
    [alert show];
}

#pragma mark -
#pragma mark viewDidLoad
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareMedia];
    isPause = YES;
    
    //設定邊框粗細
    [[self.ImageViewWave layer] setBorderWidth:2.0];
    [[self.ViewPlayer layer] setBorderWidth:2.0];
    //邊框顏色
    [[self.ImageViewWave layer] setBorderColor:[UIColor colorWithRed:0.7 green:0.7 blue:255 alpha:0.2].CGColor];
    //將超出邊框的部份做遮罩
    [[self.ImageViewWave layer] setMasksToBounds:YES];
    [[self.ViewPlayer layer] setMasksToBounds:YES];
    //設定圓角程度
    [[self.ImageViewWave layer] setCornerRadius:30.0];
    [[self.ViewPlayer layer] setCornerRadius:30.0];
    
    // 監聽當按下Home鍵的時候
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationWillResign)
     name:UIApplicationWillResignActiveNotification
     object:NULL];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 偵測麥克風
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(MicDeviceChecking)
     name:@"DeviceOnput!!"
     object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // 移除偵測麥克風
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DeviceOnput!!" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    // 移除當按下Home鍵的監聽
    [[NSNotificationCenter defaultCenter] removeObserver: self name:UIApplicationWillResignActiveNotification object:NULL];
}

- (void)viewDidUnload {
    [self setSliderTracktime:nil];
    [self setLbTracktime:nil];
    [self setViewPlayer:nil];
    [self setImageViewWave:nil];
    [self setButtonPlay:nil];
    [super viewDidUnload];
}

#pragma mark -
#pragma mark AlertDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        if ([[[alertView buttonTitleAtIndex:buttonIndex] substringFromIndex:[alertView buttonTitleAtIndex:buttonIndex].length - 4]  compare:@"繼續播放"]==NSOrderedSame) {
            if (isPause) {
                [self PlayAndPauseMusic:nil];
            }
        }
    }
}


@end
