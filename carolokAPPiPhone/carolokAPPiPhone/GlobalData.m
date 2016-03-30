//
//  GlobalData.m
//  carolAPPs
//
//  Created by iscom on 12/10/12.
//
//

#import "GlobalData.h"

@implementation GlobalData
@synthesize Login,isFristAccount;
@synthesize currentUser, UserID, Password, UserNickname, FacebookID;
@synthesize Membership;
@synthesize Point,Timelimits,HasMic;

static GlobalData *instance = nil;

+ (GlobalData*)getInstance
{
    @synchronized(self)
    {
        if (instance == nil) {
            instance = [GlobalData new];
        }
    }
    return instance;
}
@end
