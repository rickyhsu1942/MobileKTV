//
//  ForgetPasswordViewController.h
//  carolAPPs
//
//  Created by iscom on 13/6/24.
//
//

#import <UIKit/UIKit.h>

@protocol MJSecondPopupDelegate;
@interface ForgetPasswordViewController : UIViewController

@property (assign, nonatomic) id <MJSecondPopupDelegate>delegate;
@end

@protocol MJSecondPopupDelegate<NSObject>
@optional
- (void)dismissForgetPasswordView:(ForgetPasswordViewController*)secondDetailViewController;
@end