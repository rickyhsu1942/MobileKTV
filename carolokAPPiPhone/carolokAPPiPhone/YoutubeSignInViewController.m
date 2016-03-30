//
//  YoutubeSignInViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/7.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

//-----View-----
#import "YoutubeSignInViewController.h"
//-----Tool-----
#import "SQLiteDBTool.h"
//-----Object-----
#import "Setting.h"
#import "GlobalData.h"

@interface YoutubeSignInViewController () <UITextFieldDelegate>
{
    SQLiteDBTool *database;
    Setting *aSetting;
}

@end

@implementation YoutubeSignInViewController
@synthesize txtYoutubeAccount,txtYoutubePasswd;
@synthesize NoneYoutubeDelegate;


#pragma mark -
#pragma mark - IBAction
// 取消
- (IBAction)Cancel:(id)sender
{
    if ([aSetting.YoutubeAccount isEqualToString:@"none"]) {
        [NoneYoutubeDelegate noneYoutubeSetNone];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissYoutubeSignInView:)]) {
        [self.delegate dismissYoutubeSignInView:self];
    }
}

- (IBAction)YoutubeLogin:(id)sender {
    // 收下鍵盤
    [txtYoutubePasswd resignFirstResponder];
    [txtYoutubeAccount resignFirstResponder];
    
    // 要求帳號是依照完整E-mail型式登入
    NSRange search = [txtYoutubeAccount.text rangeOfString:@"@"];
    if(NSNotFound == search.location)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                        message:@"請輸入完整的Youtube帳號\nEx：abc@gmail.com"
                                                       delegate:nil
                                              cancelButtonTitle:@"了解"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // 判斷是否登入成功
    if ([self login:txtYoutubeAccount.text password:txtYoutubePasswd.text]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                        message:@"登入成功"
                                                       delegate:nil
                                              cancelButtonTitle:@"了解"
                                              otherButtonTitles:nil];
        [alert show];
        
        // 將資訊寫入資料庫
        aSetting.YoutubeAccount = txtYoutubeAccount.text;
        aSetting.YoutubePasswd = txtYoutubePasswd.text;
        [database updateSettingYoutubeAccountWithUserID:aSetting];
        [NoneYoutubeDelegate reloadSetting];
        // 關閉視窗
        if (self.delegate && [self.delegate respondsToSelector:@selector(dismissYoutubeSignInView:)]) {
            [self.delegate dismissYoutubeSignInView:self];
        }
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                        message:@"帳號密碼錯誤"
                                                       delegate:nil
                                              cancelButtonTitle:@"了解"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark -
#pragma mark - Textfield Delegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark - View Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // 初始化
    database = [[SQLiteDBTool alloc] init];
    aSetting = [[Setting alloc]init];
    
    NSAttributedString *AccountPlaceholder = [[NSAttributedString alloc] initWithString:@"請輸入Youtube帳號" attributes:@{ NSForegroundColorAttributeName :[UIColor darkGrayColor]}];
    NSAttributedString *PasswordPlaceholder = [[NSAttributedString alloc] initWithString:@"請輸入Youtube密碼" attributes:@{ NSForegroundColorAttributeName :[UIColor darkGrayColor]}];
    txtYoutubeAccount.attributedPlaceholder = AccountPlaceholder;
    txtYoutubePasswd.attributedPlaceholder = PasswordPlaceholder;
    txtYoutubeAccount.delegate = self;
    txtYoutubePasswd.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    GlobalData *globalItem = [GlobalData getInstance];
    // 抓出目前設定資料
    aSetting = [database getSettingWithUserID:globalItem.UserID];
    // 如果先前有登入，把登入資訊傳給textField裡面
    if ([aSetting.YoutubeAccount compare:@"none"] != NSOrderedSame) {
        txtYoutubeAccount.text = aSetting.YoutubeAccount;
        txtYoutubePasswd.text = aSetting.YoutubePasswd;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - MySubCode
- (BOOL)login:(NSString *)username password:(NSString *)password{
    NSMutableURLRequest *request = [NSMutableURLRequest
                                    requestWithURL:[NSURL URLWithString:@"https://www.google.com/accounts/ClientLogin"]];
    
    //NSString *params = [[NSString alloc] initWithFormat:@"Email=%@&Passwd=%@&service=youtube&source=&continue=http://www.google.com/",username,password];
    NSString *params = [[NSString alloc] initWithFormat:@"accountType=GOOGLE&Email=%@&Passwd=%@&service=cl",username,password];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    
    NSHTTPURLResponse *response;
    NSError *error;
    [request setTimeoutInterval:120];
    NSData *replyData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSString *replyString = [[NSString alloc] initWithData:replyData encoding:NSUTF8StringEncoding];
    NSLog(@"%@",replyString);
    
//    if([replyString rangeOfString:@"Auth="].location!=NSNotFound){
        return YES;
//    }else{
//        return NO;
//    }
}


@end
