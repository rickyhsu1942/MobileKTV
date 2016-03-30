//
//  AppDelegate.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/17.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import "AppDelegate.h"
//-----Tool-----
#import "SQLiteDBTool.h"
//-----Define-----
#define FrontEND @"http://www.carolok.com.tw"
#define BackEND @"http://webadmin.carolok.com.tw"

@implementation AppDelegate

NSString *const FBSessionStateChangedNotification = @"Iscom.CloudService.Ricky:FBSessionStateChangedNotification";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //use for detect internet connection
    reachability = [Reachability reachabilityForInternetConnection];
    
    //-----Facebook照片宣告-----
    [FBProfilePictureView class];
    //-----資料庫網址-----
    SQLiteDBTool *database = [[SQLiteDBTool alloc] init];
    [database updateWebSiteWithFrontEnd:FrontEND BackEnd:BackEND];
    
    //-----檢查硬體尺寸-----
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        UIStoryboard *storyBoard;
        
        CGSize result = [[UIScreen mainScreen] bounds].size;
        CGFloat scale = [UIScreen mainScreen].scale;
        result = CGSizeMake(result.width * scale, result.height * scale);
        
        if(result.height == 1136){
            storyBoard = [UIStoryboard storyboardWithName:@"iPhone5Storyboard" bundle:nil];
            UIViewController *initViewController = [storyBoard instantiateInitialViewController];
            [self.window setRootViewController:initViewController];
        }
    }
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // FBSample logic
    // this means the user switched back to this app without completing a login in Safari/Facebook App
    if (FBSession.activeSession.state == FBSessionStateCreatedOpening) {
        // BUG: for the iOS 6 preview we comment this line out to compensate for a race-condition in our
        // state transition handling for integrated Facebook Login; production code should close a
        // session in the opening state on transition back to the application; this line will again be
        // active in the next production rev
        [FBSession.activeSession close]; // so we close our session and start over
    }
    [FBAppCall handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    // FBSample logic
    // if the app is going away, we close the session object
    //    [FBSession.activeSession closeAndClearTokenInformation];
    
    // FBSample logic
    // if the app is going away, we close the session if it is open
    // this is a good idea because things may be hanging off the session, that need
    // releasing (completion block, etc.) and other components in the app may be awaiting
    // close notification in order to do cleanup
    [FBSession.activeSession close];
    
}


#pragma mark -
#pragma mark - FaceBook
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"email",
                            @"user_likes",
                            nil];
    return [FBSession openActiveSessionWithReadPermissions:permissions
                                              allowLoginUI:allowLoginUI
                                         completionHandler:^(FBSession *session,
                                                             FBSessionState state,
                                                             NSError *error) {
                                             if (error) {
                                                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                                     message:error.localizedDescription
                                                                                                    delegate:nil
                                                                                           cancelButtonTitle:@"OK"
                                                                                           otherButtonTitles:nil];
                                                 [alertView show];
                                             } else {
                                                 [self sessionStateChanged:session state:state error:error];
                                             }
                                         }];;
}

- (FBSession *) getSession {
    return [FBSession activeSession];
}

- (void) closeSession {
    [FBSession.activeSession closeAndClearTokenInformation];
}

- (void)  closeSessionButKeepCache {
    [FBSession.activeSession close];
}

//追蹤狀態變化
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            if (!error) {
                // We have a valid session
                NSLog(@"User session found");
            }
            break;
        case FBSessionStateCreatedOpening:
            [FBSession.activeSession close];
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FBSessionStateChangedNotification object:session];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

// This method will be used for iOS versions greater than 4.2.
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // attempt to extract a token from the url
    // return [FBSession.activeSession handleOpenURL:url];
    // attempt to extract a token from the url
    
    //return [FBSession.activeSession handleOpenURL:url];
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                    fallbackHandler:^(FBAppCall *call) {
                        NSLog(@"In fallback handler");
                    }];
}

#pragma mark -
#pragma mark - NetWork
- (NetworkStatus)getInternetStatus
{
    /*
     return status type:
     
     1. NotReachable     :no internet
     2. ReachableViaWiFi :WiFi
     3. ReachableViaWWAN :3G
     */
    return [reachability currentReachabilityStatus];
}

@end
