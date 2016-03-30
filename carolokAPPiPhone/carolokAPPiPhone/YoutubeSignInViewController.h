//
//  YoutubeSignInViewController.h
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/7.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NoneYoutubeDelegate <NSObject>
- (void)noneYoutubeSetNone;
- (void)reloadSetting;
@end

@protocol MJSecondPopupDelegate;
@interface YoutubeSignInViewController : UIViewController {
    
}
@property (weak, nonatomic) IBOutlet UITextField *txtYoutubeAccount;
@property (weak, nonatomic) IBOutlet UITextField *txtYoutubePasswd;
@property (weak) id NoneYoutubeDelegate;
@property (assign, nonatomic) id <MJSecondPopupDelegate>delegate;

@end


@protocol MJSecondPopupDelegate<NSObject>
@optional
- (void)dismissYoutubeSignInView:(YoutubeSignInViewController*)secondDetailViewController;
@end
