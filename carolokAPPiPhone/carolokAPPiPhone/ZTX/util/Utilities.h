/*
 *  Utilities.h
 *
 *
 */

#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif


void checkStatus(int status);
long wrappedDiff(long in1, long in2, long wrap);
void DeallocateAudioBuffer(SInt16 **audio, int numChannels);
void DeallocateAudioBufferWithFloat(float **audio, int numChannels);
float **AllocateAudioBuffer(int numChannels, int numFrames);
SInt16 **AllocateAudioBufferSInt16(int numChannels, int numFrames);
void ClearAudioBufferWithFloat(float **audio, long numChannels, long numFrames);
void ClearAudioBuffer(SInt16 **audio, long numChannels, long numFrames);

void arc_release(id a);
id arc_retain(id a);

