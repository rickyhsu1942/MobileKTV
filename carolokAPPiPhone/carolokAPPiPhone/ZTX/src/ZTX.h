/*--------------------------------------------------------------------------------
 
 ZTX.h
 Version 1.0.0
 
 Copyright (C) Zynaptiq GmbH
 Stephan M. Bernsee (SMB)
 All rights reserved
 
 CONFIDENTIAL: This document contains confidential information. 
 Do not disclose any information contained in this document to any
 third-party without the prior written consent of Zynaptiq.
  
 --------------------------------------------------------------------------------*/

// This file contains all the constants and prototypes for the ZTX calls
// that you will need in your project.


#ifndef __ZTX__
#define __ZTX__



// Windows DLL definitions
// ----------------------------------------------------------------------------

#ifndef __APPLE__
	#ifdef ZTX_AS_DLL
		#define DLL_DEF_TYPE __declspec(dllexport)
	#else
		#define DLL_DEF_TYPE
	#endif
#else
	#define DLL_DEF_TYPE __attribute__((visibility("default")))
#endif


// Function prototypes
// ----------------------------------------------------------------------------
#ifdef __cplusplus
extern "C" {
#endif

	/* ******************* ZTX CORE API ********************** */
	/* ZTX Core calls */
	DLL_DEF_TYPE void *ZtxCreate(long lambda, long quality, long numChannels, float sampleRate, long (*readFromChannelsCallback)(float **data, long numFrames, void *userData), void *userData);
	DLL_DEF_TYPE void *ZtxCreateInterleaved(long lambda, long quality, long numChannels, float sampleRate, long (*readFromInterleavedChannelsCallback)(float *data, long numFrames, void *userData), void *userData);
	DLL_DEF_TYPE long ZtxSetProperty(long selector, long double value, void *ztx);
	DLL_DEF_TYPE long double ZtxGetProperty(long selector, void *ztx);
	DLL_DEF_TYPE void ZtxReset(bool clear, void *ztx);
	DLL_DEF_TYPE long ZtxProcess(float **audioOut, long numFrames, void *ztx);
	DLL_DEF_TYPE long ZtxProcessInterleaved(float *audioOut, long numFrames, void *ztx);
	DLL_DEF_TYPE void ZtxDestroy(void *ztx);
	DLL_DEF_TYPE void ZtxSetProcessingBeganCallback(void (*processingCallback)(unsigned long position, void *userData), void *userData, void *ztx);
	
	// available in ZTX PRO only	
	DLL_DEF_TYPE long ZtxSetTuningTable(float *frequencyTable, long numFrequencies, void *ztx);

	
	
	/* ******************* ZTX RETUNE API ********************** */
	/* This is the interface for ZTX Retune algorithm - available in ZTX PRO only */
	DLL_DEF_TYPE void *ZtxRetuneCreate(long quality, float sampleRateHz, float referenceTuningHz);
	DLL_DEF_TYPE void ZtxRetuneDestroy(void *instance);
	DLL_DEF_TYPE void ZtxRetuneProcess(short *indata, short *outdata, long numSampsToProcess, void *instance);
	DLL_DEF_TYPE void ZtxRetuneProcessFloat(float *indata, float *outdata, long numSampsToProcess, void *instance);
	DLL_DEF_TYPE void ZtxRetuneSetKeyList(float *tuningCentRelativeToKey0, long numKeysPerOctave, long octaveOffsetKeyNo, void *ztxRetune);
	DLL_DEF_TYPE void ZtxRetuneSetProperties(float correctionAmountPercent,
								  float correctionCaptureCent,
								  float correctionAutoBypassThreshold,
								  float correctionAmbienceThreshold,
								  void *instance);
	
	DLL_DEF_TYPE float ZtxRetuneGetPitchHz(void *instance);
	DLL_DEF_TYPE bool ZtxRetuneGetKeyStatus(long keyNo, void *instance);
	DLL_DEF_TYPE void ZtxRetuneSetKeyStatus(long keyNo, bool enable, void *instance);
	DLL_DEF_TYPE unsigned long ZtxRetuneGetAllowedKeysMask(void *instance);
	DLL_DEF_TYPE void ZtxRetuneSetAllowedKeysMask(unsigned long mask, void *instance);
	DLL_DEF_TYPE float ZtxRetuneGetClosestKeyDetuneCent(bool respectKeyState, void *instance);
	DLL_DEF_TYPE long ZtxRetuneGetClosestKey(bool respectKeyState, void *instance);
	DLL_DEF_TYPE void ZtxRetunePrintInternalTuningTable(void *instance);
	DLL_DEF_TYPE long ZtxRetuneLatencyFrames(float sampleRate);

	/* Deprecated calls */
	DLL_DEF_TYPE void ZtxRetuneSetPitchHz(float pitchHz, void *instance);
	DLL_DEF_TYPE void ZtxRetuneSetTuningReferenceHz(float referenceTuningHz, void *instance);
	DLL_DEF_TYPE void ZtxRetuneSetTuningTable(float *frequencyTable, long numFrequencies, void *instance);
	
	
	
	/* ******************* ZTX FX API ********************** */
	/* This is the interface for ZTX FX mode */
	DLL_DEF_TYPE void *ZtxFxCreate(long quality, float sampleRateHz, long numChannels);
	DLL_DEF_TYPE long ZtxFxMaxOutputBufferFramesRequired(long double timeFactor, long double pitchFactor, long numInputFrames);
	DLL_DEF_TYPE long ZtxFxOutputBufferFramesRequiredNextCall(long double timeFactor, long double pitchFactor, long numInputFrames, void *instance);
	DLL_DEF_TYPE long ZtxFxLatencyFrames(float sampleRate);
	DLL_DEF_TYPE void ZtxFxDestroy(void *instance);
	DLL_DEF_TYPE long ZtxFxProcessFloat(long double timeFactor, long double pitchFactor, float **indata, float **outdata, long numInputFrames, void *instance);
	DLL_DEF_TYPE long ZtxFxProcessFloatInterleaved(long double timeFactor, long double pitchFactor, float *indata, float *outdata, long numInputFrames, void *instance);
	DLL_DEF_TYPE long ZtxFxProcess(long double timeFactor, long double pitchFactor, short **indata, short **outdata, long numInputFrames, void *instance);
	DLL_DEF_TYPE long ZtxFxProcessInterleaved(long double timeFactor, long double pitchFactor, short *indata, short *outdata, long numInputFrames, void *instance);
	DLL_DEF_TYPE void ZtxFxReset(bool clear, void *instance);
	
		
	
	/* Utilities */
	DLL_DEF_TYPE const char *ZtxVersion(void);
	DLL_DEF_TYPE void ZtxStartClock(void);
	DLL_DEF_TYPE long double ZtxClockTimeSeconds(void);
	DLL_DEF_TYPE float ZtxPeakCpuUsagePercent(void *ztx);
	DLL_DEF_TYPE long double ZtxValidateStretchFactor(long double factor);
	DLL_DEF_TYPE void ZtxPrintSettings(void *ztx);
	DLL_DEF_TYPE const char *ZtxErrorToString(long error);
	DLL_DEF_TYPE long ZtxValidateNumChannels(long numChannels);		// Adjusts number of channels to the allowed range for license type (PRO [n], STUDIO [2] and LE [1])
	
	
#ifdef __cplusplus
}
#endif



