/*
 
 Originally from Apple MixerHost app
 
 File: KOKSMixerHostAudio.h
 Abstract: Audio object: Handles all audio tasks for the application.
 Version: 1.0
 

 */


#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>			// for vdsp functions

//#import "TPCircularBuffer.h"              // for ring buffers 

#define NUM_CHANNELS 2                         // number of audio files read in by old method

#define kDelayBufferLength 1024 * 100       // measured in slices - a couple seconds worth at 44.1k

//#define DEBUG	1

#define kAudioBufferNumFrames	(8192)		/* 8192 number of frames in our cache */
#define kOversample				1			/* leave at this value in this version */


// Data structure for mono or stereo sound, to pass to the application's render callback function, 
//    which gets invoked by a Mixer unit input bus when it needs more audio to play.
//
// Note: this is used by the callbacks for playing looped files (old way)
typedef struct {
    
    BOOL                 isStereo;           // set to true if there is data in the audioDataRight member
    UInt32               frameCount;         // the total number of frames in the audio data
    UInt32               sampleNumber;       // the next audio sample to play
    AudioUnitSampleType  *audioDataLeft;     // the complete left (or mono) channel of audio data read from an audio file
    AudioUnitSampleType  *audioDataRight;    // the complete right channel of audio data read from an audio file
    
} soundStruct, *soundStructPtr;




@interface KOKSMixerHostAudio : NSObject <AVAudioSessionDelegate> {
    
    Float64                         graphSampleRate;                   // audio graph sample rate
    CFURLRef                        sourceURLArray[NUM_CHANNELS];      // for handling left/right-channel files
    soundStruct                     soundStructArray[NUM_CHANNELS];    // scope reference for left/right channels' callback
	
    
    
    // Before using an AudioStreamBasicDescription struct you must initialize it to 0. However, because these ASBDs
    // are declared in external storage, they are automatically initialized to 0. 
    
    AudioStreamBasicDescription     stereoStreamFormat;     // standard stereo 8.24 fixed point
    AudioStreamBasicDescription     monoStreamFormat;       // standard mono 8.24 fixed point
    AudioStreamBasicDescription     SInt16StreamFormat;		// signed 16 bit int sample format
	AudioStreamBasicDescription     floatStreamFormat;		// float sample format (for testing)
    AudioStreamBasicDescription     auEffectStreamFormat;		// audio unit Effect format 
    AudioStreamBasicDescription     auVocalEffectStreamFormat;		// audio unit Effect format
    AudioStreamBasicDescription     auEffectReverbStreamFormat;		// audio unit Effect format
    AudioStreamBasicDescription     auConvertStreamFormat;
    AudioStreamBasicDescription     auConvert2StreamFormat;		// audio unit Effect format

    
    
    AUGraph                         processingGraph;        // the main audio graph
    
    BOOL                            playing;                // indicates audiograph is running
    BOOL                            interruptedDuringPlayback;  // indicates interruption happened while audiograph running
    
    // some of the audio units in this app
    
    
    AudioUnit                       ioUnit;                 // remote io unit
    AudioUnit                       mixerUnit;              // multichannel mixer audio unit
    AudioUnit						auEffectUnit;           // this is the master effect on mixer output
    AudioUnit						auVocalEffectUnit;      // this is themaster effect on vocal output
    AudioUnit						auEffectReverbUnit;     // this is the master effect on Reverb (iOS 5)
    AudioUnit                       auConvertUnit;
    
    
    // audio graph nodes
    
    AUNode      iONode;              // node for I/O unit speaker
    AUNode      mixerNode;           // node for Multichannel Mixer unit
    AUNode      auEffectNode;        // master mix effect node
    AUNode      auVocalEffectNode;   // Vocal effect node
    AUNode      auEffectReverbNode;  // effect node (Reverb)
    AUNode      auConvertNode;    
    
	// fft
    
	FFTSetup fftSetup;			// fft predefined structure required by vdsp fft functions
	COMPLEX_SPLIT fftA;			// complex variable for fft
	int fftLog2n;               // base 2 log of fft size
    int fftN;                   // fft size
    int fftNOver2;              // half fft size
	size_t fftBufferCapacity;	// fft buffer size (in samples)
	size_t fftIndex;            // read index pointer in fft buffer 
    
    // working buffers for sample data
    
	void *dataBuffer;               //  input buffer from mic/line
	float *outputBuffer;            //  fft conversion buffer
	float *analysisBuffer;          //  fft analysis buffer
    SInt16 *conversionBufferLeft;   // for data conversion from fixed point to integer
    SInt16 *conversionBufferRight;   // for data conversion from fixed point to integer
    
