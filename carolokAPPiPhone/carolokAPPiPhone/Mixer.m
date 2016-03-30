/*
 File: MixerHostAudio.m
 Abstract: Audio object: Handles all audio tasks for the application.
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */


#import "Mixer.h"
//#import "VoiceFile.h"
//#import "DBTool.h"
#import "SQLiteDBTool.h"
#import "Production.h"
#import "GlobalData.h"
BOOL isRecordNow;
UInt64 maxFrameNum;
/*
 
 following code is add by Jay, 2012/5/24, update by Jay, 2012/6/5
 5/24
 recording callback setup
 
 6/5
 sec to frame mSampleTime: sampleRate * channel# * sec 
 */
#pragma mark Recoding callback
static OSStatus recordingCallback       (void *                            inRefCon,
                                         AudioUnitRenderActionFlags *      ioActionFlags,
                                         const AudioTimeStamp *            inTimeStamp,
                                         UInt32                            inBusNumber,
                                         UInt32                            inNumberFrames,
                                         AudioBufferList *                 ioData) 
{
    
    
    if (*ioActionFlags == kAudioUnitRenderAction_PostRender)
    {
        EffectState *effectState = (EffectState *)inRefCon;
        //if (isRecordNow) 
            ExtAudioFileWriteAsync(effectState->audioFileRef, inNumberFrames, ioData);
    }
    return noErr;     
}

/*end*/

#pragma mark Mixer input bus render callback

//    This callback is invoked each time a Multichannel Mixer unit input bus requires more audio
//        samples. In this app, the mixer unit has two input buses. Each of them has its own render 
//        callback function and its own interleaved audio data buffer to read from.
//
//    This callback is written for an inRefCon parameter that can point to two noninterleaved 
//        buffers (for a stereo sound) or to one mono buffer (for a mono sound).
//
//    Audio unit input render callbacks are invoked on a realtime priority thread (the highest 
//    priority on the system). To work well, to not make the system unresponsive, and to avoid 
//    audio artifacts, a render callback must not:
//
//        * allocate memory
//        * access the file system or a network connection
//        * take locks
//        * waste time
//
//    In addition, it's usually best to avoid sending Objective-C messages in a render callback.
//
//    Declared as AURenderCallback in AudioUnit/AUComponent.h. See Audio Unit Component Services Reference.
static OSStatus inputRenderCallback (
                                     
                                     void                        *inRefCon,      // A pointer to a struct containing the complete audio data 
                                     //    to play, as well as state information such as the  
                                     //    first sample to play on this invocation of the callback.
                                     AudioUnitRenderActionFlags  *ioActionFlags, // Unused here. When generating audio, use ioActionFlags to indicate silence 
                                     //    between sounds; for silence, also memset the ioData buffers to 0.
                                     const AudioTimeStamp        *inTimeStamp,   // Unused here.
                                     UInt32                      inBusNumber,    // The mixer unit input bus that is requesting some new
                                     //        frames of audio data to play.
                                     UInt32                      inNumberFrames, // The number of frames of audio to provide to the buffer(s)
                                     //        pointed to by the ioData parameter.
                                     AudioBufferList             *ioData         // On output, the audio data to play. The callback's primary 
                                     //        responsibility is to fill the buffer(s) in the 
                                     //        AudioBufferList.
                                     ) {
    
    soundStructPtr    soundStructPointerArray   = (soundStructPtr) inRefCon;
    UInt32            frameTotalForSound        = soundStructPointerArray[inBusNumber].frameCount;
    BOOL              isStereo                  = soundStructPointerArray[inBusNumber].isStereo;

    // Declare variables to point to the audio buffers. Their data type must match the buffer data type.
    AudioUnitSampleType *dataInLeft;
    AudioUnitSampleType *dataInRight;
    dataInLeft                 = soundStructPointerArray[inBusNumber].audioDataLeft;
    if (isStereo) dataInRight   = soundStructPointerArray[inBusNumber].audioDataRight;

    // Establish pointers to the memory into which the audio from the buffers should go. This reflects
    //    the fact that each Multichannel Mixer unit input bus has two channels, as specified by this app's
    //    graphStreamFormat variable.
    AudioUnitSampleType *outSamplesChannel1;
    AudioUnitSampleType *outSamplesChannel2;
    
    outSamplesChannel1                 = (AudioUnitSampleType *) ioData->mBuffers[0].mData;
    if (isStereo) outSamplesChannel2   = (AudioUnitSampleType *) ioData->mBuffers[1].mData;
    
    // Get the sample number, as an index into the sound stored in memory,
    //    to start reading data from.
    Float64 sampleNumber = soundStructPointerArray[inBusNumber].sampleNumber;
    
    // Fill the buffer or buffers pointed at by *ioData with the requested number of samples 
    //    of audio from the sound stored in memory.
    for (UInt64 frameNumber = 0; frameNumber < inNumberFrames; ++frameNumber) {
        
        outSamplesChannel1[frameNumber]                 = dataInLeft[(UInt64)sampleNumber];
        if (isStereo) outSamplesChannel2[frameNumber]   = dataInRight[(UInt64)sampleNumber];
        
        sampleNumber++;
        
        // After reaching the end of the sound stored in memory--that is, after
        //    (frameTotalForSound / inNumberFrames) invocations of this callback--loop back to the 
        //    start of the sound so playback resumes from there.
        
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        //indicator all track is finished
//        if (sampleNumber >= maxFrameNum) 
//        {
//            NSLog (@"Audio output end.");
//            [[NSNotificationCenter defaultCenter] postNotificationName: @"MixerDidFinishedPlaying" object: nil];
//        }
        /*
         comment by Jay 2013/5/9
         If sampleNumber exceed the frameTotalForSound, then track finished
         There are two circumstances:
         1. sampleNumber == frameTotalForSound
         This circumstances means first finished, notify mixerview that track finished playing.
         2. sampleNumber > frameTotalForSound
         This circumstances means that this track has bee finish playing.
         Because sampleNumber is exceed 1 than frameTotalForSound
         */
        if (sampleNumber >= frameTotalForSound)
        {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            if (sampleNumber == frameTotalForSound) {
                
                NSString *event = [[[NSString stringWithFormat:@"Bus%ldFinishedPlay", inBusNumber] retain] autorelease];
                
                NSLog(@"%@, s:%d, t:%d",event , (unsigned int)sampleNumber, (unsigned int)frameTotalForSound);
                
                [[NSNotificationCenter defaultCenter] postNotificationName: event object: nil];
            }


            sampleNumber = frameTotalForSound;
            //sampleNumber = 0;
            //end comment by Jay
            
            [pool drain];
        }
        
         //[pool drain];
    }

    // Update the stored sample number so, the next time this callback is invoked, playback resumes 
    //    at the correct spot.
    soundStructPointerArray[inBusNumber].sampleNumber = sampleNumber;
    
    return noErr;
}