// Property enums
// ----------------------------------------------------------------------------

enum
{
	kZtxPropertyPitchFactor = 100,
	kZtxPropertyTimeFactor,
	kZtxPropertyFormantFactor,
	kZtxPropertyCompactSupport,
	kZtxPropertyCacheGranularity,
	kZtxPropertyCacheMaxSizeFrames,
	kZtxPropertyCacheNumFramesLeftInCache,
	kZtxPropertyUseConstantCpuPitchShift,
	kZtxPropertyDoPitchCorrection,
	kZtxPropertyOutputGainDb,
	kZtxPropertyPitchCorrectionBasicTuningHz = 400,
	kZtxPropertyPitchCorrectionSlurTime,
	kZtxPropertyPitchCorrectionDoFormantCorrection = 500,
	kZtxPropertyPitchCorrectionFundamentalFrequency,
	
	kZtxPropertyNumProperties
};


// Lambda enums
// ----------------------------------------------------------------------------
enum
{
	kZtxLambdaPreview = 200,
	kZtxLambda1,
	kZtxLambda2,
	kZtxLambda3,
	kZtxLambda4,
	kZtxLambda5,
	kZtxLambdaTranscribe,
	
	kZtxPropertyNumLambdas
};




// Quality enums
// ----------------------------------------------------------------------------
enum
{
	kZtxQualityPreview = 300,	
	kZtxQualityGood,
	kZtxQualityBetter,
	kZtxQualityBest,
	
	kZtxPropertyNumQualities
};




// Error enums
// ----------------------------------------------------------------------------
enum
{
	kZtxErrorNoErr		= 0,	
	kZtxErrorParamErr		= -1,
	kZtxErrorUnknownErr	= -2,
	kZtxErrorInvalidCb	= -3,
	kZtxErrorCacheErr		= -4,
	kZtxErrorNotInited	= -5,
	kZtxErrorMultipleInits	= -6,
	kZtxErrorFeatureNotSupported	= -7,
	kZtxErrorMemErr		= -108,
	kZtxErrorDemoTimeoutReached = -10001,
	
	kZtxErrorNumErrs
};





#endif /* __ZTX__ */


