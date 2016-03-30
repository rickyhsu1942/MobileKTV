//
//  KOKSAVMixer.h
//  TrySinging
//
//  Created by 國立中興大學 資訊工程學系 國立中興大學 資訊工程學系 on 12/11/4.
//
//

#import <AVFoundation/AVFoundation.h>
#import <CoreText/CoreText.h>

typedef enum {
	TransitionTypeNone,
	TransitionTypeCrossFade,
	TransitionTypePush
} TransitionType;

@interface KOKSAVMixer : NSObject
{
    AVMutableComposition *outputComposition;
    AVMutableComposition *previewComposition;
    AVMutableVideoComposition *videoComposition;
    AVMutableVideoComposition *videoComposition4Export;
    AVPlayerItem        *playerItem;
    AVMutableAudioMix   *audioMix;
    AVSynchronizedLayer *synchronizedLayer;
    AVAsset         *audioAsset;
    //
    NSString        *title;
    UInt32          titleFontSize;
    CALayer         *animatedTitleLayer;
    CATextLayer     *titleLayer;
    //
    CMTime          transitionDuration;
    TransitionType  transitionType;
    //
    UIImage         *grayImage;
    BOOL            movieIsReady;
    CGSize          videoSize;
    //
    Float32         titleShowDuration;
}

@property     AVMutableComposition      *outputComposition;
@property     AVMutableComposition      *previewComposition;
@property     AVMutableVideoComposition *videoComposition;
@property     AVMutableVideoComposition *videoComposition4Export;
@property     AVPlayerItem              *playerItem;
@property     AVMutableAudioMix         *audioMix;
@property     AVSynchronizedLayer       *synchronizedLayer;
@property     CMTime                    transitionDuration;
@property     TransitionType            transitionType;
@property     float                     TitlecolorRed;
@property     float                     TitlecolorGreen;
@property     float                     TitlecolorBlue;

- (id) initWithVideoSize:(CGSize)videoSize;
- (void) setMovieNotReady;
- (BOOL) isMovieReadyForPlay;
- (CALayer *) getTitleLayerForVideoSize:(CGSize)curSize forOutput:(Boolean)forOutput;
- (void) setTitle:(NSString *)title withSize:(UInt32)size withShowDuration:(Float32) duration;
- (void) resetAVComposition;
- (AVMutableComposition *) prepareAVCompositionforPlayback:(BOOL)forPlayback forVideoSize:(CGSize)currentSize withAudio:(NSArray *)selectedAudioFiles withPhotos:(NSArray *)imageList showTime:(Float32)picShowTime withVideos:(NSArray *)videoList;
- (NSString *) productMovieFromUIImages:(NSArray *)imageList withWholeDuration:(Float32)duration withPresentationTimer:(int)stepTimer;
- (NSError *) writeImagesAsMovie:(NSArray *)imageList toPath:(NSString*)path  waitingSeconds:(Float32)waitingSeconds withDuration:(Float64)duration;
//
// ------ adopted from AVEditDemo in WWDC 2010 demo
// The synchronized layer contains a layer tree which is synchronized with the provided player item.
// Inside the layer tree there is a playerLayer along with other layers related to titling.
- (void)getPlayerItem:(AVPlayerItem**)playerItemOut andSynchronizedLayer:(AVSynchronizedLayer**)synchronizedLayerOut;
- (AVAssetImageGenerator*)assetImageGenerator;
- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName;

@end