#pragma mark -
#pragma mark Audio route change listener callback

// Audio session callback function for responding to audio route changes. If playing back audio and
//   the user unplugs a headset or headphones, or removes the device from a dock connector for hardware  
//   that supports audio playback, this callback detects that and stops playback. 
//
// Refer to AudioSessionPropertyListener in Audio Session Services Reference.
void CarolAudioRouteChangeListenerCallback (
                                       void                      *inUserData,
                                       AudioSessionPropertyID    inPropertyID,
                                       UInt32                    inPropertyValueSize,
                                       const void                *inPropertyValue
                                       ) {
    
    // Ensure that this callback was invoked because of an audio route change
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;
    
    // This callback, being outside the implementation block, needs a reference to the Mixer
    //   object, which it receives in the inUserData parameter. You provide this reference when
    //   registering this callback (see the call to AudioSessionAddPropertyListener).
    
    Mixer *audioObject = (Mixer *) inUserData;
    
    // if application sound is not playing, there's nothing to do, so return.
    if (NO == audioObject.isPlaying) {
        
        NSLog (@"Audio route change while application audio is stopped.");
        return;
        
    } else {
        
        // Determine the specific type of audio route change that occurred.
        CFDictionaryRef routeChangeDictionary = inPropertyValue;
        
        CFNumberRef routeChangeReasonRef =
        CFDictionaryGetValue (
                              routeChangeDictionary,
                              CFSTR (kAudioSession_AudioRouteChangeKey_Reason)
                              );
        
        SInt32 routeChangeReason;
        
        CFNumberGetValue (
                          routeChangeReasonRef,
                          kCFNumberSInt32Type,
                          &routeChangeReason
                          );
        
        // "Old device unavailable" indicates that a headset or headphones were unplugged, or that 
        //    the device was removed from a dock connector that supports audio output. In such a case,
        //    pause or stop audio (as advised by the iOS Human Interface Guidelines).
        if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            
            NSLog (@"Audio output device was removed; stopping audio playback.");
            NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = [[NSString alloc] initWithString: @"MixerHostAudioObjectPlaybackStateDidChangeNotification"];
            [[NSNotificationCenter defaultCenter] postNotificationName: MixerHostAudioObjectPlaybackStateDidChangeNotification object: audioObject]; 
            
            [MixerHostAudioObjectPlaybackStateDidChangeNotification release];
        } else {
            
            NSLog (@"A route change occurred that does not require stopping application audio.");
        }
    }
}


#pragma mark -
@implementation Mixer

@synthesize stereoStreamFormat;         // stereo format for use in buffer and mixer input for "guitar" sound
@synthesize monoStreamFormat;           // mono format for use in buffer and mixer input for "beats" sound
@synthesize graphSampleRate;            // sample rate to use throughout audio processing chain
@synthesize mixerUnit;                  // the Multichannel Mixer unit
@synthesize playing;                    // Boolean flag to indicate whether audio is playing or not
@synthesize interruptedDuringPlayback;  // Boolean flag to indicate whether audio was playing when an interruption arrived
@synthesize isRecorded;

- (Float64)mixerInputGetCurrentProgress:(UInt32)inputBus
{
//    if (inputBus == 0) {
//        NSLog(@"%f",(Float64)soundStructArray[inputBus].sampleNumber);
//    }
    return (Float64)soundStructArray[inputBus].sampleNumber / (Float64)soundStructArray[inputBus].frameCount;
}

- (void)mixerInput:(UInt32)inputBus seekTime:(float)ratio
{
    //use ratio to seek frame
    UInt64 frame = ratio * soundStructArray[inputBus].frameCount;
    //NSLog(@"input:%ld  %lld", inputBus,frame);
    soundStructArray[inputBus].sampleNumber = frame;
}

- (void) setRecordNow:(BOOL)isRecord
{
    isRecordNow = isRecord;
}
- (BOOL) getRecordNow
{
    return isRecordNow;
}

