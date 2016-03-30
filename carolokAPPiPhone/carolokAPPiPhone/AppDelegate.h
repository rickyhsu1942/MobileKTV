//
//  AppDelegate.h
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/17.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "Reachability.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    Reachability *reachability;
}

extern NSString * const FBSessionStateChangedNotification;
@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, nonatomic, retain) Reachability *reachability;

- (FBSession *) getSession;
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (void) closeSession;

- (NetworkStatus) getInternetStatus;
@end
