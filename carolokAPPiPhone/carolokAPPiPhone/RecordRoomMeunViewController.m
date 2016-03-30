//
//  RecordRoomMeunViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/29.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

//-----View-----
#import "RecordRoomMeunViewController.h"
#import "RecorderViewController.h"
#import "MixerViewController.h"
#import "AVMixerViewController.h"
#import "LoginViewController.h"
#import "ForgetPasswordViewController.h"
#import "AgreeTermsViewController.h"
//-----Object-----
#import "GlobalData.h"
//-----UI-----
#import "UIViewController+MJPopupViewController.h"

@interface RecordRoomMeunViewController () <MJSecondPopupDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnRecorder;
@property (weak, nonatomic) IBOutlet UIButton *btnMixer;
@property (weak, nonatomic) IBOutlet UIButton *btnAvMixer;
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
@property (weak, nonatomic) IBOutlet UILabel *lbAccount;
@end

@implementation RecordRoomMeunViewController

#pragma mark -
#pragma mark - IBAction
- (IBAction)LoginPressed:(id)sender {
    UIStoryboard *storyboard = self.storyboard;
    LoginViewController *LoginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginVC"];
    [LoginVC setDelegate:self];
    [self presentPopupViewController:LoginVC animationType:MJPopupViewAnimationSlideBottomTop];
}

- (IBAction)RecorderPressed:(id)sender {
    UIStoryboard *storyboard = self.storyboard;
    RecorderViewController *RecorderVC = [storyboard instantiateViewControllerWithIdentifier:@"RecorderVC"];
    RecorderVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:RecorderVC animated:YES completion:nil];
}

- (IBAction)MixerPressed:(id)sender {
    UIStoryboard *storyboard = self.storyboard;
    MixerViewController *MixerVC = [storyboard instantiateViewControllerWithIdentifier:@"MixerVC"];
    MixerVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:MixerVC animated:YES completion:nil];
}

- (IBAction)AvmixerPressed:(id)sender {
    UIStoryboard *storyboard = self.storyboard;
    AVMixerViewController *AVMixerVC = [storyboard instantiateViewControllerWithIdentifier:@"AVMixerVC"];
    AVMixerVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:AVMixerVC animated:YES completion:nil];
}

#pragma mark -
#pragma mark MJSecondPopupDelegateDelegate
- (void)dismissLoginView:(LoginViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)LoginSuccess:(LoginViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    //-----變更登入與帳號顯示-----
    GlobalData *globalItem = [GlobalData getInstance];
    if ([globalItem.UserID isEqualToString:@"-2"]) {
        [self.lbAccount setHidden:YES];
        [self.btnLogin setHidden:NO];
    } else {
        [self.lbAccount setHidden:NO];
        [self.btnLogin setHidden:YES];
    }
    self.lbAccount.text = globalItem.UserNickname;
}

- (void)ForgetPasswordPressed:(LoginViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    [self performSelector:@selector(presentPopupForgetPasswordView) withObject:nil afterDelay:.5];
}

- (void)dismissForgetPasswordView:(ForgetPasswordViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)RegisterPressed:(LoginViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    [self performSelector:@selector(presentPopupRegisterView) withObject:nil afterDelay:.5];
}

#pragma mark -
#pragma mark - view life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];    
    self.lbAccount.adjustsFontSizeToFitWidth = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //-----變更登入與帳號顯示-----
    GlobalData *globalItem = [GlobalData getInstance];
    if ([globalItem.UserID isEqualToString:@"-2"]) {
        [self.lbAccount setHidden:YES];
        [self.btnLogin setHidden:NO];
    } else {
        [self.lbAccount setHidden:NO];
        [self.btnLogin setHidden:YES];
    }
    self.lbAccount.text = globalItem.UserNickname;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - MySubCode
- (void)presentPopupForgetPasswordView
{
    //-----開始忘記密碼視窗-----
    UIStoryboard *storyboard = self.storyboard;
    ForgetPasswordViewController *ForgetPasswordVC = [storyboard instantiateViewControllerWithIdentifier:@"ForgetPasswordVC"];
    [ForgetPasswordVC setDelegate:self];
    [self presentPopupViewController:ForgetPasswordVC animationType:MJPopupViewAnimationFade];
}

- (void)presentPopupRegisterView
{
    //-----開始忘記密碼視窗-----
    UIStoryboard *storyboard = self.storyboard;
    AgreeTermsViewController *AgreeTermsVC = [storyboard instantiateViewControllerWithIdentifier:@"AgreeTermsNC"];
    [self presentViewController:AgreeTermsVC animated:YES completion:nil];
}


@end