- (void) setBusCount:(int)value
{
    busNum = value;
}

- (void) createExtFile
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    /*
     following code is add by Jay, 2012/5/24
     add recorded file setup
     */
    // 20130712 修改聲道
    AudioStreamBasicDescription dstFormat = {0};
    dstFormat.mSampleRate=44100.0;
    dstFormat.mFormatID=kAudioFormatLinearPCM;
    dstFormat.mFormatFlags=kAudioFormatFlagsNativeEndian|kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
    dstFormat.mBytesPerPacket=4;
    dstFormat.mFramesPerPacket=1;
    dstFormat.mBytesPerFrame=4;
    dstFormat.mChannelsPerFrame=2;
    dstFormat.mBitsPerChannel=16;
    dstFormat.mReserved=0;
    
    GlobalData *globalItem = [GlobalData getInstance];
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [path objectAtIndex:0];
    //get NSTime and formatting
    
    // 運用yyyyMMdd形式建立檔案
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
    //[formatter1 setDateFormat:@"yyyyMMddHHmmss"];
    [formatter1 setDateFormat:@"yyyyMMdd"];
    NSString *valuestr = [formatter1 stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"Mixer%@(1).caf",valuestr]; ;
    
    // 運用括弧流水號
    NSFileManager *manger = [NSFileManager defaultManager];
    NSString *filePaths = [[NSString alloc] initWithFormat:@"%@/%@",documentDirectory,fileName];
    NSString *OldPath = filePaths;
    filePaths = [[OldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    NSLog(@"%@",filePaths);
    //if file exist at new path, appending number
    NSInteger count = 0;
    while ([manger fileExistsAtPath:filePaths])
    {
        count++;
        fileName = [NSString stringWithFormat:@"Mixer%@(%d).caf", valuestr, count];
        filePaths = [[OldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    }
    
    NSLog(@">>> %@", filePaths);
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePaths, kCFURLPOSIXPathStyle, false);
    
    OSStatus setupErr = ExtAudioFileCreateWithURL(destinationURL, kAudioFileWAVEType, &dstFormat, NULL, kAudioFileFlags_EraseFile, &effectState.audioFileRef);  
    CFRelease(destinationURL);
    NSAssert(setupErr == noErr, @"Couldn't create file for writing");
    
    setupErr = ExtAudioFileSetProperty(effectState.audioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &stereoStreamFormat);
    NSAssert(setupErr == noErr, @"Couldn't create file for format");
    
    setupErr =  ExtAudioFileWriteAsync(effectState.audioFileRef, 0, NULL);
    NSAssert(setupErr == noErr, @"Couldn't initialize write buffers for audio file");
    
    NSDate *now = [NSDate date];
    
    
    Production *currentProduct = [[Production alloc] init];
    
    currentProduct.ProductName = fileName;
    currentProduct.ProductCreateTime = now;
    currentProduct.ProductPath = filePaths;
    currentProduct.ProductRight = @"私人";
    currentProduct.ProductType = @"聲音";
    currentProduct.userID =([globalItem.currentUser compare:@""] == NSOrderedSame) ? @"-1" : globalItem.UserID;
    
    NSDictionary* dict = [NSDictionary dictionaryWithObject:currentProduct forKey:@"MixerWorkInfo"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GetMixerWorkInfo" object:dict];
    
    [currentProduct release];
    /*end*/
    /*
     following code is add by Jay, 2012/5/28
     add recorded file setup
     */
    //self.resultFilePath = destinationFilePath;
    /*end*/
    //[path release];
    //[destinationFilePath release];
    
    [pool drain];
    
}

- (void) setSourcePathwithIndex:(int)index value:(NSString*)path
{
    if (path != NULL) {
        sourcePath[index] = [path retain];
        NSLog(@"path %@ is set", sourcePath[index]);
    }
}

#pragma mark -
#pragma mark Initialize

// Get the app ready for playback.
- (id) init {
    
    self = [super init];
    
    if (!self) return nil;
    self.interruptedDuringPlayback = NO;
    [self setupAudioSession];
    self.playing = NO;
    //database = [[DBTool alloc]init];
    database1 = [[SQLiteDBTool alloc] init];
    return self;
}

- (void) initialToReady
{
    [self obtainSoundFileURLs];
    [self setupStereoStreamFormat];
    [self setupMonoStreamFormat];
    [self readAudioFilesIntoMemory];
    [self configureAndInitializeAudioProcessingGraph];
    if (isRecorded) {
        [self createExtFile];
    }
}

#pragma mark -
#pragma mark Audio set up

- (void) setupAudioSession {
    
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
    [mySession setDelegate: self];
    
    // Assign the Playback category to the audio session.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback
                     error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error setting audio session category.");
        return;
    }
    
    // Request the desired hardware sample rate.
    self.graphSampleRate = 44100.0;    // Hertz
    
    [mySession setPreferredHardwareSampleRate: graphSampleRate
                                        error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error setting preferred hardware sample rate.");
        return;
    }
    
    // Activate the audio session
    [mySession setActive: YES
                   error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error activating audio session during initial setup.");
        return;
    }
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    
    //20130712修改Bug
    //self.graphSampleRate = [mySession currentHardwareSampleRate];
    
    
    /*
     comment to avoid crash 2012/7/12, by Jay
     */
    // Register the audio route change listener callback function with the audio session.
    AudioSessionAddPropertyListener (
                                     kAudioSessionProperty_AudioRouteChange,
                                     CarolAudioRouteChangeListenerCallback,
                                     self
                                     );
}


- (void) obtainSoundFileURLs {
    NSLog(@"%@", sourcePath[0]);
    sourceURLArray[0] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)sourcePath[0], kCFURLPOSIXPathStyle, false);
    sourceURLArray[1] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)sourcePath[1], kCFURLPOSIXPathStyle, false);
    
    if (busNum >= 3) {
        sourceURLArray[2] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)sourcePath[2], kCFURLPOSIXPathStyle, false);
    }
    if (busNum >= 4) {
        sourceURLArray[3] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)sourcePath[3], kCFURLPOSIXPathStyle, false);
    }
}