    // convolution 
    
   	float *filterBuffer;        // impusle response buffer
    int filterLength;           // length of filterBuffer
    float *signalBuffer;        // signal buffer
    int signalLength;           // signal length
    float *resultBuffer;        // result buffer
    int resultLength;           // result length
    
    
    // new instance variables for UI display objects
	
    int displayInputFrequency;              // frequency determined by analysis 
    float displayInputLevelLeft;            // average input level for meter left channel
    float displayInputLevelRight;           // average input level for meter right channel
    int displayNumberOfInputChannels;       // number of input channels detected on startup
    
    
    // mic FX type selection
    
    int micFxType;  // enumerated fx types: 
    // 0: ring mod
    // 1: fft
    // 2: pitch shift
    // 3: echo (delay)
    // 4: low pass filter (moving average)
    // 5: low pass filter (convolution)
    
    BOOL  micFxOn;       // toggle for using mic fx
    float micFxControl; // multipurpose mix fx control slider
    
    BOOL inputDeviceIsAvailable;    // indicates whether input device is available on ipod touch
    
    //------
    AVAssetWriterInput  *vocalWriterInput;
    NSString            *tmpVocalFileName;
    ExtAudioFileRef     extRecordingAudioFileRef;
    AudioBufferList		*audioBufferList;
    //
    NSURL               *songUrl;
    
    // for DiracFx3
    void                *mDiracFx31;
    void                *mDiracFx32;
    float               mPitchFactor;
    SInt16              **mAudioIn;
    SInt16              **mAudioOut;
    
    // for LOW_PASS @2014/1/10
    Float32             mLowPassCutoffFrequency;
    Float32             mLowPassCutoffDB;
}

// property declarations - corresponding to instance variables declared above

@property (readwrite)           AudioStreamBasicDescription stereoStreamFormat;
@property (readwrite)           AudioStreamBasicDescription monoStreamFormat;
@property (readwrite)           AudioStreamBasicDescription SInt16StreamFormat;	
@property (readwrite)           AudioStreamBasicDescription floatStreamFormat;	
@property (readwrite)           AudioStreamBasicDescription auEffectStreamFormat;
@property (readwrite)           AudioStreamBasicDescription auVocalEffectStreamFormat;
@property (readwrite)           AudioStreamBasicDescription auEffectReverbStreamForamt;
@property (readwrite)           AudioStreamBasicDescription auConvertStreamFormat;

@property (readwrite)           Float64                     graphSampleRate;

@property (getter = isPlaying)  BOOL                        playing;
@property                       BOOL                        interruptedDuringPlayback;

@property                       AudioUnit                   ioUnit;
@property                       AudioUnit                   mixerUnit;
@property                       AudioUnit                   auEffectUnit;
@property                       AudioUnit                   auVocalEffectUnit;
@property                       AudioUnit                   auEffectReverbUnit;
@property                       AudioUnit                   auConvertUnit;

@property                       AUNode                      iONode;             
@property                       AUNode                      mixerNode;         
@property                       AUNode                      auEffectNode;
@property                       AUNode                      auVocalEffectNode;
@property                       AUNode                      auEffectReverbNode;
@property                       AUNode                      auConvertNode;

// for pitch-shifting ----------------------------------------------------------
@property                       AudioUnit                   auTimePitchUnit1;
@property                       AudioUnit                   auTimePitchUnit2;
@property                       AudioUnit                   auTimePitchUnit3;
@property                       AudioUnit                   auConvertUnit1;
@property                       AudioUnit                   auConvertUnit2;
//
@property                       AUNode                      auTimePitchNode1;
@property                       AUNode                      auTimePitchNode2;
@property                       AUNode                      auTimePitchNode3;
@property                       AUNode                      auConvertNode1;
@property                       AUNode                      auConvertNode2;
//
@property                       soundStructPtr              soundStructArrayPt;
// ------------------------------------------------------------------------------
@property FFTSetup fftSetup;			
@property COMPLEX_SPLIT fftA;			
@property int fftLog2n;
@property int fftN;
@property int fftNOver2;		

@property void *dataBuffer;			
@property float *outputBuffer;		
@property float *analysisBuffer;	

@property SInt16 *conversionBufferLeft;	
@property SInt16 *conversionBufferRight;	

