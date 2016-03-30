//
//  ColorSettingViewController.h
//  carolAPPs
//
//  Created by iscom on 13/3/20.
//
//

#import <UIKit/UIKit.h>
//-----View-----
#import "AVMixerViewController.h"
//-----Tool-----
#import "KOKSAVMixer.h"

@protocol ColorValueDelegate <NSObject>

-(void)Color_RedValue:(NSString *)RedValue Green:(NSString*)GreenValue Blue:(NSString*)BlueValue;

@end

@protocol MJSecondPopupDelegate;
@interface ColorSettingViewController : UIViewController
{
    AVMixerViewController *MixVideoVC;
}

@property (assign, nonatomic) id <MJSecondPopupDelegate>delegate;
@property (weak, nonatomic) IBOutlet UIImageView *ImageViewColor;
@property (weak, nonatomic) IBOutlet UIView *ViewColor;
@property (weak, nonatomic) IBOutlet UISlider *SliderRed;
@property (weak, nonatomic) IBOutlet UISlider *SliderGreen;
@property (weak, nonatomic) IBOutlet UISlider *SliderBlue;
@property (retain, nonatomic) IBOutlet UILabel *LBRed;
@property (retain, nonatomic) IBOutlet UILabel *LBGreen;
@property (retain, nonatomic) IBOutlet UILabel *LBBlue;
@property (retain, nonatomic) NSString *strRed;
@property (retain, nonatomic) NSString *strGreen;
@property (retain, nonatomic) NSString *strBlue;
@property (weak) id ColorvalueDelegate;
@end

@protocol MJSecondPopupDelegate<NSObject>
@optional
- (void)dismissColorSettingView:(ColorSettingViewController*)secondDetailViewController;
@end