- (void) obtainSoundFileURLswithArray:(NSArray *)array {
    
    sourceURLArray[0] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)[array objectAtIndex:0], kCFURLPOSIXPathStyle, false);
    sourceURLArray[1] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)[array objectAtIndex:1], kCFURLPOSIXPathStyle, false);
    sourceURLArray[2] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)[array objectAtIndex:2], kCFURLPOSIXPathStyle, false);
    sourceURLArray[3] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)[array objectAtIndex:3], kCFURLPOSIXPathStyle, false);
}

- (void) setupStereoStreamFormat {
    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    /*
     following code is modified by Jay 2012/5/24
     cancel the bytesPerSample
     */
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    // Fill the application audio format struct's fields to define a linear PCM, 
    //        stereo, noninterleaved stream at the hardware sample rate.
    stereoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    //2015/06/03
    //stereoStreamFormat.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    stereoStreamFormat.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat.mFramesPerPacket   = 1;
    stereoStreamFormat.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat.mChannelsPerFrame  = 2;                    // 2 indicates stereo
    stereoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat.mSampleRate        = graphSampleRate;
    stereoStreamFormat.mReserved          = 0;
    
    
    NSLog (@"The stereo stream format for the \"guitar\" mixer input bus:");
    [self printASBD: stereoStreamFormat];
}


- (void) setupMonoStreamFormat {
    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    // Fill the application audio format struct's fields to define a linear PCM, 
    //        stereo, noninterleaved stream at the hardware sample rate.
    monoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    //monoStreamFormat.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    monoStreamFormat.mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    monoStreamFormat.mBytesPerPacket    = bytesPerSample;
    monoStreamFormat.mFramesPerPacket   = 1;
    monoStreamFormat.mBytesPerFrame     = bytesPerSample;
    monoStreamFormat.mChannelsPerFrame  = 1;                  // 1 indicates mono
    monoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    monoStreamFormat.mSampleRate        = graphSampleRate;
    
    NSLog (@"The mono stream format for the \"beats\" mixer input bus:");
    [self printASBD: monoStreamFormat];
    
}

#pragma mark -
#pragma mark Read audio files into memory

