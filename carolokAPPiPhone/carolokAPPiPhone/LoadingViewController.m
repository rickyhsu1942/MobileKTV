//
//  LoadingViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/17.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

//-----View-----
#import "LoadingViewController.h"
#import "MySongListViewController.h"
//-----Tool-----
#import "UIImage+animatedGIF.h"
#import "SQLiteDBTool.h"
//-----Object-----
#import "GlobalData.h"
#import "MySongList.h"

@interface LoadingViewController ()
{
    SQLiteDBTool *database;
    GlobalData *globalItem;
}

@property (weak, nonatomic) IBOutlet UIImageView *ivLoading;
@end

@implementation LoadingViewController


#pragma mark -
#pragma mark - view life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    //-----初始化-----
    database = [[SQLiteDBTool alloc] init];
    
    //-----設定Loading的GIF動畫-----
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Loading" withExtension:@"gif"];
    self.ivLoading.image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
    
    //-----iOS8後會一直重新命名路徑名稱，所以以下為更動資料庫的路徑方法-----
    NSString *newPath;
    NSArray *paths_ = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSLog(@"%@",[paths_ firstObject]);
    if(paths_){
        newPath = [[paths_ firstObject] substringWithRange:NSMakeRange(0,[[paths_ firstObject] length] - 10)];
        [database UpdateNewPathForiOS8:newPath];
    }else{
        NSLog(@"iOS8更動路徑錯誤");
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //-----檢查是否有登入，沒有的話進入訪客模式-----
    if([database isFirstLogin]) {
        [self VisitorLogin];
    }
    
    //-----轉換頁面-----
    UIStoryboard *storyboard = self.storyboard;
    UIViewController *MainMenu  = [storyboard instantiateViewControllerWithIdentifier:@"MainTabBarController"];
    MainMenu.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:MainMenu animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark MySubCode
- (void)VisitorLogin { // 檢查是否有登入，沒有的話進入訪客模式
    globalItem = [GlobalData getInstance];
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


@end
