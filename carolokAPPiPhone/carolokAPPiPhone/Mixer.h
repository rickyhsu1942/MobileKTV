/*
 2012/5/21
 This code copy from MixerHost from apple code sample.
 edit by jay
 
 Goals:
 1. load four audio streams
 2. mix all four audio streams
 3. configure all audio stream 
 4. output one stream
 */
//
//  Mixer.h
//  Mixer Demo
//
//  Created by 國立中興大學 資訊工程學系 國立中興大學 資訊工程學系 on 12/5/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define NUM_FILES 4

@class DBTool;
@class SQLiteDBTool;
// Data structure for mono or stereo sound, to pass to the application's render callback function, 
//    which gets invoked by a Mixer unit input bus when it needs more audio to play.
typedef struct {
    
    BOOL                 isStereo;           // set to true if there is data in the audioDataRight member
    UInt32               frameCount;         // the total number of frames in the audio data
    UInt64               sampleNumber;       // the next audio sample to play
    AudioUnitSampleType  *audioDataLeft;     // the complete left (or mono) channel of audio data read from an audio file
    AudioUnitSampleType  *audioDataRight;    // the complete right channel of audio data read from an audio file
    
} soundStruct, *soundStructPtr;

typedef struct {
    AudioUnit       rioUnit;
    ExtAudioFileRef audioFileRef;
    UInt32          startTime;
    UInt32          frameCount;
} EffectState;

@interface Mixer : NSObject <AVAudioSessionDelegate>
{
    EffectState effectState;
    Float64                         graphSampleRate;
    CFURLRef                        sourceURLArray[NUM_FILES];
    soundStruct                     soundStructArray[NUM_FILES];
    NSString                        *sourcePath[NUM_FILES];
    
    // Before using an AudioStreamBasicDescription struct you must initialize it to 0. However, because these ASBDs
    // are declared in external storage, they are automatically initialized to 0.
    AudioStreamBasicDescription     stereoStreamFormat;
    AudioStreamBasicDescription     monoStreamFormat;
    AUGraph                         processingGraph;
    BOOL                            playing;
    BOOL                            interruptedDuringPlayback;
    AudioUnit                       mixerUnit;
    //DBTool                          *database;
    SQLiteDBTool                    *database1;
    int                             busNum;
}
@property (readwrite)           AudioStreamBasicDescription stereoStreamFormat;
@property (readwrite)           AudioStreamBasicDescription monoStreamFormat;
@property (readwrite)           Float64                     graphSampleRate;
@property (getter = isPlaying)  BOOL                        playing;
@property                       BOOL                        interruptedDuringPlayback;
@property                       BOOL                        isRecorded;
@property                       AudioUnit                   mixerUnit;

//seek to specific time
- (void)mixerInput:(UInt32)inputBus seekTime:(float)ratio;

//set record
- (void) setRecordNow:(BOOL)isRecord;
- (BOOL) getRecordNow;

//set # of bus for mixer
- (void) setBusCount:(int)value;

- (void) setSourcePathwithIndex:(int)index value:(NSString*)path;

- (void) initialToReady;

- (void) obtainSoundFileURLs;

- (void) setupAudioSession;

- (void) setupStereoStreamFormat;
- (void) setupMonoStreamFormat;
- (void) readAudioFilesIntoMemory;

- (void) configureAndInitializeAudioProcessingGraph;
- (void) startAUGraph;
- (void) stopAUGraph;

- (void) enableMixerInput: (UInt32) inputBus isOn: (AudioUnitParameterValue) isONValue;
- (void) setMixerInput: (UInt32) inputBus gain: (AudioUnitParameterValue) inputGain;
- (void) setMixerOutputGain: (AudioUnitParameterValue) outputGain;

- (void) printASBD: (AudioStreamBasicDescription) asbd;
- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result;

- (Float64)mixerInputGetCurrentProgress:(UInt32)inputBus ;

@end