- (void) readAudioFilesIntoMemory {
    
    for (int audioFile = 0; audioFile < busNum; ++audioFile)  {
        
        NSLog (@"readAudioFilesIntoMemory - file %i", audioFile);
        
        // Instantiate an extended audio file object.
        ExtAudioFileRef audioFileObject = 0;
        
        // Open an audio file and associate it with the extended audio file object.
        OSStatus result = ExtAudioFileOpenURL (sourceURLArray[audioFile], &audioFileObject);
        
        if (noErr != result || NULL == audioFileObject) {[self printErrorMessage: @"ExtAudioFileOpenURL" withStatus: result]; return;}
        
        // Get the audio file's length in frames.
        UInt64 totalFramesInFile = 0;
        UInt32 frameLengthPropertySize = sizeof (totalFramesInFile);
        
        result =    ExtAudioFileGetProperty (
                                             audioFileObject,
                                             kExtAudioFileProperty_FileLengthFrames,
                                             &frameLengthPropertySize,
                                             &totalFramesInFile
                                             );
        
        if (totalFramesInFile > maxFrameNum) {
            maxFrameNum = totalFramesInFile;
        }
        NSLog(@"file %d is %llu long.", audioFile, totalFramesInFile);
        if (noErr != result) {[self printErrorMessage: @"ExtAudioFileGetProperty (audio file length in frames)" withStatus: result]; return;}
        
        // Assign the frame count to the soundStructArray instance variable
        soundStructArray[audioFile].frameCount = (UInt32)totalFramesInFile;
        
        // Get the audio file's number of channels.
        AudioStreamBasicDescription fileAudioFormat = {0};
        UInt32 formatPropertySize = sizeof (fileAudioFormat);
        
        result =    ExtAudioFileGetProperty (
                                             audioFileObject,
                                             kExtAudioFileProperty_FileDataFormat,
                                             &formatPropertySize,
                                             &fileAudioFormat
                                             );
        
        if (noErr != result) {[self printErrorMessage: @"ExtAudioFileGetProperty (file audio format)" withStatus: result]; return;}
        
        UInt32 channelCount = fileAudioFormat.mChannelsPerFrame;
        
        // Allocate memory in the soundStructArray instance variable to hold the left channel, 
        //    or mono, audio data
        soundStructArray[audioFile].audioDataLeft =
        (AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
        
        AudioStreamBasicDescription importFormat = {0};
        if (2 == channelCount) {
            
            soundStructArray[audioFile].isStereo = YES;
            // Sound is stereo, so allocate memory in the soundStructArray instance variable to  
            //    hold the right channel audio data
            soundStructArray[audioFile].audioDataRight =
            (AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
            importFormat = stereoStreamFormat;
            
        } else if (1 == channelCount) {
            
            soundStructArray[audioFile].isStereo = NO;
            importFormat = monoStreamFormat;
            
        }
        else {
            
            NSLog (@"*** WARNING: File format not supported - wrong number of channels");
            ExtAudioFileDispose (audioFileObject);
            return;
        }
        
        // Assign the appropriate mixer input bus stream data format to the extended audio 
        //        file object. This is the format used for the audio data placed into the audio 
        //        buffer in the SoundStruct data structure, which is in turn used in the 
        //        inputRenderCallback callback function.
        
        result =    ExtAudioFileSetProperty (
                                             audioFileObject,
                                             kExtAudioFileProperty_ClientDataFormat,
                                             sizeof (importFormat),
                                             &importFormat
                                             );
        
        if (noErr != result) {[self printErrorMessage: @"ExtAudioFileSetProperty (client data format)" withStatus: result]; return;}
        
        // Set up an AudioBufferList struct, which has two roles:
        //
        //        1. It gives the ExtAudioFileRead function the configuration it 
        //            needs to correctly provide the data to the buffer.
        //
        //        2. It points to the soundStructArray[audioFile].audioDataLeft buffer, so 
        //            that audio data obtained from disk using the ExtAudioFileRead function
        //            goes to that buffer
        
        // Allocate memory for the buffer list struct according to the number of 
        //    channels it represents.
        AudioBufferList *bufferList;
        
        bufferList = (AudioBufferList *) malloc (
                                                 sizeof (AudioBufferList) + sizeof (AudioBuffer) * (channelCount - 1)
                                                 );
        
        if (NULL == bufferList) {NSLog (@"*** malloc failure for allocating bufferList memory"); return;}
        
        // initialize the mNumberBuffers member
        bufferList->mNumberBuffers = channelCount;
        
        // initialize the mBuffers member to 0
        AudioBuffer emptyBuffer = {0};
        size_t arrayIndex;
        for (arrayIndex = 0; arrayIndex < channelCount; arrayIndex++) {
            bufferList->mBuffers[arrayIndex] = emptyBuffer;
        }
        
        // set up the AudioBuffer structs in the buffer list
        bufferList->mBuffers[0].mNumberChannels  = 1;
        bufferList->mBuffers[0].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
        bufferList->mBuffers[0].mData            = soundStructArray[audioFile].audioDataLeft;
        
        if (2 == channelCount) {
            bufferList->mBuffers[1].mNumberChannels  = 1;
            bufferList->mBuffers[1].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
            bufferList->mBuffers[1].mData            = soundStructArray[audioFile].audioDataRight;
        }
        
        // Perform a synchronous, sequential read of the audio data out of the file and
        //    into the soundStructArray[audioFile].audioDataLeft and (if stereo) .audioDataRight members.
        UInt32 numberOfPacketsToRead = (UInt32) totalFramesInFile;
        
        result = ExtAudioFileRead (
                                   audioFileObject,
                                   &numberOfPacketsToRead,
                                   bufferList
                                   );
        
        
        
        /*
         following code is add by Jay, 2012/5/24
         add recorded file setup
         */
//        
//        ExtAudioFileRef audioFileRef;
//        
//        AudioStreamBasicDescription dstFormat = {0};
//        dstFormat.mSampleRate=44100.0;
//        dstFormat.mFormatID=kAudioFormatLinearPCM;
//        dstFormat.mFormatFlags=kAudioFormatFlagsNativeEndian|kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
//        dstFormat.mBytesPerPacket=4;
//        dstFormat.mBytesPerFrame=4;
//        dstFormat.mFramesPerPacket=1;
//        dstFormat.mChannelsPerFrame=2;
//        dstFormat.mBitsPerChannel=16;
//        dstFormat.mReserved=0;
//        
//        NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *documentDirectory = [path objectAtIndex:0];
//        NSString *destinationFilePath = [[[NSString alloc] initWithFormat:@"%@/output.caf", documentDirectory] autorelease];
//        NSLog(@">>> %@", destinationFilePath);
//        CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);
//        
//        OSStatus setupErr = ExtAudioFileCreateWithURL(destinationURL, kAudioFileWAVEType, &dstFormat, NULL, kAudioFileFlags_EraseFile, &audioFileRef);  
//        CFRelease(destinationURL);
//        NSAssert(setupErr == noErr, @"Couldn't create file for writing");
//        
//        setupErr = ExtAudioFileSetProperty(audioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &stereoStreamFormat);
//        NSAssert(setupErr == noErr, @"Couldn't create file for format");
//        
//        setupErr =  ExtAudioFileWriteAsync(audioFileRef, 0, NULL);
//        NSAssert(setupErr == noErr, @"Couldn't initialize write buffers for audio file");
//        /*end*/
//        
//        result = ExtAudioFileWrite(audioFileRef, 51200, bufferList);
//
//        if (noErr != result) {
//            NSLog(@"Write to file error");
//        }
//        else {
//            ExtAudioFileDispose(audioFileRef);
//            NSLog(@"Write to file success");
//        }
//        
//        UInt32 sampleNumber = 0;
//        while (sampleNumber < 512000) {
//            NSLog(@"%ld",soundStructArray[audioFile].audioDataLeft[sampleNumber]);
//            sampleNumber ++;
//        }
        
        free (bufferList);
        
        if (noErr != result) {
            
            [self printErrorMessage: @"ExtAudioFileRead failure - " withStatus: result];
            
            // If reading from the file failed, then free the memory for the sound buffer.
            free (soundStructArray[audioFile].audioDataLeft);
            soundStructArray[audioFile].audioDataLeft = 0;
            
            if (2 == channelCount) {
                free (soundStructArray[audioFile].audioDataRight);
                soundStructArray[audioFile].audioDataRight = 0;
            }
            
            ExtAudioFileDispose (audioFileObject);            
            return;
        }
        
        NSLog (@"Finished reading file %i into memory", audioFile);
        
        // Set the sample index to zero, so that playback starts at the 
        //    beginning of the sound.
        soundStructArray[audioFile].sampleNumber = 0;
        
        // Dispose of the extended audio file object, which also
        //    closes the associated file.
        ExtAudioFileDispose (audioFileObject);
    }
}


#pragma mark -
#pragma mark Audio processing graph setup

// This method performs all the work needed to set up the audio processing graph:

// 1. Instantiate and open an audio processing graph
// 2. Obtain the audio unit nodes for the graph
// 3. Configure the Multichannel Mixer unit
//     * specify the number of input buses
//     * specify the output sample rate
//     * specify the maximum frames-per-slice
// 4. Initialize the audio processing graph

- (void) configureAndInitializeAudioProcessingGraph {
    
    NSLog (@"Configuring and then initializing audio processing graph");
    OSStatus result = noErr;
    
    //............................................................................
    // Create a new audio processing graph.
    result = NewAUGraph (&processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"NewAUGraph" withStatus: result]; return;}
    
    
    //............................................................................
    // Specify the audio unit component descriptions for the audio units to be
    //    added to the graph.
    
    // I/O unit
    AudioComponentDescription iOUnitDescription;
    iOUnitDescription.componentType          = kAudioUnitType_Output;
    iOUnitDescription.componentSubType       = kAudioUnitSubType_RemoteIO;
    iOUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    iOUnitDescription.componentFlags         = 0;
    iOUnitDescription.componentFlagsMask     = 0;
    
    // Multichannel mixer unit
    AudioComponentDescription MixerUnitDescription;
    MixerUnitDescription.componentType          = kAudioUnitType_Mixer;
    MixerUnitDescription.componentSubType       = kAudioUnitSubType_MultiChannelMixer;
    MixerUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    MixerUnitDescription.componentFlags         = 0;
    MixerUnitDescription.componentFlagsMask     = 0;
    
    
    //............................................................................
    // Add nodes to the audio processing graph.
    NSLog (@"Adding nodes to audio processing graph");
    
    AUNode   iONode;         // node for I/O unit
    AUNode   mixerNode;      // node for Multichannel Mixer unit
    
    // Add the nodes to the audio processing graph
    result =    AUGraphAddNode (
                                processingGraph,
                                &iOUnitDescription,
                                &iONode);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNewNode failed for I/O unit" withStatus: result]; return;}
    
    
    result =    AUGraphAddNode (
                                processingGraph,
                                &MixerUnitDescription,
                                &mixerNode
                                );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNewNode failed for Mixer unit" withStatus: result]; return;}
    
    
    //............................................................................
    // Open the audio processing graph
    
    // Following this call, the audio units are instantiated but not initialized
    //    (no resource allocation occurs and the audio units are not in a state to
    //    process audio).
    result = AUGraphOpen (processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphOpen" withStatus: result]; return;}
    
    
    //............................................................................
    // Obtain the mixer unit instance from its corresponding node.
    
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 mixerNode,
                                 NULL,
                                 &mixerUnit
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo" withStatus: result]; return;}
    
    
    //............................................................................
    // Multichannel Mixer unit Setup
    /*
     following code is modify by jay 2012/5/22
     add 1 bus count: busCount = 2 -> busCount = 4
     declare UInt32 threeBus = 2
     declare UInt32 fourthBus = 3
     */
    UInt32 busCount   = busNum;    // bus count for mixer unit input

    UInt32 guitarBus  = 0;    // mixer unit bus 0 will be stereo and will take the guitar sound
    UInt32 beatsBus   = 1;    // mixer unit bus 1 will be mono and will take the beats sound
    UInt32 threerdBus = 2;
    UInt32 fourthBus  = 3;
    /*end*/
    
    NSLog (@"Setting mixer unit input bus count to: %lu", busCount);
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_ElementCount,
                                   kAudioUnitScope_Input,
                                   0,
                                   &busCount,
                                   sizeof (busCount)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit bus count)" withStatus: result]; return;}
    
    
    NSLog (@"Setting kAudioUnitProperty_MaximumFramesPerSlice for mixer unit global scope");
    // Increase the maximum frames per slice allows the mixer unit to accommodate the
    //    larger slice size used when the screen is locked.
    UInt32 maximumFramesPerSlice = 4096;
    
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_MaximumFramesPerSlice,
                                   kAudioUnitScope_Global,
                                   0,
                                   &maximumFramesPerSlice,
                                   sizeof (maximumFramesPerSlice)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit input stream format)" withStatus: result]; return;}
    
    
    // Attach the input render callback and context to each input bus
    for (UInt16 busNumber = 0; busNumber < busCount; ++busNumber) {
        
        // Setup the struture that contains the input render callback 
        AURenderCallbackStruct inputCallbackStruct;
        inputCallbackStruct.inputProc        = &inputRenderCallback;
        inputCallbackStruct.inputProcRefCon  = soundStructArray;
        
        NSLog (@"Registering the render callback with mixer unit input bus %u", busNumber);
        // Set a callback for the specified node's specified input
        result = AUGraphSetNodeInputCallback (
                                              processingGraph,
                                              mixerNode,
                                              busNumber,
                                              &inputCallbackStruct
                                              );
        
        if (noErr != result) {[self printErrorMessage: @"AUGraphSetNodeInputCallback" withStatus: result]; return;}
    }
    
    
    NSLog (@"Setting stereo stream format for mixer unit \"guitar\" input bus");
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   guitarBus,
                                   &stereoStreamFormat,
                                   sizeof (stereoStreamFormat)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit guitar input bus stream format)" withStatus: result];return;}
    
    
    NSLog (@"Setting mono stream format for mixer unit \"beats\" input bus");
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   beatsBus,
                                   &stereoStreamFormat,
                                   sizeof (stereoStreamFormat)
                                   );
    
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit beats input bus stream format)" withStatus: result];return;}
    /*
     following code is modify by jay 2012/5/22
     add 3rd bus dataformat configure
     add 4th bus dataformat configure
     */
    if (busCount >=3) {
        NSLog (@"Setting stereo stream format for mixer unit \"3rd\" input bus");
        result = AudioUnitSetProperty (
                                       mixerUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       threerdBus,
                                       &stereoStreamFormat,
                                       sizeof (stereoStreamFormat)
                                       );
        
        if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit guitar input bus stream format)" withStatus: result];return;}
    }

    if (busCount >= 4) {
        NSLog (@"Setting stereo stream format for mixer unit \"4th\" input bus");
        result = AudioUnitSetProperty (
                                       mixerUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       fourthBus,
                                       &stereoStreamFormat,
                                       sizeof (stereoStreamFormat)
                                       );
        
        if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit guitar input bus stream format)" withStatus: result];return;}
    }

    /*end*/
    
    NSLog (@"Setting sample rate for mixer unit output scope");
    // Set the mixer unit's output sample rate format. This is the only aspect of the output stream
    //    format that must be explicitly set.
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit output stream format)" withStatus: result]; return;}
    
    if (isRecorded) {
            AudioUnitAddRenderNotify(mixerUnit, &recordingCallback, &effectState);
    }
    //............................................................................
    // Connect the nodes of the audio processing graph
    NSLog (@"Connecting the mixer output to the input of the I/O unit output element");
    
    result = AUGraphConnectNodeInput (
                                      processingGraph,
                                      mixerNode,         // source node
                                      0,                 // source node output bus number
                                      iONode,            // destination node
                                      0                  // desintation node input bus number
                                      );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphConnectNodeInput" withStatus: result]; return;}
    
    
    //............................................................................
    // Initialize audio processing graph
    
    // Diagnostic code
    // Call CAShow if you want to look at the state of the audio processing 
    //    graph.
    NSLog (@"Audio processing graph state immediately before initializing it:");
    CAShow (processingGraph);
    
    NSLog (@"Initializing the audio processing graph");
    // Initialize the audio processing graph, configure audio data stream formats for
    //    each input and output, and validate the connections between audio units.
    result = AUGraphInitialize (processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphInitialize" withStatus: result]; return;}
}


