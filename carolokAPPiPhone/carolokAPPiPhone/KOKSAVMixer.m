//
//  KOKSAVMixer.m
//  TrySinging
//
//  Created by 國立中興大學 資訊工程學系 國立中興大學 資訊工程學系 on 12/11/4.
//
//

#import "KOKSAVMixer.h"

@interface KOKSAVMixer ()
@end

@implementation KOKSAVMixer
@synthesize outputComposition;
@synthesize previewComposition;
@synthesize videoComposition;
@synthesize videoComposition4Export;
@synthesize transitionDuration;
@synthesize transitionType;
@synthesize playerItem;
@synthesize audioMix;
@synthesize synchronizedLayer;

- (id)init
{
    self = [super init];
    
    if (!self) return nil;
    //
    CGSize defaultSize = {1024, 768};
    titleShowDuration = 5;
    titleFontSize = 80;                // default size
    //
    return [self initWithVideoSize:defaultSize];
}

- (id)initWithVideoSize:(CGSize)size;
{
    self = [super init];
    if (!self) return nil;
    //
    videoSize = size;
    [self setTitle:@"測試影音合成標題文字" withSize:titleFontSize withShowDuration:titleShowDuration];
    grayImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"gray_background" ofType:@"jpg"]];
    transitionType = TransitionTypePush;
    transitionDuration = CMTimeMake(3, 1);
    //
    return self;
}

- (void) dealloc {
    grayImage = nil;
}

- (void) resetAVComposition {
    previewComposition = nil;
    outputComposition = nil;
}

