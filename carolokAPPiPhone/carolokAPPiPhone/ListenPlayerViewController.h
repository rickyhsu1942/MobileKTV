//
//  ListenPlayerViewController.h
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/30.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define SONG_TYPE_MP3                       0
#define SONG_TYPE_MP4                       1


@protocol MJSecondPopupDelegate;
@interface ListenPlayerViewController : UIViewController
{
    NSURL *SongUrl;
    AVMutableComposition *composition;
    int     songType;       // 0 : mp3; 1: mp4
    AVPlayerItem                  *defaultPlayerItem;   // The Original movie
    Float32 musicDuration;
    Float32 current;
}

@property (strong,nonatomic) NSURL *SongUrl;
@property (nonatomic, strong) AVPlayer *defaultPlayer;
@property (assign, nonatomic) id <MJSecondPopupDelegate>delegate;
@end

@protocol MJSecondPopupDelegate<NSObject>
@optional
- (void)dismissListenView:(ListenPlayerViewController*)secondDetailViewController;
@end