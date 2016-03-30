//
//  ZtxAudioPlayer.h
//  ZtxAudioPlayer
//
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "EAFRead.h"
#import "ZtxAudioPlayerBase.h"


@interface ZtxFxAudioPlayer : ZtxAudioPlayerBase
{
}

-(void)processAudioThread:(id)param;
-(void)loopBack;
-(void)resetProcessing:(SInt64)position;

@end