- (void)buildPassThroughVideoComposition:(AVMutableVideoComposition *)curVideoComposition forComposition:(AVMutableComposition *)composition withVideoSize:(CGSize)currentSize
{
	// Make a "pass through video track" video composition.
	AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
	
	AVAssetTrack *videoTrack = [[composition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
	AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
	passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
	curVideoComposition.instructions = [NSArray arrayWithObject:passThroughInstruction];
}


- (AVMutableComposition *) prepareAVCompositionforPlayback:(BOOL)forPlayback forVideoSize:(CGSize)currentSize withAudio:(NSArray *)selectedAudioFiles withPhotos:(NSArray *)imageList showTime:(Float32)picShowTime withVideos:(NSArray *)videoList
{
    
    // 1. Prepare the AVMutalbeComposition
    AVMutableComposition      *tmpAVComposition = [AVMutableComposition composition];
    tmpAVComposition.naturalSize = currentSize;
    //
    AVMutableVideoComposition *tmpVideoComposition = [AVMutableVideoComposition videoComposition];
    tmpVideoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
    tmpVideoComposition.renderSize = currentSize;
    
    // 2. Insert Audio AVAsset
    NSError *error;
    NSURL *audioFileURL = [selectedAudioFiles objectAtIndex:0];
    NSLog( @"Audio File: %@", audioFileURL);
    audioAsset = [AVAsset assetWithURL:audioFileURL];
    //
    CMTime beginTime = kCMTimeZero;
    CMTime endTime =  audioAsset.duration;
    CMTime duration = CMTimeSubtract( endTime, beginTime);
    Float32 wholeDuration = CMTimeGetSeconds(duration);
    //
    CMTimeRange editRange = CMTimeRangeMake( beginTime, duration);
    
    AVAssetTrack* audioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVMutableCompositionTrack *compositionAudioTrack = [tmpAVComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [compositionAudioTrack insertTimeRange:editRange
                                   ofTrack:audioTrack
                                    atTime:kCMTimeZero
                                     error:&error];
    if (error != nil) {
        NSLog(@"Error to insert Audio to AV-composition: %@", error);
        return nil;
    }
    
    // 3-1. show Image-Slider !
    if ( imageList != nil ) {
        
        // Save JPGs to be a movie file
        NSString *moviePath = [self productMovieFromUIImages:imageList withWholeDuration:wholeDuration withPresentationTimer:picShowTime];
        
        // setup the AVMutableComposition
        NSURL *jpgMovieURL = [NSURL fileURLWithPath:moviePath];
        AVURLAsset *videoAsset = [AVAsset assetWithURL:jpgMovieURL];
        AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        AVMutableCompositionTrack *compositionVideoTrack1 = [tmpAVComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *compositionVideoTrack2 = [tmpAVComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [compositionVideoTrack1 insertTimeRange:editRange
                                        ofTrack: [[[AVAsset assetWithURL:jpgMovieURL] tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                         atTime: kCMTimeZero
                                          error:&error];
        if (error != nil) {
            NSLog(@"Error to insert JPGs/Video to final AVComposition for Transition Effect(1): %@", error);
        }
        else {
            NSLog(@"Merging JPGs/Video Successfully for Transition Effect(1)");
        }
        //
        [compositionVideoTrack2 insertTimeRange:editRange
                                        ofTrack: [[[AVAsset assetWithURL:jpgMovieURL] tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                         atTime: kCMTimeZero
                                          error:&error];
        if (error != nil) {
            NSLog(@"Error to insert JPGs/Video to final AVComposition for Transition Effect(2): %@", error);
        }
        else {
            NSLog(@"Merging JPGs/Video Successfully for Transition Effect(2)");
        }
        
        // 0. Compute the scaling parameters: for Scaling different-sized Videos
        CGFloat assetScaleToFitRatio;
        CGFloat ox=0, oy=0;
        //
        UIImageOrientation assetOrientation_ = UIImageOrientationUp;
        BOOL isAssetPortrait_ = NO;
        CGAffineTransform transform = videoAssetTrack.preferredTransform;
        if(transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0) {assetOrientation_= UIImageOrientationRight; isAssetPortrait_ = YES;}
        if(transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0) {assetOrientation_ =  UIImageOrientationLeft; isAssetPortrait_ = YES;}
        if(transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0)  {assetOrientation_ =  UIImageOrientationUp;}
        if(transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0) {assetOrientation_ = UIImageOrientationDown;}
        //
        CGFloat wRatio, hRatio;
        if (isAssetPortrait_) {
            wRatio = currentSize.width / videoAssetTrack.naturalSize.height;
            hRatio = currentSize.height / videoAssetTrack.naturalSize.width;
        }
        else {
            wRatio = currentSize.width / videoAssetTrack.naturalSize.width;
            hRatio = currentSize.height / videoAssetTrack.naturalSize.height;
        }
        //
        ox=0, oy=0;
        if (wRatio > hRatio){
            assetScaleToFitRatio = hRatio;
            if (isAssetPortrait_)
                ox = ( currentSize.width - videoAssetTrack.naturalSize.height*hRatio)/2;
            else
                ox = ( currentSize.width - videoAssetTrack.naturalSize.width*hRatio)/2;
        }
        else {
            assetScaleToFitRatio = wRatio;
            if (isAssetPortrait_)
                oy = ( currentSize.height - videoAssetTrack.naturalSize.width*wRatio)/2;
            else
                oy = ( currentSize.height - videoAssetTrack.naturalSize.height*wRatio)/2;
        }
        
        //
        //
        NSMutableArray *fullVideoInstructions = [NSMutableArray array];
        double curPosSeconds = 0.000001f;
        int pictureCounter=0;
        
        // 1. Scaling + Transition
        CMTime transitionSecond = CMTimeMakeWithSeconds( 1, 600);
        if ( picShowTime/2 < 1)
            transitionSecond = CMTimeMakeWithSeconds( picShowTime/2, 600);
        //
        while ( wholeDuration > curPosSeconds) {
            CMTime curPos = CMTimeMakeWithSeconds(curPosSeconds, 600);
            //
            if (curPosSeconds+picShowTime < wholeDuration)
                editRange = CMTimeRangeFromTimeToTime( curPos, CMTimeMakeWithSeconds(  curPosSeconds+picShowTime,600));
            else
                editRange = CMTimeRangeFromTimeToTime( curPos, CMTimeMakeWithSeconds(  wholeDuration,600));
            //
            
            // 1.1 Scaling
            // AVMutableVideoCompositionInstruction *scalingInstructions = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            // scalingInstructions.timeRange = editRange;
            AVMutableVideoCompositionLayerInstruction *theLayerInstruction;
            if (pictureCounter%2==0) {
                theLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack1];
            }else {
                theLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack2];
            }
            //
            CGAffineTransform assetScaleFactor = CGAffineTransformMakeScale( assetScaleToFitRatio, assetScaleToFitRatio);
            [theLayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(videoAssetTrack.preferredTransform, assetScaleFactor),CGAffineTransformMakeTranslation( ox, oy)) atTime:CMTimeMakeWithSeconds(curPosSeconds, 600)];
            //
            
            // 1.2 Transition
            // Fade In Track#1 by setting a ramp from 0.0 to 1.0.
            AVMutableVideoCompositionInstruction *transitionInstructions = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            AVMutableVideoCompositionLayerInstruction *theLayerInstruction2;
            transitionInstructions.timeRange = CMTimeRangeFromTimeToTime(curPos, CMTimeMakeWithSeconds(curPosSeconds+picShowTime, 600));
            
            if (curPosSeconds > 0.0001) {
                CMTimeRange transitionTimeRange1 = CMTimeRangeMake( curPos,  transitionSecond);
                [theLayerInstruction setOpacityRampFromStartOpacity:0.3 toEndOpacity:1.0 timeRange:transitionTimeRange1];
            }
            
            // Fade out Track#1 by setting a ramp from 1.0 to 0.0.
            if (curPosSeconds+picShowTime < wholeDuration) {
                CMTimeRange transitionTimeRange2 = CMTimeRangeMake( CMTimeMakeWithSeconds(curPosSeconds+picShowTime-1, 600), transitionSecond);
                [theLayerInstruction setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.3 timeRange:transitionTimeRange2];
            }
            
            //
            transitionInstructions.layerInstructions = [NSArray arrayWithObjects: theLayerInstruction, theLayerInstruction2, nil];
            [fullVideoInstructions addObject:transitionInstructions];
            
            //
            curPosSeconds += picShowTime;
            pictureCounter++;
        }
        //
        tmpVideoComposition.instructions = fullVideoInstructions;
        
    }
    // 3-2. Insert Video AVAsset !
    else  if ( videoList != nil ) {
        //
        double curPosSeconds = 0.00000000001f;
        int segCount=0;
        //
        
        // Make a "Scaled video track" video composition.
        AVMutableVideoCompositionInstruction *wholeScaledInstructions = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        wholeScaledInstructions.timeRange = CMTimeRangeMake(kCMTimeZero, [audioAsset duration]);
        NSMutableArray *layerInstructions = [NSMutableArray array];
        //
        // Create the AVURLAsset array !
        NSMutableArray * videoAssets = [NSMutableArray array];
        NSMutableArray * videoCompositionTracks = [NSMutableArray array];
        curPosSeconds = 0.00000000001f;
        for (int idx=0; curPosSeconds+0.3f < wholeDuration && idx<videoList.count; idx++) {
            NSURL *videoFileURL = [videoList objectAtIndex:idx];
            AVAsset *theVideoAsset = [AVURLAsset assetWithURL:videoFileURL];
            [videoAssets addObject: theVideoAsset];
            // TEST 2 - one track for each Video clip.
            AVMutableCompositionTrack *compositionVideoTrack = [tmpAVComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            [videoCompositionTracks addObject:compositionVideoTrack];
            // check if we need another NEW track ?
            double duration = CMTimeGetSeconds([theVideoAsset duration]);
            curPosSeconds += duration;
            NSLog(@"Video-clip#%03d, duration:%lf", idx, duration);
        }
        
        // for storing the position of each video clip
        double videoClipAtPos[2048]; // ASSUME: the max clips is 2048.
        
        curPosSeconds = 0.00000000001f;
        // Insert each video clips into the tracks
        while ( wholeDuration > curPosSeconds+0.3f) {
            //
            int videoIdx = (segCount % videoList.count);
            NSURL *videoFileURL = [videoList objectAtIndex:videoIdx];
            AVAsset *theVideoAsset = [videoAssets objectAtIndex:videoIdx];
            AVAssetTrack *videoAssetTrack = [[theVideoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            //
            CMTime userMP4Duration = [theVideoAsset duration];
            double userMP4Seconds = CMTimeGetSeconds(userMP4Duration);
            double beginMP4Seconds = 0.000000001f;
            
            //
            double endMP4Seconds = curPosSeconds+(userMP4Seconds - beginMP4Seconds) > wholeDuration ? beginMP4Seconds + (wholeDuration-curPosSeconds) : userMP4Seconds;
            //
            editRange = CMTimeRangeMake( CMTimeMakeWithSeconds(beginMP4Seconds,600),
                                        CMTimeMakeWithSeconds(endMP4Seconds-beginMP4Seconds,600));
            CMTime curPos = CMTimeMakeWithSeconds(curPosSeconds, 600);
            
            // setup the video clip !
            AVMutableCompositionTrack *videoCompositionTrackXX = [videoCompositionTracks objectAtIndex:videoIdx];
            //
            [videoCompositionTrackXX insertTimeRange: editRange
                                             ofTrack: videoAssetTrack
                                              atTime: curPos
                                               error: &error];
            //
            if (error != nil) {
                NSLog(@"Error to insert USER-Video to final composition: %@", error);
                break;
            }
            else {
                //NSLog(@"Inserting user-MP4[seg:%d:%@] from %lf(%lf) to %lf(%lf)", segCount, videoFileURL, curPosSeconds, beginMP4Seconds, curPosSeconds + endMP4Seconds, endMP4Seconds);
            }
            
            // record the position !!
            videoClipAtPos[segCount] = curPosSeconds;
            segCount++;
            
            // next one
            curPosSeconds += (endMP4Seconds - beginMP4Seconds);
            beginMP4Seconds = 0.000000001f;
        }
        
        // Having one AVMutableVideoCompositionLayerInstruction for each Track
        for (int idx=0; idx<videoCompositionTracks.count; idx++) {
            AVMutableCompositionTrack *videoCompositionTrackXX = [videoCompositionTracks objectAtIndex:idx];
            AVAssetTrack *videoAssetTrack = [[[videoAssets objectAtIndex:idx] tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            
            // (A) for Scaling different-sized Videos
            AVMutableVideoCompositionLayerInstruction *theLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrackXX];
            
            UIImageOrientation assetOrientation_ = UIImageOrientationUp;
            BOOL isAssetPortrait_ = NO;
            CGAffineTransform transform = videoAssetTrack.preferredTransform;
            if(transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0) {assetOrientation_= UIImageOrientationRight; isAssetPortrait_ = YES;}
            else if(transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0) {assetOrientation_ =  UIImageOrientationLeft; isAssetPortrait_ = YES;}
            else if(transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0)  {assetOrientation_ =  UIImageOrientationUp;}
            else if(transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0) {assetOrientation_ = UIImageOrientationDown;}
            //
            CGFloat wRatio, hRatio;
            if (isAssetPortrait_) {
                wRatio = currentSize.width / videoAssetTrack.naturalSize.height;
                hRatio = currentSize.height / videoAssetTrack.naturalSize.width;
            }
            else {
                wRatio = currentSize.width / videoAssetTrack.naturalSize.width;
                hRatio = currentSize.height / videoAssetTrack.naturalSize.height;
            }
            CGFloat assetScaleToFitRatio;
            CGFloat ox=0, oy=0;
            if (wRatio > hRatio){
                assetScaleToFitRatio = hRatio;
                if (isAssetPortrait_)
                    ox = ( currentSize.width - videoAssetTrack.naturalSize.height*hRatio)/2;
                else
                    ox = ( currentSize.width - videoAssetTrack.naturalSize.width*hRatio)/2;
            }
            else {
                assetScaleToFitRatio = wRatio;
                if (isAssetPortrait_)
                    oy = ( currentSize.height - videoAssetTrack.naturalSize.width*wRatio)/2;
                else
                    oy = ( currentSize.height - videoAssetTrack.naturalSize.height*wRatio)/2;
            }
            //
            CGAffineTransform assetScaleFactor = CGAffineTransformMakeScale( assetScaleToFitRatio, assetScaleToFitRatio);
            //[theLayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(videoAssetTrack.preferredTransform, assetScaleFactor),CGAffineTransformMakeTranslation( ox, oy)) atTime:curPos];
            [theLayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(videoAssetTrack.preferredTransform, assetScaleFactor),CGAffineTransformMakeTranslation( ox, oy)) atTime:kCMTimeZero];
            
            // (B) for transition
            AVAsset *theVideoAsset = [videoAssets objectAtIndex:idx];
            CMTime userMP4Duration = [theVideoAsset duration];
            double userMP4Seconds = CMTimeGetSeconds(userMP4Duration);
            double transitionSecond = 2.5f;
            if ( userMP4Seconds/2 <= 2.5)
                transitionSecond = userMP4Seconds * 0.3;
            //
            CMTime clipTransitionDuration = CMTimeMakeWithSeconds( transitionSecond, 600);
            double theBeginTime;
            double theEndingTime;
            // configure each segment of the same video clip
            NSLog(@"For Video Clip-%d", idx);
            for (int i=idx; i<segCount; i+= videoList.count) {
                theBeginTime = videoClipAtPos[i];
                theEndingTime = theBeginTime + userMP4Seconds-0.000001f;
                NSLog(@"---process segment:%d, begin:%lf, end:%lf", i, theBeginTime, theEndingTime);
                
                CMTime beginPos = CMTimeMakeWithSeconds(theBeginTime, 600);
                CMTime endingPos = CMTimeMakeWithSeconds( theEndingTime - transitionSecond, 600);
                // Fade In current layer by setting a ramp from 0.0 to 1.0 at the beginning of the video clip.
                if (i > 0) {
                    CMTimeRange transitionTimeRange1 = CMTimeRangeMake( beginPos,  clipTransitionDuration);
                    [theLayerInstruction setOpacityRampFromStartOpacity:0.0 toEndOpacity:1.0 timeRange:transitionTimeRange1];
                }
                // Fade out current layer by setting a ramp from 1.0 to 0.0 at the end of the video clip
                if (i+1<segCount) {
                    //
                    CMTimeRange transitionTimeRange2 = CMTimeRangeMake( endingPos,  clipTransitionDuration);
                    [theLayerInstruction setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:transitionTimeRange2];
                }
            }
            
            //
            [layerInstructions addObject:theLayerInstruction];
            
        }
        
        //
        wholeScaledInstructions.layerInstructions = [NSArray arrayWithArray: layerInstructions];
        tmpVideoComposition.instructions = [NSArray arrayWithObject:wholeScaledInstructions];
        
        // release all objects.
        [videoAssets removeAllObjects];
        videoAssets = nil;
        [videoCompositionTracks removeAllObjects];
        videoCompositionTracks = nil;
        
    }
    else {
        NSLog(@"ImageList/VideoList is wrong!??");
        return nil;
    }
    //
    // (3-3) The content of the selected video file is wrong!?
    NSArray *videoTracks = [tmpAVComposition tracksWithMediaType:AVMediaTypeVideo];
    if ([videoTracks count] == 0) {
        // no Viewo !!
        [self showAlertMessage:@"目前選擇的檔案並無任何影像內容，請重新選擇！" withTitle:@"<<<< 影像檔案內容錯誤 >>>>" buttonText:@"確認"];
        return nil;
    }
    
    //
    // [self buildPassThroughVideoComposition:tmpVideoComposition forComposition:tmpAVComposition];
    //tmpAVComposition = [AVMutableComposition composition];
    //[self buildTransitionComposition: tmpAVComposition andVideoComposition:tmpVideoComposition];
    
    //---------
    if (forPlayback) {
        previewComposition = [tmpAVComposition copy];
        //
        AVPlayerItem *thePlayerItem = [AVPlayerItem playerItemWithAsset:tmpAVComposition];
		thePlayerItem.videoComposition = tmpVideoComposition;
		self.playerItem = thePlayerItem;
        [self getTitleLayerForVideoSize:currentSize forOutput:false];
    }
    else {
        outputComposition = [tmpAVComposition copy];
        // For export: build a Core Animation tree that contains both the animated title and the video.
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, currentSize.width, currentSize.height);
        parentLayer.bounds =  CGRectMake(0, 0, currentSize.width, currentSize.height);
        videoLayer.frame = CGRectMake(0, 0, currentSize.width, currentSize.height);
        videoLayer.bounds =  CGRectMake(0, 0, currentSize.width, currentSize.height);
        CALayer *curTitleLayer = [self getTitleLayerForVideoSize:currentSize forOutput:true];
        //
        [parentLayer addSublayer:videoLayer];
        [parentLayer addSublayer:curTitleLayer];
        //
        //videoComposition4Export = [AVMutableVideoComposition videoComposition];
        //[self buildPassThroughVideoComposition:videoComposition4Export forComposition:outputComposition];
        
        // we need a NEW one having the same setting, so [COPY] is the best answer!
        videoComposition4Export = [tmpVideoComposition copy];
        
        //tmpAVComposition = [AVMutableComposition composition];
        //[self buildTransitionComposition: tmpAVComposition andVideoComposition:videoComposition4Export];
        //-------
        videoComposition4Export.animationTool = [AVVideoCompositionCoreAnimationTool                videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
        videoComposition4Export.frameDuration = CMTimeMake(1, 30); // 30 fps
        videoComposition4Export.renderSize = currentSize;
        //videoComposition4Export.renderSize = outputComposition.naturalSize;
    }
    
    //
    videoComposition = tmpVideoComposition;
    
    // Sucessfully !
    return tmpAVComposition;
}

- (NSString *) productMovieFromUIImages:(NSArray *)imageList withWholeDuration:(Float32)duration withPresentationTimer:(int)stepTimer{
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
    NSString *exportPath = [documentsDirectoryPath stringByAppendingPathComponent:@"CarolKOK_tempJPG.mov" ];
    NSLog(@"[AVMixer/JPG2MOV] prepare to merge the selected-JPGs to be a Movie file: %@", exportPath);
    [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
    
    // write JPG files to a movie file
    NSError * error = [self writeImagesAsMovie:imageList toPath:exportPath waitingSeconds:stepTimer withDuration:duration ];
    
    if (error)
        return nil;
    else
        return exportPath;
}

- (NSError *) writeImagesAsMovie:(NSArray *)imageList toPath:(NSString*)path  waitingSeconds:(Float32)waitingSeconds withDuration:(Float64)duration {
    
    UIImage *first = [imageList objectAtIndex:0];
    
    // NOT based on the first PHOTO !!
    // CGSize frameSize = first.size;
    CGSize frameSize = {1024, 768};
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    
    if(error) {
        NSLog(@"[AVMixer/JPG2MOV] error creating AssetWriter: %@",[error description]);
        return error;
    }
    
    // OR 1024 * 768 ??
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:frameSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:frameSize.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                       assetWriterInputWithMediaType:AVMediaTypeVideo
                                       outputSettings:videoSettings];
    
    //
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.width] forKey:(NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.height] forKey:(NSString*)kCVPixelBufferHeightKey];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:attributes];
    
    [videoWriter addInput:writerInput];
    
    // fixes all errors
    writerInput.expectsMediaDataInRealTime = YES;
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //-------------------------------------------------------------
    CVPixelBufferRef buffer = NULL;
    buffer = [self pixelBufferFromCGImage:[first CGImage] videoWidth:frameSize.width videoHeight:frameSize.height];
    BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    
    if (result == NO) {//failes on 3GS, but works on iphone 4
        NSLog(@"[AVMixer/JPG2MOV] failed to append buffer! the error is: %@", [videoWriter error]);
        return [videoWriter error];
    }
    if(buffer) {
        CVPixelBufferRelease(buffer);
    }
    
    
    //-------------------------------------------------------------
    int i = 0;
    int errCounter=0;
    int errNotReadyCounter=0;
    int idx;
    // for remainder part issue !
    double orgDuration = duration;
    duration = ((int)(duration/waitingSeconds + 0.999999999)) * waitingSeconds +0.01;
    //
    while (duration > 0) {
        if (adaptor.assetWriterInput.readyForMoreMediaData) {
            CMTime presentTime;
            // write the last image for avoiding empty screen !!
            if (i * waitingSeconds > orgDuration) {
                presentTime =  CMTimeMakeWithSeconds( orgDuration-0.01, 600);
                i--; // for showing the same image.
            }
            else
                presentTime = CMTimeMakeWithSeconds( i * waitingSeconds+0.1, 600);
            //
            idx = i % [imageList count];
            UIImage *imgFrame = [imageList objectAtIndex:idx];
            buffer = [self pixelBufferFromCGImage:[imgFrame CGImage] videoWidth:frameSize.width videoHeight:frameSize.height];
            BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
            
            if (result == NO) //failes on 3GS, but works on iphone 4
            {
                NSLog(@"[AVMixer/JPG2MOV] Failed to append buffer, the error is: %@", [videoWriter error]);
                // if there is too many errors occured, we need interrupt this procedure.
                errCounter++;
                if (errCounter > 100) {
                    NSLog(@"[AVMixer/JPG2MOV] Error: appendPixelBuffer... -- No space !?");
                    break;
                }
            }
            else {
                duration -= waitingSeconds;
                i++;
                errCounter = 0;
                errNotReadyCounter = 0;
            }
            
            if(buffer) {
                CVPixelBufferRelease(buffer);
                buffer = nil; // NULL?
            }
            
        } else {
            NSLog(@"[AVMixer/JPG2MOV:%d:%d] Error(%u): readyForMoreMediaData -- Too fast !? duration:%f", i, idx, errNotReadyCounter, duration);
            // if there is too many errors occured, we need interrupt this procedure.
            errNotReadyCounter++;
            [NSThread sleepForTimeInterval:0.01];
            if (errNotReadyCounter > 10000) {
                //NSLog(@"[JPG to MOV] Error: readyForMoreMediaData -- Too fast !?");
                break;
            }
        }
        // [self performSelectorOnMainThread:@selector(addprogress) withObject:nil waitUntilDone:YES];
    }
    
    //Finish the session:
    [writerInput markAsFinished];
    
    // this call will be blocked in iOS 6 ==> WHY ??
    // [videoWriter finishWriting];
    
    // for solving iOS 6 blocked issue !
    movieIsReady = false;
    dispatch_async( dispatch_get_main_queue(), ^{
        // MUST called in MAIN_THREAD, otherwise, it will be blocked!
        [videoWriter finishWriting];
        NSLog(@"[AVMixer/JPG2MOV] The movie is ready for playing!");
        movieIsReady = true;
    });
    
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
    videoWriter=nil;
    writerInput=nil;
    
    //
    if (errCounter > 100 || errNotReadyCounter > 10000) {
        NSLog(@"[AVMixer/JPG2MOV] Fail to produce the Movie with the Photos!!");
        return [videoWriter error];
    }
    else {
        NSLog(@"[AVMixer/JPG2MOV] The movie created successfully, but not ready!");
        // for iOS 6 blocked issue ==> wait for the JPG/MP4 ready ! (iOS 6)
        while (movieIsReady == false) {
            [NSThread sleepForTimeInterval:0.1];
        }
        return nil;
    }
    //[self performSelectorOnMainThread:@selector(displaySheet) withObject:nil waitUntilDone:YES];
}

- (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image videoWidth:(UInt32)width videoHeight:(UInt32)height
{
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    UInt32 imgWidth = CGImageGetWidth(image);
    UInt32 imgHeight = CGImageGetHeight(image);
    
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                        &pxbuffer);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, width, height, 8, 4*width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    // CGAffineTransform flipVertical = CGAffineTransformMake(
    //                                                        1, 0, 0, -1, 0, CGImageGetHeight(image)
    //                                                        );
    // CGContextConcatCTM(context, flipVertical);
    
    //    CGAffineTransform flipHorizontal = CGAffineTransformMake(
    //                                                             -1.0, 0.0, 0.0, 1.0, CGImageGetWidth(image), 0.0
    //                                                             );
    //
    //    CGContextConcatCTM(context, flipHorizontal);
    
    
    // CGContextDrawImage(context, CGRectMake(0, 0, imgWidth, imgHeight), image);
    UInt32 outWidth, outHeight;
    Float32 wRatio = (Float32) imgWidth/width;
    Float32 hRatio = (Float32) imgHeight/height;
    // adjust the output width/height !
    if (wRatio > hRatio) {
        outWidth = width;
        outHeight = imgHeight/wRatio;
    } else {
        outWidth = imgWidth/hRatio;
        outHeight = height;
    }
    //
    CGContextDrawImage(context, CGRectMake( 0, 0, width, height), [grayImage CGImage]);
    CGContextDrawImage(context, CGRectMake( (width-outWidth)/2, (height-outHeight)/2, outWidth, outHeight), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void) setMovieNotReady {
    movieIsReady = false;
}

- (BOOL) isMovieReadyForPlay{
    return movieIsReady;
}

- (CALayer *) getTitleLayerForVideoSize:(CGSize)curSize forOutput:(Boolean)forOutput {
    //
    // 0. Prepare the title
    if (animatedTitleLayer != nil) {
        [animatedTitleLayer removeFromSuperlayer];
        animatedTitleLayer = nil;
    }
    // nothing for show !!
    if (title==nil) {
        return nil;
    }
    //
    //
    Float32 vRatio = curSize.height/videoSize.height;
    Float32 hRatio = curSize.width/videoSize.width;
    UInt32 runFontSize = titleFontSize;
    if (hRatio > vRatio)
        runFontSize  *= vRatio;
    else
        runFontSize  *= hRatio;
    
	// Create a layer for the text of the title.
	titleLayer = [CATextLayer layer];
    CTFontRef fontRef = CTFontCreateWithName((CFStringRef)@"Helvetical", runFontSize, NULL);
    NSDictionary *attrDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (__bridge id)fontRef, (NSString *)kCTFontAttributeName,
                                    (id)[[UIColor colorWithRed:_TitlecolorRed green:_TitlecolorGreen blue:_TitlecolorBlue alpha:1] CGColor], (NSString *)(kCTForegroundColorAttributeName),
                                    (id)[[UIColor whiteColor] CGColor], (NSString *) kCTStrokeColorAttributeName,
                                    (id)[NSNumber numberWithFloat:-2], (NSString *)kCTStrokeWidthAttributeName,
                                    nil];
    CFRelease(fontRef);
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:title attributes:attrDictionary];
    /*
     // 換顏色！！
     CTFontRef fontRefBold = CTFontCreateWithName((CFStringRef)@"Palatino-Bold", runFontSize, NULL);
     NSDictionary *attrDictionaryBold = [NSDictionary dictionaryWithObjectsAndKeys:
     (__bridge id)fontRefBold, (NSString *)kCTFontAttributeName,
     (id)[[UIColor blackColor] CGColor], (NSString *)(kCTForegroundColorAttributeName),
     nil];
     [attString addAttributes:attrDictionaryBold range:NSMakeRange(5,attString.length-5)];
     CFRelease(fontRefBold);
     */
    titleLayer.string = attString;
    
	titleLayer.alignmentMode = kCAAlignmentCenter;
    // titleLayer.frame = CGRectMake(0, 0, curSize.width, (runFontSize+20)   );
    titleLayer.bounds = CGRectMake(0, 0, curSize.width, (runFontSize+20)   );
    //--------------------------------------------------------------------------------------------------
    // It's very strange, but workable !
    if (forOutput)
        titleLayer.position = CGPointMake(curSize.width / 2.0, (runFontSize+20) / 2.0);
    else
        titleLayer.position = CGPointMake(curSize.width / 2.0, curSize.height - (runFontSize+20) / 2.0);
    //--------------------------------------------------------------------------------------------------
    // NSAttributedStrings
    /*
     NSString *const NSFontAttributeName;
     NSString *const NSParagraphStyleAttributeName;
     NSString *const NSForegroundColorAttributeName;
     NSString *const NSBackgroundColorAttributeName;
     NSString *const NSLigatureAttributeName;
     NSString *const NSBaselineOffsetAttributeName;
     NSString *const NSStrikethroughStyleAttributeName;
     NSString *const NSStrokeColorAttributeName;
     NSString *const NSStrokeWidthAttributeName;
     NSString *const NSShadowAttributeName;
     */
    /*
     http://stackoverflow.com/questions/8702740/catextlayer-font-bordercolor
     Basically it is possible to make text with a stroke (border) without using CoreText directly. The string property of CATextLayer accepts NSAttributedStrings. Therefore it would be as easy as giving a NSAttributedString with a stroke color and a stroke width in its attributes.
     
     Unfortunately I needed to animated the font size. The string property is animatable but only if it's an NSString. So I decided to subclass CATextLayer. After much trying I came to realize that the string and the contents properties of the CATextLayer are mutually exclusive, which means, either the string or the content is displayed. I couldn't figure out how to do the drawing of the string myself. The display and drawInContext:ctx methods are called only when the content is being updated but I didn't know what I would have to call for updating the string.
     
     So I decided to write my own CATextLayer class, subclassing CALayer. I created an animatable property called fontSize. When this one is animated, the drawInContext:ctx method is called. In the drawInContext:ctx method I create a a new string with CoreText and update its size accordingly using the fontSize property.
     */
    
	// Add it to the Animation layer.
	animatedTitleLayer = [CALayer layer] ;
    [animatedTitleLayer addSublayer:titleLayer];
    
    //
    // Animate the opacity of the overall layer so that it fades out from 3 sec to 4 sec.
    CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnimation.fromValue = [NSNumber numberWithFloat:1.0]; // fully visible
    fadeAnimation.toValue = [NSNumber numberWithFloat:0.0];   // fully invisible!
    fadeAnimation.additive = NO;
    fadeAnimation.removedOnCompletion = NO;
    //------------------------------------------------------------------------
    // It's very strange, but workable !
    if (forOutput)
        fadeAnimation.beginTime = 1e-100;   //AVCoreAnimationBeginTimeAtZero
    else
        fadeAnimation.beginTime = 0;
    //------------------------------------------------------------------------
    fadeAnimation.duration = titleShowDuration+1;
    fadeAnimation.fillMode = kCAFillModeBoth;
    [animatedTitleLayer addAnimation:fadeAnimation forKey:nil];
    
    //
    return animatedTitleLayer;
}

- (void) setTitle:(NSString *)newTitle withSize:(UInt32)size withShowDuration:(Float32)duration
{
    title = newTitle;
    titleFontSize = size;
    titleShowDuration = duration;
}

//==========
- (void)addAudioMixTrackToComposition:(AVMutableComposition *)composition withAudioAsset:(AVAsset *)audioMixAsset from:(CMTime)fromTime duration:(CMTime) duration
{
	NSInteger i;
	NSArray *tracksToDuck = [composition tracksWithMediaType:AVMediaTypeAudio]; // before we add the commentary
	audioMix = nil;
    audioMix = [AVMutableAudioMix audioMix];
	// Clip commentary duration to composition duration.
	CMTimeRange commentaryTimeRange = CMTimeRangeMake(fromTime, duration);
	if (CMTIME_COMPARE_INLINE(CMTimeRangeGetEnd(commentaryTimeRange), >, [composition duration]))
		commentaryTimeRange.duration = CMTimeSubtract([composition duration], commentaryTimeRange.start);
	
	// Add the commentary track.
	AVMutableCompositionTrack *compositionCommentaryTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	[compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, commentaryTimeRange.duration) ofTrack:[[audioMixAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:commentaryTimeRange.start error:nil];
	
	
	NSMutableArray *trackMixArray = [NSMutableArray array];
	CMTime rampDuration = CMTimeMake(1, 2); // half-second ramps
	for (i = 0; i < [tracksToDuck count]; i++) {
		AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:[tracksToDuck objectAtIndex:i]];
		[trackMix setVolumeRampFromStartVolume:1.0 toEndVolume:0.2 timeRange:CMTimeRangeMake(CMTimeSubtract(commentaryTimeRange.start, rampDuration), rampDuration)];
		[trackMix setVolumeRampFromStartVolume:0.2 toEndVolume:1.0 timeRange:CMTimeRangeMake(CMTimeRangeGetEnd(commentaryTimeRange), rampDuration)];
		[trackMixArray addObject:trackMix];
	}
	audioMix.inputParameters = trackMixArray;
}

- (AVAssetImageGenerator*)assetImageGenerator
{
	AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.previewComposition];
	generator.videoComposition = self.videoComposition;
	return generator;
}

- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName
{
	AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:self.outputComposition presetName:presetName];
	session.videoComposition = self.videoComposition4Export;
	session.audioMix = self.audioMix;
	return session;
}

- (void)getPlayerItem:(AVPlayerItem**)playerItemOut andSynchronizedLayer:(AVSynchronizedLayer**)synchronizedLayerOut
{
	if (playerItemOut) {
		*playerItemOut = playerItem;
	}
    
    // title
    if (animatedTitleLayer) {
        // Build an AVSynchronizedLayer that contains the animated title.
        self.synchronizedLayer = [AVSynchronizedLayer synchronizedLayerWithPlayerItem:self.playerItem];
        self.synchronizedLayer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height);
        //self.synchronizedLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        [self.synchronizedLayer addSublayer:animatedTitleLayer];
    }
    
    //
	if (synchronizedLayerOut) {
		*synchronizedLayerOut = synchronizedLayer;
	}
}

-(void) showAlertMessage:(NSString *) message withTitle:(NSString *)title buttonText:(NSString *) btnCancelText {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: title
                          message:message
                          delegate:nil
                          cancelButtonTitle: btnCancelText
                          otherButtonTitles: nil];
    [alert show];
}

@end
