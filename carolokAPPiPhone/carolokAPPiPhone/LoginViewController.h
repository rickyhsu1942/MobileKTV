//
//  LoginViewController.h
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/8.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MJSecondPopupDelegate;
@interface LoginViewController : UIViewController

@property (assign, nonatomic) id <MJSecondPopupDelegate>delegate;
@end

@protocol MJSecondPopupDelegate<NSObject>
@optional
- (void)dismissLoginView:(LoginViewController*)secondDetailViewController;
- (void)LoginSuccess:(LoginViewController*)secondDetailViewController;
- (void)ForgetPasswordPressed:(LoginViewController*)secondDetailViewController;
- (void)RegisterPressed:(LoginViewController*)secondDetailViewController;
@end