#pragma mark -
#pragma mark Playback control

// Start playback
- (void) startAUGraph  {
    
    NSLog(@"max is %llu", maxFrameNum);
    
    NSLog (@"Starting audio processing graph");
    OSStatus result = AUGraphStart (processingGraph);
    if (noErr != result) {[self printErrorMessage: @"AUGraphStart" withStatus: result]; return;}
    
    self.playing = YES;
}

// Stop playback
- (void) stopAUGraph {
    
    NSLog (@"Stopping audio processing graph");
    Boolean isRunning = false;
    OSStatus result = AUGraphIsRunning (processingGraph, &isRunning);
    if (noErr != result) {[self printErrorMessage: @"AUGraphIsRunning" withStatus: result]; return;}
    
    if (isRunning) {
        
        result = AUGraphStop (processingGraph);
        if (noErr != result) {[self printErrorMessage: @"AUGraphStop" withStatus: result]; return;}
        self.playing = NO;
        
        if (isRecorded) {
            ExtAudioFileDispose(effectState.audioFileRef);
        }

    }
}


#pragma mark -
#pragma mark Mixer unit control
// Enable or disable a specified bus
- (void) enableMixerInput: (UInt32) inputBus isOn: (AudioUnitParameterValue) isOnValue {
    
    NSLog (@"Bus %d now %@", (int) inputBus, isOnValue ? @"on" : @"off");
    
    OSStatus result = AudioUnitSetParameter (
                                             mixerUnit,
                                             kMultiChannelMixerParam_Enable,
                                             kAudioUnitScope_Input,
                                             inputBus,
                                             isOnValue,
                                             0
                                             );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetParameter (enable the mixer unit)" withStatus: result]; return;}
    
    /*
     comment by Jay 2013/5/9
     no more need sync
     */
    // Ensure that the sound loops stay in sync when reenabling an input bus
    /*if (0 == inputBus && 1 == isOnValue) {
        soundStructArray[0].sampleNumber = soundStructArray[1].sampleNumber;
    }
    
    if (1 == inputBus && 1 == isOnValue) {
        soundStructArray[1].sampleNumber = soundStructArray[0].sampleNumber;
    }
    */
    /*
     following code is add by Jay 2012/5/22
     add sync control for 3rd bus
     */
    /*
    if (2 == inputBus && 1 == isOnValue) {
        soundStructArray[2].sampleNumber = soundStructArray[3].sampleNumber;
    }
    if (3 == inputBus && 1 == isOnValue) {
        soundStructArray[3].sampleNumber = soundStructArray[2].sampleNumber;
    }
     */
    /*end*/
}


