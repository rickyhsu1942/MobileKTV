//
//  SettingViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/7.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

//-----View-----
#import "SettingViewController.h"
#import "YoutubeSignInViewController.h"
//-----Tool-----
#import "SQLiteDBTool.h"
#import "AppDelegate.h"
//-----Object-----
#import "GlobalData.h"
#import "Setting.h"
//-----UI-----
#import "RESwitch.h"
#import "UIViewController+MJPopupViewController.h"

@interface SettingViewController () <FBLoginViewDelegate,MJSecondPopupDelegate>
{
    SQLiteDBTool *database;
    AppDelegate *appDelegate;
    Setting *aSetting;
    GlobalData *globalItem;
    RESwitch *YoutubeswitchView;
}

@property (weak, nonatomic) IBOutlet UIButton *ButtonChangeYoutbe;
@property (weak, nonatomic) IBOutlet UIButton *Button800x600;
@property (weak, nonatomic) IBOutlet UIButton *Button640x480;
@property (weak, nonatomic) IBOutlet UIButton *Button400x300;
@property (weak, nonatomic) IBOutlet UIButton *ButtonLogout;
@property (weak, nonatomic) IBOutlet UIButton *ButtonFacebook;
@property (strong, nonatomic) id<FBGraphUser> loggedInUser;
@property (weak, nonatomic) IBOutlet UILabel *LabelVersion;

@end

@implementation SettingViewController
@synthesize ButtonChangeYoutbe,Button400x300,Button640x480,Button800x600,ButtonLogout,ButtonFacebook;
#pragma mark -
#pragma mark - IBAction
- (IBAction)BackPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)ChangeResolution:(id)sender {
    UIButton *btn = sender;
    if ([globalItem.UserID compare:@"-2"] != NSOrderedSame) {
        [self ResolutionSelected:btn.tag];
    }
}

- (IBAction)LoginOut:(id)sender {
    if ([[FBSession activeSession] isOpen]) { // 登出Facebook
        [appDelegate closeSession];
    }
    [self AutoLogout];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)FacebookLogin:(id)sender
{
    if ([[FBSession activeSession] isOpen]) {
        [appDelegate closeSession];
    } else {
        [appDelegate openSessionWithAllowLoginUI:YES];
    }
}

- (IBAction)ChangeYoutubeAccount:(id)sender {
    [self YoutbeLogin];
}

- (void)YoutubeChanged:(RESwitch *)switchView
{
    if (YoutubeswitchView.isOn) {
        aSetting.YoutubeEnable = @"1";
        if ([aSetting.YoutubeAccount isEqualToString:@"none"]) {
            [self YoutbeLogin];
        }
    }
    else {
        aSetting.YoutubeEnable = @"0";
    }
    [database updateSettingYoutubeEnableWithUserID:aSetting];
}

#pragma mark -
#pragma mark - YoutubeSignIn Delegate
- (void)noneYoutubeSetNone
{
    YoutubeswitchView.on = NO;
    aSetting.UserID = globalItem.UserID;
    aSetting.YoutubeEnable = @"0";
    [database updateSettingYoutubeEnableWithUserID:aSetting];
}


- (void)reloadSetting
{
    aSetting = [database getSettingWithUserID:globalItem.UserID];
    YoutubeswitchView.on = YES;
    aSetting.UserID = globalItem.UserID;
    aSetting.YoutubeEnable = @"1";
    [database updateSettingYoutubeEnableWithUserID:aSetting];
}

#pragma mark -
#pragma mark FbDelegate
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    self.loggedInUser = user;
    
    aSetting.FacebookEnable = @"1";
    [database updateSettingFacebookEnableWithUserID:aSetting];
    [ButtonFacebook setTitle:@"FaceBook登出" forState:UIControlStateNormal];
}


- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    // test to see if we can use the share dialog built into the Facebook application
    FBShareDialogParams *p = [[FBShareDialogParams alloc] init];
    p.link = [NSURL URLWithString:@"http://developers.facebook.com/ios"];
#ifdef DEBUG
    [FBSettings enableBetaFeatures:FBBetaFeaturesShareDialog];
