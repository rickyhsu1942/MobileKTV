//
//  WaveformImageVew.h
//  carolAPPs
//
//  Created by iscom on 13/1/21.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface WaveformImageVew : UIImageView{
    
}
-(id)initWithUrl:(NSURL*)url;
- (NSData *) renderPNGAudioPictogramLogForAssett:(AVURLAsset *)songAsset;

@end
