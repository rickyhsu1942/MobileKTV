//
//  ProductPlayerViewController.h
//  carolAPPs
//
//  Created by iscom on 13/3/8.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "KOKSMixerHostAudio.h"

#define SONG_TYPE_MP3                       0
#define SONG_TYPE_MP4                       1

@interface ProductPlayerViewController : UIViewController
{
    NSURL *SongUrl;
    AVMutableComposition *composition;
    int     songType;       // 0 : mp3; 1: mp4
    AVPlayerItem                  *defaultPlayerItem;   // The Original movie
    Float32 musicDuration;
    Float32 current;
    KOKSMixerHostAudio *audioProcessor;
}

@property (strong,nonatomic) NSURL *SongUrl;
@property (nonatomic, strong) AVPlayer *defaultPlayer;
@property (nonatomic, strong) KOKSMixerHostAudio *audioProcessor;
@property (strong,nonatomic) NSString *strTitle;

@end