// Set the mixer unit input volume for a specified bus
- (void) setMixerInput: (UInt32) inputBus gain: (AudioUnitParameterValue) newGain {
    
    /*
     This method does *not* ensure that sound loops stay in sync if the user has 
     moved the volume of an input channel to zero. When a channel's input 
     level goes to zero, the corresponding input render callback is no longer 
     invoked. Consequently, the sample number for that channel remains constant 
     while the sample number for the other channel continues to increment. As a  
     workaround, the view controller Nib file specifies that the minimum input
     level is 0.01, not zero.
     
     The enableMixerInput:isOn: method in this class, however, does ensure that the 
     loops stay in sync when a user disables and then reenables an input bus.
     */
    OSStatus result = AudioUnitSetParameter (
                                             mixerUnit,
                                             kMultiChannelMixerParam_Volume,
                                             kAudioUnitScope_Input,
                                             inputBus,
                                             newGain,
                                             0
                                             );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetParameter (set mixer unit input volume)" withStatus: result]; return;}
    
}


// Set the mxer unit output volume
- (void) setMixerOutputGain: (AudioUnitParameterValue) newGain {
    
    OSStatus result = AudioUnitSetParameter (
                                             mixerUnit,
                                             kMultiChannelMixerParam_Volume,
                                             kAudioUnitScope_Output,
                                             0,
                                             newGain,
                                             0
                                             );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetParameter (set mixer unit output volume)" withStatus: result]; return;}
    
}


