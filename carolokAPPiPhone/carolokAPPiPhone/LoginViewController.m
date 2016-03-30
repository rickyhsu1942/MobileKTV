//
//  LoginViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/8.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
//-----View-----
#import "LoginViewController.h"
//-----Tool-----
#import "SQLiteDBTool.h"
#import "AppDelegate.h"
#import "ASIHttpMethod.h"
//-----Object-----
#import "GlobalData.h"
#import "Setting.h"
//-----UI-----
#import "UIImage+animatedGIF.h"


@interface LoginViewController () <FBLoginViewDelegate,UITextFieldDelegate>
{
    NSString *account;
    NSString *password;
    AppDelegate *appDelegate;
    ASIHttpMethod *asiHttpmethod;
    SQLiteDBTool *database;
}
@property (weak, nonatomic) IBOutlet UIButton *ButtonRegister;
@property (weak, nonatomic) IBOutlet UIButton *ButtonLogin;
@property (weak, nonatomic) IBOutlet UIView *ViewUILogin;
@property (strong, nonatomic) id<FBGraphUser> loggedInUser;
@property (weak, nonatomic) IBOutlet UIImageView *ivLoading;
@property (weak, nonatomic) IBOutlet UITextField *TextFieldAccount;
@property (weak, nonatomic) IBOutlet UITextField *TextFieldPasswd;

@end

@implementation LoginViewController
@synthesize TextFieldAccount,TextFieldPasswd;
@synthesize ButtonLogin,ButtonRegister;
@synthesize ViewUILogin;
#pragma mark -
#pragma mark - IBAction
- (IBAction)Login:(id)sender {
    if ([appDelegate getInternetStatus] == 0)
    {
        [self showAlertMessage:@"請確認網路是否已連線" withTitle:@"Warning" buttonText:@"了解"];
        return;
    }
    
    [TextFieldAccount resignFirstResponder];
    [TextFieldPasswd resignFirstResponder];
    
    account = TextFieldAccount.text;
    password = TextFieldPasswd.text;
    
    //account and password can't be null
    if ([account compare:@""] == NSOrderedSame || [password compare:@""] == NSOrderedSame) {
        [self showAlertMessage:@"請輸入帳號密碼" withTitle:@"訊息" buttonText:@"了解"];
        return;
    }
    
    [self startLoadingView];
    [self performSelector:@selector(LoginPostToServer) withObject:nil afterDelay:0.5f];
}

- (IBAction)FacebookLogin:(id)sender {
    UIButton *ButtonFacebook = sender;
    if ([[FBSession activeSession] isOpen]) {
        [ButtonFacebook setTitle:@"Facebook Login" forState:UIControlStateNormal];
        [appDelegate closeSession];
    } else {
        [ButtonFacebook setTitle:@"Facebook Logout" forState:UIControlStateNormal];
        [appDelegate openSessionWithAllowLoginUI:YES];
    }
}

- (IBAction)ForgetPasswd:(id)sender {
    if ([appDelegate getInternetStatus] == 0)
    {
        [self showAlertMessage:@"請確認網路是否已連線" withTitle:@"Warning" buttonText:@"了解"];
        return;
    }
    
    [TextFieldAccount resignFirstResponder];
    [TextFieldPasswd resignFirstResponder];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(ForgetPasswordPressed:)]) {
        [self.delegate ForgetPasswordPressed:self];
    }
}

- (IBAction)RegisterAccount:(id)sender {
    if ([appDelegate getInternetStatus] == 0)
    {
        [self showAlertMessage:@"請確認網路是否已連線" withTitle:@"Warning" buttonText:@"了解"];
        return;
    }
    
    [TextFieldAccount resignFirstResponder];
    [TextFieldPasswd resignFirstResponder];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(RegisterPressed:)]) {
        [self.delegate RegisterPressed:self];
    }
}

- (IBAction)AccountEditingBegin:(id)sender {
    [self ChangeUILoginPosition:YES];
}

- (IBAction)PasswdEditingBegin:(id)sender {
    [self ChangeUILoginPosition:YES];
}

- (IBAction)AccountEditingEnd:(id)sender {
    [self ChangeUILoginPosition:NO];
}

- (IBAction)PasswdEditingEnd:(id)sender {
    [self ChangeUILoginPosition:NO];
}

