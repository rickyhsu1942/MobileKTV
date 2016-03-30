//
//  ColorSettingViewController.m
//  carolAPPs
//
//  Created by iscom on 13/3/20.
//
//

//-----View-----
#import "ColorSettingViewController.h"

@interface ColorSettingViewController ()
{
    NSString *strRed;
    NSString *strGreen;
    NSString *strBlue;
}
@end

@implementation ColorSettingViewController
@synthesize ImageViewColor;
@synthesize SliderRed,SliderGreen,SliderBlue;
@synthesize LBRed,LBGreen,LBBlue;
@synthesize ViewColor;
@synthesize strRed,strGreen,strBlue;
@synthesize ColorvalueDelegate;

#pragma mark - 
#pragma mark IBAction
- (IBAction)ChageColor:(id)sender {
    float red,green,blue;
    [ViewColor setBackgroundColor:[UIColor colorWithRed:SliderRed.value/255.0
                                                       green:SliderGreen.value/255.0
                                                        blue:SliderBlue.value/255.0
                                                       alpha:1]];
    strRed = [NSString stringWithFormat:@"%3.0f",SliderRed.value];
    strGreen = [NSString stringWithFormat:@"%3.0f",SliderGreen.value];
    strBlue = [NSString stringWithFormat:@"%3.0f",SliderBlue.value];
    red = SliderRed.value > 0 ? SliderRed.value : 0;
    green = SliderGreen.value > 0 ? SliderGreen.value : 0;
    blue = SliderBlue.value > 0 ? SliderBlue.value : 0;
    
}
- (IBAction)Done:(id)sender {
    
    [ColorvalueDelegate Color_RedValue:strRed Green:strGreen Blue:strBlue];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissColorSettingView:)]) {
        [self.delegate dismissColorSettingView:self];
    }
}
#pragma mark - 
#pragma viewDidLoad
- (void)viewDidLoad
{
    [super viewDidLoad];
    SliderRed.value = [strRed floatValue];
    SliderGreen.value = [strGreen floatValue];
    SliderBlue.value = [strBlue floatValue];
    LBRed.text = strRed;
    LBGreen.text = strGreen;
    LBBlue.text = strBlue;
    [ViewColor setBackgroundColor:[UIColor colorWithRed:[strRed intValue]/255.0
                                                  green:[strGreen intValue]/255.0
                                                   blue:[strBlue intValue]/255.0
                                                  alpha:1]];
    
    UIImage *redThumb = [UIImage imageNamed:@"調色-彈跳視窗-R.png"];
    UIImage *blueThumb = [UIImage imageNamed:@"調色-彈跳視窗-B.png"];
    UIImage *greenThumb = [UIImage imageNamed:@"調色-彈跳視窗-G.png"];
    [SliderRed setThumbImage:redThumb forState:UIControlStateNormal];
    [SliderGreen setThumbImage:greenThumb forState:UIControlStateNormal];
    [SliderBlue setThumbImage:blueThumb forState:UIControlStateNormal];
    
}

- (void)viewDidUnload {
    [self setImageViewColor:nil];
    [self setSliderRed:nil];
    [self setSliderGreen:nil];
    [self setSliderBlue:nil];
    [self setLBRed:nil];
    [self setLBGreen:nil];
    [self setLBBlue:nil];
    [self setViewColor:nil];
    [super viewDidUnload];
}
@end
