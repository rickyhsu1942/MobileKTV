/*
 
 Original comments from Apple:
 
 File: KOKSMixerHostAudio.m
 Abstract: Audio object: Handles all audio tasks for the application.
 Version: 1.0
 
 
 */


#import "KOKSMixerHostAudio.h"      

#import "TPCircularBuffer.h"        // ring buffer
#import "SNFCoreAudioUtils.h"       // Chris Adamson's debug print util
//------
#import "ZTX.h"        // ZTX header

#include "Utilities.h"

//#define NODEBUG 1
#ifdef NODEBUG
   #define MyLog(str, ...)
#else
   #define MyLog(str, ...) NSLog(str, ##__VA_ARGS__)
#endif

// function defs for fft code

float MagnitudeSquared(float x, float y);
void ConvertInt16ToFloat(KOKSMixerHostAudio *THIS, void *buf, float *outputBuf, size_t capacity);

// function defs for smb fft code

void smbPitchShift(float pitchShift, long numSampsToProcess, long fftFrameSize, long osamp, float sampleRate, float *indata, float *outdata);

void smb2PitchShift(float pitchShift, long numSampsToProcess, long fftFrameSize,
					long osamp, float sampleRate, float *indata, float *outdata,
					FFTSetup fftSetup, float * frequency);


// function defs for mic fx dsp methods used in callbacks


void ringMod( void *inRefCon,  UInt32 inNumberFrames, SInt16 *sampleBuffer );
OSStatus fftPassThrough ( void *inRefCon, UInt32 inNumberFrames, SInt16 *sampleBuffer);
OSStatus fftPitchShift ( void *inRefCon, UInt32 inNumberFrames, SInt16 *sampleBuffer);
OSStatus doPitchShift ( void *inRefCon, int numOfSemitone, UInt32 inNumberFrames, SInt16 *sampleBuffer);
OSStatus simpleDelay ( void *inRefCon, UInt32 inNumberFrames, SInt16 *sampleBuffer);
OSStatus movingAverageFilterFloat ( void *inRefCon, UInt32 inNumberFrames, SInt16 *sampleBuffer);
OSStatus logFilter ( void *inRefCon, UInt32 inNumberFrames, SInt16 *sampleBuffer);
OSStatus convolutionFilter ( void *inRefCon, UInt32 inNumberFrames, SInt16 *sampleBuffer);

// function defs for audio processing to support callbacks

void  lowPassWindowedSincFilter( float *buf , float fc );
float xslide(int sval, float x );
void fixedPointToSInt16( SInt32 * source, SInt16 * target, int length );
void SInt16ToFixedPoint( SInt16 * source, SInt32 * target, int length );
float getMeanVolumeSint16( SInt16 * vector , int length );

// audio callbacks

static OSStatus inputRenderCallback (void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp,  UInt32  inBusNumber,   UInt32  inNumberFrames,  AudioBufferList *ioData );


static OSStatus musicRenderCallback (void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp,  UInt32  inBusNumber,   UInt32  inNumberFrames,  AudioBufferList *ioData );

static OSStatus musicRenderCallbackBus0 (void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp,  UInt32  inBusNumber,   UInt32  inNumberFrames,  AudioBufferList *ioData );

static OSStatus musicRenderCallbackBus1 (void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp,  UInt32  inBusNumber,   UInt32  inNumberFrames,  AudioBufferList *ioData );

static OSStatus micLineInRenderCallback (void *inRefCon, AudioUnitRenderActionFlags  *ioActionFlags, const AudioTimeStamp *inTimeStamp,  UInt32  inBusNumber,   UInt32  inNumberFrames,  AudioBufferList *ioData );

void audioRouteChangeListenerCallback ( void   *inUserData,  AudioSessionPropertyID  inPropertyID,  UInt32 inPropertyValueSize,  const void  *inPropertyValue );


// ring buffer buffer declarations

// SInt16 circular delay buffer (used for echo effect)

SInt16 *delayBuffer;
TPCircularBufferRecord delayBufferRecord;
NSLock *delayBufferRecordLock;
SInt16 *tempDelayBuffer;

// float circular filter buffer declarations (used for filters)

float *circularFilterBuffer;
TPCircularBufferRecord circularFilterBufferRecord;
NSLock *circularFilterBufferRecordLock;
float *tempCircularFilterBuffer;

// end of declarations //


//////////////
/*
 *  Utilities.cpp
 *
 *  Created by Stephan on 21.03.11.
 *  Copyright 2011-2012 The DSP Dimension. All rights reserved.
 *	Version 3.6
 */

#include "Utilities.h"


#pragma mark Helper Functions

// ---------------------------------------------------------------------------------------------------------------------------

void arc_release(id a)
{
#if __has_feature(objc_arc)
    a = nil;
#else
    [a release];
    a = nil;
#endif
    
}
// ---------------------------------------------------------------------------------------------------------------------------

id arc_retain(id a)
{
#if __has_feature(objc_arc)
    
#else
    [a retain];
#endif
    return a;
}

// ---------------------------------------------------------------------------------------------------------------------------

void checkStatus(int status)
{
	if (status)
		printf("Status not 0! %d\n", status);
}
// ---------------------------------------------------------------------------------------------------------------------------

long wrappedDiff(long in1, long in2, long wrap)
{
	long m1 = in2-in1;
	if (m1 < 0) m1 = (in2+wrap)-in1;
	return m1;
}
// ---------------------------------------------------------------------------------------------------------------------------

void DeallocateAudioBuffer(SInt16 **audio, int numChannels)
{
	if (!audio) return;
	for (long v = 0; v < numChannels; v++) {
		if (audio[v]) {
			free(audio[v]);
			audio[v] = nil;
		}
	}
	free(audio);
	audio = nil;
}
// ---------------------------------------------------------------------------------------------------------------------------

void DeallocateAudioBufferWithFloat(float **audio, int numChannels)
{
	if (!audio) return;
	for (long v = 0; v < numChannels; v++) {
		if (audio[v]) {
			free(audio[v]);
			audio[v] = nil;
		}
	}
	free(audio);
	audio = nil;
}
// ---------------------------------------------------------------------------------------------------------------------------

float **AllocateAudioBuffer(int numChannels, int numFrames)
{
	// Allocate buffer for output
	float **audio = (float**)malloc(numChannels*sizeof(float*));
	if (!audio) return NULL;
	memset(audio, 0, numChannels*sizeof(float*));
	for (long v = 0; v < numChannels; v++) {
		audio[v] = (float*)malloc(numFrames*sizeof(float));
		if (!audio[v]) {
			DeallocateAudioBuffer(audio, numChannels);
			return NULL;
		}
		else memset(audio[v], 0, numFrames*sizeof(float));
	}
	return audio;
}
// ---------------------------------------------------------------------------------------------------------------------------

SInt16 **AllocateAudioBufferSInt16(int numChannels, int numFrames)
{
	// Allocate buffer for output
	SInt16 **audio = (SInt16**)malloc(numChannels*sizeof(SInt16*));
	if (!audio) return NULL;
	memset(audio, 0, numChannels*sizeof(SInt16*));
	for (long v = 0; v < numChannels; v++) {
		audio[v] = (SInt16*)malloc(numFrames*sizeof(SInt16));
		if (!audio[v]) {
			DeallocateAudioBuffer(audio, numChannels);
			return NULL;
		}
		else memset(audio[v], 0, numFrames*sizeof(SInt16));
	}
	return audio;
}
// ---------------------------------------------------------------------------------------------------------------------------

void ClearAudioBufferWithFloat(float **audio, long numChannels, long numFrames)
{
	for (long v = 0; v < numChannels; v++) {
		memset(audio[v], 0, numFrames*sizeof(float));
	}
}
// ---------------------------------------------------------------------------------------------------------------------------

void ClearAudioBufferSInt16(SInt16 **audio, long numChannels, long numFrames)
{
	for (long v = 0; v < numChannels; v++) {
		memset(audio[v], 0, numFrames*sizeof(SInt16));
	}
}

// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------


/////////////////////
#pragma mark -
#pragma mark Callback functions

#pragma mark Mixer input bus 0/1 render callback (Music buffers)

//  Callback for MP3/MP4 Audio input - mixer channels 0/1
//
//  original comments from Apple:

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
//
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
    
    // 全部換為左聲道！
    if (inBusNumber==0) {
       dataInLeft                 = soundStructPointerArray[inBusNumber].audioDataLeft;
       if (isStereo) dataInRight  = soundStructPointerArray[inBusNumber].audioDataRight;
    }
    else {
        dataInLeft                 = soundStructPointerArray[inBusNumber].audioDataLeft;
        if (isStereo) {
            dataInRight  = soundStructPointerArray[inBusNumber].audioDataLeft;
            dataInLeft  = soundStructPointerArray[inBusNumber].audioDataRight;
        }
    }
    // Establish pointers to the memory into which the audio from the buffers should go. This reflects
    //    the fact that each Multichannel Mixer unit input bus has two channels, as specified by this app's
    //    graphStreamFormat variable.
    AudioUnitSampleType *outSamplesChannelLeft;
    AudioUnitSampleType *outSamplesChannelRight;
    
    outSamplesChannelLeft                 = (AudioUnitSampleType *) ioData->mBuffers[0].mData;
    if (isStereo) outSamplesChannelRight  = (AudioUnitSampleType *) ioData->mBuffers[1].mData;
    
    // Get the sample number, as an index into the sound stored in memory,
    //    to start reading data from.
    UInt32 sampleNumber = soundStructPointerArray[inBusNumber].sampleNumber;
    
    // Fill the buffer or buffers pointed at by *ioData with the requested number of samples 
    //    of audio from the sound stored in memory.
    for (UInt32 frameNumber = 0; frameNumber < inNumberFrames; ++frameNumber) {
        if (sampleNumber < frameTotalForSound) {
          outSamplesChannelLeft[frameNumber]                 = dataInLeft[sampleNumber];
          if (isStereo && outSamplesChannelRight!=nil)
              outSamplesChannelRight[frameNumber]  = dataInRight[sampleNumber];
        }
        else {
            outSamplesChannelLeft[frameNumber]   = 0;
            if (isStereo && outSamplesChannelRight!=nil)
                outSamplesChannelRight[frameNumber]  = 0;
        } 
        sampleNumber++;

    }
    
    // Update the stored sample number so, the next time this callback is invoked, playback resumes 
    //    at the correct spot.
    soundStructPointerArray[inBusNumber].sampleNumber = sampleNumber;
    
    return noErr;
}

//-----------------------
// for pitch-shifting
//-----------------------

static OSStatus musicRenderCallback (
                                     
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
    
    // soundStructPtr    soundStructPointerArray   = (soundStructPtr) inRefCon;
    KOKSMixerHostAudio *THIS = (__bridge KOKSMixerHostAudio *)inRefCon;
    soundStructPtr    soundStructPointerArray   = THIS.soundStructArrayPt;
    float             mPitchFactor = THIS.mPitchFactor;
    void              *diracFx3    = THIS.mDiracFx31;

    //
    UInt32            frameTotalForSound        = soundStructPointerArray[inBusNumber].frameCount;
    BOOL              isStereo                  = soundStructPointerArray[inBusNumber].isStereo;
    
    // Declare variables to point to the audio buffers. Their data type must match the buffer data type.
    AudioUnitSampleType *dataInLeft = nil;
    AudioUnitSampleType *dataInRight = nil;
    
    // Source(Input from Buffer/Memory): 全部換為左聲道！
    if (inBusNumber==0) {
        diracFx3 = THIS.mDiracFx31;
        dataInLeft                 = soundStructPointerArray[inBusNumber].audioDataLeft;
        if (isStereo) dataInRight  = soundStructPointerArray[inBusNumber].audioDataRight;
    }
    else {
        diracFx3 = THIS.mDiracFx32;
        if (isStereo) {
            // 左右交換～
            dataInRight  = soundStructPointerArray[inBusNumber].audioDataLeft;
            dataInLeft  = soundStructPointerArray[inBusNumber].audioDataRight;
        }
        else {
            dataInLeft   = soundStructPointerArray[inBusNumber].audioDataLeft;
            dataInRight  = soundStructPointerArray[inBusNumber].audioDataLeft;
        }
    }
    
    // Establish pointers to the memory into which the audio from the buffers should go.
    AudioUnitSampleType *outSamplesChannelLeft;
    AudioUnitSampleType *outSamplesChannelRight;
    
    outSamplesChannelLeft = (AudioUnitSampleType *) ioData->mBuffers[0].mData;
    if (isStereo)
        // maybe it need only MONO !?
        outSamplesChannelRight  = (AudioUnitSampleType *) ioData->mBuffers[1].mData;
    else
        outSamplesChannelRight = nil;
    
    // Get the sample number, as an index into the sound stored in memory,
    //    to start reading data from.
    UInt32 sampleNumber = soundStructPointerArray[inBusNumber].sampleNumber;
    
    // Fill the buffer or buffers pointed at by *ioData with the requested number of samples
    //    of audio from the sound stored in memory.
    UInt32 frameNumber=0;
    for (frameNumber = 0; frameNumber < inNumberFrames; ++frameNumber) {
        if (sampleNumber < frameTotalForSound) {
            outSamplesChannelLeft[frameNumber] = dataInLeft[sampleNumber];
            //if (isStereo && outSamplesChannelRight != nil)
             //   outSamplesChannelRight[frameNumber]  = dataInRight[sampleNumber];
        }
        else {
            outSamplesChannelLeft[frameNumber]   = 0;
            //if (isStereo && outSamplesChannelRight != nil)
            //    outSamplesChannelRight[frameNumber]  = 0;
            
        }
        sampleNumber++;
        
    }
    
    // Update the stored sample number so, the next time this callback is invoked, playback resumes
    //    at the correct spot.
    soundStructPointerArray[inBusNumber].sampleNumber = sampleNumber;
    
    // Don't need to do the pitch-shifting procedure!
    if (mPitchFactor == 1.0)
         return noErr;
    
    /*
     //--------------------------------------------------------
     // For 3dMixer, we need manually convert 8.24 --> SInt16
     //--------------------------------------------------------
     SInt16 *sampleBufferLeft = THIS.conversionBufferLeft;
     SInt16 *sampleBufferRight = THIS.conversionBufferRight;
     fixedPointToSInt16(outSamplesChannelLeft, outSamplesChannelLeft, inNumberFrames);
     if (outSamplesChannelRight!=nil) fixedPointToSInt16(outSamplesChannelRight, outSamplesChannelRight, inNumberFrames);
     //--------------------------------------------------------
     */
    
    
     //--------------------------------------------------------
     // For DiracFx3 LE 
     //--------------------------------------------------------
     // Allocate buffer for Dirac output
   
    SInt16 **audioIn = THIS.mAudioIn;
    SInt16 **audioOut = THIS.mAudioOut;
    //
    long framesOut = 0;
    fixedPointToSInt16(outSamplesChannelLeft, audioIn[0], inNumberFrames);
    framesOut = ZtxFxProcess( 1.0f, mPitchFactor, audioIn, audioOut, inNumberFrames, diracFx3);
    if (inNumberFrames != framesOut)
        printf("DiracFxProcess: original frame num:%ld, after frame num:%ld\n", inNumberFrames, framesOut);
    SInt16ToFixedPoint(audioOut[0], outSamplesChannelLeft, inNumberFrames);
    
    if (isStereo && outSamplesChannelRight != nil) {
        fixedPointToSInt16(outSamplesChannelRight, audioIn[0], inNumberFrames);
        framesOut = ZtxFxProcess( 1.0, mPitchFactor, audioIn, audioOut, inNumberFrames, diracFx3);
        SInt16ToFixedPoint(audioOut[0], outSamplesChannelRight, inNumberFrames);
    }
    
    
    /*
    // -----------------------------------
    // TRY the open source solution !
    // -----------------------------------
    // After got the music, we do pitch-shifting if need!
    int numOfSemitoneShift = 0;
    
     if (mPitchFactor != 1.0) {
         // Sint16 buffers to hold sample data after conversion
         SInt16 *sampleBufferLeft = THIS.conversionBufferLeft;
         SInt16 *sampleBufferRight = THIS.conversionBufferRight;
         
         // left channel
         // (1) convert to SInt16
         fixedPointToSInt16(outSamplesChannelLeft, sampleBufferLeft, inNumberFrames);
         // (2)
         doPitchShift(inRefCon, numOfSemitoneShift, inNumberFrames, sampleBufferLeft);
         //
         if (isStereo && outSamplesChannelRight!=nil) {
             // right channel
             fixedPointToSInt16(outSamplesChannelRight, sampleBufferRight, inNumberFrames);
             doPitchShift(inRefCon, numOfSemitoneShift, inNumberFrames, sampleBufferRight);
         }
         // convert back to 8.24 fixed point
         SInt16ToFixedPoint(sampleBufferLeft, outSamplesChannelLeft, inNumberFrames);
         if(isStereo && outSamplesChannelRight!=nil) {
             SInt16ToFixedPoint(sampleBufferRight, outSamplesChannelRight, inNumberFrames);
         }
     }
     //----------------
    */
    
    return noErr;
}