#endif
    self.loggedInUser = nil;
    [ButtonFacebook setTitle:@"FaceBook登入" forState:UIControlStateNormal];
    aSetting.FacebookEnable = @"0";
    [database updateSettingFacebookEnableWithUserID:aSetting];
    
}

#pragma mark -
#pragma mark MJSecondPopupDelegateDelegate
- (void)dismissYoutubeSignInView:(YoutubeSignInViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

#pragma mark - 
#pragma mark - View Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    //-----初始化-----
    database = [[SQLiteDBTool alloc] init];
    appDelegate = [[UIApplication sharedApplication] delegate];
    globalItem = [GlobalData getInstance];
    NSLog(@"%@",globalItem.UserID);
    aSetting = [[Setting alloc]init];
    
    //-----Youtube Switch-----
    CGSize result = [[UIScreen mainScreen] bounds].size;
    CGFloat scale = [UIScreen mainScreen].scale;
    result = CGSizeMake(result.width * scale, result.height * scale);
    
    YoutubeswitchView = [[RESwitch alloc] initWithFrame:CGRectMake(ButtonChangeYoutbe.frame.origin.x + 80, ButtonChangeYoutbe.frame.origin.y + 5, 60, 31)];
    [YoutubeswitchView setBackgroundImage:[UIImage imageNamed:@"btn-onoff顯示"]];
    [YoutubeswitchView setKnobImage:[UIImage imageNamed:@"btn-拉把"]];
    [YoutubeswitchView setOverlayImage:nil];
    [YoutubeswitchView setHighlightedKnobImage:nil];
    [YoutubeswitchView setCornerRadius:0];
    [YoutubeswitchView setKnobOffset:CGSizeMake(0, 0)];
    [YoutubeswitchView setTextShadowOffset:CGSizeMake(0, 0)];
    [YoutubeswitchView setFont:[UIFont boldSystemFontOfSize:14]];
    [YoutubeswitchView setTextOffset:CGSizeMake(0, 2) forLabel:RESwitchLabelOn];
    [YoutubeswitchView setTextOffset:CGSizeMake(3, 2) forLabel:RESwitchLabelOff];
    [YoutubeswitchView setTextColor:[UIColor clearColor] forLabel:RESwitchLabelOn];
    [YoutubeswitchView setTextColor:[UIColor clearColor] forLabel:RESwitchLabelOff];
    [self.view addSubview:YoutubeswitchView];
    [YoutubeswitchView addTarget:self action:@selector(YoutubeChanged:) forControlEvents:UIControlEventValueChanged];
    
    //-----Version-----
    self.LabelVersion.adjustsFontSizeToFitWidth = YES;
    self.LabelVersion.text = [NSString stringWithFormat:@"Carolok V.%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];

    //----Facebook-----
    FBLoginView *loginview = [[FBLoginView alloc] init];
    loginview.frame = CGRectOffset(loginview.frame, 5, 5);
    loginview.delegate = self;
    [self.view addSubview:loginview];
    [loginview setAlpha:0];
    [loginview sizeToFit];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 訪客權限限定
    if ([globalItem.UserID isEqualToString:@"-2"]) {
        [ButtonFacebook setUserInteractionEnabled:NO];
        //        [FBswitchView setEnabled:NO];
        [YoutubeswitchView setEnabled:NO];
        [ButtonChangeYoutbe setEnabled:NO];
    }
    
    // 取得目前使用者的設定狀態
    [self CurrentResolution];
    [self currentYoutubeAndFacebookEnable];
    
    //-----設定登出按鈕禁智能------
    if ([globalItem.UserID isEqualToString:@"-2"])
        [ButtonLogout setEnabled:NO];
    else
        [ButtonLogout setEnabled:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - MySubCode
-(void)ResolutionSelected:(int)Tag
{
    for (int i=1; i<5; i++)
    {
        switch (i) {
            case 2:
                [Button800x600 setImage:[UIImage imageNamed:@"800X600-2.png"] forState:UIControlStateNormal];
                break;
            case 3:
                [Button640x480 setImage:[UIImage imageNamed:@"640X480-2.png"] forState:UIControlStateNormal];
                break;
            case 4:
                [Button400x300 setImage:[UIImage imageNamed:@"400X300-2.png"] forState:UIControlStateNormal];
                break;
            default:
                break;
        }
    }
    UIButton *btnSelected =(UIButton*)[self.view viewWithTag:Tag];
    switch (Tag)
    {
        case 12:
            [Button800x600 setImage:[UIImage imageNamed:@"800X600.png"] forState:UIControlStateNormal];
            break;
        case 13:
            [Button640x480 setImage:[UIImage imageNamed:@"640X480.png"] forState:UIControlStateNormal];
            break;
        case 14:
            [Button400x300 setImage:[UIImage imageNamed:@"400X300.png"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    
    aSetting.UserID = globalItem.UserID;
    aSetting.Resolution = btnSelected.titleLabel.text;
    [database updateSettingResolutionWithUserID:aSetting];
}

-(void)AutoLogout {
    globalItem = [GlobalData getInstance];
    
    // 登出目前使用者
    globalItem.Login = NO;
    globalItem.UserID = nil;
    globalItem.currentUser = nil;
    globalItem.Password = nil;
    globalItem.Membership = nil;
    [database LoginOutAllUser];
    
    // 進入訪客模式
    globalItem.Login = YES;
    globalItem.currentUser = @"G";
    globalItem.Password = @"Guest";
    globalItem.UserID = @"-2";
    globalItem.Membership = @"Guest";
    globalItem.HasMic = @"1";
    globalItem.Point = @"0";
    globalItem.Timelimits = @"none";
    globalItem.UserNickname = @"";
    globalItem.isFristAccount = NO;
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
    NSLog(@"%@ %@ %@ %@ LoginGuest", globalItem.UserID, globalItem.currentUser, globalItem.Password, globalItem.Membership);
    [database addUserInfoToAccount:accinf];
    
}

- (void)YoutbeLogin {
    UIStoryboard *storyboard = self.storyboard;
    YoutubeSignInViewController *YoutubeSignIn  = [storyboard instantiateViewControllerWithIdentifier:@"YoutubeSignInVC"];
    [YoutubeSignIn setValue:self forKey:@"NoneYoutubeDelegate"];
    [YoutubeSignIn setDelegate:self];
    [self presentPopupViewController:YoutubeSignIn animationType:MJPopupViewAnimationFade];
}

-(void)CurrentResolution
{
    for (int i=1; i<5; i++)
    {
        switch (i) {
            case 2:
                [Button800x600 setImage:[UIImage imageNamed:@"800X600-2.png"] forState:UIControlStateNormal];
                break;
            case 3:
                [Button640x480 setImage:[UIImage imageNamed:@"640X480-2.png"] forState:UIControlStateNormal];
                break;
            case 4:
                [Button400x300 setImage:[UIImage imageNamed:@"400X300-2.png"] forState:UIControlStateNormal];
                break;
            default:
                break;
        }
    }
    
    if ([globalItem.UserID isEqualToString:@"-2"])
    {
        aSetting.UserID = globalItem.UserID;
        aSetting.Resolution = @"400*300";
    }
    else {
        aSetting = [database getSettingWithUserID:globalItem.UserID];
    }
    
    if ([aSetting.Resolution isEqualToString:@"400*300"])
        [Button400x300 setImage:[UIImage imageNamed:@"400X300.png"] forState:UIControlStateNormal];
    else if ([aSetting.Resolution isEqualToString:@"640*480"])
        [Button640x480 setImage:[UIImage imageNamed:@"640X480.png"] forState:UIControlStateNormal];
    else if ([aSetting.Resolution isEqualToString:@"800*600"])
        [Button800x600 setImage:[UIImage imageNamed:@"800X600.png"] forState:UIControlStateNormal];
}

- (void)currentYoutubeAndFacebookEnable
{
    aSetting = [database getSettingWithUserID:globalItem.UserID];
    
    if ([aSetting.YoutubeEnable boolValue])
        YoutubeswitchView.on = YES;
    else
        YoutubeswitchView.on = NO;
}

#pragma mark -
#pragma mark - screen control
//- (BOOL)shouldAutorotate {
//    return NO;
//}
//
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    return UIInterfaceOrientationLandscapeRight;
//}


@end
