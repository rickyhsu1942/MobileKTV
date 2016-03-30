//
//  KOKSMP4PlayerViewController.h
//  TrySinging
//
//  Created by 國立中興大學 資訊工程學系 國立中興大學 資訊工程學系 on 12/8/13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <ExternalAccessory/ExternalAccessory.h>

#import "KOKSMixerHostAudio.h"
#import "KOKSAVMixer.h"

#import "ELCImagePickerController.h"

#define IMAGE_SOURCE_TYPE_DEFAULT           0
#define IMAGE_SOURCE_TYPE_USER_PHOTOS       1
#define IMAGE_SOURCE_TYPE_USER_VIDEOS       2
#define IMAGE_SOURCE_TYPE_CAMERA            3

#define SONG_TYPE_MP3                       0
#define SONG_TYPE_MP4                       1

#define degressToRadian(x) (M_PI * (x)/180.0)

@interface KOKSMP4PlayerViewController : UIViewController < UIPopoverControllerDelegate, ELCImagePickerControllerDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    // coomponent
    AVPlayer *defaultPlayer;
    AVPlayer *userPlayer;
    KOKSMixerHostAudio *audioProcessor;
    
    // background component for composition !
    AVMutableComposition *composition;
    AVURLAsset *musicAsset;
    AVCaptureSession *captureSession;

    NSTimer *sliderTimer;
    Float64 musicDuration; // of the original MP3/MP4
    NSURL   *songUrl;
    NSURL   *usrMP4Url;     
    int     songType;       // 0 : mp3; 1: mp4
    BOOL    needResume;
    // NavigationItem's title
    UILabel *naviTitleLabel;
    //
    NSMutableArray *imageList1;                     // Default Image List
    NSMutableArray *imageList2;                     // User's Photo List
    int     imageSrcTypeIdx, curImageSrcIdx;        // type of image source !
    //
    AVPlayerLayer                 *playerLayer;         // AVPlayerLayer - Original Movie 
    AVPlayerLayer                 *userVideoLayer;      // AVPlayerLayer - User's selected Movie
    AVPlayerLayer                 *subLayer;         // AVPlayerLayer - Original Movie / User's selected Movie
    AVCaptureVideoPreviewLayer    *cameraPreviewLayer;  // Camera preview !
    AVPlayerItem                  *defaultPlayerItem;   // The Original movie
    AVPlayerItem                  *userPlayerItem;      // User's selected Movie
    AVCaptureDevice               *videoDevice;         // Camera Device!
    AVCaptureDeviceInput          *videoDeviceInput;
    //
    UIPopoverController           *videoPickerPopoverController;
    UIPopoverController           *imagePickerPopoverController;
    ELCImagePickerController      *imagePickerController;
    UIImage                       *grayImage;
    //
    // For Recording
    AVMutableComposition          *outputAVComposition;
    AVAssetWriter                 *usrVocalWriter;
    AVAssetWriterInput            *usrVocalWriterInput;
    AVAssetWriter                 *jpgVideoWriter;
    AVCaptureMovieFileOutput      *movieFileOutput;
    NSURL                         *captureMovieURL;
    //
    NSString                      *vocalFile;
    NSString                      *videoFile;
    Float64                        beginRecordingTime;
    Float64                        endRecordingTime;
    // new
    KOKSAVMixer                   *avMixer;
    AVAsset                       *audioAsset;
    //
    AVPlayer                      *tmpPlayer;
    Boolean                       bAssetReady;
    
    // Orientation
    AVCaptureVideoOrientation     captureVideoOrientation;
    //
    AVCaptureDevicePosition       cameraPosition;
    
    //ExternalAccessory
    NSMutableArray                *accessoryList;
    EAAccessory                   *selectedAccessory;
}


@property (readwrite) Float64 graphSampleRate;

@property (nonatomic, strong) AVPlayer *defaultPlayer;
@property (nonatomic, strong) AVPlayer *userPlayer;
@property (nonatomic, strong) KOKSMixerHostAudio *audioProcessor;
@property (nonatomic, retain) NSURL    *songUrl;
@property (nonatomic, retain) NSURL    *usrMP4Url;
@property (nonatomic, retain) NSString *SongName;
@property (nonatomic, retain) NSString *Singer;
@property (nonatomic, retain) NSString *SongID;
@property (nonatomic, retain) NSString *costPoint;
@property (nonatomic, retain) NSString *StreamRecord;
@property (nonatomic, retain) NSMutableArray *aryPlaylist;

@end