#pragma mark -
#pragma mark Audio Session Delegate Methods
// Respond to having been interrupted. This method sends a notification to the 
//    controller object, which in turn invokes the playOrStop: toggle method. The 
//    interruptedDuringPlayback flag lets the  endInterruptionWithFlags: method know 
//    whether playback was in progress at the time of the interruption.
- (void) beginInterruption {
    
    NSLog (@"Audio session was interrupted.");
    
    if (playing) {
        
        self.interruptedDuringPlayback = YES;
        
        NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";
        [[NSNotificationCenter defaultCenter] postNotificationName: MixerHostAudioObjectPlaybackStateDidChangeNotification object: self]; 
    }
}


// Respond to the end of an interruption. This method gets invoked, for example, 
//    after the user dismisses a clock alarm. 
- (void) endInterruptionWithFlags: (NSUInteger) flags {
    
    // Test if the interruption that has just ended was one from which this app 
    //    should resume playback.
    if (flags & AVAudioSessionInterruptionFlags_ShouldResume) {
        
        NSError *endInterruptionError = nil;
        [[AVAudioSession sharedInstance] setActive: YES
                                             error: &endInterruptionError];
        if (endInterruptionError != nil) {
            
            NSLog (@"Unable to reactivate the audio session after the interruption ended.");
            return;
            
        } else {
            
            NSLog (@"Audio session reactivated after interruption.");
            
            if (interruptedDuringPlayback) {
                
                self.interruptedDuringPlayback = NO;
                
                // Resume playback by sending a notification to the controller object, which
                //    in turn invokes the playOrStop: toggle method.
                NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";
                [[NSNotificationCenter defaultCenter] postNotificationName: MixerHostAudioObjectPlaybackStateDidChangeNotification object: self]; 
                
            }
        }
    }
}


#pragma mark -
#pragma mark Utility methods

// You can use this method during development and debugging to look at the
//    fields of an AudioStreamBasicDescription struct.
- (void) printASBD: (AudioStreamBasicDescription) asbd {
    
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10X",    (unsigned int)asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10u",    (unsigned int)asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10u",    (unsigned int)asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10u",    (unsigned int)asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10u",    (unsigned int)asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10u",    (unsigned int)asbd.mBitsPerChannel);
}


- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result {
    
    char resultString[5];
    UInt32 swappedResult = CFSwapInt32HostToBig (result);
    bcopy (&swappedResult, resultString, 4);
    resultString[4] = '\0';
    
    NSLog (
           @"*** %@ error: %s %08X %4.4s\n",
           errorString,
           (char*) &resultString
           );
}


#pragma mark -
#pragma mark Deallocate

- (void) dealloc {
    
    [database1 release];
    
    for (int audioFile = 0; audioFile < busNum; ++audioFile)  {    
        
        if (sourceURLArray[audioFile] != NULL) CFRelease (sourceURLArray[audioFile]);
        
        if (soundStructArray[audioFile].audioDataLeft != NULL) {
            free (soundStructArray[audioFile].audioDataLeft);
            soundStructArray[audioFile].audioDataLeft = 0;
        }
        
        if (soundStructArray[audioFile].audioDataRight != NULL) {
            free (soundStructArray[audioFile].audioDataRight);
            soundStructArray[audioFile].audioDataRight = 0;
        }
        [sourcePath[audioFile] release];
    }
    //when mixer dealloc, also remove property listener.
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange, CarolAudioRouteChangeListenerCallback, self);
    [super dealloc];
}

@end

