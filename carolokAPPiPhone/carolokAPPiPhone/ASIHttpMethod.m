//
//  ASIHttpMethod.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/8.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

//-----Tool-----
#import "ASIHttpMethod.h"
#import "ASIFormDataRequest.h"
#import "SQLiteDBTool.h"
#import "AppDelegate.h"
//-----Object-----
#import "WebSite.h"

@implementation ASIHttpMethod
{
    
    AppDelegate *appDelegate;
    SQLiteDBTool *database;
    WebSite *website;
}


static ASIHttpMethod *instance = nil;

#pragma mark -
#pragma mark - Init
- (id)init
{
    self = [super init];
    if (self) {
        database = [[SQLiteDBTool alloc] init];
        appDelegate = [[UIApplication sharedApplication] delegate];
        website = [[WebSite alloc] init];
        website = [database getWebsite];
    }
    return self;
}

+ (ASIHttpMethod*)getInstance
{
    @synchronized(self)
    {
        if (instance == nil) {
            instance = [ASIHttpMethod new];
        }
    }
    return instance;
}

#pragma mark - 
#pragma mark - Login(登入)
- (NSString *)LoginServerwithAccount:(NSString*)name Password:(NSString*)passwd
{
    __block NSString *Result;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/MemberVerify/MemberVerify",website.BackEnd]];
    __weak ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:name forKey:@"Username"];
    [request setPostValue:passwd forKey:@"Password"];
    
    //-----當請求完成-----
    [request setCompletionBlock :^{
        NSString *responseString = [request responseString];
        NSLog (@"LoginResult >> %@" ,responseString);
        Result = responseString;
    }];
    
    //-----當請求失敗-----
    [request setFailedBlock :^{
        NSError *error = [request error];
        NSLog ( @"LoginResultError >> %@" ,[error userInfo]);
        Result = @"False";
    }];
    
    //-----同步傳輸-----
    [request startSynchronous];
    
    return Result;
}

#pragma mark -
#pragma mark - ForgetPassword (忘記密碼)
- (NSString *)ForgetPasswdToServerByEmail:(NSString*)MailAddr
{
    __block NSString *Result;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ServiceForApp/ForgetPassWord",website.BackEnd]];
    __weak ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:MailAddr forKey:@"MailAddr"];
    
    //-----當請求完成-----
    [request setCompletionBlock :^{
        NSString *responseString = [request responseString];
        NSLog (@"ForgetPasswordResult >> %@" ,responseString);
        Result = responseString;
    }];
    
    //-----當請求失敗-----
    [request setFailedBlock :^{
        NSError *error = [request error];
        NSLog ( @"ForgetPasswordResultError >> %@" ,[error userInfo]);
        Result = @"";
    }];
    
    //-----同步傳輸-----
    [request startSynchronous];

    return Result;
}

- (NSString *)RegisterForFBwithAccount:(NSString*)MailAddr NickName:(NSString*)nickname Sex:(NSString*)sex
{
    __block NSString *Result;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ServiceForApp/RegisterForFB",website.BackEnd]];
    __weak ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:MailAddr forKey:@"MailAddr"];
    [request setPostValue:nickname forKey:@"NickName"];
    [request setPostValue:sex forKey:@"Sex"];
    
    //-----當請求完成-----
    [request setCompletionBlock :^{
        NSString *responseString = [request responseString];
        NSLog (@"FBwithAccountResult >> %@" ,responseString);
        Result = responseString;
    }];
    
    //-----當請求失敗-----
    [request setFailedBlock :^{
        NSError *error = [request error];
        NSLog ( @"FBwithAccountResultError >> %@" ,[error userInfo]);
        Result = @"";
    }];
    
    //-----同步傳輸-----
    [request startSynchronous];
    
    return Result;
}

#pragma mark -
#pragma mark - Register(註冊)
- (NSString *)RegisterServerwithAccount:(NSString*)MailAddr Password:(NSString*)passwd NickName:(NSString*)nickname Sex:(NSString*)sex
{
    __block NSString *Result;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ServiceForApp/Register",website.BackEnd]];
    __weak ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:MailAddr forKey:@"MailAddr"];
    [request setPostValue:passwd forKey:@"Password"];
    [request setPostValue:nickname forKey:@"NickName"];
    [request setPostValue:sex forKey:@"Sex"];
    
    //-----當請求完成-----
    [request setCompletionBlock :^{
        NSString *responseString = [request responseString];
        NSLog (@"RegisterResult >> %@" ,responseString);
        Result = responseString;
    }];
    
    //-----當請求失敗-----
    [request setFailedBlock :^{
        NSError *error = [request error];
        NSLog ( @"RegisterResultError >> %@" ,[error userInfo]);
        Result = @"";
    }];
    
    //-----同步傳輸-----
    [request startSynchronous];
    
    return Result;
}

#pragma mark -
#pragma mark - Youtube上傳通知
-(NSString*)PostYoutubeToSeverWithKey:(NSString*)youtubekey YoutubeTitle:(NSString*)youtubetitle Account:(NSString*)username Passwd:(NSString*)passwd isPublic:(NSString*)ispublic Singer:(NSString*)singer {
    __block NSString *Result;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ServiceForApp/UploadYouTubeProductData",website.BackEnd]];
    __weak ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:username forKey:@"Username"];
    [request setPostValue:passwd forKey:@"Password"];
    [request setPostValue:youtubekey forKey:@"YouTubeCode"];
    [request setPostValue:youtubetitle forKey:@"Title"];
    [request setPostValue:ispublic forKey:@"isPublic"];
    [request setPostValue:singer forKey:@"singer"];
    
    //-----當請求完成-----
    [request setCompletionBlock :^{
        NSString *responseString = [request responseString];
        NSLog (@"YoutubeResult >> %@" ,responseString);
        Result = responseString;
    }];
    
    //-----當請求失敗-----
    [request setFailedBlock :^{
        NSError *error = [request error];
        NSLog ( @"YoutubeResultError >> %@" ,[error userInfo]);
        Result = @"";
    }];
    
    //-----同步傳輸-----
    [request startSynchronous];
    
    return Result;
}

@end