//
static OSStatus musicRenderCallbackBus0 (
                                         void                        *inRefCon,
                                         AudioUnitRenderActionFlags  *ioActionFlags,
                                         const AudioTimeStamp        *inTimeStamp,
                                         UInt32                      inBusNumber,
                                         UInt32                      inNumberFrames,
                                         AudioBufferList             *ioData         ) {
    // for stereo channel-bus0
    inBusNumber = 0;
    return musicRenderCallback( inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
}

static OSStatus musicRenderCallbackBus1 (
                                         void                        *inRefCon,
                                         AudioUnitRenderActionFlags  *ioActionFlags,
                                         const AudioTimeStamp        *inTimeStamp,
                                         UInt32                      inBusNumber,
                                         UInt32                      inNumberFrames,
                                         AudioBufferList             *ioData         ) {
    // for stereo channel-bus1
    inBusNumber = 1;
    return musicRenderCallback( inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
}

//---------------------------

#pragma mark Mic, line in Audio Rendering

////////////////////////////////
// callback for mic/lineIn input
//
// 
// this callback is now the clearinghouse for
// DSP fx processing 
//
//

OSStatus micLineInCallback (void					    *inRefCon, 
                            AudioUnitRenderActionFlags 	*ioActionFlags, 
                            const AudioTimeStamp		*inTimeStamp, 
                            UInt32 						inBusNumber, 
                            UInt32 						inNumberFrames, 
                            AudioBufferList				*ioData)
{
	
	// set params & local variables
    
    // scope reference that allows access to everything in KOKSMixerHostAudio class
    
	KOKSMixerHostAudio *THIS = (__bridge KOKSMixerHostAudio *)inRefCon;
    
    AudioUnit rioUnit = THIS.ioUnit;    // io unit which has the input data from mic/lineIn
    int i;                              // loop counter
    
	OSStatus err;                       // error returns
	OSStatus renderErr;
	
    UInt32 bus1 = 1;                    // input bus
	
    
    AudioUnitSampleType *inSamplesLeft;         // convenience pointers to sample data
    AudioUnitSampleType *inSamplesRight;
    
    int isStereo;               // c boolean - for deciding how many channels to process.
    int numberOfChannels;       // 1 = mono, 2= stereo
    
    // Sint16 buffers to hold sample data after conversion 
    
    SInt16 *sampleBufferLeft = THIS.conversionBufferLeft;
    SInt16 *sampleBufferRight = THIS.conversionBufferRight;
    SInt16 *sampleBuffer;
    
	
    // start the actual processing 
    
    numberOfChannels = THIS.displayNumberOfInputChannels;
    isStereo = numberOfChannels > 1 ? 1 : 0;  // decide stereo or mono
    
    //  printf("isStereo: %d\n", isStereo);
    //  MyLog(@"frames: %lu, bus: %lu",inNumberFrames, inBusNumber );
	
	// copy all the input samples to the callback buffer - after this point we could bail and have a pass through
    renderErr = AudioUnitRender(rioUnit, ioActionFlags, 
								inTimeStamp, bus1, inNumberFrames, ioData);
	if (renderErr < 0) {
		return renderErr;
	}
    
    // this comment is open to debate:
    // it seems that you can process single channel audio input as SInt16 just fine
    // In fact thats what this program had previously done with mono audio input.
    
    // but you get format errors if you set Sint16 samples in an ASBD with 2 channels
    // So... now to simplify things, we're going to get all input as 8.24 and just 
    // convert it to SInt16 or float for processing
    //
    // There may be some 3 stage conversions here, ie., 8.24->Sint16->float 
    // that could probably obviously be replaced by direct 8.24->float conversion
    // 
    
    // convert to SInt16
    
    
    inSamplesLeft = (AudioUnitSampleType *) ioData->mBuffers[0].mData; // left channel
    fixedPointToSInt16(inSamplesLeft, sampleBufferLeft, inNumberFrames);
    
    if(isStereo) {
        inSamplesRight = (AudioUnitSampleType *) ioData->mBuffers[1].mData; // right channel
        fixedPointToSInt16(inSamplesRight, sampleBufferRight, inNumberFrames);
    }
    
    
    
    
    // get average input volume level for meter display
    // 
    // (note: there's a vdsp function to do this but it works on float samples
    
    
    
    THIS.displayInputLevelLeft = getMeanVolumeSint16( sampleBufferLeft, inNumberFrames); // assign to instance variable for display
    if(isStereo) {
        THIS.displayInputLevelRight = getMeanVolumeSint16(sampleBufferRight, inNumberFrames); // assign to instance variable for display
    }
    
    
    //     
    //  get user mic/line FX selection 
    //
    //  so... none of these effects except fftPassthrough and delay (echo) are fast enough to
    //  render in stereo at the default sample rate and buffer sizes - on the ipad2
    //  This is kind of sad but I didn't really do any optimization 
    //  and there's a lot of wasteful conversion and duplication going on... so there is hope
    
    // for now, run the effects in mono
    
    
    if(THIS.micFxOn == YES) {       // if user toggled on mic fx
        
        if(isStereo) {              // if stereo, combine left and right channels into left
            for( i = 0; i < inNumberFrames; i++ ) {
                sampleBufferLeft[i] = (SInt16) ((.5 * (float) sampleBufferLeft[i]) + (.5 * (float) sampleBufferRight[i]));
            }
        }    
        sampleBuffer = sampleBufferLeft;
        
        // do effect based on user selection
        switch (THIS.micFxType) {
            case 0:
                ringMod( inRefCon, inNumberFrames, sampleBuffer );
                break;
            case 1:
                err = fftPassThrough ( inRefCon, inNumberFrames, sampleBuffer);
                break;
            case 2:
                err = fftPitchShift ( inRefCon, inNumberFrames, sampleBuffer);
                break;
            case 3:
                err = simpleDelay ( inRefCon, inNumberFrames, sampleBuffer);
                break;
            case 4:
                err = movingAverageFilterFloat ( inRefCon, inNumberFrames, sampleBuffer);
                break;    
            case 5:
                err = convolutionFilter ( inRefCon, inNumberFrames, sampleBuffer);
                break;     
                
            default:
                break;
        }
        // If stereo, copy left channel (mono) results to right channel 
        if(isStereo) {
            for(i = 0; i < inNumberFrames; i++ ) {
                sampleBufferRight[i] = sampleBufferLeft[i];
            }
        }
    }
    
    
    // convert back to 8.24 fixed point 
    SInt16ToFixedPoint(sampleBufferLeft, inSamplesLeft, inNumberFrames); 
    if(isStereo) {
        SInt16ToFixedPoint(sampleBufferRight, inSamplesRight, inNumberFrames); 
    }
    
    // ---- the 1st method 
    /*
    // In case, we need save the vocal ( in ioData) to file 
    if (THIS.vocalWriterInput != nil) {
        // --------
        CMSampleBufferRef buffer = NULL;
        CMFormatDescriptionRef format = NULL;
        AudioStreamBasicDescription asbd;
        if (isStereo)
            asbd = THIS.stereoStreamFormat;
        else 
            asbd = THIS.monoStreamFormat;
        //
        OSStatus error = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &asbd, 0, NULL, 0, NULL, NULL, &format);
        if ( error ) { MyLog(@"CMAudioFormatDescriptionCreate returned error: %ld", error); }
        CMSampleTimingInfo timing = { CMTimeMakeWithSeconds(1 / 44100.0, 1), kCMTimeZero, kCMTimeInvalid };
        error = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, inNumberFrames, 1, &timing, 0, NULL, &buffer);
        if ( error ) { MyLog(@"CMSampleBufferCreate returned error: %ld", error); }
        error = CMSampleBufferSetDataBufferFromAudioBufferList(buffer, kCFAllocatorDefault, kCFAllocatorDefault, 0, ioData);
        if ( error ) { MyLog(@"CMSampleBufferSetDataBufferFromAudioBufferList returned error: %ld", error); }
        // --------
        [THIS.vocalWriterInput appendSampleBuffer:buffer]; 
    }
    */
    
    //
    return noErr;	// return with samples in iOdata
}

static OSStatus recordingAURenderCallback(void *inRefCon,
                            AudioUnitRenderActionFlags *actionFlags,
                            const AudioTimeStamp *inTimeStamp,
                            UInt32 inBusNumber,
                            UInt32 inNumberFrames,
                            AudioBufferList *ioData) {
    
    if (*actionFlags & kAudioUnitRenderAction_PostRender) {
       
        KOKSMixerHostAudio *THIS = (__bridge KOKSMixerHostAudio *)inRefCon;
        
        // in case of utilizing 'PostRender' (by addRenderNotify), we must skip this render procedure !
// ----------------------------------------------------------------------------------------------
//        AudioUnit previousUnit = THIS.auEffectUnit; // the unit before ioUnit (Remote: Speaker)    
//        AudioUnitRender(previousUnit,
//                    actionFlags,
//                    inTimeStamp,
//                    0,                      // inOutputNumber : 0 --> Output
//                    inNumberFrames,
//                    ioData);
// ----------------------------------------------------------------------------------------------    
        // if extRecordingAudioFileRef is not nil --> recording now!
        ExtAudioFileRef extAudioFileRef = THIS.extRecordingAudioFileRef;
        if (extAudioFileRef != nil) {
            //
            UInt32 numOfBuffers = ioData->mNumberBuffers;
            // Currently, "STEREO" will cause the system CRASH ! So, we limit the number of channel to be 1 !
            numOfBuffers = 1;
            UInt32 size = ioData->mBuffers[0].mDataByteSize;
            //
            // double timeInSeconds = inTimeStamp->mSampleTime / 44100.0;
            // printf("\n%fs inBusNumber: %lu inNumberFrames: %lu ", timeInSeconds, inBusNumber, inNumberFrames);
    
            // Allocate memory for the buffer list struct according to the number of 
            //    channels it represents.
            AudioBufferList *bufferList;
            bufferList = [THIS allocateAudioBufferListWithNumChannels:numOfBuffers withSize:size];
            THIS.audioBufferList = bufferList;
            
            for (int i=0; i<numOfBuffers; i++) {
                memcpy( bufferList->mBuffers[i].mData, ioData->mBuffers[i].mData, ioData->mBuffers[i].mDataByteSize);
            }
            //
            if (THIS.extRecordingAudioFileRef != nil)
               ExtAudioFileWriteAsync(extAudioFileRef, inNumberFrames, bufferList);
            //
            [THIS destroyAudioBufferList:bufferList];
        }
    }
    return noErr;
}


#pragma mark Audio route change listener callback

// Audio session callback function for responding to audio route changes. If playing back audio and
//   the user unplugs a headset or headphones, or removes the device from a dock connector for hardware  
//   that supports audio playback, this callback detects that and stops playback. 
//
// Refer to AudioSessionPropertyListener in Audio Session Services Reference.
void audioRouteChangeListenerCallback (
                                       void                      *inUserData,
                                       AudioSessionPropertyID    inPropertyID,
                                       UInt32                    inPropertyValueSize,
                                       const void                *inPropertyValue
                                       ) 
{
    
    // Ensure that this callback was invoked because of an audio route change
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;
    
    // This callback, being outside the implementation block, needs a reference to the KOKSMixerHostAudio
    //   object, which it receives in the inUserData parameter. You provide this reference when
    //   registering this callback (see the call to AudioSessionAddPropertyListener).
    
//    KOKSMixerHostAudio *audioObject = (__bridge KOKSMixerHostAudio *) inUserData;
//    
//    // if application sound is not playing, there's nothing to do, so return.
//    if (NO == audioObject.isPlaying) {
//        
//        MyLog (@"Audio route change while application audio is stopped.");
//        return;
//        
//    } else {
    
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
            
            MyLog (@"Audio output device was removed; stopping audio playback.");
            //NSString *KOKSMixerHostAudioObjectPlaybackStateDidChangeNotification = @"KOKSMixerHostAudioObjectPlaybackStateDidChangeNotification";
            //[[NSNotificationCenter defaultCenter] postNotificationName: KOKSMixerHostAudioObjectPlaybackStateDidChangeNotification object: audioObject];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceOnput!!" object:nil];
            
        } else {
            
            MyLog (@"A route change occurred that does not require stopping application audio.");
        }
//    }
}




//////////////////////////////////////////////////////////
// functions to support audio processing done in callbacks


///////////////////////////////////////////////////
//
// recursive logarithmic smoothing (low pass filter)

// based on algorithm in Max/MSP slide object
// http://cycling74.com
//
float xslide(int sval, float x ) {
	
	static int firstTime = TRUE;
	static float yP;
	float y;
	
	if(sval <= 0) {
		sval = 1;
	}
	
	if(firstTime) {
		firstTime = FALSE;
		yP = x;
    }
	
	
	y = yP + ((x - yP) / sval);
	
	yP = y;
	
	return(y);
	
	
}


////////////////////////////////////////////////////////////////////////
//
// pitch shifter using stft - based on dsp dimension articles and source
// http://www.dspdimension.com/admin/pitch-shifting-using-the-ft/

OSStatus fftPitchShift (
                        void *inRefCon,                // scope (KOKSMixerHostAudio)
                        UInt32 inNumberFrames,        // number of frames in this slice
                        SInt16 *sampleBuffer) {      // frames (sample data)
    
    // scope reference that allows access to everything in KOKSMixerHostAudio class
    
	KOKSMixerHostAudio *THIS = (__bridge KOKSMixerHostAudio *)inRefCon;
    
    
  	float *outputBuffer = THIS.outputBuffer;        // sample buffers
	float *analysisBuffer = THIS.analysisBuffer;
    
    
	
	FFTSetup fftSetup = THIS.fftSetup;      // fft setup structures need to support vdsp functions
	
    
	uint32_t stride = 1;                    // interleaving factor for vdsp functions
	int bufferCapacity = THIS.fftBufferCapacity;    // maximum size of fft buffers
    
    float pitchShift = 1.0;                 // pitch shift factor 1=normal, range is .5->2.0
    long osamp = 4;                         // oversampling factor
    long fftSize = 1024;                    // fft size 
    
	
	float frequency;                        // analysis frequency result
    
    
    //	ConvertInt16ToFloat
    
    vDSP_vflt16((SInt16 *) sampleBuffer, stride, (float *) analysisBuffer, stride, bufferCapacity );
    
    // run the pitch shift
    
    // scale the fx control 0->1 to range of pitchShift .5->2.0
    
    pitchShift = (THIS.micFxControl * 1.5) + .5;
    
    // osamp should be at least 4, but at this time my ipod touch gets very unhappy with 
    // anything greater than 2
    
    osamp = 4;
    fftSize = 1024;		// this seems to work in real time since we are actually doing the fft on smaller windows
    
    smb2PitchShift( pitchShift , (long) inNumberFrames,
                   fftSize,  osamp, (float) THIS.graphSampleRate,
                   (float *) analysisBuffer , (float *) outputBuffer,
                   fftSetup, &frequency);
    
    
    // display detected pitch
    
    
    THIS.displayInputFrequency = (int) frequency;
    
    
    // very very cool effect but lets skip it temporarily    
    //    THIS.sinFreq = THIS.frequency;   // set synth frequency to the pitch detected by microphone
    
    
    
    // now convert from float to Sint16
    
    vDSP_vfixr16((float *) outputBuffer, stride, (SInt16 *) sampleBuffer, stride, bufferCapacity );
    
    
    
    return noErr;
    
    
}

////////////////////////////////////////////////////////////////////////
//
// pitch shifter using stft - based on dsp dimension articles and source
// http://www.dspdimension.com/admin/pitch-shifting-using-the-ft/

OSStatus doPitchShift (
                       void *inRefCon,                // scope (KOKSMixerHostAudio)
                       int  numOfSemitone,           // number of semitone ( -12 ~ 12)
                       UInt32 inNumberFrames,        // number of frames in this slice
                       SInt16 *sampleBuffer) {       // frames (sample data)
    
    // scope reference that allows access to everything in KOKSMixerHostAudio class
	KOKSMixerHostAudio *THIS = (__bridge KOKSMixerHostAudio *)inRefCon;
    
    
  	float *outputBuffer = THIS.outputBuffer;        // sample buffers
	float *analysisBuffer = THIS.analysisBuffer;
    
    
	
	FFTSetup fftSetup = THIS.fftSetup;      // fft setup structures need to support vdsp functions
	
    
	uint32_t stride = 1;                    // interleaving factor for vdsp functions
	int bufferCapacity = THIS.fftBufferCapacity;    // maximum size of fft buffers
    
    float pitchShift = 1.0;                 // pitch shift factor 1=normal, range is .5->2.0
    //
    long osamp = 4;                        //  oversampling factor, original: 4
    long fftSize = 1024;                    // fft size, original:1024
    
	
	float frequency;                        // analysis frequency result
    
    
    //	ConvertInt16ToFloat
    vDSP_vflt16((SInt16 *) sampleBuffer, stride, (float *) analysisBuffer, stride, bufferCapacity );
    
    //  1/1.0594 = 0.9439
    // run the pitch shift
    // scale the fx control 0->1 to range of pitchShift .5->2.0
    // for (1.0594)^(+12) = 2.0
    // for (1.0594)^(-12) = 0.5
    // pitchShift = powf( 1.0594f, numOfSemitone);
    // pitchShift = powf(2.0f, numOfSemitone/12.0f);	// convert semitones to factor
    pitchShift = THIS.mPitchFactor;
    
    // for Debugging
    // MyLog(@"doPitchShift...NumOfFrame:%d, pitchShift:%f", (unsigned int)inNumberFrames, pitchShift);
    
    
    // osamp should be at least 4, but at this time my ipod touch gets very unhappy with
    // anything greater than 2
    
    osamp = 2;
    fftSize = 1024;		// this seems to work in real time since we are actually doing the fft on smaller windows
    
    smb2PitchShift( pitchShift , (long) inNumberFrames,
                   fftSize,  osamp, (float) THIS.graphSampleRate,
                   (float *) analysisBuffer , (float *) outputBuffer,
                   fftSetup, &frequency);
    
    // now convert from float to Sint16
    vDSP_vfixr16((float *) outputBuffer, stride, (SInt16 *) sampleBuffer, stride, bufferCapacity );
    
    return noErr;
    
}


#pragma mark fft passthrough function

// called by audio callback function with a slice of sample frames
//
// note this is nearly identical to the code example in apple developer lib at
// http://developer.apple.com/library/ios/#documentation/Performance/Conceptual/vDSP_Programming_Guide/SampleCode/SampleCode.html%23//apple_ref/doc/uid/TP40005147-CH205-CIAEJIGF
//
// this code does a passthrough from mic input to mixer bus using forward and inverse fft
// it also analyzes frequency with the freq domain data
//-------------------------------------------------------------

OSStatus fftPassThrough (   void                        *inRefCon,          // scope referece for external data
                         UInt32 						inNumberFrames,     // number of frames to process
                         SInt16 *sampleBuffer)                           // frame buffer
{
	
    // note: the fx control slider does nothing during fft passthrough
    
    // set all the params
    
    // scope reference that allows access to everything in KOKSMixerHostAudio class
    
	KOKSMixerHostAudio *THIS = (__bridge KOKSMixerHostAudio *)inRefCon;
    
    COMPLEX_SPLIT A = THIS.fftA;                // complex buffers
	
	void *dataBuffer = THIS.dataBuffer;         // working sample buffers
	float *outputBuffer = THIS.outputBuffer;
	float *analysisBuffer = THIS.analysisBuffer;
	
	FFTSetup fftSetup = THIS.fftSetup;          // fft structure to support vdsp functions
    
    // fft params
    
	uint32_t log2n = THIS.fftLog2n;             
	uint32_t n = THIS.fftN;
	uint32_t nOver2 = THIS.fftNOver2;
	uint32_t stride = 1;
	int bufferCapacity = THIS.fftBufferCapacity;
	SInt16 index = THIS.fftIndex;
	
    
    
	// this next logic assumes that the bufferCapacity determined by maxFrames in the fft-setup is less than or equal to
	// the inNumberFrames (which should be determined by the av session IO buffer size (ie duration)
	//
	// If we can guarantee the fft buffer size is equal to the inNumberFrames, then this buffer filling step is unecessary
	//
	// at this point i think its essential to make the two buffers equal size in order to do the fft passthrough without doing
	// the overlapping buffer thing
	//
	
    
	// Fill the buffer with our sampled data. If we fill our buffer, run the
	// fft.
	
	// so I have a question - the fft buffer  needs to be an even multiple of the frame (packet size?) or what?
    
	// MyLog(@"index: %d", index);
	int read = bufferCapacity - index;
	if (read > inNumberFrames) {
		// MyLog(@"filling");
        
		memcpy((SInt16 *)dataBuffer + index, sampleBuffer, inNumberFrames * sizeof(SInt16));
		THIS.fftIndex += inNumberFrames;
	} else {
		// MyLog(@"processing");
		// If we enter this conditional, our buffer will be filled and we should 
		// perform the FFT.
        
		memcpy((SInt16 *)dataBuffer + index, sampleBuffer, read * sizeof(SInt16));
        
		
		// Reset the index.
		THIS.fftIndex = 0;
        
        
        // *************** FFT ***************		
        // convert Sint16 to floating point
        
        vDSP_vflt16((SInt16 *) dataBuffer, stride, (float *) outputBuffer, stride, bufferCapacity );
        
        
		//
		// Look at the real signal as an interleaved complex vector by casting it.
		// Then call the transformation function vDSP_ctoz to get a split complex 
		// vector, which for a real signal, divides into an even-odd configuration.
		//
        
        vDSP_ctoz((COMPLEX*)outputBuffer, 2, &A, 1, nOver2);
		
		// Carry out a Forward FFT transform.
        
        vDSP_fft_zrip(fftSetup, &A, stride, log2n, FFT_FORWARD);
		
        
		// The output signal is now in a split real form. Use the vDSP_ztoc to get
		// an interleaved complex vector.
        
        vDSP_ztoc(&A, 1, (COMPLEX *)analysisBuffer, 2, nOver2);
		
		// for display purposes...
        //
        // Determine the dominant frequency by taking the magnitude squared and 
		// saving the bin which it resides in. This isn't precise and doesn't
        // necessary get the "fundamental" frequency, but its quick and sort of works...
        
        // note there are vdsp functions to do the amplitude calcs
        
        float dominantFrequency = 0;
        int bin = -1;
        for (int i=0; i<n; i+=2) {
			float curFreq = MagnitudeSquared(analysisBuffer[i], analysisBuffer[i+1]);
			if (curFreq > dominantFrequency) {
				dominantFrequency = curFreq;
				bin = (i+1)/2;
			}
		}
        
        dominantFrequency = bin*(THIS.graphSampleRate/bufferCapacity);
        
        // printf("Dominant frequency: %f   \n" , dominantFrequency);
        THIS.displayInputFrequency = (int) dominantFrequency;   // set instance variable with detected frequency
		
        
        // Carry out an inverse FFT transform.
		
        vDSP_fft_zrip(fftSetup, &A, stride, log2n, FFT_INVERSE );
        
        // scale it
		
		float scale = (float) 1.0 / (2 * n);					
		vDSP_vsmul(A.realp, 1, &scale, A.realp, 1, nOver2 );
		vDSP_vsmul(A.imagp, 1, &scale, A.imagp, 1, nOver2 );
		
		
        // convert from split complex to interleaved complex form
		
		vDSP_ztoc(&A, 1, (COMPLEX *) outputBuffer, 2, nOver2);
		
        // now convert from float to Sint16
		
		vDSP_vfixr16((float *) outputBuffer, stride, (SInt16 *) sampleBuffer, stride, bufferCapacity );
        
        
		
        
	}
    
    
    return noErr;
    
    
	
    
}



/////////////////////////////////////////////
// ring modulator effect - for SInt16 samples
//
// called from callback function that passes in a slice of frames
//
void ringMod( 
             void *inRefCon,                // scope (KOKSMixerHostAudio)
             
             UInt32 inNumberFrames,        // number of frames in this slice
             SInt16 *sampleBuffer) {      // frames (sample data)
    
    //  scope reference that allows access to everything in KOKSMixerHostAudio class 
    
    KOKSMixerHostAudio* THIS = (__bridge KOKSMixerHostAudio *)inRefCon;	    
    
    UInt32 frameNumber;     // current frame number for looping 
    float theta;            // for frequency calculation
    static float phase = 0; // for frequency calculation
    float freq;             // etc.,
    AudioSampleType *outSamples;    // convenience pointer to result samples
	
    outSamples  = (AudioSampleType *) sampleBuffer; // pointer to samples
    
    freq = (THIS.micFxControl * 4000) + .00001; // get freq from fx control slider
    // .00001 prevents divide by 0
    
    // loop through the samples
    
    for (frameNumber = 0; frameNumber < inNumberFrames; ++frameNumber) {
		
        theta = phase * M_PI * 2;   // convert to radians 
        outSamples[frameNumber] = (AudioSampleType) (sin(theta) * outSamples[frameNumber]);
        
        phase += 1.0 / (THIS.graphSampleRate / freq);	// increment phase
        if (phase > 1.0) {                              // phase goes from 0 -> 1
            phase -= 1.0;
        }
        
    }
    
    
    
}


////////////////////////////////////////////
//
// simple (one tap) delay using ring buffer  
//
// called by callback with a slice of sample data in ioData
//
OSStatus simpleDelay (
                      void                          *inRefCon,              // scope reference
                      UInt32 						inNumberFrames,         // number of frames to process
                      SInt16 *sampleBuffer)                                 // frame data
{
	
	// set all the params
	
	KOKSMixerHostAudio *THIS = (__bridge KOKSMixerHostAudio *)inRefCon;	// scope reference that allows access to everything in KOKSMixerHostAudio class
    
    UInt32 i;                                       // loop counter
    //    UInt32 averageVolume = 0;                           // for tracking microphone level
    
    
    
    int32_t tail;           // tail of ring buffer (read pointer)
    // int32_t head;       // head of ring buffer (write pointer)
    SInt16 *targetBuffer, *sourceBuffer;   // convenience pointers to sample data
    
    
    SInt16 *buffer;         // 
    int sampleCount = 0;                    // number of samples processed in ring buffer
    int samplesToCopy = inNumberFrames;     // total number of samples to process
    int32_t length;                         // length of ring buffer
    int32_t delayLength;                    // size of delay in samples
    int delaySlices;    // number of slices to delay by
	
	
	// Put audio into circular delay buffer
    
    // write incoming samples into the ring at the current head position
    // head is incremented by inNumberFrames
    
    
    // The logic is a bit different than usual circular buffer because we don't care 
    // whether the head catches up to the tail - because we're going to manually
    // set the tail position based on the delay length each time this function gets
    // called. 
    
    samplesToCopy = inNumberFrames;
    
    sourceBuffer = sampleBuffer;
    length = TPCircularBufferLength(&delayBufferRecord);
    // printf("length: %d\n", length );
    
    //        [delayBufferRecordLock lock];     // skip locks 
    while(samplesToCopy > 0) {
        sampleCount =  MIN(samplesToCopy, length - TPCircularBufferHead(&delayBufferRecord));
        if(sampleCount == 0) {
            break;
        }
        buffer = delayBuffer + TPCircularBufferHead(&delayBufferRecord);
        memcpy( buffer, sourceBuffer, sampleCount*sizeof(SInt16)); // actual copy
        sourceBuffer += sampleCount;
        samplesToCopy -= sampleCount;
        TPCircularBufferProduceAnywhere(&delayBufferRecord, sampleCount);  // this increments head
    }
    
    // head = TPCircularBufferHead(&delayBufferRecord);
    // printf("new head is %d\n", head );
    
    
    //    [THIS.delayBufferRecordLock unlock];  // skip lock because processing is local
    
    
    
    
    // Now we need to calculate where to put the tail - note this will probably blow
    // up if you don't make the circular buffer big enough for the delay
    
    delaySlices = (int) (THIS.micFxControl * 80);
    
    delayLength = delaySlices * inNumberFrames;      // number of slices do delay by
    // printf("delayLength: %d\n", delayLength);
    tail = TPCircularBufferHead(&delayBufferRecord) - delayLength;
    if(tail < 0) {
        tail = length + tail;
    }
    
    
    // printf("new tail is %d", tail );
    
    TPCircularBufferSetTailAnywhere(&delayBufferRecord, tail);
    
    
    targetBuffer = tempDelayBuffer; // tail data will get copied into temporary buffer
    samplesToCopy = inNumberFrames;
    
    
    
    // Pull audio from playthrough buffer, in contiguous chunks
    
    //        [delayBufferRecordLock lock];     // skip locks
    
    // this is the tricky part of the ring buffer where we need to break the circular
    // illusion and do linear housekeeping. If we're within 1024 of the physical
    // end of buffer, then copy out the samples in 2 steps.
    
    while ( samplesToCopy > 0 ) {
        sampleCount = MIN(samplesToCopy, length - TPCircularBufferTail(&delayBufferRecord));
        if ( sampleCount == 0 ) {
            break;   
        }
        // set pointer based on location of the tail
        
        buffer = delayBuffer + TPCircularBufferTail(&delayBufferRecord);
        
        // printf("\ncopying %d to temp, head: %d, tail %d", sampleCount, head, tail );
        
        memcpy(targetBuffer, buffer, sampleCount*sizeof(SInt16)); // actual copy
        
        targetBuffer += sampleCount;    // move up target pointer
        samplesToCopy -= sampleCount;   // keep track of what's already written
        TPCircularBufferConsumeAnywhere(&delayBufferRecord, sampleCount);  // this increments tail
    }
    
    //        [THIS.delayBufferRecordLock unlock];      // skip locks
    
    
    
    
    
    // convenience pointers for looping
    
    AudioSampleType *outSamples;
    outSamples = (AudioSampleType *) sampleBuffer;
    
    
    
    // this is just a debug test to see if anything is in the delay buffer  
    // by calculating mean volume of the buffer
    // and displaying it to the screen
    
    // for ( i = 0; i < inNumberFrames ; i++ ) {
    //    averageVolume += abs((int) tempDelayBuffer[i]);
    // }
    //    THIS.micLevel = averageVolume / inNumberFrames; 
    //    printf("\naverageVolume = %lu", averageVolume);
    
    
    // mix the delay buffer with the input buffer
    
    // so here the ratio is .4 * input signal
    // and .6 * delayed signal
    
    for ( i = 0; i < inNumberFrames ; i++ ) {
        outSamples[i] = (.4 * outSamples[i]) + (.6 * tempDelayBuffer[i]);
    }
    
    
  	return noErr;  
    
    
}


//////////////////////////////////////////
// logarithmic smoothing (low pass) filter
//
// based on algorithm in Max/MSP slide object
// http://cycling74.com
//
// called by callback with sample data in ioData
//
OSStatus logFilter (
                    void                          *inRefCon,        // scope reference
                    UInt32 						inNumberFrames,     // number of frames to process
                    SInt16 *sampleBuffer)                           // frame data
{
    
    // set params
	
    // scope reference that allows access to everything in KOKSMixerHostAudio class
    
    KOKSMixerHostAudio *THIS = (__bridge KOKSMixerHostAudio *)inRefCon;	    
    
    
    int i;     // loop counter
    SInt16 *buffer;
    int slide;  // smoothing factor (1 = no smoothing)
    
    // map fx control slider 0->1 to 1->15 for slide range
    
    slide = (int) (THIS.micFxControl * 14) + 1;
    
    buffer = sampleBuffer;
    
    // logarihmic filter
    
    for(i = 0 ; i < inNumberFrames; i++ ) {
        sampleBuffer[i] = (SInt16) xslide( slide, (float) buffer[i]);
    }
    
    return noErr;
    
}





//////////////////////////////////////////
//
// recursive Moving Average filter (float)  

// from http://www.dspguide.com/
// table 15-2
//
// called by callback with a slice of sample data in ioData
//
// note - the integer version didn't work 
// but this version works fine
// integer version causes clipping regardless of length
//
OSStatus movingAverageFilterFloat (
                                   void                          *inRefCon,         // scope reference
                                   UInt32 						inNumberFrames,     // number of frames to process
                                   SInt16 *sampleBuffer)                            // frame data
{
	
	// set all the params
	
    KOKSMixerHostAudio *THIS = (__bridge KOKSMixerHostAudio *)inRefCon;	// scope reference that allows access to everything in KOKSMixerHostAudio class
    
    int i;                                       // loop counter
    //    UInt32 averageVolume = 0;                           // for tracking microphone level
    
    float *analysisBuffer = THIS.analysisBuffer;                // working sample data buffers
    size_t bufferCapacity = THIS.fftBufferCapacity;
    
    
    int32_t tail;               // tail of ring buffer (read pointer)
    
    float *targetBuffer, *sourceBuffer;         // convenience points for sample data
    
    float *buffer;                      //
    int sampleCount = 0;                // number of samples read in while processing ring buffer
    int samplesToCopy = inNumberFrames; // total number samples to process in ring buffer
    int32_t length;                     // length of ring buffer
    int32_t delayLength;                   //  
    
    int filterLength;                   // size of filter (in samples)
    int middle;                         // middle of filter
	
    float acc;   // accumulator for moving average calculation
    float *resultBuffer;   // output
    
    int stride = 1;             // interleaving factor for sample data for vdsp functions
    
    // convenience pointers for looping
    
    float *signalBuffer;            //
    
    // on first pass, move the head up far enough into the ring buffer so we 
    // have enough zero padding to process the incoming signal data
    
    
    
    // set filter size from mix fx control
    
    filterLength = (int) (THIS.micFxControl * 30) + 3;
    if((filterLength % 2) == 0) {   // if even
        filterLength += 1;          // make it odd
    }
    
    // printf("filterLength %d\n", filterLength );
    
    //    filterLength = 51;
    middle = (filterLength - 1) / 2;
    
    
    // convert vector to float 
    
    //	ConvertInt16ToFloat
    
    vDSP_vflt16((SInt16 *) sampleBuffer, stride, (float *) analysisBuffer, stride, bufferCapacity );
    
    // Put audio into circular delay buffer
    
    // write incoming samples into the ring at the current head position
    // head is incremented by inNumberFrames
    
    
    // The logic is a bit different than usual circular buffer because we don't care 
    // whether the head catches up to the tail - because we're doing all the processing
    // within this function. So tail position gets reset manually each time.
    
    samplesToCopy = inNumberFrames;
    
    sourceBuffer = analysisBuffer;
    length = TPCircularBufferLength(&circularFilterBufferRecord);
    // printf("length: %d\n", length );
    
    //        [delayBufferRecordLock lock];     // skip locks 
    while(samplesToCopy > 0) {
        sampleCount =  MIN(samplesToCopy, length - TPCircularBufferHead(&circularFilterBufferRecord));
        if(sampleCount == 0) {
            break;
        }
        buffer = circularFilterBuffer + TPCircularBufferHead(&circularFilterBufferRecord);
        memcpy( buffer, sourceBuffer, sampleCount*sizeof(float)); // actual copy
        sourceBuffer += sampleCount;
        samplesToCopy -= sampleCount;
        TPCircularBufferProduceAnywhere(&circularFilterBufferRecord, sampleCount);  // this increments head
    }
    
    // head = TPCircularBufferHead(&delayBufferRecord);
    // printf("new head is %d\n", head );
    
    
    //    [THIS.delayBufferRecordLock unlock];  // skip lock because processing is local
    
    
    // Now we need to calculate where to put the tail - note this will probably blow
    // up if you don't make the circular buffer big enough for the delay
    
    // delaySlices = (int) (THIS.micFxControl * 80);
    
    delayLength = (inNumberFrames + filterLength) - 1; 
    
    
    // printf("delayLength: %d\n", delayLength);
    tail = TPCircularBufferHead(&circularFilterBufferRecord) - delayLength;
    if(tail < 0) {
        tail = length + tail;
    }
    
    
    // printf("new tail is %d", tail );
    
    TPCircularBufferSetTailAnywhere(&circularFilterBufferRecord, tail);
    
    
    targetBuffer = tempCircularFilterBuffer; // tail data will get copied into temporary buffer
    samplesToCopy = delayLength;
    
    
    
    // Pull audio from playthrough buffer, in contiguous chunks
    
    //        [delayBufferRecordLock lock];     // skip locks
    
    // this is the tricky part of the ring buffer where we need to break the circular
    // illusion and do linear housekeeping. If we're within 1024 of the physical
    // end of buffer, then copy out the samples in 2 steps.
    
    while ( samplesToCopy > 0 ) {
        sampleCount = MIN(samplesToCopy, length - TPCircularBufferTail(&circularFilterBufferRecord));
        if ( sampleCount == 0 ) {
            break;   
        }
        // set pointer based on location of the tail
        
        buffer = circularFilterBuffer + TPCircularBufferTail(&circularFilterBufferRecord);
        
        // printf("\ncopying %d to temp, head: %d, tail %d", sampleCount, head, tail );
        
        memcpy(targetBuffer, buffer, sampleCount*sizeof(float)); // actual copy
        
        targetBuffer += sampleCount;    // move up target pointer
        samplesToCopy -= sampleCount;   // keep track of what's already written
        TPCircularBufferConsumeAnywhere(&circularFilterBufferRecord, sampleCount);  // this increments tail
    }
    
    //        [THIS.delayBufferRecordLock unlock];      // skip locks
    
    
    // ok now we have enough samples in the temp delay buffer to actually run the 
    // filter. For example, if slice size is 1024 and filterLength is 101 - then we
    // should have 1124 samples in the tempDelayBuffer
    
    
    signalBuffer = tempCircularFilterBuffer;
    resultBuffer = THIS.outputBuffer;
    
    
    
    acc = 0;  // accumulator - find y[50] by averaging points x[0] to x[100]
    
    for(i = 0; i < filterLength; i++ ) {
        acc += signalBuffer[i];
    }
    
    
    resultBuffer[0] = (float) acc / filterLength;
    
    // recursive moving average filter
    
    middle = (filterLength - 1) / 2;
    
    
    for ( i = middle + 1; i < (inNumberFrames + middle) ; i++ ) {
        acc = acc + signalBuffer[i + middle] - signalBuffer[i - (middle + 1)];
        resultBuffer[i - middle] = (float) acc / filterLength;
    }
    
    //    printf("last i-middle is: %d\n", i - middle);
    
    // now convert from float to Sint16
    
    vDSP_vfixr16((float *) resultBuffer, stride, (SInt16 *) sampleBuffer, stride, bufferCapacity );
    
    
    
    return noErr;  
    
    
}




//////////////////////////////////////////////////////////////////////
//
// 101 point windowed sinc lowpass filter from http://www.dspguide.com/
// table 16-1
//
void  lowPassWindowedSincFilter( float *buf , float fc ) {
    
    // re-calculate 101 point lowpass filter kernel    
    
    int i;
    int m = 100;
    float sum = 0;
    
    
    for( i = 0; i < 101 ; i++ ) {
        if((i - m / 2) == 0 ) {
            buf[i] = 2 * M_PI * fc;
        }
        else {
            buf[i] = sin(2 * M_PI * fc * (i - m / 2)) / (i - m / 2);
        }
        buf[i] = buf[i] * (.54 - .46 * cos(2 * M_PI * i / m ));
    }
    
    // normalize for unity gain at dc
    
    
    for ( i = 0 ; i < 101 ; i++ ) {
        sum = sum + buf[i]; 
    }
    
    for ( i = 0 ; i < 101 ; i++ ) {
        buf[i] = buf[i] / sum;
    }
    
}



//////////////////////////////////////
//
// Convoluation Filter example (float)  
//
// called by callback with a slice of sample data in ioData
//
OSStatus convolutionFilter (
                            void                          *inRefCon,        // scope reference
                            UInt32 						inNumberFrames,     // number of frames to process
                            SInt16 *sampleBuffer)                           // frame data
{
	
	// set all the params
	
    KOKSMixerHostAudio *THIS = (__bridge KOKSMixerHostAudio *)inRefCon;	// scope reference that allows access to everything in KOKSMixerHostAudio class
    
    //    int i;                                       // loop counter
    //    UInt32 averageVolume = 0;                           // for tracking microphone level
    
    float *analysisBuffer = THIS.analysisBuffer;            // working data buffers
    size_t bufferCapacity = THIS.fftBufferCapacity;
    
    
    int32_t tail;    // tail of ring buffer (read pointer)
    //    int32_t head;       // head of ring buffer (write pointer)
    float *targetBuffer, *sourceBuffer;   
    //    static BOOL firstTime = YES;        // flag for some buffer initialization
    
    float *buffer;
    int sampleCount = 0;
    int samplesToCopy = inNumberFrames;
    int32_t length;
    int32_t delayLength;    
    //    int delaySlices;    // number of slices to delay by
    //    int filterLength;
    //    int middle;
	
    //    float acc;   // accumulator for moving average calculation
    //    float *resultBuffer;   // output
    
    int stride = 1;
    // convolution stuff
	
    
   	float *filterBuffer = THIS.filterBuffer;        // impusle response buffer
    int filterLength = THIS.filterLength;           // length of filterBuffer
    float *signalBuffer = THIS.signalBuffer;        // signal buffer
    //    int signalLength = THIS.signalLength;           // signal length
    float *resultBuffer = THIS.resultBuffer;        // result buffer
    int resultLength = THIS.resultLength;           // result length
    
	
	int filterStride = -1;           // -1 = convolution, 1 = correlation
    float fc;   // cutoff frequency
    
    resultLength = 1024;
    filterLength = 101;
    
    
    // get mix fx control for cutoff freq (fc)
    
    fc = (THIS.micFxControl * .18) + .001;
    
    // make filter with this fc
    
    lowPassWindowedSincFilter( filterBuffer, fc);
    
    //	Convert input signal from Int16ToFloat
    
    vDSP_vflt16((SInt16 *) sampleBuffer, stride, (float *) analysisBuffer, stride, bufferCapacity );
    
    // Put audio into circular delay buffer
    
    // write incoming samples into the ring at the current head position
    // head is incremented by inNumberFrames
    
    
    // The logic is a bit different than usual circular buffer because we don't care 
    // whether the head catches up to the tail - because we're doing all the processing
    // within this function. So tail position gets reset manually each time.
    
    samplesToCopy = inNumberFrames;
    
    sourceBuffer = analysisBuffer;
    length = TPCircularBufferLength(&circularFilterBufferRecord);
    // printf("length: %d\n", length );
    
    //        [delayBufferRecordLock lock];     // skip locks 
    while(samplesToCopy > 0) {
        sampleCount =  MIN(samplesToCopy, length - TPCircularBufferHead(&circularFilterBufferRecord));
        if(sampleCount == 0) {
            break;
        }
        buffer = circularFilterBuffer + TPCircularBufferHead(&circularFilterBufferRecord);
        memcpy( buffer, sourceBuffer, sampleCount*sizeof(float)); // actual copy
        sourceBuffer += sampleCount;
        samplesToCopy -= sampleCount;
        TPCircularBufferProduceAnywhere(&circularFilterBufferRecord, sampleCount);  // this increments head
    }
    
    // head = TPCircularBufferHead(&delayBufferRecord);
    // printf("new head is %d\n", head );
    
    
    //    [THIS.delayBufferRecordLock unlock];  // skip lock because processing is local
    
    
    // Now we need to calculate where to put the tail - note this will probably blow
    // up if you don't make the circular buffer big enough for the delay
    
    // delaySlices = (int) (THIS.micFxControl * 80);
    
    delayLength = (inNumberFrames + filterLength) - 1; 
    
    
    // printf("delayLength: %d\n", delayLength);
    tail = TPCircularBufferHead(&circularFilterBufferRecord) - delayLength;
    if(tail < 0) {
        tail = length + tail;
    }
    
    
    // printf("new tail is %d", tail );
    
    TPCircularBufferSetTailAnywhere(&circularFilterBufferRecord, tail);
    
    
    //   targetBuffer = tempCircularFilterBuffer; // tail data will get copied into temporary buffer
    
    targetBuffer = signalBuffer; // tail data will get copied into temporary buffer
    
    
    samplesToCopy = delayLength;
    
    
    
    // Pull audio from playthrough buffer, in contiguous chunks
    
    //        [delayBufferRecordLock lock];     // skip locks
    
    // this is the tricky part of the ring buffer where we need to break the circular
    // illusion and do linear housekeeping. If we're within 1024 of the physical
    // end of buffer, then copy out the samples in 2 steps.
    
    while ( samplesToCopy > 0 ) {
        sampleCount = MIN(samplesToCopy, length - TPCircularBufferTail(&circularFilterBufferRecord));
        if ( sampleCount == 0 ) {
            break;   
        }
        // set pointer based on location of the tail
        
        buffer = circularFilterBuffer + TPCircularBufferTail(&circularFilterBufferRecord);
        
        // printf("\ncopying %d to temp, head: %d, tail %d", sampleCount, head, tail );
        
        memcpy(targetBuffer, buffer, sampleCount*sizeof(float)); // actual copy
        
        targetBuffer += sampleCount;    // move up target pointer
        samplesToCopy -= sampleCount;   // keep track of what's already written
        TPCircularBufferConsumeAnywhere(&circularFilterBufferRecord, sampleCount);  // this increments tail
    }
    
    //        [THIS.delayBufferRecordLock unlock];      // skip locks
    
    
    // ok now we have enough samples in the temp delay buffer to actually run the 
    // filter. For example, if slice size is 1024 and filterLength is 101 - then we
    // should have 1124 samples in the tempDelayBuffer
    
    
    // do convolution
    
    filterStride = -1;      // convolution
    vDSP_conv( signalBuffer, stride, filterBuffer + filterLength - 1, filterStride, resultBuffer, stride,  resultLength, filterLength ); 
    
    
    
    // now convert from float to Sint16
    
    vDSP_vfixr16((float *) resultBuffer, stride, (SInt16 *) sampleBuffer, stride, bufferCapacity );
    
    
    
    return noErr;  
    
    
    
}





////////////////////////////////////////////////////////
// convert sample vector from fixed point 8.24 to SInt16
void fixedPointToSInt16( SInt32 * source, SInt16 * target, int length ) {
    
    int i;
    
    for(i = 0;i < length; i++ ) {
        target[i] = (SInt16) (source[i] >> 9);
    }
    
}

////////////////////////////////////////////////////////
// convert sample vector from SInt16 to fixed point 8.24 
void SInt16ToFixedPoint( SInt16 * source, SInt32 * target, int length ) {
    
    int i;
    
    for(i = 0;i < length; i++ ) {
        target[i] =  (SInt32) (source[i] << 9);
        if(source[i] < 0) { 
            target[i] |= 0xFF000000;
        }
        else {
            target[i] &= 0x00FFFFFF;
        }
        
    }
    
}



//////////////////////////////////////////////////
float getMeanVolumeSint16( SInt16 * vector , int length ) {
    
    
    // get average input volume level for meter display
    // by calculating log of mean volume of the buffer
    // and displaying it to the screen
    // (note: there's a vdsp function to do this but it works on float samples
    
    int sum;
    int i;
    int averageVolume;
    float logVolume;
    
    
    sum = 0;    
    for ( i = 0; i < length ; i++ ) {
        sum += abs((int) vector[i]);
    }
    
    averageVolume = sum / length;
    
    //    printf("\naverageVolume before scale = %lu", averageVolume );
    
    // now convert to logarithm and scale log10(0->32768) into 0->1 for display
    
    
    logVolume = log10f( (float) averageVolume ); 
    logVolume = logVolume / log10(32768);
    
    return (logVolume);
    
}




//////////////////////////
//
// calculate magnitude 

#pragma mark -
#pragma mark fft 

// for some calculation in the fft callback
// check to see if there is a vDsp library version
float MagnitudeSquared(float x, float y) {
	return ((x*x) + (y*y));
}



// end of audio functions supporting callbacks

///////////////////////
// KOKSMixerHostAudio class

#pragma mark -
#pragma mark KOKSMixerHostAudio implementation 

@implementation KOKSMixerHostAudio

// properties (see header file for definitions and comments)

@synthesize stereoStreamFormat;         // stereo format for use in buffer and mixer input for "guitar" sound
@synthesize monoStreamFormat;           // mono format for use in buffer and mixer input for "beats" sound

@synthesize SInt16StreamFormat;

@synthesize floatStreamFormat;
@synthesize auEffectStreamFormat;
@synthesize auEffectReverbStreamForamt;
@synthesize auConvertStreamFormat;

@synthesize graphSampleRate;            // sample rate to use throughout audio processing chain

@synthesize mixerUnit;                  // the Multichannel Mixer unit
@synthesize ioUnit;                  // the io unit
@synthesize auEffectUnit;  
@synthesize auEffectReverbUnit;
@synthesize auConvertUnit;

@synthesize mixerNode;
@synthesize auEffectNode;
@synthesize auEffectReverbNode;
@synthesize auConvertNode;
@synthesize iONode;

// for pitch-shifting -----------------------
@synthesize auTimePitchUnit1;
@synthesize auTimePitchUnit2;
@synthesize auTimePitchUnit3;
@synthesize auConvertUnit1;
@synthesize auConvertUnit2;
//
@synthesize auTimePitchNode1;
@synthesize auTimePitchNode2;
@synthesize auTimePitchNode3;
@synthesize auConvertNode1;
@synthesize auConvertNode2;
//
@synthesize soundStructArrayPt;
//-------------------------------------------

@synthesize playing;                    // Boolean flag to indicate whether audio is playing or not
@synthesize interruptedDuringPlayback;  // Boolean flag to indicate whether audio was playing when an interruption arrived


@synthesize fftSetup;			// this is required by fft methods in the callback
@synthesize fftA;			
@synthesize fftLog2n;
@synthesize fftN;
@synthesize fftNOver2;		// params for fft setup

@synthesize dataBuffer;			// input buffer from mic
@synthesize outputBuffer;		// for fft conversion
@synthesize analysisBuffer;		// for fft frequency analysis

@synthesize conversionBufferLeft;
@synthesize conversionBufferRight;

@synthesize filterBuffer;
@synthesize filterLength;
@synthesize signalBuffer;
@synthesize signalLength;
@synthesize resultBuffer;
@synthesize resultLength;

@synthesize fftBufferCapacity;	// In samples
@synthesize fftIndex;	// In samples - this is a horrible variable name

@synthesize displayInputFrequency;
@synthesize displayInputLevelLeft;
@synthesize displayInputLevelRight;
@synthesize displayNumberOfInputChannels;

@synthesize micFxType;
@synthesize micFxOn;
@synthesize micFxControl;

@synthesize inputDeviceIsAvailable;

@synthesize vocalWriterInput;
@synthesize tmpVocalFileName;
@synthesize extRecordingAudioFileRef;
@synthesize audioBufferList;

// for DiracFx 3
@synthesize mDiracFx31;
@synthesize mDiracFx32;
@synthesize mPitchFactor;
@synthesize mAudioIn;
@synthesize mAudioOut;
// end of properties


#pragma mark -
#pragma mark Initialize

//////////////////////////////////
// Get the app ready for playback.
- (id) init {
    
    
    self = [super init];
    
    if (!self) return nil;
    
    self.interruptedDuringPlayback = NO;
    
    
    [self setupAudioSession];		            
	
    [self FFTSetup];
    [self convolutionSetup];
    [self initDelayBuffer];
    [self initSoundFileURLs];
    //
    [self setupStereoStreamFormat];
    [self setupMonoStreamFormat];
    [self setupSInt16StreamFormat];
    
    // initial
    soundStructArrayPt = soundStructArray;
    //
    
    songUrl = nil;
	[self readAudioFilesIntoMemory];
    
    //    
    [self configureAndInitializeAudioProcessingGraph];
    
	
	return self;
}

- (id) initWithUrl:(NSURL *) curSongUrl {
    
    self = [super init];
    
    if (!self) return nil;
    
    self.interruptedDuringPlayback = NO;
    
    
    [self setupAudioSession];
	
    [self FFTSetup];
    [self convolutionSetup];
    [self initDelayBuffer];
    [self initSoundFileURLs];
    //
    [self setupStereoStreamFormat];
    [self setupMonoStreamFormat];
    [self setupSInt16StreamFormat];
    //
    // initial
    soundStructArrayPt = soundStructArray;
    //
    songUrl = curSongUrl;
	[self readAudioFilesIntoMemory];
    
    [self configureAndInitializeAudioProcessingGraph];
    
	return self;
    
}

- (id) initWithAsset:(AVAsset *) asset {
    
    
    self = [super init];
    
    if (!self) return nil;
    
    self.interruptedDuringPlayback = NO;
    
    
    [self setupAudioSession];		            
	
    [self FFTSetup];
    [self convolutionSetup];
    [self initDelayBuffer];
    [self initSoundFileURLs];
    //
    [self setupStereoStreamFormat];
    [self setupMonoStreamFormat];
    [self setupSInt16StreamFormat];
    //
    // initial
    soundStructArrayPt = soundStructArray;
    //
	[self readAudioAssetIntoMemory:[asset copy]];
    
    [self configureAndInitializeAudioProcessingGraph];
    
	
	return self;
}


// ----------------------
// for Pitch-shifting !
// ----------------------
// for DiracFx3 Le
- (void) setPitchFactor:(int)pitch {
    mPitchFactor = powf(2.f, pitch / 12.f);
    ZtxFxReset(true, mDiracFx31);
    ZtxFxReset(true, mDiracFx32);
}
// -------------------------------
// for NewTimePitch Unit
- (void) setMusicWithPitch:(int)newPitch withRate:(float)newRate {
    // MyLog (@"Adjust pitch:%d ...", newPitch);
    // [self setMixerInputBus:0 withPitch:newPitch withRate:newRate];
    // [self setMixerInputBus:1 withPitch:newPitch withRate:newRate];
    [self setPitchFactor:newPitch];
}


- (void) setVoiceWithPitch:(int)newPitch withRate:(float)newRate {
    [self setMixerInputBus:2 withPitch:newPitch withRate:newRate];
}

- (void) setMixerInputBus:(int)busNumber withPitch:(int)newPitch withRate:(float)newRate {
    MyLog (@"Adjust Mixer-Bus(%u) with pitch:%d & Rate:%f ...", busNumber, newPitch, newRate);
    OSStatus result = noErr;
    // set Pitch ?
    /*
     // Parameters for AUNewTimePitch
     // kNewTimePitchParam_Rate, Global, rate; 1/32 -> 32.0, 1.0
     // kNewTimePitchParam_Pitch, Global, Cents; -2400 -> 2400, 1.0
     // kNewTimePitchParam_Overlap, Global, generic; 3.0 -> 32.0, 8.0
     // kNewTimePitchParam_EnablePeakLocking, Global, Boolean, 0->1, 1
     */
    
    // pitch-shift
    AudioUnitParameterValue value = 100 * (newPitch);
    AudioUnitParameterValue valueOverlap = 12;
    AudioUnitParameterValue lockPeaking = 1;
    switch (busNumber) {
        case 0:
            result = AudioUnitSetParameter(auTimePitchUnit1, kNewTimePitchParam_EnablePeakLocking, kAudioUnitScope_Global, 0, lockPeaking, 0);
            result = AudioUnitSetParameter(auTimePitchUnit1, kNewTimePitchParam_Overlap, kAudioUnitScope_Global, 0, valueOverlap, 0);
            
            if (result) { printf("AudioUnitSetParameter kTimePitchParam_Overlap Global result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); }
            result = AudioUnitSetParameter(auTimePitchUnit1, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, value, 0);
            if (result) { printf("AudioUnitSetParameter kTimePitchParam_Pitch Global result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); }
            break;
        case 1:
            result = AudioUnitSetParameter(auTimePitchUnit2, kNewTimePitchParam_EnablePeakLocking, kAudioUnitScope_Global, 0, lockPeaking, 0);
            result = AudioUnitSetParameter(auTimePitchUnit2, kNewTimePitchParam_Overlap, kAudioUnitScope_Global, 0, valueOverlap, 0);
            if (result) { printf("AudioUnitSetParameter kTimePitchParam_Overlap Global result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); }
            result = AudioUnitSetParameter(auTimePitchUnit2, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, value, 0);
            if (result) { printf("AudioUnitSetParameter kTimePitchParam_Pitch Global result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); }
            break;
        case 2:
            result = AudioUnitSetParameter(auTimePitchUnit3, kNewTimePitchParam_Overlap, kAudioUnitScope_Global, 0, 16, 0);
            if (result) { printf("AudioUnitSetParameter kTimePitchParam_Overlap Global result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); }
            result = AudioUnitSetParameter(auTimePitchUnit3, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, value, 0);
            if (result) { printf("AudioUnitSetParameter kTimePitchParam_Pitch Global result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); }
            break;
    }
    /*
    // play rate
    switch (busNumber) {
        case 0:
            result = AudioUnitSetParameter(auTimePitchUnit1, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, newRate, 0);
            if (result) { printf("AudioUnitSetParameter kTimePitchParam_Rate Global result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); }
            break;
        case 1:
            result = AudioUnitSetParameter(auTimePitchUnit2, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, newRate, 0);
            if (result) { printf("AudioUnitSetParameter kTimePitchParam_Rate Global result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); }
            break;
        case 2:
            result = AudioUnitSetParameter(auTimePitchUnit3, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, newRate, 0);
            if (result) { printf("AudioUnitSetParameter kTimePitchParam_Rate Global result %ld %08X %4.4s\n", (long)result, (unsigned int)result, (char*)&result); }
            break;
    }
     */
    
    /*
     //-------------------------
     // for 3DMixer Unit !!!!!
     //-------------------------
     UInt32 busCount3D = 2;
     result = AudioUnitSetProperty ( au3DMixerUnit1,
     kAudioUnitProperty_ElementCount ,
     kAudioUnitScope_Input,
     0,
     &busCount3D,
     sizeof (busCount3D));
     // shift +3 semitone !
     float speed = powf(2.0f, -3/12.0f);
     result = AudioUnitSetParameter(
     au3DMixerUnit1,
     k3DMixerParam_PlaybackRate,
     kAudioUnitScope_Input,
     0,
     speed,
     0
     );
     if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (k3DMixerParam_PlaybackRate)-1" withStatus: result]; return;}
     */
}

//-------------------------------

#pragma mark -
#pragma mark Release Audio Session Listener callback to avoid error !
- (void) releaseAudioSession {
    // UN-Register the audio route change listener callback function with the audio session.
    AudioSessionRemovePropertyListenerWithUserData(
                                                   kAudioSessionProperty_AudioRouteChange,
                                                   audioRouteChangeListenerCallback,
                                                   (__bridge void *)self
                                                   );
}

- (void) registerAudioSession{
    AudioSessionAddPropertyListener (
                                     kAudioSessionProperty_AudioRouteChange,
                                     audioRouteChangeListenerCallback,
                                     (__bridge void *)self
                                     );
}

#pragma mark -
#pragma mark Audio set up
//
//  AVAudioSession setup
//  This is all the external housekeeping needed in any ios coreaudio app
//
- (void) setupAudioSession {
    
    // some debugging to find out about ourselves    
    
#if !CA_PREFER_FIXED_POINT
	MyLog(@"not fixed point");
#else
	MyLog(@"fixed point");
#endif
	
    
#if TARGET_IPHONE_SIMULATOR
    
    // #warning *** Simulator mode: beware ***
	MyLog(@"simulator is running");
#else
	MyLog(@"device is running");
#endif
    
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        MyLog(@"running iphone or ipod touch...\n");
    }
	
	NSString *deviceType = [UIDevice currentDevice].model;
    MyLog(@"device type is: %@", deviceType);
    
    
    NSString *operatingSystemVersion = [UIDevice currentDevice].systemVersion;
    MyLog(@"OS version is: %@", operatingSystemVersion);
    
    //////////////////////////
    // setup the session
	
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
    [mySession setDelegate: self];

    // tz change to play and record
	// Assign the Playback category to the audio session.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayAndRecord
                     error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error setting audio session category.");
        
    }
    
    // added on 2013/7/8, James Chen
    // -- disable low frequency filter
	[mySession setMode: AVAudioSessionModeMeasurement error:NULL];
    
    //
	// check if input is available
    // this only really applies to older ipod touch without builtin mic
    //
    // There seems to be no graceful way to handle this
	//
    // what we do is:
    //
    //  1. set instance var: inputDeviceIsAvailable so app can make decisions based on input availability
    //  2. give the user a message saying input device is not available
    //  3. set the session for Playback only
    // 
    //
    // haven't tried this helpful tip:
    //
    //  set info.plist key: UIApplicationExitsOnSuspend to make the app terminate when
    //  the home button is pressed (instead of just suspending)
    //
    // another note on this: since ios5 the detection of the mic (headset) on ipod touch
    // is a lot less accurate.  It seems that sometimes you need to reboot the ipod or at the
    // very least terminate the app to 
    // get AVSession to actually detect the mic is plugged in...
    //
    
    
    
	inputDeviceIsAvailable = [mySession inputIsAvailable];
    //    NSAssert( micIsAvailable, @"No audio input device available." );
    
	
    if(inputDeviceIsAvailable) {
        MyLog(@"input device is available");
    }
    else {
        MyLog(@"input device not available...");
        [mySession setCategory: AVAudioSessionCategoryPlayback
                         error: &audioSessionError];
        
        // --- show something ...
        UIAlertView *warning = [[UIAlertView alloc] init];
        [warning setTitle:@"無錄音設備可用！？"];
        [warning setMessage:@"若無錄音設備，使用者只能擁有聽歌功能！！"];
        [warning show];
        
    }
    
    
    
    
    
    // Request the desired hardware sample rate.
    //self.graphSampleRate = 22050.0;    // Hertz
    self.graphSampleRate = 44100.0;    // Hertz
    //self.graphSampleRate = 48000.0;    // Hertz
    [mySession setPreferredHardwareSampleRate: graphSampleRate
                                        error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        MyLog (@"Error setting preferred hardware sample rate.");
        
    }
	
	// refer to IOS developer library : Audio Session Programming Guide
	// set preferred buffer duration to 1024 using
	//  try ((buffer size + 1) / sample rate) - due to little arm6 floating point bug?
	// doesn't seem to help - the duration seems to get set to whatever the system wants...
	
    Float32 currentBufferDuration =  (Float32) (1024.0 / self.graphSampleRate);
    // default is about 0.023 for 48000 sample-rate.
	UInt32 sss = sizeof(currentBufferDuration);
	
	//AudioSessionSetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, sizeof(currentBufferDuration), &currentBufferDuration);
	//MyLog(@"[AudioSession]: DEFAULT buffer duration is: %f", currentBufferDuration);
    
	// 4/28, 256 is minimal value for pitch-shifting
    NSTimeInterval preferredBufferDuration = (Float32) (256.0 / self.graphSampleRate);
    [mySession setPreferredIOBufferDuration:preferredBufferDuration error:&audioSessionError];
    if (audioSessionError != nil)
    {
        MyLog (@"Error setting preferred buffer duration.");
    }

    
	// note: this is where ipod touch (w/o mic) erred out when mic (ie earbud thing) was not plugged - before we added
	// the code above to check for mic available 
    // Activate the audio session
    [mySession setActive: YES
                   error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        MyLog (@"Error activating audio session during initial setup.");
        
    }
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    self.graphSampleRate = [mySession currentHardwareSampleRate];
	MyLog(@"Actual sample rate is: %f", self.graphSampleRate );
	
	// find out the current buffer duration
	// to calculate duration use: buffersize / sample rate, eg., 512 / 44100 = .012
	
	// Obtain the actual buffer duration - this may be necessary to get fft stuff working properly in passthru
	AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &sss, &currentBufferDuration);
	MyLog(@"Actual current hardware io buffer duration: %f ", currentBufferDuration );
	
    
    // find out how many input channels are available 
    
    NSInteger numberOfChannels = [mySession currentHardwareInputNumberOfChannels];  
	MyLog(@"number of channels: %d", numberOfChannels );	
    displayNumberOfInputChannels = numberOfChannels;    // set instance variable for display
    
    return ;   // everything ok
    
}


/////////////////////////////
//
// housekeeping for loop files
//
- (void) initSoundFileURLs {
    
    // Create the URLs for the source audio files. The URLForResource:withExtension: method is new in iOS 4.0.
    
    // tz note: file references must added as resources to the xcode project bundle
    
    
    //NSURL *guitarLoop   = [[NSBundle mainBundle] URLForResource: @"caitlin"
    //                                              withExtension: @"caf"];
    //
    //NSURL *song1  = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"康康-快樂鳥日子" ofType:@"mp3"]];
    
    //NSURL *song2   = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"范瑋琪 - 黑白配" ofType:@"mp3"]];
    
    
    // ExtAudioFileRef objects expect CFURLRef URLs, so cast to CRURLRef here
    //sourceURLArray[0]   = (__bridge_retained CFURLRef)song2;
    //sourceURLArray[1]   = (__bridge_retained CFURLRef)song2;
}




// this converts the samples in the input buffer into floats
//
// there is an accelerate framework vdsp function 
// that does this conversion, so we're not using this function now
// but its good to know how to do it this way, although I would split it up into a setup and execute module
// I left this code to show how its done with an audio converter
//
void ConvertInt16ToFloat(KOKSMixerHostAudio *THIS, void *buf, float *outputBuf, size_t capacity) {
	AudioConverterRef converter;
	OSStatus err;
	
	size_t bytesPerSample = sizeof(float);
	AudioStreamBasicDescription outFormat = {0};
	outFormat.mFormatID = kAudioFormatLinearPCM;
	outFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
	outFormat.mBitsPerChannel = 8 * bytesPerSample;
	outFormat.mFramesPerPacket = 1;
	outFormat.mChannelsPerFrame = 1;	
	outFormat.mBytesPerPacket = bytesPerSample * outFormat.mFramesPerPacket;
	outFormat.mBytesPerFrame = bytesPerSample * outFormat.mChannelsPerFrame;		
	outFormat.mSampleRate = THIS->graphSampleRate;
	
	const AudioStreamBasicDescription inFormat = THIS->SInt16StreamFormat;
	
	UInt32 inSize = capacity*sizeof(SInt16);
	UInt32 outSize = capacity*sizeof(float);
	
	// this is the famed audio converter
	
	err = AudioConverterNew(&inFormat, &outFormat, &converter);
	if(noErr != err) {
		MyLog(@"error in audioConverterNew: %ld", err);
	}
	
	
	err = AudioConverterConvertBuffer(converter, inSize, buf, &outSize, outputBuf);
	if(noErr != err) {
		MyLog(@"error in audioConverterConvertBuffer: %ld", err);
	}
	
}




////////////////////////////
//
// setup asbd stream formats
//
//
- (void) setupStereoStreamFormat {
    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    //     MyLog (@"size of AudioUnitSampleType: %lu", bytesPerSample);
    
    // Fill the application audio format struct's fields to define a linear PCM, 
    //        stereo, noninterleaved stream at the hardware sample rate.
    stereoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    stereoStreamFormat.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat.mFramesPerPacket   = 1;
    stereoStreamFormat.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat.mChannelsPerFrame  = 2;                    // 2 indicates stereo
    stereoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat.mSampleRate        = graphSampleRate;
    
    
    MyLog (@"The stereo stream format:");
    [self printASBD: stereoStreamFormat];
}

//////////////////////////////
- (void) setupMonoStreamFormat {
    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    
    // Fill the application audio format struct's fields to define a linear PCM, 
    //        stereo, noninterleaved stream at the hardware sample rate.
    monoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    monoStreamFormat.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    monoStreamFormat.mBytesPerPacket    = bytesPerSample;
    monoStreamFormat.mFramesPerPacket   = 1;
    monoStreamFormat.mBytesPerFrame     = bytesPerSample;
    monoStreamFormat.mChannelsPerFrame  = 1;                  // 1 indicates mono
    monoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    monoStreamFormat.mSampleRate        = graphSampleRate;
    
    MyLog (@"The mono stream format:");
    [self printASBD: monoStreamFormat];
    
}

// this will be the stream format for anything that gets seriously processed by a render callback function
// it users 16bit signed int for sample data, assuming that this callback is probably on the input bus of a mixer
// or the input scope of the rio Output bus, in either case, we're assumeing that the AU will do the necessary format
// conversion to satisfy the output hardware - tz
//
// important distinction here with asbd's:
//
// note the difference between AudioUnitSampleType and AudioSampleType
//
// the former is an 8.24 (32 bit) fixed point sample format
// the latter is signed 16 bit (SInt16) integer sample format
//
// a subtle name differnce for a huge programming differece


- (void) setupSInt16StreamFormat {
    
    // Stream format for Signed 16 bit integers
    //
    // note: as of ios5 this works for signal channel mic/line input (not stereo)
    // and for mono audio generators (like synths) which pull no device data
    
    //    This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioSampleType);	// Sint16
    //    MyLog (@"size of AudioSampleType: %lu", bytesPerSample);
	
    // Fill the application audio format struct's fields to define a linear PCM, 
    //        stereo, noninterleaved stream at the hardware sample rate.
    SInt16StreamFormat.mFormatID          = kAudioFormatLinearPCM;
    SInt16StreamFormat.mFormatFlags       = kAudioFormatFlagsCanonical;
    SInt16StreamFormat.mBytesPerPacket    = bytesPerSample;
    SInt16StreamFormat.mFramesPerPacket   = 1;
    SInt16StreamFormat.mBytesPerFrame     = bytesPerSample;
    SInt16StreamFormat.mChannelsPerFrame  = 1;                  // 1 indicates mono
    SInt16StreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    SInt16StreamFormat.mSampleRate        = graphSampleRate;
	
    MyLog (@"The SInt16 (mono) stream format:");
    [self printASBD: SInt16StreamFormat];
    
    
    
}


// this is a test of using a float stream for the output scope of rio input bus
// and the input bus of a mixer channel
// the reason for this is that it would allow float algorithms to run without extra conversion
// that is, if it actually works
//
// so - apparently this doesn't work - at least in the context just described - there was no error in setting it
//
- (void) setupFloatStreamFormat {
	
    
    //    This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof(float);
	
    // Fill the application audio format struct's fields to define a linear PCM, 
    //        stereo, noninterleaved stream at the hardware sample rate.
    floatStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    floatStreamFormat.mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
    floatStreamFormat.mBytesPerPacket    = bytesPerSample;
    floatStreamFormat.mFramesPerPacket   = 1;
    floatStreamFormat.mBytesPerFrame     = bytesPerSample;
    floatStreamFormat.mChannelsPerFrame  = 1;                  // 1 indicates mono
    floatStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    floatStreamFormat.mSampleRate        = graphSampleRate;
	
    MyLog (@"The float stream format:");
    [self printASBD: floatStreamFormat];
	
}







// initialize the circular delay buffer
// 
- (void) initDelayBuffer {
    
    // for avoiding memory-leaking
    return;
    
    // Allocate buffer
    
    delayBuffer = (SInt16*)malloc(sizeof(SInt16) * kDelayBufferLength);
    
    memset(delayBuffer,0, kDelayBufferLength );  // set to zero 
    
    // Initialise record
    TPCircularBufferInit(&delayBufferRecord, kDelayBufferLength);
    delayBufferRecordLock = [[NSLock alloc] init];
    
    // this should be set with a constant equal to frame buffer size
    // so we're using this for other big stuff, so...
    
    tempDelayBuffer = (SInt16*)malloc(sizeof(SInt16) * 2048);
    
    // now do the same thing for the float filter buffer
    
    
    // Allocate buffer
    
    circularFilterBuffer = (float *)malloc(sizeof(float) * kDelayBufferLength);
    
    memset(circularFilterBuffer,0, kDelayBufferLength );  // set to zero 
    
    // Initialise record
    
    TPCircularBufferInit(&circularFilterBufferRecord, kDelayBufferLength);
    circularFilterBufferRecordLock = [[NSLock alloc] init];
    
    // this should be set with a constant equal to frame buffer size
    // so we're using this for other big stuff, so...
    
    tempCircularFilterBuffer = (float *)malloc(sizeof(float) * 2048);
    
    
    
}

//////////////////////////////////////////////////
// Setup FFT - structures needed by vdsp functions
//
- (void) FFTSetup {
    
    // for avoiding memory-leaking
    return;
	
	// I'm going to just convert everything to 1024
	
	
	// on the simulator the callback gets 512 frames even if you set the buffer to 1024, so this is a temp workaround in our efforts
	// to make the fft buffer = the callback buffer, 
	
	
	// for smb it doesn't matter if frame size is bigger than callback buffer
	
	UInt32 maxFrames = 1024;    // fft size
	
	
	// setup input and output buffers to equal max frame size
	
	dataBuffer = (void*)malloc(maxFrames * sizeof(SInt16));
	outputBuffer = (float*)malloc(maxFrames *sizeof(float));
	analysisBuffer = (float*)malloc(maxFrames *sizeof(float));
	
	// set the init stuff for fft based on number of frames
	
	fftLog2n = log2f(maxFrames);		// log base2 of max number of frames, eg., 10 for 1024
	fftN = 1 << fftLog2n;					// actual max number of frames, eg., 1024 - what a silly way to compute it
    
    
	fftNOver2 = maxFrames/2;                // half fft size
	fftBufferCapacity = maxFrames;          // yet another way of expressing fft size
	fftIndex = 0;                           // index for reading frame data in callback
	
	// split complex number buffer
	fftA.realp = (float *)malloc(fftNOver2 * sizeof(float));		// 
	fftA.imagp = (float *)malloc(fftNOver2 * sizeof(float));		// 
	
	
	// zero return indicates an error setting up internal buffers
	
	fftSetup = vDSP_create_fftsetup(fftLog2n, FFT_RADIX2);
    if( fftSetup == (FFTSetup) 0) {
        MyLog(@"Error - unable to allocate FFT setup buffers" );
	}
	
}




/////////////////////////////////////////
// Setup stuff for convolution testing 

- (void)convolutionSetup {
	
    
	int i;
    
    // just throwing this in here for testing 
    // these are the callback data conversion buffers
    
    conversionBufferLeft = (void *) malloc(1024 * sizeof(SInt16));
    conversionBufferRight = (void *) malloc(1024 * sizeof(SInt16));
	
	
    // for avoiding memory-leaking
    return;

	filterLength = 101;
    
    // signal length is actually 1024 but we're padding it 
    // with convolution the result length is signal + filter - 1
    
    signalLength = 1024;
    resultLength = 1024;
    
    filterBuffer = (void*)malloc(filterLength * sizeof(float));
    signalBuffer = (void*)malloc(signalLength * sizeof(float));
    resultBuffer = (void*)malloc(resultLength * sizeof(float));
    //    paddingBuffer = (void*)malloc(paddingLength * sizeof(float));
    
    
    // build a filter 
    // 101 point windowed sinc lowpass filter from http://www.dspguide.com/
    // table 16-1
    
    // note - now the filter gets rebuilt on the fly according to UI value for cutoff frequency
    //    
    
    
    // calculate lowpass filter kernel    
    
    
    int m = 100;
    float fc = .14;
    
    for( i = 0; i < 101 ; i++ ) {
        if((i - m / 2) == 0 ) {
            filterBuffer[i] = 2 * M_PI * fc;
        }
        else {
            filterBuffer[i] = sin(2 * M_PI * fc * (i - m / 2)) / (i - m / 2);
        }
        filterBuffer[i] = filterBuffer[i] * (.54 - .46 * cos(2 * M_PI * i / m ));
    }
    
    // normalize for unity gain at dc
    
    float sum = 0;
    for ( i = 0 ; i < 101 ; i++ ) {
        sum = sum + filterBuffer[i]; 
    }
    
    for ( i = 0 ; i < 101 ; i++ ) {
        filterBuffer[i] = filterBuffer[i] / sum;
    }
	
}

//--------
/*
 
 
 And for the sync problem you have to use something like that : 
 [compositionVideoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration) toDuration:audioAsset.duration];
 
 */


//////////////////////////////////////////////////
// TEST 1 - read Sample Buffer from AVAssetReader
//////////////////////////////////////////////////
#define kUnitSize sizeof(AudioSampleType) 
#define kBufferUnit 655360 
#define kTotalBufferSize kBufferUnit * kUnitSize

- (void) loadBuffer:(NSURL *)assetURL_
{
/*
    if (nil != self.iPodAssetReader) {
        [iTunesOperationQueue cancelAllOperations];
        
        [self cleanUpBuffer];
    }
    
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey, 
                                    [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                    [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                    nil];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:assetURL_ options:nil];
    if (asset == nil) {
        MyLog(@"asset is not defined!");
        return;
    }
    
    MyLog(@"Total Asset Duration: %f", CMTimeGetSeconds(asset.duration));
    
    NSError *assetError = nil;
    self.iPodAssetReader = [AVAssetReader assetReaderWithAsset:asset error:&assetError];
    if (assetError) {
        MyLog (@"error: %@", assetError);
        return;
    }
    
    AVAssetReaderOutput *readerOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:asset.tracks audioSettings:outputSettings];
    
    if (! [iPodAssetReader canAddOutput: readerOutput]) {
        MyLog (@"can't add reader output... die!");
        return;
    }
    
    // add output reader to reader
    [iPodAssetReader addOutput: readerOutput];
    
    if (! [iPodAssetReader startReading]) {
        MyLog(@"Unable to start reading!");
        return;
    }
    
    // Init circular buffer
    TPCircularBufferInit(&playbackState.circularBuffer, kTotalBufferSize);
    
    __block NSBlockOperation * feediPodBufferOperation = [NSBlockOperation blockOperationWithBlock:^{
        while (![feediPodBufferOperation isCancelled] && iPodAssetReader.status != AVAssetReaderStatusCompleted) {
            if (iPodAssetReader.status == AVAssetReaderStatusReading) {
                // Check if the available buffer space is enough to hold at least one cycle of the sample data
                if (kTotalBufferSize - playbackState.circularBuffer.fillCount >= 32768) {
                    CMSampleBufferRef nextBuffer = [readerOutput copyNextSampleBuffer];
                    
                    if (nextBuffer) {
                        AudioBufferList abl;
                        CMBlockBufferRef blockBuffer;
                        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(nextBuffer, NULL, &abl, sizeof(abl), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);
                        UInt64 size = CMSampleBufferGetTotalSampleSize(nextBuffer);
                        
                        int bytesCopied = TPCircularBufferProduceBytes(&playbackState.circularBuffer, abl.mBuffers[0].mData, size);
                        
                        if (!playbackState.bufferIsReady && bytesCopied > 0) {
                            playbackState.bufferIsReady = YES;
                        }
                        
                        CFRelease(nextBuffer);
                        CFRelease(blockBuffer);
                    }
                    else {
                        break;
                    }
                }
            }
        }
        MyLog(@"iPod Buffer Reading Finished");
    }];
    
    [iTunesOperationQueue addOperation:feediPodBufferOperation];
 */
}

static OSStatus ipodRenderCallback (
                                    
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
                                    ) 
{
    /*
    Audio* audioObject   = (Audio*)inRefCon;
    
    AudioSampleType *outSample          = (AudioSampleType *)ioData->mBuffers[0].mData;
    
    // Zero-out all the output samples first
    memset(outSample, 0, inNumberFrames * kUnitSize * 2);
    
    if ( audioObject.playingiPod && audioObject.bufferIsReady) {
        // Pull audio from circular buffer
        int32_t availableBytes;
        
        AudioSampleType *bufferTail     = TPCircularBufferTail(&audioObject.circularBuffer, &availableBytes);
        
        memcpy(outSample, bufferTail, MIN(availableBytes, inNumberFrames * kUnitSize * 2) );
        TPCircularBufferConsume(&audioObject.circularBuffer, MIN(availableBytes, inNumberFrames * kUnitSize * 2) );
        audioObject.currentSampleNum += MIN(availableBytes / (kUnitSize * 2), inNumberFrames);
        
        if (availableBytes <= inNumberFrames * kUnitSize * 2) {
            // Buffer is running out or playback is finished
            audioObject.bufferIsReady = NO;
            audioObject.playingiPod = NO;
            audioObject.currentSampleNum = 0;
            
            if ([[audioObject delegate] respondsToSelector:@selector(playbackDidFinish)]) {
                [[audioObject delegate] performSelector:@selector(playbackDidFinish)];
            }
        }
    }
    */
    return noErr;
}

- (void) setupSInt16StereoStreamFormat {
/*    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioSampleType);
    
    // Fill the application audio format struct's fields to define a linear PCM, 
    //        stereo, noninterleaved stream at the hardware sample rate.
    SInt16StereoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    SInt16StereoStreamFormat.mFormatFlags       = kAudioFormatFlagsCanonical;
    SInt16StereoStreamFormat.mBytesPerPacket    = 2 * bytesPerSample;   // *** kAudioFormatFlagsCanonical <- implicit interleaved data => (left sample + right sample) per Packet 
    SInt16StereoStreamFormat.mFramesPerPacket   = 1;
    SInt16StereoStreamFormat.mBytesPerFrame     = SInt16StereoStreamFormat.mBytesPerPacket * SInt16StereoStreamFormat.mFramesPerPacket;
    SInt16StereoStreamFormat.mChannelsPerFrame  = 2;                    // 2 indicates stereo
    SInt16StereoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    SInt16StereoStreamFormat.mSampleRate        = graphSampleRate;
    
    
    MyLog (@"The stereo stream format for the \"iPod\" mixer input bus:");
    [self printASBD: SInt16StereoStreamFormat];
*/
}
///----------------------

//////////////////
// read loop files

#pragma mark -
#pragma mark Read audio files into memory

- (void) readAudioFilesIntoMemory {
    
    //for (int audioChannel = 0; audioChannel < NUM_CHANNELS; ++audioChannel)  {
    int audioChannel = 0;
    //
        MyLog (@"readAudioFilesIntoMemory - channel %i", audioChannel);
        
        // Instantiate an extended audio file object.
        ExtAudioFileRef audioFileObject = 0;
        
        // Open an audio file and associate it with the extended audio file object.
        OSStatus result;
        if (songUrl != nil) {
            MyLog(@"MixerHostAudio: load song streams into memory with File-URL");
            result = ExtAudioFileOpenURL ((__bridge CFURLRef)(songUrl), &audioFileObject);
        } else {
            MyLog(@"MixerHostAudio: load DEFAULT song-streams into memory");
           result = ExtAudioFileOpenURL (sourceURLArray[audioChannel], &audioFileObject);
        }
    
        if (noErr != result || NULL == audioFileObject) {
            [self printErrorMessage: @"ExtAudioFileOpenURL" withStatus: result];
            return;
        }
    
        /* for Test purpose !
         SInt64 numPackets;
         UInt32 propDataSize = sizeof(numPackets);
         //
         AudioStreamBasicDescription dataFormat = stereoStreamFormat;
         AudioStreamBasicDescription originalDataFormat;

         propDataSize = (UInt32)sizeof(originalDataFormat);
         result = ExtAudioFileGetProperty(audioFileObject, kExtAudioFileProperty_FileDataFormat, &propDataSize, &originalDataFormat);
    
         dataFormat.mSampleRate = originalDataFormat.mSampleRate;
    
         propDataSize = (UInt32)sizeof(dataFormat);
         result = ExtAudioFileSetProperty(audioFileObject, kExtAudioFileProperty_ClientDataFormat, propDataSize, &dataFormat);

         result = ExtAudioFileGetProperty(audioFileObject, kExtAudioFileProperty_FileLengthFrames, &propDataSize, &numPackets);
         numPackets = (SInt64)(numPackets / (originalDataFormat.mSampleRate / dataFormat.mSampleRate));

        */
    
        // Get the audio file's length in frames.
        UInt64 totalFramesInFile = 0;
        UInt32 frameLengthPropertySize = sizeof (totalFramesInFile);
        result =    ExtAudioFileGetProperty (
                                             audioFileObject,
                                             kExtAudioFileProperty_FileLengthFrames,
                                             &frameLengthPropertySize,
                                             &totalFramesInFile
                                             );
        
        if (noErr != result) {
            [self printErrorMessage: @"ExtAudioFileGetProperty (audio file length in frames)" withStatus: result];
            return;
        }
        
        //
        MyLog(@"*** Original Audio file's(File-%d) frame count=%llu", audioChannel, totalFramesInFile);
    
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
    
        MyLog(@"*** File format of File-%d:", audioChannel);
        [self printASBD:fileAudioFormat];
    
        //-------------------------------------------------------------------------------------------------
        // Recompute the NEW number of Frames !
        totalFramesInFile = totalFramesInFile / (fileAudioFormat.mSampleRate/graphSampleRate);
        MyLog(@"*** Re-computed Audio file's(File-%d) frame count=%llu", audioChannel, totalFramesInFile);
        //-------------------------------------------------------------------------------------------------
    
    // Assign the frame count to the soundStructArray instance variable
        soundStructArray[audioChannel].frameCount = totalFramesInFile;
    
        // Allocate memory in the soundStructArray instance variable to hold the left channel, 
        //    or mono, audio data
        if ( soundStructArray[audioChannel].audioDataLeft != nil)
            free( soundStructArray[audioChannel].audioDataLeft );
        if ( soundStructArray[audioChannel].audioDataRight != nil)
            free ( soundStructArray[audioChannel].audioDataRight);
        //
        soundStructArray[audioChannel].audioDataLeft =
        (AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
        
        AudioStreamBasicDescription importFormat = {0};
        if (channelCount == 2) {
            soundStructArray[audioChannel].isStereo = YES;
            // Sound is stereo, so allocate memory in the soundStructArray instance variable to  
            //    hold the right channel audio data
            soundStructArray[audioChannel].audioDataRight =
            (AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
            importFormat = stereoStreamFormat;
            
        } else if (channelCount == 1) {
            
            soundStructArray[audioChannel].isStereo = NO;
            importFormat = monoStreamFormat;
            
        } else {
            
            MyLog (@"*** WARNING: File format not supported - wrong number of channels");
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
        
        if (NULL == bufferList) {MyLog (@"*** malloc failure for allocating bufferList memory"); return;}
        
        // initialize the mNumberBuffers member
        bufferList->mNumberBuffers = channelCount;
        
        // initialize the mBuffers member to 0
        AudioBuffer emptyBuffer = {0};
        size_t arrayIndex;
        for (arrayIndex = 0; arrayIndex < channelCount; arrayIndex++) {
            bufferList->mBuffers[arrayIndex] = emptyBuffer;
        }
        
        // set up the AudioBuffer structs in the buffer list FOR reading audio media !
        bufferList->mBuffers[0].mNumberChannels  = 1;
        bufferList->mBuffers[0].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
        bufferList->mBuffers[0].mData            = soundStructArray[audioChannel].audioDataLeft;
        
        if (channelCount == 2) {
            bufferList->mBuffers[1].mNumberChannels  = 1;
            bufferList->mBuffers[1].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
            bufferList->mBuffers[1].mData            = soundStructArray[audioChannel].audioDataRight;
        }
        
        // Perform a synchronous, sequential read of the audio data out of the file and
        //    into the soundStructArray[audioFile].audioDataLeft and (if stereo) .audioDataRight members.
        UInt32 numberOfPacketsToRead = (UInt32) totalFramesInFile;
        
        result = ExtAudioFileRead (
                                   audioFileObject,
                                   &numberOfPacketsToRead,
                                   bufferList
                                   );
        
        free (bufferList);
        
        if (noErr != result) {
            
            [self printErrorMessage: @"ExtAudioFileRead failure - " withStatus: result];
            
            // If reading from the file failed, then free the memory for the sound buffer.
            free (soundStructArray[audioChannel].audioDataLeft);
            soundStructArray[audioChannel].audioDataLeft = nil;
            
            if (channelCount==2) {
                free (soundStructArray[audioChannel].audioDataRight);
                soundStructArray[audioChannel].audioDataRight = nil;
            }
            
            ExtAudioFileDispose (audioFileObject);            
            return;
        }
        
        MyLog (@"Finished reading file %i into memory", audioChannel);
        
        // Set the sample index to zero, so that playback starts at the 
        //    beginning of the sound.
        soundStructArray[audioChannel].sampleNumber = 0;
        
        // Dispose of the extended audio file object, which also
        //    closes the associated file.
        ExtAudioFileDispose (audioFileObject);
    //}
    
    // Duplicate channel 0 TO channel 1
    soundStructArray[1] = soundStructArray[0];
}

#pragma mark Read audio Asset into memory
- (void) readAudioAssetIntoMemory:(AVAsset *) orgAsset {
    //
    MyLog(@"MixerHostAudio: load song streams into memory with AVAsset");
    
    //
    AVMutableComposition *audioComposition = [[AVMutableComposition alloc] init];
    MyLog (@"[readAudioAssetIntoMemory] - Asset's tracks %@", [orgAsset tracks] );
    
    
    int numOfChannels = 2;
    // for Test!!
    NSArray *audioAsset = [orgAsset tracksWithMediaType:AVMediaTypeAudio];
    if (audioAsset.count == 0) {
        //****** No Audio file !?? ---
        MyLog(@"[readAudioAssetIntoMemory] - A wrong URL or without any audio tacks in the AVAsset!");
        return;
    }
    //
    AVAssetTrack* songTrack = [audioAsset objectAtIndex:0];
    NSArray* formatDesc = songTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
        const AudioStreamBasicDescription* theDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        if(theDesc != nil){
            [self printASBD: *theDesc];
            numOfChannels = theDesc->mChannelsPerFrame;
        }
    }
    
    // from asset to audioComposition (audio only )
    NSError *error = 0;
    NSArray *audioAssetTracks = [orgAsset tracksWithMediaType:AVMediaTypeAudio];
    for ( AVAssetTrack *aTrack in audioAssetTracks) {
        
        AVMutableCompositionTrack *compositionAudioTrack = [audioComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, orgAsset.duration)
                                       ofTrack:aTrack
                                        atTime:kCMTimeZero
                                         error:&error];
    }
    
    /*
     NSMutableDictionary* dic2 = [NSMutableDictionary dictionary];
     [dic2 setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
     */
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    //
    NSMutableDictionary *dic2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [ NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                 [ NSNumber numberWithFloat:graphSampleRate], AVSampleRateKey, // 44.1 khz / 48.0 kHz
                                 [ NSNumber numberWithInt:2], AVNumberOfChannelsKey,   // Stereo
                                 [ NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
                                 [ NSNumber numberWithInt:32], AVLinearPCMBitDepthKey, // 8, 16, 24, 32 ??
                                 [ NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                 [ NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                 [ NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                 nil ];
    //
    NSError *assetError = nil;
    NSArray *tracks = [audioComposition tracksWithMediaType:AVMediaTypeAudio];
    if (![tracks count]) return;
    MyLog(@"**readAudioAssetIntoMemory: retrieve Tacks of asset.");
    
    AVAssetReader* assetReader = [AVAssetReader assetReaderWithAsset:audioComposition error:&assetError];
    
    //AVAssetReaderTrackOutput *readerOutput = [AVAssetReaderTrackOutput
    //                                          assetReaderTrackOutputWithTrack:[tracks objectAtIndex:0]
    //                                          outputSettings:dic2];
    AVAssetReaderAudioMixOutput *readerOutput = [AVAssetReaderAudioMixOutput
                                                 assetReaderAudioMixOutputWithAudioTracks:tracks
                                                 audioSettings:dic2];
    
    // ----->>>>> NEED VERIFY AGAIN !! <<<<<<------------------------
    // ------ adjust the volume of output !! ------------------------
    Float32 volume = 1.0f/128;
    //---------------------------------------------------------------
    NSArray *audioTracks = [readerOutput audioTracks];
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:volume atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    //
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    [readerOutput setAudioMix:audioMix];
    
    //-----------------------------------------------------------
    if (![assetReader canAddOutput:readerOutput]) return;
    //
    [assetReader addOutput :readerOutput];
    MyLog(@"**readAudioAssetIntoMemory: Add AudioMix-output to AssetReader.");
    
    if (![assetReader startReading]) return;
    MyLog(@"**readAudioAssetIntoMemory: Start Reading...");
    
    //
    NSMutableData * bufferLeftChannel  = [NSMutableData new];
    NSMutableData * bufferRightChannel = [NSMutableData new];
    
    //
    int numOfSamples = 0;
    CMSampleBufferRef sample = [readerOutput copyNextSampleBuffer];
    int sampleSize = (sample != nil) ? CMSampleBufferGetSampleSize(sample, 0) : 0;
    while( sample != nil)
    {
        int countSample = CMSampleBufferGetNumSamples(sample);
        // MyLog(@"Read number of Samples: %i, sizeOfSample: %i", countSample,  sampleSize);
        numOfSamples += countSample;
        
        //--- for testing the relationship of time and Sample Number.
        // MyLog(@"*** Received PCM buffer with [TIMESTAMP:%.1fms]", CMTimeGetSeconds(CMSampleBufferGetOutputPresentationTimeStamp(sample)) * 1000);
        // MyLog(@"*** Buffer contains [DURATION:%.1fms] worth of audio", CMTimeGetSeconds(CMSampleBufferGetDuration(sample)) * 1000);
        //-------------
        
        AudioBufferList bufferList;
        CMBlockBufferRef buffer;
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                                                                sample,  NULL, &bufferList, sizeof(bufferList), NULL, NULL,
                                                                kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                &buffer
                                                                );
        
        for (int bufferIdx=0; bufferIdx < bufferList.mNumberBuffers; bufferIdx++) {
            //SInt16* samples = (SInt16 *)bufferList.mBuffers[bufferIdx].mData;
            //for (int i=0; i < numOfSamples; i++) {
            // amplitude for the sample is samples[i], assuming you have linear pcm to start with
            //}
            AudioBuffer audioBuffer = bufferList.mBuffers[bufferIdx];
            //frames = audioBuffer.mData;
            //MyLog(@"the number of channel for buffer number %d is %lu", bufferIdx, audioBuffer.mNumberChannels);
            //MyLog(@"The buffer size is %lu", audioBuffer.mDataByteSize);
            numOfChannels = audioBuffer.mNumberChannels;
            
            if (numOfChannels==2) {
                // Split the original buffer to left/right channels.
                UInt32 sizeOfSampleUnit = sampleSize/numOfChannels;
                for (UInt32 i=0; i<audioBuffer.mDataByteSize; i += sampleSize) {
                    [bufferLeftChannel  appendBytes:(audioBuffer.mData+i) length:sizeOfSampleUnit];
                    [bufferRightChannel appendBytes:(audioBuffer.mData+i+sizeOfSampleUnit) length:sizeOfSampleUnit];
                }
            }
            else {
                // Duplicate the whole buffer to left & right channels.
                [bufferLeftChannel  appendBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
                [bufferRightChannel appendBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
            }
        }
        
        
        //Release the buffer when done with the samples
        //(retained by CMSampleBufferGetAudioBufferListWithRetainedblockBuffer)
        CFRelease( buffer );
        CFRelease( sample );
        //
        sample = [readerOutput copyNextSampleBuffer];
        
    }
    
    // Release all Resources
    readerOutput = nil;
    assetReader = nil;
    audioComposition = nil;
    
    // setup the information of soundStructArray for Audio Asset !!
    //for ( int musicChannel =0; musicChannel<NUM_CHANNELS; musicChannel++) {
    int musicChannel = 0;
    // soundStructArray[0].isStereo = (numOfChannels == 2) ? YES : NO;
    // 將左右聲道分割為兩個單音的 AudioData！
    soundStructArray[musicChannel].isStereo = (numOfChannels == 2) ? YES : NO;
    
    // Set the sample index to zero, so that playback starts at the beginning of the sound.
    soundStructArray[musicChannel].sampleNumber = 0;
    
    // total amount of the samples
    soundStructArray[musicChannel].frameCount = numOfSamples;
    
    /*
     // (L) Copy Left-Audio TO Audio Channel-0
     if (musicChannel==0) {
     // Allocate memory in the soundStructArray instance variable to hold the left channel, or mono, audio data
     soundStructArray[musicChannel].audioDataLeft =(AudioUnitSampleType *) calloc (numOfSamples, sampleSize/numOfChannels);
     [bufferLeftChannel getBytes:soundStructArray[musicChannel].audioDataLeft length:bufferLeftChannel.length];
     }
     else { // (R) Copy Right-Audio TO Audio Channel-1
     soundStructArray[musicChannel].audioDataLeft =(AudioUnitSampleType *) calloc (numOfSamples, sampleSize/numOfChannels);
     [bufferRightChannel getBytes:soundStructArray[musicChannel].audioDataLeft length:bufferRightChannel.length];
     }
     */
    soundStructArray[musicChannel].audioDataLeft =(AudioUnitSampleType *) calloc (numOfSamples, sampleSize/numOfChannels);
    [bufferLeftChannel getBytes:soundStructArray[musicChannel].audioDataLeft length:bufferLeftChannel.length];
    soundStructArray[musicChannel].audioDataRight =(AudioUnitSampleType *) calloc (numOfSamples, sampleSize/numOfChannels);
    [bufferRightChannel getBytes:soundStructArray[musicChannel].audioDataRight length:bufferRightChannel.length];
    
    // Normalize the sample !
    //[self normalizeValueOfSamples:soundStructArray[musicChannel].audioDataLeft sampleSize:numOfSamples];
    //}
    
    
    //
    MyLog(@"Read number of Samples: %i; Stereo/Mono: %@ ", numOfSamples, (numOfChannels == 1) ? @"Mono" : @"Stereo");
    //
    bufferLeftChannel =nil;
    bufferRightChannel=nil;
    //free (myBufferList);
    
    // Duplicate channel 0 TO channel 1
    soundStructArray[1] = soundStructArray[0];
}

-(void) normalizeValueOfSamples: (AudioUnitSampleType *)samples sampleSize:(UInt32)size {
    AudioUnitSampleType max= samples[0];
    for (UInt32 i=1; i<size; i++) {
        if (samples[i] > max)
            max = samples[i];
    }
    MyLog(@"Max value of samples is: %ld", max);
    for (UInt32 i=0; i<size; i++) {
        samples[i] = (SInt32) (((Float32)samples[i]/max) * 6000000);
    }
}


#pragma mark -
#pragma mark seekToTime:
- (void) seekToTime:(Float64) seekTime {
    UInt32 sampleIdx = ((Float64)seekTime) * graphSampleRate;
    // seek to the position.
    for (int chIdx=0; chIdx<NUM_CHANNELS; chIdx++)
       soundStructArray[chIdx].sampleNumber = sampleIdx;
    
}

#pragma mark currentTime:totalDuration
- (Float64) currentTime {
    // basic on Left-Channel !!
    //double curTime = (totalDuration * soundStructArray[0].sampleNumber) / soundStructArray[0].frameCount;
    Float64 curTime = ((Float64)soundStructArray[0].sampleNumber) / graphSampleRate;
    return curTime;
}

#pragma mark isEndOfMusic
- (BOOL) isEndOfMusic {
    // basic on Left-Channel !!
    if (soundStructArray[0].sampleNumber >= soundStructArray[0].frameCount && soundStructArray[0].frameCount != 0)
        return TRUE;
    else 
        return FALSE;
}

- (BOOL) isEndOfMov {
    if (soundStructArray[0].frameCount == 0)
        return TRUE;
    else if (soundStructArray[0].sampleNumber >= soundStructArray[0].frameCount)
        return TRUE;
    else
        return FALSE;
}

#pragma mark Switch Reverb Effect ON/OFF
/*
- (void) setReverbEffectOn: (BOOL)  isOnValue {
    /////////////////////////////////////////////
    // turn on or off on the Reverb Effect au fx
    // -----------------------------------------
    MyLog (@"Reverb Effect - FxSwitch now %@", isOnValue ? @"on" : @"off");
        
        UInt32 bypassed = (BOOL) isOnValue ? NO : YES ;
        MyLog (@"setting bypassed to %ld", bypassed);
        
        // ok there's a bug in disortion & reverb - once you bypass it, you can't
        // turn it back on - it just leaves dead air
        //
        
        CheckError(AudioUnitSetProperty (auEffectReverbUnit,
                                         kAudioUnitProperty_BypassEffect,
                                         kAudioUnitScope_Global,
                                         0,
                                         &bypassed,
                                         sizeof(bypassed)),
                   "Reverb: couldn't set bypassed status");
        
}
*/

- (void) setReverbDryWetMix:(Float32)dryWetValue gain:(Float32)gainValue minDelay:(Float32)minDelayValue maxDelay:(Float32)maxDelayValue f0HzDecay:(Float32)f0HzDecayValue fNyquistDecay:(Float32)fNyquistDecayValue randReflectRate:(Float32)randReflectRateValue {
    //
    [self setReverbDryWetMix:dryWetValue];
    //
    [self setReverbGain:gainValue];
    //
    [self setReverb0HzDecayTime:f0HzDecayValue NyquistDecayTime:fNyquistDecayValue];
    // new !!
    [self setReverbMinDelay:minDelayValue maxDelay:maxDelayValue];
    //
    [self setReverbRandomReflections:(int)randReflectRateValue ];
    
}

// Range: 0 ~ 100
- (void) setReverbDryWetMix:(Float32)value {
    CheckError( AudioUnitSetParameter( auEffectReverbUnit, 
                                      kReverb2Param_DryWetMix, 
                                      kAudioUnitScope_Global, 
                                      0, 
                                      value, 
                                      0), 
                   "Reverb set parameter error: Dry/Wet");
}
// Range: -20 ~ 20 (0)
- (void) setReverbGain:(Float32)value {
    CheckError( AudioUnitSetParameter( auEffectReverbUnit,
                                      kReverb2Param_Gain,
                                      kAudioUnitScope_Global,
                                      0,
                                      value,
                                      0),
               "Reverb set parameter error: Gain");
}
// Range: 1 ~ 1000
- (void) setReverbRandomReflections:(int)rvalue {
    if (rvalue < 1)
        rvalue = 1;
    //
    CheckError( AudioUnitSetParameter( auEffectReverbUnit,
                                      kReverb2Param_RandomizeReflections,
                                      kAudioUnitScope_Global,
                                      0,
                                      rvalue,
                                      0),
               "Reverb set parameter error: kReverb2Param_RandomizeReflections");
}
// Range: 0.001 ~ 20.0
- (void) setReverb0HzDecayTime:(Float32)value1 NyquistDecayTime:(Float32)value2 {
    if (value1 < 0.001)
        value1 = 0.001; // min~max : 0.001 ~ 20.0
    if (value2 < 0.001)
        value2 = 0.001; // min~max : 0.001 ~ 20.0
    //
    CheckError( AudioUnitSetParameter( auEffectReverbUnit,
                                      kReverb2Param_DecayTimeAt0Hz,
                                      kAudioUnitScope_Global,
                                      0,
                                      value1,
                                      0),
               "Reverb set parameter error: kReverb2Param_DecayTimeAt0Hz");
    //
    CheckError( AudioUnitSetParameter( auEffectReverbUnit,
                                      kReverb2Param_DecayTimeAtNyquist,
                                      kAudioUnitScope_Global,
                                      0,
                                      value2,
                                      0),
               "Reverb set parameter error: kReverb2Param_DecayTimeAtNyquist");
}
// Range: 0.0001 ~ 1.00
- (void) setReverbMinDelay:(Float32)value1 maxDelay:(Float32)value2 {
    if (value1 < 0.0001)
        value1 = 0.0001; // min~max : 0.0001 ~ 1.0
    if (value2 < 0.0001)
        value2 = 0.0001; // min~max : 0.0001 ~ 1.0
    //
    CheckError( AudioUnitSetParameter( auEffectReverbUnit,
                                      kReverb2Param_MinDelayTime,
                                      kAudioUnitScope_Global,
                                      0,
                                      value1,
                                      0),
               "Reverb set parameter error: kReverb2Param_MinDelayTime");
    //
    CheckError( AudioUnitSetParameter( auEffectReverbUnit,
                                      kReverb2Param_MaxDelayTime,
                                      kAudioUnitScope_Global,
                                      0,
                                      value2,
                                      0),
               "Reverb set parameter error: kReverb2Param_MaxDelayTime");
}

#pragma mark -
#pragma mark setupAudioProcessingGraph + AUGraphAddNode
////////////////////////////////////////////////////////////////////////////////////////////
// create and setup audio processing graph by setting component descriptions and adding nodes

- (void) setupAudioProcessingGraph {
    
    OSStatus result = noErr;
    
    
    // Create a new audio processing graph.
    result = NewAUGraph (&processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"NewAUGraph" withStatus: result]; return;}
    
    
    //............................................................................
    // Specify the audio unit component descriptions for the audio units to be
    //    added to the graph.
    
    // remote I/O unit connects both to mic/lineIn and to speaker
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
    
    // au unit effect for mixer output - Low/HighPass filter
    // ( FOR LOW_PASS , @2014/1/10)
    AudioComponentDescription auEffectUnitDescription; 
    auEffectUnitDescription.componentType = kAudioUnitType_Effect;
    auEffectUnitDescription.componentSubType = kAudioUnitSubType_LowPassFilter;
    //auEffectUnitDescription.componentSubType = kAudioUnitSubType_HighPassFilter;
    auEffectUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AudioComponentDescription auEffectReverbUnitDescription;
    auEffectReverbUnitDescription.componentType          = kAudioUnitType_Effect;
    auEffectReverbUnitDescription.componentSubType       = kAudioUnitSubType_Reverb2;
    auEffectReverbUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    auEffectReverbUnitDescription.componentFlags         = 0;
    auEffectReverbUnitDescription.componentFlagsMask     = 0;
    
    AudioComponentDescription auConvertUnitDescription;
    auConvertUnitDescription.componentType          = kAudioUnitType_FormatConverter;
    auConvertUnitDescription.componentSubType       = kAudioUnitSubType_AUConverter;
    auConvertUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    auConvertUnitDescription.componentFlags         = 0;
    auConvertUnitDescription.componentFlagsMask     = 0;

    // for pitch-shifting -------------------------------
    AudioComponentDescription au3DMixerUnitDescription;
    au3DMixerUnitDescription.componentType = kAudioUnitType_Mixer;
    au3DMixerUnitDescription.componentSubType = kAudioUnitSubType_AU3DMixerEmbedded;
    au3DMixerUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    au3DMixerUnitDescription.componentFlags         = 0;
    au3DMixerUnitDescription.componentFlagsMask     = 0;
    
    AudioComponentDescription auTimePitchUnitDescription;
    auTimePitchUnitDescription.componentType = kAudioUnitType_FormatConverter;
    auTimePitchUnitDescription.componentSubType = kAudioUnitSubType_NewTimePitch;
    auTimePitchUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    auTimePitchUnitDescription.componentFlags         = 0;
    auTimePitchUnitDescription.componentFlagsMask     = 0;
    
    ///////////////////////////////////////////////	
    // Add the nodes to the audio processing graph
    ///////////////////////////////////////////////
    
    MyLog (@"Adding nodes to audio processing graph");
    
    
    
    // io unit 
    
    result =    AUGraphAddNode (
                                processingGraph,
                                &iOUnitDescription,
                                &iONode);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNewNode failed for I/O unit" withStatus: result]; return;}
    
    
    // mixer unit
    
    result =    AUGraphAddNode (
                                processingGraph,
                                &MixerUnitDescription,
                                &mixerNode
                                );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNewNode failed for Mixer unit" withStatus: result]; return;}
    
    
    // au effect unit ( FOR LOW_PASS , @2014/1/10)
    
	CheckError( AUGraphAddNode(
                               processingGraph,
                               &auEffectUnitDescription,
                               &auEffectNode), 
               "AUGraphNode for auEffectUnit(LOW_PASS) failed");
    
    
    // au effect unit (Reverb)
    
	CheckError(AUGraphAddNode(
                              processingGraph,
                              &auEffectReverbUnitDescription,
                              &auEffectReverbNode), 
			   "AUGraphNode for auEffectReverbUnit failed");
    
    // au Convert unit 
    
	CheckError(AUGraphAddNode(
                              processingGraph,
                              &auConvertUnitDescription,
                              &auConvertNode), 
			   "AUGraphNode for auConvertUnit failed");
    //
    //
    /*
    // for builtin pitch-shifting ----------------------------------
    CheckError(AUGraphAddNode(
                              processingGraph,
                              &auTimePitchUnitDescription,
                              &auTimePitchNode1),
			   "AUGraphNode for auTimePitchNode/Unit1 failed");
    
    CheckError(AUGraphAddNode(
                              processingGraph,
                              &auTimePitchUnitDescription,
                              &auTimePitchNode2),
			   "AUGraphNode for auTimePitchNode/Unit2 failed");
    
    CheckError(AUGraphAddNode(
                              processingGraph,
                              &auTimePitchUnitDescription,
                              &auTimePitchNode3),
			   "AUGraphNode for auTimePitchNode/Unit3 failed");
    // ------------
    
    CheckError(AUGraphAddNode(
                              processingGraph,
                              &auConvertUnitDescription,
                              &auConvertNode1),
			   "AUGraphNode for auConvertUnit-1 failed");
    
    //
    CheckError(AUGraphAddNode(
                              processingGraph,
                              &auConvertUnitDescription,
                              &auConvertNode2),
			   "AUGraphNode for auConvertUnit-2 failed");
    
    //
    //-----------------------
     */
}

#pragma mark Connect AudioProgessingGraph

- (void) connectAudioProcessingGraph {
    
    OSStatus result = noErr;
    
    //............................................................................
    // Connect the nodes of the audio processing graph
    
    // note: you only need to connect nodes which don't have assigned callbacks.
    // So for example, the mic/lineIn channel doesn't need to be connected.
    
	
	MyLog (@"Connecting nodes in audio processing graph");
    
    /*
    //----------------------
    MyLog (@"Connecting the Converter-1 effect output to the TimePitch-1 input node 0");
    // connect Converter1(output) to 3DMixer1 Effect bus 0
	CheckError(AUGraphConnectNodeInput(processingGraph, auConvertNode1, 0, auTimePitchNode1, 0),
			   "AUGraphConnectNodeInput failed ( Converter1(0) to TimePitch1(0))");
    
    MyLog (@"Connecting the Converter-2 effect output to the TimePitch-2 input node 0");
    // connect Converter2(output) to 3DMixer2 Effect bus 0
	CheckError(AUGraphConnectNodeInput(processingGraph, auConvertNode2, 0, auTimePitchNode2, 0),
			   "AUGraphConnectNodeInput failed ( Converter2(0) to TimePitch2(0))");
    */
    
    /*
    //----------------------
    MyLog (@"Connecting the TimePitch1 effect output to the mixer input node 0");
    // connect 3DMixer1 Effect bus 0 (output) to mixer bus 0
	CheckError(AUGraphConnectNodeInput(processingGraph, auTimePitchNode1, 0, mixerNode, 0),
			   "AUGraphConnectNodeInput failed (TimePitch1(0) to mixer 0)");
    
    MyLog (@"Connecting the TimePitch2 effect output to the mixer input node 1");
    // connect 3DMixer2 Effect bus 0 (output) to mixer bus 1
	CheckError(AUGraphConnectNodeInput(processingGraph, auTimePitchNode2, 0, mixerNode, 1),
			   "AUGraphConnectNodeInput failed (TimePitch2(0) to mixer 1)");
    */
    //----------------------
    // for LOW_PASS @2014/1/10
    MyLog (@"Connecting the revb2 output to the input of effect(LOW_PASS) element");
    result = AUGraphConnectNodeInput (
                                      processingGraph,
                                      auEffectReverbNode,// source node
                                      0,                 // source node output bus number
                                      auEffectNode,      // destination node
                                      0                  // desintation node input bus number
                                      );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphConnectNodeInput" withStatus: result]; return;}
    
    MyLog (@"Connecting the effect(Reverb2) output to the input of the Effect unit output element");
    
    //-----------------------
    MyLog (@"Connecting the effect(LOW_PASS) output to the mixer input node 2");
    // connect Reverb Effect bus 0 (LOW_PASS) to mixer bus 2
	CheckError(AUGraphConnectNodeInput(processingGraph, auEffectNode, 0, mixerNode, 2),
			   "AUGraphConnectNodeInput failed (LOW_PASS Effect 0 to mixer 2)");
    
    //-------------------
    
    /*
    MyLog (@"Connecting the Converter effect output to the TimePitch-3 input node 0");
    // connect Converter(output) to TimePitch Effect-3 bus 0
	CheckError(AUGraphConnectNodeInput(processingGraph, auConvertNode, 0, auTimePitchNode3, 0),
			   "AUGraphConnectNodeInput failed ( Converter(0) to TimePitch3(0))");

    MyLog (@"Connecting the TimePitch3 output to the Reverb Effect Node input");
    // TimePitch Effect-3 bus 0 to Reverb Effect bus 0
	CheckError(AUGraphConnectNodeInput(processingGraph, auTimePitchNode3, 0, auEffectReverbNode, 0),
			   "AUGraphConnectNodeInput failed (TimePitch-3(0) to Reverb Effect 0)");
    */

    MyLog (@"Connecting the Converter effect output to the Reverb input node 0");
    // connect Converter(output) to Reverb bus 0
	CheckError(AUGraphConnectNodeInput(processingGraph, auConvertNode, 0, auEffectReverbNode, 0),
			   "AUGraphConnectNodeInput failed ( Converter(0) to Reverb Effect 0)");

    //------------

    result = AUGraphConnectNodeInput (
                                      processingGraph,
                                      mixerNode, //auEffectNode,     // source node
                                      0,                 // source node output bus number
                                      iONode,            // destination node
                                      0                  // desintation node input bus number
                                      );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphConnectNodeInput" withStatus: result]; return;}
}


#pragma mark Audio processing graph : Open AUGraph and then Setup Audio UNIT !
// This method does the audio processing graph:

//  - Instantiate and open an audio processing graph
//  - specify audio unit component descriptions for all units in the graph
//  - add nodes to the graph
//  - Open graph and get the audio unit nodes for the graph
//  - configure the io input unit
//  - Configure the Multichannel Mixer unit
//     * specify the number of input buses
//     * specify the output sample rate
//     * specify the maximum frames-per-slice
//      - configure each input channel of mixer
//          - set callback structs
//          - set asbd's
//  - configure any other audio units (fx, sampler, fileplayer)
//  - make connections
//  - start the audio processing graph
//  configure audio unit params
//  setup midi and fileplayer 



- (void) configureAndInitializeAudioProcessingGraph {
    
    MyLog (@"Configuring and then initializing audio processing graph");
    OSStatus result = noErr;
    
    UInt16 busNumber;           // mixer input bus number (starts with 0)
    
    // instantiate and setup audio processing graph by setting component descriptions and adding nodes
    
    [self setupAudioProcessingGraph];
    
    
    // --for DiracFx3 LE
    // Before starting processing we set up our Dirac instance
    int numOfChannels = 1;
    mDiracFx31 = ZtxFxCreate(kZtxQualityBest, graphSampleRate, numOfChannels);
    if (!mDiracFx31) {
        NSLog(@"!! ERROR !!\n\n\tCould not create DiracFx-1 instance\n\tCheck sample rate!\n");
        exit(-1);
    }
    else {
        MyLog(@"[DiracFx3-1 LE is Ready]!!\n\n");
    }
    mDiracFx32 = ZtxFxCreate(kZtxQualityBest, graphSampleRate, numOfChannels);
    if (!mDiracFx32) {
        NSLog(@"!! ERROR !!\n\n\tCould not create DiracFx-2 instance\n\tCheck sample rate!\n");
        exit(-1);
    }
    else {
        MyLog(@"[DiracFx3-2 LE is Ready]!!\n\n");
    }
    
    // ------------------------------------------------
    mAudioIn = AllocateAudioBufferSInt16( numOfChannels, 2048);
    mAudioOut = AllocateAudioBufferSInt16( numOfChannels, (int)ZtxFxMaxOutputBufferFramesRequired(2.0, 1.0, 2048));
    mPitchFactor = 1.0f;
    
    ///////////////////////////////////////////////////////////////////
    //............................................................................
    // Open the audio processing graph
    
    // Following this call, the audio units are instantiated but not initialized
    //    (no resource allocation occurs and the audio units are not in a state to
    //    process audio).
    result = AUGraphOpen (processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphOpen" withStatus: result]; return;}
    
    
    //
    //  at this point we set all the audio units individually
    //
    //  - get unit instance from audio graph node
    //  - set bus io params
    //  - set other params
    //  - set ASBD's
    //
    
    
    //............................................................................
    // Obtain the I/O unit instance from the corresponding node.
	result =	AUGraphNodeInfo (
								 processingGraph,
								 iONode,
								 NULL,
								 &ioUnit
								 );
	
	if (result) {[self printErrorMessage: @"AUGraphNodeInfo - I/O unit" withStatus: result]; return;}
    
    
    /////////////////////////////
    // I/O Unit Setup (input bus)
	
    
	
    if(inputDeviceIsAvailable) {            // if no input device, skip this step
        AudioUnitElement ioUnitInputBus = 1;
        
        // Enable input for the I/O unit, which is disabled by default. (Output is
        //	enabled by default, so there's no need to explicitly enable it.)
        UInt32 enableInput = 1;
        
        AudioUnitSetProperty (
                              ioUnit,
                              kAudioOutputUnitProperty_EnableIO,
                              kAudioUnitScope_Input,
                              ioUnitInputBus,
                              &enableInput,
                              sizeof (enableInput)
                              );
        
        
        // Specify the stream format for output side of the I/O unit's
        //	input bus (bus 1). For a description of these fields, see
        //	AudioStreamBasicDescription in Core Audio Data Types Reference.
        //
        // Instead of explicitly setting the fields in the ASBD as is done
        //	here, you can use the SetAUCanonical method from the Core Audio
        //	"Examples" folder. Refer to:
        //		/Developer/Examples/CoreAudio/PublicUtility/CAStreamBasicDescription.h
        
        // The AudioUnitSampleType data type is the recommended type for sample data in audio
        //	units
        
        
        //  set the stream format for the callback that does processing
        // of the mic/line input samples
        
        // using 8.24 fixed point now because SInt doesn't work in stereo
        
        // Apply the stream format to the output scope of the I/O unit's input bus.
        
        
        // tz 11/28 stereo input!!
        //
        // we could set the asbd to stereo and then decide in the callback
        // whether to use the right channel or not, but for now I would like to not have
        // the extra rendering and copying step for an un-used channel - so we'll customize
        // the asbd selection here...
        
        //    Now checking for number of input channels to decide mono or stereo asbd
        //    note, we're assuming mono for one channel, stereo for anything else
        //    if no input channels, then the program shouldn't have gotten this far.
        
        if( displayNumberOfInputChannels == 1) {
            MyLog (@"Setting kAudioUnitProperty_StreamFormat (monoStreamFormat) for the I/O unit input bus's output scope");
            result =	AudioUnitSetProperty (
                                              ioUnit,
                                              kAudioUnitProperty_StreamFormat,
                                              kAudioUnitScope_Output,
                                              ioUnitInputBus,
                                              &monoStreamFormat,
                                              sizeof (monoStreamFormat)
                                              );
            
            if (result) {[self printErrorMessage: @"AudioUnitSetProperty (set I/O unit input stream format output scope) monoStreamFormat" withStatus: result]; return;}
        }
        else {
            MyLog (@"Setting kAudioUnitProperty_StreamFormat (stereoStreamFormat) for the I/O unit input bus's output scope");
            result =	AudioUnitSetProperty (
                                              ioUnit,
                                              kAudioUnitProperty_StreamFormat,
                                              kAudioUnitScope_Output,
                                              ioUnitInputBus,
                                              &stereoStreamFormat,
                                              sizeof (stereoStreamFormat)
                                              );
            
            if (result) {[self printErrorMessage: @"AudioUnitSetProperty (set I/O unit input stream format output scope) stereoStreamFormat" withStatus: result]; return;}
            
        }
    }
	
    
    // this completes setup for the RemoteIO audio unit, other than setting the callback which gets attached to the mixer input bus
    
    //////////////////////////////////////////////////////////////
    // Obtain the mixer unit instance from its corresponding node.
    /*
     http://lists.apple.com/archives/coreaudio-api/2010/Sep/msg00144.html
     3D mixer unit—Allows any number of mono inputs, each of which can be
     8-bit or 16-bit linear PCM. Provides one stereo output in 8.24-bit
     fixed-point PCM. The 3D mixer unit performs sample rate conversion on
     its inputs and provides a great deal of control over each input
     channel. This control includes volume, muting, panning, distance
     attenuation, and rate control for these changes. Programmatically,
     this is the kAudioUnitSubType_AU3DMixerEmbedded
     */
    
    // for builtin pitch-shift
    /*
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 auConvertNode1,
                                 NULL,
                                 &auConvertUnit1
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo_auConvertNode1" withStatus: result]; return;}
    
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 auConvertNode2,
                                 NULL,
                                 &auConvertUnit2
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo_auConvertNode2" withStatus: result]; return;}
    //
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 auTimePitchNode1,
                                 NULL,
                                 &auTimePitchUnit1
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo_auTimePitch1" withStatus: result]; return;}
    
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 auTimePitchNode2,
                                 NULL,
                                 &auTimePitchUnit2
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo_auTimePitch2" withStatus: result]; return;}
    
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 auTimePitchNode3,
                                 NULL,
                                 &auTimePitchUnit3
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo_auTimePitch3" withStatus: result]; return;}
    
     */
    
    /*
     //-------------------------
     // for 3DMixer Unit !!!!!
     //-------------------------
     
     result = AudioUnitSetProperty ( au3DMixerUnit2,
     kAudioUnitProperty_ElementCount ,
     kAudioUnitScope_Input,
     0,
     &busCount3D,
     sizeof (busCount3D));
     result = AudioUnitSetParameter(
     au3DMixerUnit2,
     k3DMixerParam_PlaybackRate,
     kAudioUnitScope_Input,
     1, // bus: 1
     speed,
     0
     );
     //
     if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (k3DMixerParam_PlaybackRate)-2" withStatus: result]; return;}
     //
     result = AudioUnitSetParameter(
     au3DMixerUnit1,
     k3DMixerParam_Enable,
     kAudioUnitScope_Input,
     0, // bus: 1
     true,
     0
     );
     result = AudioUnitSetParameter(
     au3DMixerUnit1,
     k3DMixerParam_Enable,
     kAudioUnitScope_Input,
     1, // bus: 1
     false,
     0
     );
     result = AudioUnitSetParameter(
     au3DMixerUnit2,
     k3DMixerParam_Enable,
     kAudioUnitScope_Input,
     0, // bus: 1
     false,
     0
     );
     result = AudioUnitSetParameter(
     au3DMixerUnit2,
     k3DMixerParam_Enable,
     kAudioUnitScope_Input,
     1, // bus: 1
     true,
     0
     );
     */
    
    //--------------------------------------------------------------------------
    
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 mixerNode,
                                 NULL,
                                 &mixerUnit
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo" withStatus: result]; return;}
    
    
    /////////////////////////////////
    // Multichannel Mixer unit Setup
    //-------------------------------
    
    UInt32 musicLeftBus   = 0;          // mixer unit bus 0 will be stereo and will take the Music (MP3/MP4) - Left Channel
    UInt32 musicRightBus  = 1;          // mixer unit bus 1 will be stereo and will take the Music (MP3/MP4) - Right Channel
	UInt32 micBus	      = 2;          // mixer unit bus 2 will be mono and will take the microphone input (Reverb Effect)
    UInt32 busCount       = micBus+1;   // bus count for mixer unit input
    
    MyLog (@"Setting mixer unit input bus count to: %lu", busCount);
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_ElementCount,
                                   kAudioUnitScope_Input,
                                   0,
                                   &busCount,
                                   sizeof (busCount)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit bus count)" withStatus: result]; return;}
    
    
    MyLog (@"Setting kAudioUnitProperty_MaximumFramesPerSlice for mixer unit global scope");
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
    
	// UInt16 musicChannelCount = NUM_CHANNELS;	// number of 'file' busses to init on the mixer
    // Attach the input render callback and context to each input bus
	// this is for the two file players
	// subtract 2 from bus count because we're not including mic & synth bus for now...  tz
    for (UInt16 busNumber = musicLeftBus; busNumber < NUM_CHANNELS; busNumber++) {
        
        // Setup the structure that contains the input render callback
        AURenderCallbackStruct musicCallbackStruct1;
        musicCallbackStruct1.inputProc        = &musicRenderCallbackBus0;
        // inputCallbackStruct.inputProcRefCon  = soundStructArray;
        musicCallbackStruct1.inputProcRefCon  = (__bridge void *)self;
        AURenderCallbackStruct musicCallbackStruct2;
        musicCallbackStruct2.inputProc        = &musicRenderCallbackBus1;
        // inputCallbackStruct.inputProcRefCon  = soundStructArray;
        musicCallbackStruct2.inputProcRefCon  = (__bridge void *)self;
        
        MyLog (@"Registering the render callback with mixer unit input bus %u", busNumber);
        // Set a callback for the specified node's specified input
        if (busNumber == 0) {
            result = AUGraphSetNodeInputCallback (
                                                  processingGraph,
                                                  mixerNode, //auTimePitchNode1, //auConvertNode1, //au3DMixerNode1,
                                                  0, // bus:0
                                                  &musicCallbackStruct1
                                                  );
            if (noErr != result) {[self printErrorMessage: @"AUGraphSetNodeInputCallback_auConvertNode1" withStatus: result]; return;}
        }
        else {
            result = AUGraphSetNodeInputCallback (
                                                  processingGraph,
                                                  mixerNode, //auTimePitchNode2, //auConvertNode2, // au3DMixerNode2,
                                                  1, // bus: 1
                                                  &musicCallbackStruct2
                                                  );
            if (noErr != result) {[self printErrorMessage: @"AUGraphSetNodeInputCallback_auConvertNode2" withStatus: result]; return;}
        }
    }
    
    ///////////////////////////////////////////////
    // set all the ASBD's for the mixer input buses
    //
    // each mixer input bus needs an asbd that matches the asbd of the output bus its pulling data from
    //
    // In the case of the synth bus, which generates its own data, the asbd can be anything reasonable that
    // works on the input bus.
    //
    // The asbd of the mixer input bus does not have to match the asbd of the mixer output bus.
    // In that sense, the mixer acts as a format converter. But I don't know to what extent this will work.
    // It does sample format conversions, but I don't know that it can do sample rate conversions.
    
    //------------------
    // Except for 3DMixer
    //------------------
    
    result = AudioUnitSetProperty (
                                   mixerUnit, //auConvertUnit1,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   0,
                                   &monoStreamFormat,
                                   sizeof (monoStreamFormat)
                                   );
    
    result = AudioUnitSetProperty (
                                   mixerUnit, //auConvertUnit2,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   1,  // bus:1
                                   &monoStreamFormat,
                                   sizeof (monoStreamFormat)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set Convert unit bus (INPUT) mono format)" withStatus: result];return;}
    //------------------
    
    
    // --------- ???????????????? --------------
    //for (UInt16 busNumber = musicLeftBus; busNumber < NUM_CHANNELS+1; busNumber++) {
        MyLog (@"Setting the stream format for mixer unit bus %u", busNumber);
        result = AudioUnitSetProperty (
                                       mixerUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       micBus, // busNumber,                               // micBus
                                       &stereoStreamFormat,
                                       sizeof (stereoStreamFormat)
                                       );
        if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty set mixer unit bus - stream format) " withStatus: result];return;}
    //}
    
    
    
    /////////////////////////////////////////////////////////////////////////
    //
    // Obtain the au effect unit instance from its corresponding node.
    
    MyLog (@"Getting effect Node(LOW_PASS) Info...");
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 auEffectNode,
                                 NULL,
                                 &auEffectUnit
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo - auEffect(LOW_PASS)" withStatus: result]; return;}
    
    // setup ASBD for effects unit
    
    // This section is very confusing but important to getting things working
    //
    // The output of the mixer is now feeding the input of an effects au
    //
    // if the effects au wasn't there, you would just set the sample rate on the output scope of the mixer
    // as is explained in the Apple docs, and be done with it. Essesntially letting the system handle the
    // rest of the asbd setup for the mixer output
    //
    // But... in our setup, since the mixer ouput is not at the end of the chain, we set the sample rate on the
    // effects output scope instead.
    
    // and for the effects unit input scope... we need to obtain the default asbd from the the effects unit - this is
    // where things are weird because the default turns out to be 32bit float packed 2 channel, non interleaved
    //
    // and we use the asbd we obtain (auEffectStreamFormat) to apply to the output scope of the mixer. and any
    // other effects au's that we set up.
    //
    // The critical thing here is that you need to 1)set the audio unit description for auEffectUnit, 2)add it to the audio graph, then
    // 3) get the instance of the unit from its node in the audio graph (see just prior to this comment)
    // at that point the asbd has been initialized to the proper default. If you try to do the AudioUnitGetProperty before
    // that point you'll get an error -50
    //
    // As an alternative you could manually set the effects unit asbd to 32bit float, packed 2 channel, non interleaved -
    // ahead of time, like we did with the other asbd's.
    //
    
    
    // get default asbd properties of au effect unit,
    // this sets up the auEffectStreamFormat asbd
    
	UInt32 asbdSize = sizeof (auEffectStreamFormat);
	memset (&auEffectStreamFormat, 0, sizeof (auEffectStreamFormat ));
	CheckError(AudioUnitGetProperty(auEffectUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &auEffectStreamFormat, &asbdSize),
			   "Couldn't get aueffectunit ASBD");
	
    // debug print to find out what's actually in this asbd
    
    MyLog (@"The stream format for the effects unit:");
    [self printASBD: auEffectStreamFormat];
    
    auEffectStreamFormat.mSampleRate = graphSampleRate;      // make sure the sample rate is correct
    
    // now set this asbd to the effect unit input scope
    // note: if the asbd sample rate is already equal to graphsamplerate then this next statement is not
    // necessary because we derived the asbd from what it was already set to.
    
    
	CheckError(AudioUnitSetProperty(auEffectUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &auEffectStreamFormat, sizeof(auEffectStreamFormat)),
			   "Couldn't set ASBD on effect unit input");
    
    // set the sample rate on the effect unit output scope...
    //
    // Here
    // i'm just doing for the effect the same thing that worked for the
    // mixer output when there was no effect
    //
    
    MyLog (@"Setting sample rate for au effect unit output scope");
    // Set the mixer unit's output sample rate format. This is the only aspect of the output stream
    //    format that must be explicitly set.
    result = AudioUnitSetProperty (
                                   auEffectUnit,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set au effect unit output stream format)" withStatus: result]; return;}
    
    // and finally... set our new effect stream format on the output scope of the mixer.
    // app will blow up at runtime without this
    
    
    CheckError(AudioUnitSetProperty(mixerUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &auEffectStreamFormat,
                                    sizeof(auEffectStreamFormat)),
			   "Couldn't set ASBD on mixer output");
    
    /*
     CheckError(AudioUnitSetProperty(au3DMixerUnit1,
     kAudioUnitProperty_StreamFormat,
     kAudioUnitScope_Output,
     0,
     &stereoStreamFormat,
     sizeof(stereoStreamFormat)),
     "Couldn't set ASBD on 3DMixer-1 output");
     
     CheckError(AudioUnitSetProperty(au3DMixerUnit2,
     kAudioUnitProperty_StreamFormat,
     kAudioUnitScope_Output,
     0,
     &stereoStreamFormat,
     sizeof(stereoStreamFormat)),
     "Couldn't set ASBD on 3DMixer-2 output");
     */
    
    
    /*
    result = AudioUnitSetProperty (
                                   auConvertUnit1,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Input,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    result = AudioUnitSetProperty (
                                   auConvertUnit2,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Input,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    result = AudioUnitSetProperty (
                                   auConvertUnit1,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    result = AudioUnitSetProperty (
                                   auConvertUnit2,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    //----------
    
    result = AudioUnitSetProperty (
                                   auTimePitchUnit1,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Input,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    result = AudioUnitSetProperty (
                                   auTimePitchUnit2,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Input,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    result = AudioUnitSetProperty (
                                   auTimePitchUnit3,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Input,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    result = AudioUnitSetProperty (
                                   auTimePitchUnit1,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    result = AudioUnitSetProperty (
                                   auTimePitchUnit2,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    result = AudioUnitSetProperty (
                                   auTimePitchUnit3,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    */
    
    ////////// Convert unit ////////////////
    MyLog (@"Getting Convert Node Info...");
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 auConvertNode,
                                 NULL,
                                 &auConvertUnit
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo - auConvert" withStatus: result]; return;}
    
    /////////////////////////////////////////////////////////////////////
    // now attach the separate render callback for the mic/lineIn channel
    
	if(inputDeviceIsAvailable) {
        
        UInt16 busNumber = 0;		// mic channel on Convert Unit
        
        // Setup the structure that contains the input render callback
        AURenderCallbackStruct inputCallbackStruct;
        inputCallbackStruct.inputProc        = micLineInCallback;	// 8.24 version
        inputCallbackStruct.inputProcRefCon  = (__bridge void *)self;
        
        MyLog (@"Registering the render callback - mic/lineIn - with Convert unit input bus %u", busNumber);
        // Set a callback for the specified node's specified input
        result = AUGraphSetNodeInputCallback (
                                              processingGraph,
                                              auConvertNode,
                                              busNumber,
                                              &inputCallbackStruct
                                              );
        
        if (noErr != result) {[self printErrorMessage: @"AUGraphSetNodeInputCallback mic/lineIn" withStatus: result]; return;}
        
    }
	
	
    // set either mono or stereo 8.24 format (default) for mic/lineIn bus
    //
    // Note: you can also get mono mic/line input using SInt16 samples (see synth asbd)
    // But SInt16 gives asbd format errors with more than one channel
    
    
    if(displayNumberOfInputChannels == 1) {     // number of available channels determines mono/stereo choice
        
        MyLog (@"Setting mono-StreamFormat for Convert unit bus 0 (mic/lineIn)");
        result = AudioUnitSetProperty (
                                       auConvertUnit,                    // original: mixerUnit
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       0,                               // original: micBus
                                       &monoStreamFormat,
                                       sizeof (monoStreamFormat)
                                       );
        
        if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set Convert Unit bus 0 mic/line stream format mono)" withStatus: result];return;}
    }
    else if(displayNumberOfInputChannels > 1) {  // do the stereo asbd
        
        MyLog (@"Setting stereo-StreamFormat for Convert unit bus 0 mic/lineIn input");
        result = AudioUnitSetProperty (
                                       auConvertUnit,                   // originaL: mixerUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       0,                               // original: micBus,
                                       &stereoStreamFormat,
                                       sizeof (stereoStreamFormat)
                                       );
        
        if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set Convert Unit bus 0 mic/line stream format stereo)" withStatus: result];return;}
        
    }
    
    // set the sample rate on the effect unit output scope...
    //
    // Here
    // i'm just doing for the effect the same thing that worked for the
    // mixer output when there was no effect
    //
    
    MyLog (@"Setting sample rate for au Convert unit output scope");
    // Set the mixer unit's output sample rate format. This is the only aspect of the output stream
    //    format that must be explicitly set.
    result = AudioUnitSetProperty (
                                   auConvertUnit,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set au Convert unit output Sample-Rate)" withStatus: result]; return;}
    
    /*
     CheckError(AudioUnitSetProperty( auConvertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &auConvertStreamFormat, sizeof(auConvertStreamFormat)),
     "Couldn't set ASBD on AU Convert output");
     
     */
    
    ////////// Reverb effect unit ////////////////
    MyLog (@"Getting Reverb effect Node Info...");
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 auEffectReverbNode,
                                 NULL,
                                 &auEffectReverbUnit
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo - auEffect(Reverb)" withStatus: result]; return;}
    
	
    //------------------
    /*
     // 參數名稱： kReverb2Param_XXXXX
     //    範圍： scope, unit(?), min->max; default-value
     (0) kReverb2Param_DryWetMix
     Global, CrossFade, 0->100; 100
     At zero there is no effect (Dry). At 100% only the processed reverb signal (Wet) is produced.
     (1) kReverb2Param_Gain
     Global, Decibels, -20->20; 0
     (2) kReverb2Param_MinDelayTime
     Global, Secs, 0.0001->1.0; 0.008
     (3) kReverb2Param_MaxDelayTime
     Global, Secs, 0.0001->1.0; 0.050
     (4) kReverb2Param_DecayTimeAt0Hz
     Global, Secs, 0.001->20.0; 1.0
     ==> Short reverb times simulate small room reflections. Use longer reverb time to simulate larger spaces.
     (5) kReverb2Param_DecayTimeAtNyquist
     Global, Secs, 0.001->20.0; 0.5
     // Nyquist Frequency: 1/2 Sampling domain.
     (6) kReverb2Param_RandomizeReflections
     Global, Integer, 1->1000;
     Low values create a hard reverb suitable for producing small "bathroom" type reverbs. Higher values produce a softer reverb suitable for simulating large spaces such as Cathedrals.
     
     // 混聲效果 : 小延遲和低反射率（一個小房間內），較長的混響時間（音樂廳或體育場）
     */
    
    /*
     ==> Parameters for test
     [ 33, N/A, N/A, N/A, 2.5, 1.5, 100]
     [ 60,   2, N/A, 1.0, .66, 1000]
     */
    
    CheckError( AudioUnitSetParameter( auEffectReverbUnit, kReverb2Param_DryWetMix,    kAudioUnitScope_Global, 0, 50, 0), "Reverb set parameter error:0");
    CheckError( AudioUnitSetParameter( auEffectReverbUnit, kReverb2Param_Gain,         kAudioUnitScope_Global, 0,   2, 0), "Reverb set parameter error:1");
    //CheckError( AudioUnitSetParameter( auEffectReverbUnit, kReverb2Param_MinDelayTime, kAudioUnitScope_Global, 0, .01f, 0), "Reverb set parameter error:2");
    //CheckError( AudioUnitSetParameter( auEffectReverbUnit, kReverb2Param_MaxDelayTime, kAudioUnitScope_Global, 0, 1.0f, 0), "Reverb set parameter error:3");
    CheckError( AudioUnitSetParameter( auEffectReverbUnit, kReverb2Param_DecayTimeAt0Hz, kAudioUnitScope_Global, 0, 2.5f, 0), "Reverb set parameter error:4");
    CheckError( AudioUnitSetParameter( auEffectReverbUnit, kReverb2Param_DecayTimeAtNyquist, kAudioUnitScope_Global, 0, 1.5f, 0), "Reverb set parameter error:5");
    CheckError( AudioUnitSetParameter( auEffectReverbUnit, kReverb2Param_RandomizeReflections, kAudioUnitScope_Global, 0, 1000, 0), "Reverb set parameter error:6");
    
    
    // -------- for MAC OS X --------
    // const UInt32 roomType = kReverbRoomType_MediumChamber;
    // CheckError(AudioUnitSetProperty( auEffectReverbUnit, kAudioUnitProperty_ReverbRoomType, kAudioUnitScope_Global, 0, &roomType, sizeof(UInt32)),
    //           "AudioUnitSetProperty[kAudioUnitProperty_ReverbRoomType] failed:6");
    // ----------------------------------------------------------------------------------
    
    
    // get default asbd properties of au effect unit,
    // this sets up the auEffectStreamFormat asbd
    
    
    UInt32 asbdSize2 = sizeof (auEffectReverbStreamFormat);
    memset (&auEffectReverbStreamFormat, 0, sizeof (auEffectReverbStreamFormat ));
    CheckError(AudioUnitGetProperty(auEffectReverbUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &auEffectReverbStreamFormat, &asbdSize2),
               "Couldn't get auEffectUnit(Reverb) ASBD");
    
    // debug print to find out what's actually in this asbd
    
    MyLog (@"The stream format for the effects unit (Reverb):");
    [self printASBD: auEffectReverbStreamFormat];
    
    auEffectReverbStreamFormat.mSampleRate = graphSampleRate;      // make sure the sample rate is correct
    
    CheckError(AudioUnitSetProperty(auEffectReverbUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &auEffectReverbStreamFormat, sizeof(auEffectReverbStreamFormat)),
               "Couldn't set ASBD on effect unit (Reverb) input");
    
    
	// set the sample rate on the effect unit output scope...
    //
    // Here
    // i'm just doing for the effect the same thing that worked for the
    // mixer output when there was no effect
    //
    
    MyLog (@"Setting sample rate for au effect unit (Reverb) output scope");
    // Set the mixer unit's output sample rate format. This is the only aspect of the output stream
    //    format that must be explicitly set.
    result = AudioUnitSetProperty (
                                   auEffectReverbUnit,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set au effect Reverb unit output stream format)" withStatus: result]; return;}
    
    //
    CheckError(AudioUnitSetProperty( auEffectReverbUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &auEffectStreamFormat, sizeof(auEffectStreamFormat)),
               "Couldn't set ASBD on AU Effect Reverb output");
    
    CheckError(AudioUnitSetProperty( auConvertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &auEffectReverbStreamFormat, sizeof(auEffectReverbStreamFormat)),
               "Couldn't set ASBD on AU Convert output");
    
    /*
    CheckError(AudioUnitSetProperty( auConvertUnit1, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &auEffectReverbStreamFormat, sizeof(auEffectStreamFormat)),
               "Couldn't set ASBD on AU Convert-1 output");
    CheckError(AudioUnitSetProperty( auConvertUnit2, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &auEffectReverbStreamFormat, sizeof(auEffectStreamFormat)),
               "Couldn't set ASBD on AU Convert-2 output");
    */
    
    
    // Connect the nodes of the audio processing graph
    [self connectAudioProcessingGraph];
    
    
    //............................................................................
    // Initialize audio processing graph
    
    // Diagnostic code
    // Call CAShow if you want to look at the state of the audio processing
    //    graph.
    MyLog (@"Audio processing graph state immediately before initializing it:");
    CAShow (processingGraph);
    
    MyLog (@"Initializing the audio processing graph");
    // Initialize the audio processing graph, configure audio data stream formats for
    //    each input and output, and validate the connections between audio units.
    result = AUGraphInitialize (processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphInitialize" withStatus: result]; return;}
    
    
    
    /*
     // ------------------- new for Recording file ----------------------------------
     // Method (A)
     AURenderCallbackStruct callbackStruct = {0};
     callbackStruct.inputProc = recordingAURenderCallback;
     callbackStruct.inputProcRefCon = (__bridge void *)self;   // auEffectUnit;
     
     result = AudioUnitSetProperty(ioUnit,
     kAudioUnitProperty_SetRenderCallback,
     kAudioUnitScope_Input,
     0,
     &callbackStruct,
     sizeof(callbackStruct));
     if (noErr != result) {[self printErrorMessage: @"(*******)IO_Unit setRenderCallback " withStatus: result]; return;}
     */
    
    // Method (B)
    // ---- move to startRecording --------
    //    result = AudioUnitAddRenderNotify(auEffectUnit, recordingAURenderCallback, (__bridge void *) self);
    //    if (noErr != result) {[self printErrorMessage: @"(*******)IO_Unit setRenderCallback " withStatus: result]; return;}
    
    //-------------------------------------------------------------------------------
    
    
    // ------------------------------------------------
    // for LOW_PASS, @2014/1/10
    ////////////////////////////////////////////////
    // post-init configs
    //
    //[self setLowPassFrequency:20000.0 cutOffDB:-20.0];
    
    /*
     // the relationship between value and db.
     //
     double sampleValue = (double)intSampleValue / 32767.0;
     double db = 20.0 * log10(value);
     */
    
    // wow - this completes all the audiograph setup and initialization
}


// -----------------------------------------------------------------------------
//	allocateAudioBufferListWithNumChannels:size:
//		Create our audio buffer list. A buffer list is the storage we use in
//		our AudioInputProc to get the sound data and hand it on to the sound
//		file writer.
// -----------------------------------------------------------------------------

-(AudioBufferList *) allocateAudioBufferListWithNumChannels: (UInt32)numChannels withSize: (UInt32)size
{
	AudioBufferList *			list = NULL;
	UInt32						i = 0;
	
	list = (AudioBufferList*) calloc( 1, sizeof(AudioBufferList) + numChannels * sizeof(AudioBuffer) );
	if( list == NULL )
		return NULL;
	
	list->mNumberBuffers = numChannels;
	
	for( i = 0; i < numChannels; i++ )
	{
		list->mBuffers[i].mNumberChannels = 1;
		list->mBuffers[i].mDataByteSize = size;
		list->mBuffers[i].mData = malloc(size);
		if(list->mBuffers[i].mData == NULL)
		{
			[self destroyAudioBufferList: list];
			return NULL;
		}
	}
	
	return list;
}


// -----------------------------------------------------------------------------
//	destroyAudioBufferList:size:
//		Dispose of our audio buffer list. A buffer list is the storage we use in
//		our AudioInputProc to get the sound data and hand it on to the sound
//		file writer.
// -----------------------------------------------------------------------------

-(void)	destroyAudioBufferList: (AudioBufferList*)list
{
	UInt32	i = 0;
	
	if( list )
	{
		for( i = 0; i < list->mNumberBuffers; i++ )
		{
			if( list->mBuffers[i].mData )
				free( list->mBuffers[i].mData );
		}
		free( list );
	}
}

- (void) showErrorMessage:(OSStatus) errorCode:(NSString *) title {
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:errorCode
                                     userInfo:nil];
    MyLog(@"%@_Error: %@", title, [error description]);    
}

- (void) startRecording:(NSString *) fileName {
    // Otherwise, we need write the samples buffer to file !!
    
    // Describe format
//    AudioStreamBasicDescription audioFormat=stereoStreamFormat;
//    audioFormat.mFormatID = kAudioFileCAFType;
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    //
    AudioStreamBasicDescription audioFormat = { 0 };
    audioFormat.mSampleRate         = graphSampleRate;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked ;
    audioFormat.mFramesPerPacket    = 1;  
    audioFormat.mChannelsPerFrame   = 1;  // Mono:1  ; Stereo: 2 (Fail to create File);
    audioFormat.mBitsPerChannel     = 32; // Float32(4) * 8 = 32 bits
    audioFormat.mBytesPerPacket     = 4;
    audioFormat.mBytesPerFrame      = 4;
    audioFormat.mReserved           = 0;
    //
    ExtAudioFileRef extAudioFileRef;
    //
        NSURL *destinationURL = [NSURL fileURLWithPath:fileName];
        MyLog([NSString stringWithFormat:@"Ready to RECORD file: %@", fileName]);
        //
         //----------------
        OSStatus result;
        //result = ExtAudioFileOpenURL( (__bridge CFURLRef)destinationURL, &extAudioFileRef);
    
        // output ?
        result = ExtAudioFileCreateWithURL((__bridge CFURLRef) destinationURL, 
                                                    kAudioFileCAFType, 
                                                    &audioFormat, 
                                                    &channelLayout,  // channel layout
                                                    kAudioFileFlags_EraseFile, 
                                                    &extAudioFileRef); 
        //
        if (result != noErr) [self showErrorMessage:result:@" (1) ExtAudioFileCreateWithURL"];
        
        // specify codec
        UInt32 codec = kAppleHardwareAudioCodecManufacturer;
        int size = sizeof(codec);
        result = ExtAudioFileSetProperty(extAudioFileRef, 
                                              kExtAudioFileProperty_CodecManufacturer, 
                                              size, 
                                              &codec);
        if(result != noErr) [self showErrorMessage:result:@" (2) ExtAudioFileSetProperty"];
        // input ??
        result = ExtAudioFileSetProperty(extAudioFileRef, 
                                         kExtAudioFileProperty_ClientDataFormat, 
                                         sizeof(AudioStreamBasicDescription), 
                                         &audioFormat);
        if (result != noErr) [self showErrorMessage:result:@" (3) ExtAudioFileSetProperty"];
        //
        result =  ExtAudioFileWriteAsync(extAudioFileRef, 0, NULL);
        if (result != noErr) [self showErrorMessage:result:@" (4) ExtAudioFileWriteAsync"];
        //
    [self setExtRecordingAudioFileRef: extAudioFileRef];
    
    // ----- Add Render Notify !!
    result = AudioUnitAddRenderNotify(mixerUnit, recordingAURenderCallback, (__bridge void *) self);
    if (noErr != result) {[self printErrorMessage: @"(*******)IO_Unit addRenderNotify(Callback) " withStatus: result]; return;}

    
}

- (void) stopRecording {
    // ----- Remove Render Notify !!
    OSStatus result = AudioUnitRemoveRenderNotify(mixerUnit, recordingAURenderCallback, (__bridge void *) self);
    if (noErr != result) {[self printErrorMessage: @"(*******)IO_Unit removeRenderNotify(Callback) " withStatus: result]; return;}
    
    OSStatus status = ExtAudioFileDispose(extRecordingAudioFileRef);
    printf("OSStatus(ExtAudioFileDispose): %ld\n", status); 
    [self setExtRecordingAudioFileRef: nil];
    // [self destroyAudioBufferList:audioBufferList];
}

#pragma mark -
#pragma mark Playback control

/////////////////
// Start playback
//
//  This is the master on/off switch that starts the processing graph
//
- (void) startAUGraph  {
    //
    MyLog(@"Register Audio Session Route-Changing Listener!");
    // Register the audio route change listener callback function with the audio session.
    [self registerAudioSession];
    
    //
    MyLog (@"Starting audio processing graph");
    OSStatus result = AUGraphStart (processingGraph);
    if (noErr != result) {[self printErrorMessage: @"AUGraphStart" withStatus: result]; return;}
    
    self.playing = YES;
}

////////////////
// Stop playback
- (void) stopAUGraph {
    //
    MyLog(@"UN-Register Audio Session Route-Changing Listener!");
    [self releaseAudioSession];
    //
    MyLog (@"Stopping audio processing graph");
    Boolean isRunning = false;
    OSStatus result = AUGraphIsRunning (processingGraph, &isRunning);
    if (noErr != result) {[self printErrorMessage: @"AUGraphStop:AUGraphIsRunning" withStatus: result]; return;}
    
    if (isRunning) {
        
        result = AUGraphStop (processingGraph);
        if (noErr != result) {[self printErrorMessage: @"AUGraphStop" withStatus: result]; return;}
        self.playing = NO;
    }
}


#pragma mark -
#pragma mark Mixer unit control

////////////////////////
// mixer handler methods

//-----------------------------------
// for LOW_PASS, @2014/1/10
//-----------------------------------
- (void) setLowPassFrequency:(Float32)lowPassFreq cutOffDB:(Float32) cutOffDB {
    // set DEFAULT value : 20k
    mLowPassCutoffFrequency = lowPassFreq;
    CheckError(AudioUnitSetParameter(auEffectUnit,
                                     kLowPassParam_CutoffFrequency,
                                     kAudioUnitScope_Global,
                                     0,
                                     mLowPassCutoffFrequency,
                                     0),
               "Coulnd't set kLowPassParam_CutoffFrequency");
    //
    mLowPassCutoffDB = cutOffDB;
    CheckError(AudioUnitSetParameter(auEffectUnit,
                                     kLowPassParam_Resonance,
                                     kAudioUnitScope_Global,
                                     0,
                                     mLowPassCutoffDB,
                                     0),
               "Coulnd't set kLowPassParam_CutoffDB");
}

//-----------------------------------

//////////////////////////////////////////////////////
// Set pan for Stereo audio
// -1 <-- 0 --> + 1 
// (Left) ----- (Right)
/////////////////////////////////////////////////////
- (void) setMixerInput:(UInt32)inputBus panValue:(AudioUnitParameterValue)newPanGain {
    OSStatus result = AudioUnitSetParameter (
                                             mixerUnit,
                                             kMultiChannelMixerParam_Pan,
                                             kAudioUnitScope_Input,
                                             inputBus,
                                             newPanGain,
                                             0
                                             );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetParameter (set mixer unit Pan volume)" withStatus: result]; return;}    
}

////////////////////////////////////
// Enable or disable a specified bus
- (void) enableMixerInput: (UInt32) inputBus isOn: (AudioUnitParameterValue) isOnValue {
    
    MyLog (@"Bus %d now %@", (int) inputBus, isOnValue ? @"on" : @"off");
    
    OSStatus result = AudioUnitSetParameter (
                                             mixerUnit,
                                             kMultiChannelMixerParam_Enable,
                                             kAudioUnitScope_Input,
                                             inputBus,
                                             isOnValue,
                                             0
                                             );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetParameter (enable the mixer unit)" withStatus: result]; return;}
    
}

//////////////////////////////////////////////////////
// Set the mixer unit input volume for a specified bus
- (void) setMixerInput: (UInt32) inputBus gain: (AudioUnitParameterValue) newGain {
    
    /*
     This method does *not* ensure that sound loops stay in sync if the user has 
     moved the volume of an input channel to zero. When a channel's input 
     level goes to zero, the corresponding input render callback is no longer 
     invoked. Consequently, the sample number for that channel remains constant 
     while the sample number for the other channel continues to increment. As a  
     workaround, the view controller Nib file specifies that the minimum input
     level is 0.01, not zero. (tz: changed this to .00001)
     
     The enableMixerInput:isOn: method in this class, however, does ensure that the 
     loops stay in sync when a user disables and then reenables an input bus.
    */
    
    // adjust the min value for avoiding abnormal operation.
    if (newGain <= 0) newGain = 0.0001f;
    
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

///////////////////////////////////
// Set the mixer unit output volume
- (void) setMixerOutputGain: (AudioUnitParameterValue) newGain {
    
    if (newGain <= 0) newGain = 0.0001f;
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


/////////////////////////////////
// turn on or off master mixer fx
- (void) setMixerFx: (AudioUnitParameterValue) isOnValue {
	
	MyLog (@"mixerFxSwitch now %@", isOnValue ? @"on" : @"off");
	
    UInt32 bypassed = (BOOL) isOnValue ? NO : YES ;
	MyLog (@"setting bypassed to %ld", bypassed);
    
    // ok there's a bug in disortion and reverb - once you bypass it, you can't
    // turn it back on - it just leaves dead air
    //
    
    CheckError(AudioUnitSetProperty (auEffectUnit,
									 kAudioUnitProperty_BypassEffect,
									 kAudioUnitScope_Global,
									 0,
									 &bypassed,
									 sizeof(bypassed)),
			   "Couldn't set bypassed status");
    
    
    
}


/////////////////////////////////////////
// Get the mxer unit output level (post)
- (Float32) getMixerOutputLevel {
    
    // this does not work in any shape or form on any bus of the mixer
    // input or output scope....
    
    Float32 outputLevel;
    
    
    CheckError( AudioUnitGetParameter (      mixerUnit,
                                       kMultiChannelMixerParam_PostAveragePower,
                                       kAudioUnitScope_Output,
                                       0,
                                       &outputLevel
                                       ) ,
               "AudioUnitGetParameter (get mixer unit level") ;
    
    
    
    
    // printf("mixer level is: %f\n", outputLevel);
    
    return outputLevel;
    
}

//////////////////
// mic fx handlers
//
//  mic fx now handled by setting KOKSMixerHostAudio instance variables in
//  the view control UI object handlers
//
//  then the instance variables get evaluated inside the mic callback function
//




////////////////////////////////////////////
// delegates, utilities, other housekeeping
////////////////////////////////////////////

#pragma mark -
#pragma mark Audio Session Delegate Methods
// Respond to having been interrupted. This method sends a notification to the 
//    controller object, which in turn invokes the playOrStop: toggle method. The 
//    interruptedDuringPlayback flag lets the  endInterruptionWithFlags: method know 
//    whether playback was in progress at the time of the interruption.
- (void) beginInterruption {
    
    MyLog (@"Audio session was interrupted.");
    
    if (playing) {
        
        self.interruptedDuringPlayback = YES;
        
        NSString *KOKSMixerHostAudioObjectPlaybackStateDidChangeNotification = @"KOKSMixerHostAudioObjectPlaybackStateDidChangeNotification";
        [[NSNotificationCenter defaultCenter] postNotificationName: KOKSMixerHostAudioObjectPlaybackStateDidChangeNotification object: self]; 
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
            
            MyLog (@"Unable to reactivate the audio session after the interruption ended.");
            return;
            
        } else {
            
            MyLog (@"Audio session reactivated after interruption.");
            
            if (interruptedDuringPlayback) {
                
                self.interruptedDuringPlayback = NO;
                
                // Resume playback by sending a notification to the controller object, which
                //    in turn invokes the playOrStop: toggle method.
                NSString *KOKSMixerHostAudioObjectPlaybackStateDidChangeNotification = @"KOKSMixerHostAudioObjectPlaybackStateDidChangeNotification";
                [[NSNotificationCenter defaultCenter] postNotificationName: KOKSMixerHostAudioObjectPlaybackStateDidChangeNotification object: self]; 
                
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
    
    MyLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    MyLog (@"  Format ID:           %10s",    formatIDString);
    MyLog (@"  Format Flags:        %10lu",    asbd.mFormatFlags);
    MyLog (@"  Bytes per Packet:    %10lu",    asbd.mBytesPerPacket);
    MyLog (@"  Frames per Packet:   %10lu",    asbd.mFramesPerPacket);
    MyLog (@"  Bytes per Frame:     %10lu",    asbd.mBytesPerFrame);
    MyLog (@"  Channels per Frame:  %10lu",    asbd.mChannelsPerFrame);
    MyLog (@"  Bits per Channel:    %10lu",    asbd.mBitsPerChannel);
    
}


- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result {
    
    
    char str[20];
	// see if it appears to be a 4-char-code
	*(UInt32 *)(str + 1) = CFSwapInt32HostToBig(result);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else
		// no, format it as an integer
		sprintf(str, "%d", (int)result);
	
    //	fprintf(stderr, "Error: %s (%s)\n", operation, str);
    
    
    NSLog (
           @"*** %@ error: %s\n",
           errorString,
           str
           );
}



#pragma mark -
#pragma mark Deallocate

- (void) dealloc {

    // [self releaseAudioBuffer];
    // [super dealloc];
    //

}

- (void) releaseAudioBuffer {

    // release - setDelegate nil , 2013/7/4
    [[AVAudioSession sharedInstance] setDelegate:nil];
    
    // release
    DisposeAUGraph(processingGraph);
    
    // get rid of DiracFx3
    if (mDiracFx31) {
        ZtxFxDestroy(mDiracFx31);
        mDiracFx31 = nil;
    }
    if (mDiracFx32) {
        ZtxFxDestroy(mDiracFx32);
        mDiracFx32 = nil;
    }
    // Free buffer for output
    DeallocateAudioBuffer(mAudioIn, 1);
    DeallocateAudioBuffer(mAudioOut, 1);
    
    //---------------------------------------
    for (int musicChannel = 0; musicChannel < NUM_CHANNELS; ++musicChannel)  {
        
        if (sourceURLArray[musicChannel] != nil) {
            CFRelease (sourceURLArray[musicChannel]);
            sourceURLArray[musicChannel] = nil;
        }
        //
        if (soundStructArray[musicChannel].audioDataLeft != nil) {
            free (soundStructArray[musicChannel].audioDataLeft);
            soundStructArray[musicChannel].audioDataLeft = nil;
            // it's a deplicated buffer
            soundStructArray[1].audioDataLeft = nil;
        }
        
        if (soundStructArray[musicChannel].audioDataRight != nil) {
            free (soundStructArray[musicChannel].audioDataRight);
            soundStructArray[musicChannel].audioDataRight = nil;
            // it's a deplicated buffer
            soundStructArray[1].audioDataRight = nil;
        }
    }
    
    // release the buffer
    if (conversionBufferLeft != nil)
       free(conversionBufferLeft);
    // release the buffer
    if (conversionBufferRight != nil)
       free(conversionBufferRight);
}

@end

