//
//  OtherViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/30.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

//-----View-----
#import "OtherViewController.h"
#import "SettingViewController.h"
#import "LoginViewController.h"
#import "ForgetPasswordViewController.h"
#import "AgreeTermsViewController.h"
#import "MoreAPPsViewController.h"
//-----Tool-----
#import "SQLiteDBTool.h"
//-----Object-----
#import "GlobalData.h"
//-----UI-----
#import "UIViewController+MJPopupViewController.h"


@interface OtherViewController () <MJSecondPopupDelegate>
{
    SQLiteDBTool *database;
}

@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
@property (weak, nonatomic) IBOutlet UILabel *lbAccount;
@end

@implementation OtherViewController

#pragma mark -
#pragma mark - IBAction
- (IBAction)LoginPressed:(id)sender {
    UIStoryboard *storyboard = self.storyboard;
    LoginViewController *LoginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginVC"];
    [LoginVC setDelegate:self];
    [self presentPopupViewController:LoginVC animationType:MJPopupViewAnimationSlideBottomTop];
}

- (IBAction)SettingPressed:(id)sender
{
    UIStoryboard *storyboard = self.storyboard;
    SettingViewController *SettingVC = [storyboard instantiateViewControllerWithIdentifier:@"SettingVC"];
    SettingVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:SettingVC animated:YES completion:nil];
}

- (IBAction)HelpPressed:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.carolok.com.tw/CustomerService/CustomerServiceFAQ"]];
}

- (IBAction)MoreAppsPressed:(id)sender
{
    UIStoryboard *storyboard = self.storyboard;
    MoreAPPsViewController *MoreAPPsVC = [storyboard instantiateViewControllerWithIdentifier:@"MoreAPPsVC"];
    MoreAPPsVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:MoreAPPsVC animated:YES completion:nil];
}

- (IBAction)NewsPresed:(id)sender {
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
#pragma mark - View Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    //-----初始化-----
    database = [[SQLiteDBTool alloc] init];
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