@property float *filterBuffer;      // filter buffer
@property int filterLength;         // filter length
@property float *signalBuffer;      // signal buffer
@property int signalLength;         // signal length
@property float *resultBuffer;      // signal buffer
@property int resultLength;         // signal length


@property size_t fftBufferCapacity;	
@property size_t fftIndex;	


@property (assign) int displayInputFrequency;
@property (assign) float displayInputLevelLeft;
@property (assign) float displayInputLevelRight;
@property (assign) int displayNumberOfInputChannels;


@property int   micFxType;
@property BOOL  micFxOn;
@property float micFxControl;

@property BOOL inputDeviceIsAvailable;

@property AVAssetWriterInput  *vocalWriterInput; // for recording user-vocal
@property NSString *tmpVocalFileName;            // for recording user-vocal
@property ExtAudioFileRef extRecordingAudioFileRef; // ... ...
@property AudioBufferList *audioBufferList;

// for DiracFx3
@property void *mDiracFx31;
@property void *mDiracFx32;
@property float mPitchFactor;
@property SInt16 **mAudioIn;
@property SInt16 **mAudioOut;

// for LOW_PASS, @2014/1/10
@property Float32 mLowPassCutoffFrequency;
@property Float32 mLowPassCutoffDB;
// ----------------------------------

// function (method) declarations
- (id) initWithAsset:(AVAsset *) asset;
- (id) initWithUrl:(NSURL *) songUrl;
- (void) initSoundFileURLs;
- (void) setupAudioSession;
- (void) setupStereoStreamFormat;
- (void) setupMonoStreamFormat;


- (void) setupSInt16StreamFormat;
- (void) setupFloatStreamFormat; // tz

- (void) readAudioFilesIntoMemory;
- (void) readAudioAssetIntoMemory:(AVAsset *) orgAsset;
- (void) seekToTime:(Float64) seekTime;
- (Float64) currentTime;
- (BOOL) isEndOfMusic;
- (BOOL) isEndOfMov;


- (void) configureAndInitializeAudioProcessingGraph;

- (void) setupAudioProcessingGraph;
- (void) connectAudioProcessingGraph;

// ------- for Recording Vocal file ------------
-(AudioBufferList*)	allocateAudioBufferListWithNumChannels: (UInt32)numChannels withSize: (UInt32)size;
-(void)	destroyAudioBufferList: (AudioBufferList *)list;
// --------------------------------------------

- (void) startAUGraph;
- (void) stopAUGraph;

- (void) setMixerInput:(UInt32)inputBus panValue:(AudioUnitParameterValue)newPanGain;
- (void) enableMixerInput: (UInt32) inputBus isOn: (AudioUnitParameterValue) isONValue;
- (void) setMixerInput: (UInt32) inputBus gain: (AudioUnitParameterValue) inputGain;
- (void) setMixerOutputGain: (AudioUnitParameterValue) outputGain;
- (void) setMixerFx: (AudioUnitParameterValue) isOnValue;


- (void) printASBD: (AudioStreamBasicDescription) asbd;
- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result;

- (void) convolutionSetup;
- (void) FFTSetup;
- (void) initDelayBuffer;

- (Float32) getMixerOutputLevel;
- (void) setReverbDryWetMix:(Float32)dryWetValue gain:(Float32)gainValue minDelay:(Float32)minDelayValue maxDelay:(Float32)maxDelayValue f0HzDecay:(Float32)f0HzDecayValue fNyquistDecay:(Float32)fNyquistDecayValue randReflectRate:(Float32)randReflectRateValue;
- (void) setReverbDryWetMix:(Float32)value;
- (void) setReverbRandomReflections:(int)rvalue;
- (void) setReverb0HzDecayTime:(Float32)value1 NyquistDecayTime:(Float32)value2;
- (void) setReverbGain:(Float32)value;
- (void) releaseAudioSession;
- (void) registerAudioSession;
- (void) startRecording:(NSString *) fileName;
- (void) stopRecording;
- (void) releaseAudioBuffer;

//-- for pitch-shifting -------------
- (void) setMusicWithPitch:(int)newPitch withRate:(float)newRate ;
- (void) setVoiceWithPitch:(int)newPitch withRate:(float)newRate ;
//-----------------------------------
- (void) setPitchFactor:(int)pitch;
//-----------------------------------
//-----------------------------------
// for LOW_PASS, @2014/1/10
//-----------------------------------
- (void) setLowPassFrequency:(Float32)lowPassFreq cutOffDB:(Float32) cutOffDB;
//-----------------------------------

@end

