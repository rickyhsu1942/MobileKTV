//
//  ZtxAudioPlayerBase.h
//  ZtxAudioPlayer
//
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "EAFRead.h"
#include "ZTX.h"

//#define DEBUG	1

#define kAudioBufferNumFrames	(8192)		/* 8192 number of frames in our cache */
#define kOversample				1			/* leave at this value in this version */

#ifndef __has_feature      // Optional.
	#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif


#if __has_feature(objc_arc)
#else
	#define __bridge
#endif


#define kOutputBus 0
#define kInputBus 1


@interface ZtxAudioPlayerBase : NSObject 
{
	AudioComponentInstance mAudioUnit;

	NSURL *mInUrl;
	
	EAFRead *mReader;
	void *mZtx;
	float mSampleRate;
	
	SInt16 **mAudioBuffer;
	long mAudioBufferReadPos;
	long mAudioBufferWritePos;
	
	NSThread *mWorkerThread;
	
	float mTimeFactor, mPitchFactor;
	int mNumberOfLoops;
	int mNumChannels;
	int mLoopCount;
	BOOL mIsPrepared;
	BOOL mIsProcessing;
	volatile BOOL mHasFinishedPlaying;
	
	SInt64 mLastResetPositionInFile;
	SInt64 mFramePositionInInputFile;
	SInt64 mTotalFramesPlayed;
	SInt64 mTotalFramesConsumed;
	SInt64 mTotalFramesGenerated;
	UInt64 mTotalFramesInFile;
	
	float mVolume;
	SInt16 *mPeak;
	SInt16 *mPeakOut;
	
	BOOL mIsRunning;
	
	id mDelegate;
	
}


- (void) processAudioThread:(id)param;			// !!! OVERRIDE THIS!!!
- (void) resetProcessing:(SInt64)position;		// !!! OVERRIDE THIS!!!

- (void) setDelegate:(id)delegate;
- (id) delegate;

- (void) changeDuration:(float)duration;
- (void) changePitch:(float)pitch;
- (NSInteger) numberOfLoops;
- (void) setNumberOfLoops:(NSInteger)loops;
- (void) updateMeters;
- (float) peakPowerForChannel:(NSUInteger)channelNumber;
- (id) initWithContentsOfURL:(NSURL*)inUrl channels:(int)channels error: (NSError **)error;
- (BOOL) prepareToPlay;
- (NSUInteger) numberOfChannels;
- (NSTimeInterval) fileDuration;
- (NSTimeInterval) currentTime;
- (void) play;
- (NSURL*) url;
- (void) setVolume:(float)volume;
- (float) volume;
- (BOOL) playing;
- (void) pause;
- (void) stop;
- (void) dealloc;
- (void) setCurrentTime:(NSTimeInterval)time;



// private calls and accessors, do not use
- (void) notifyDelegateDidFinishPlaying:(ZtxAudioPlayerBase*)player successfully:(BOOL)flag;
- (void) HandleDemoTimeout:(id)param;
- (void) stopProcessing;
- (void) stopAll:(id)param;
- (void) triggerPlay:(id)param;
@property (readonly) AudioComponentInstance mAudioUnit;
@property (readonly) EAFRead *mReader;
@property (readonly) SInt16 **mAudioBuffer;
@property (readonly) void *mZtx;
@property (readwrite) long mAudioBufferReadPos;
@property (readwrite) SInt64 mFramePositionInInputFile;
@property (readwrite) SInt64 mLastResetPositionInFile;
@property (readwrite) SInt64 mTotalFramesPlayed;
@property (readwrite) SInt64 mTotalFramesConsumed;
@property (readwrite) SInt64 mTotalFramesGenerated;
@property (readonly) long mAudioBufferWritePos;
@property (readonly) BOOL mIsProcessing;
@property (readonly) UInt64 mTotalFramesInFile;
@property (readwrite) float mVolume;
@property (readonly) SInt16 *mPeak;
@property (readonly) BOOL mIsPrepared;
@property (readonly) int mNumberOfLoops;
@property (readwrite) int mLoopCount;
@property (readonly) int mNumChannels;


@end


@interface NSObject (ZtxAudioPlayerBaseDelegate)
- (void)ztxPlayerDidFinishPlaying:(ZtxAudioPlayerBase *)player successfully:(BOOL)flag;
@end