- (IBAction)Back:(id)sender {
    [TextFieldAccount resignFirstResponder];
    [TextFieldPasswd resignFirstResponder];
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissLoginView:)]) {
        [self.delegate dismissLoginView:self];
    }
}

#pragma mark -
#pragma mark FBLoginViewDelegate
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    
    if ([self presentedViewController] != nil) { // 一定要在登入畫面才觸發
        return;
    }
    
    self.loggedInUser = user;
    NSLog(@"%@",[user objectForKey:@"email"]);
    NSLog(@"%@",[user objectForKey:@"gender"]);
    
    if ([user objectForKey:@"email"] == nil) {
        [self showAlertMessage:@"FB認證失敗" withTitle:@"訊息" buttonText:@"了解"];
        if ([[FBSession activeSession] isOpen]) {
            [appDelegate closeSession];
        }
        return;
    }
    
    [self startLoadingView];
    [self performSelector:@selector(FacebookCheckAccountToServer) withObject:nil afterDelay:0.5];
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    // test to see if we can use the share dialog built into the Facebook application
    FBShareDialogParams *p = [[FBShareDialogParams alloc] init];
    p.link = [NSURL URLWithString:@"http://developers.facebook.com/ios"];
#ifdef DEBUG
    [FBSettings enableBetaFeatures:FBBetaFeaturesShareDialog];
#endif
    self.loggedInUser = nil;
}

- (void) FacebookCheckAccountToServer
{
    NSString *ServerResult;
    if ([[self.loggedInUser objectForKey:@"gender"] isEqual:@"male"]) {
        ServerResult = [asiHttpmethod RegisterForFBwithAccount:[self.loggedInUser objectForKey:@"email"] NickName:self.loggedInUser.first_name Sex:@"0"];
    } else {
        ServerResult = [asiHttpmethod RegisterForFBwithAccount:[self.loggedInUser objectForKey:@"email"] NickName:self.loggedInUser.first_name Sex:@"1"];
    }
    // 寫入資料庫
    [self GetResultAndAddToDatabase:ServerResult isFacebook:YES];
}

#pragma mark - 
#pragma mark - Textfield Delegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField
{    
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark - View Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    //-----初始化-----
    asiHttpmethod = [[ASIHttpMethod alloc] init];
    database = [[SQLiteDBTool alloc] init];
    appDelegate = [[UIApplication sharedApplication] delegate];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //-----載入圖片設定-----
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Loading2" withExtension:@"gif"];
    self.ivLoading.image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
    
    //-----取消大小寫與自動修正拼字-----
    [TextFieldAccount setAutocorrectionType:UITextAutocorrectionTypeNo];
    [TextFieldAccount setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    
    //-----委託-----
    TextFieldAccount.delegate = self;
    TextFieldPasswd.delegate = self;
    
    
    FBLoginView *loginview = [[FBLoginView alloc] init];
    loginview.frame = CGRectOffset(loginview.frame, 5, 5);
    loginview.delegate = self;
    [self.view addSubview:loginview];
    [loginview setAlpha:0];
    [loginview sizeToFit];
    
}

-(void)viewDidAppear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - MySubCode
- (void) showAlertMessage:(NSString *) message withTitle:(NSString *)title buttonText:(NSString *) btnCancelText
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: title
                          message:message
                          delegate:nil
                          cancelButtonTitle: btnCancelText
                          otherButtonTitles: nil];
    [alert show];
}

- (void)startLoadingView
{
    [self.ivLoading setHidden:NO];
}

- (void)stopLoadingView
{
    [self.ivLoading setHidden:YES];
}

-(void)LoginPostToServer {
    NSString *resultStr;
    resultStr = [asiHttpmethod LoginServerwithAccount:account Password:password];
    
    if ([resultStr isEqualToString:@"False"])
        [self showAlertMessage:@"網路傳輸失敗" withTitle:@"訊息" buttonText:@"了解"];
    else
        [self GetResultAndAddToDatabase:resultStr isFacebook:NO];
}

