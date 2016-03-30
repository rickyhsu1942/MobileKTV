//
//  ZtxAudioPlayer.h
//  ZtxAudioPlayer
//

#import "ZtxAudioPlayerBase.h"
#import "EAFRead.h"



@interface ZtxAudioPlayer : ZtxAudioPlayerBase 
{

}

-(void)changeDuration:(float)duration;
-(void)changePitch:(float)pitch;
-(void)processAudioThread:(id)param;
-(void)loopBack;
-(void)resetProcessing:(SInt64)position;

@end