- (void) GetResultAndAddToDatabase : (NSString *)strResult isFacebook:(BOOL)isfacebook
{
    if ([strResult isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"網路傳輸失敗"
                                                       delegate:nil
                                              cancelButtonTitle:@"了解"
                                              otherButtonTitles:nil];
        [alert show];
        if ([[FBSession activeSession] isOpen]) {
            [appDelegate closeSession];
        }
        [self stopLoadingView];
        return;
    }
    
    //get result
    NSArray *resultArray = [strResult componentsSeparatedByString:@","];
    
    //get global item instance
    GlobalData *globalItem = [GlobalData getInstance];
    if ([resultArray count] <= 0) {
        [self showAlertMessage:@"Error" withTitle:@"與伺服器連線失敗" buttonText:@"了解"];
        [self stopLoadingView];
        return;
    }
    if ([(NSString*)[resultArray objectAtIndex:1] compare:@"ErrorWithLogin"] != NSOrderedSame)
    {
        NSString *loginResult = [resultArray objectAtIndex:1];
        if ([loginResult compare:@"LoginOK"] == NSOrderedSame)
        {
            //NSLog(@"%@ %@ LoginOK", account, password);
            //GlobalData *globalItem = [GlobalData getInstance];
            globalItem.Login = YES;
            if (isfacebook) { // 如果是facebook登入
                globalItem.currentUser = [self.loggedInUser objectForKey:@"email"];
                globalItem.Password = @"Eu$ji!865DefTT^ji092";
            } else { // 如果是帳號密碼登入
                globalItem.currentUser = account;
                globalItem.Password = password;
            }
            globalItem.UserID = [resultArray objectAtIndex:3];
            globalItem.Membership = [resultArray objectAtIndex:4];
            globalItem.Timelimits = [[resultArray objectAtIndex:5] substringFromIndex:10];
            globalItem.HasMic = [[resultArray objectAtIndex:6] substringFromIndex:7];
            globalItem.Point = [[resultArray objectAtIndex:7] substringFromIndex:7];
            globalItem.UserNickname = [[resultArray objectAtIndex:8] substringFromIndex:9];
            if ([[[resultArray objectAtIndex:9] substringFromIndex:13] isEqualToString:@"1"]) { // 查看是否第一次用FB創立帳號
                globalItem.isFristAccount = YES;
            } else {
                globalItem.isFristAccount = NO;
            }
            NSArray *accinf = [[NSArray alloc] initWithObjects:
                               globalItem.UserID,
                               globalItem.currentUser,
                               globalItem.Password,
                               globalItem.Membership,
                               globalItem.HasMic,
                               globalItem.Point,
                               globalItem.Timelimits,
                               globalItem.UserNickname,
                               nil];
            NSLog(@"%@ %@ %@ %@ %@ LoginOK", globalItem.UserID, globalItem.currentUser, globalItem.Password, globalItem.Membership,globalItem.HasMic);
            [database addUserInfoToAccount:accinf];
            
            Setting *aSetting = [[Setting alloc]init];
            aSetting.UserID = globalItem.UserID;
            [database insertSettingResolutionWithUserID:aSetting];
            
            TextFieldAccount.text=@"";
            TextFieldPasswd.text=@"";
            
            [self stopLoadingView];
            
            [TextFieldAccount resignFirstResponder];
            [TextFieldPasswd resignFirstResponder];
            if (self.delegate && [self.delegate respondsToSelector:@selector(LoginSuccess:)]) {
                [self.delegate LoginSuccess:self];
            }
        }
        else if ([loginResult compare:@"unregister"] == NSOrderedSame)
        {
            NSLog(@"User Unregister");
            globalItem.Login = NO;
            globalItem.UserID = @"";
            globalItem.currentUser = @"";
            globalItem.Password = @"";
            globalItem.Membership = @"";
            globalItem.HasMic = @"";
            if ([resultArray count] > 2) {
                [self showAlertMessage:[resultArray objectAtIndex:2] withTitle:@"訊息" buttonText:@"了解"];
            } else {
                [self showAlertMessage:@"帳號或密碼錯誤" withTitle:@"訊息" buttonText:@"了解"];
            }
            [self stopLoadingView];

        }
        else
        {
            NSLog(@"Login Error");
            globalItem.Login = NO;
            globalItem.UserID = @"";
            globalItem.currentUser = @"";
            globalItem.Password = @"";
            globalItem.Membership = @"";
            globalItem.HasMic = @"";
            [self stopLoadingView];
        }
    }
}

-(void)ChangeUILoginPosition:(BOOL)YesNo
{
    
}

@end
