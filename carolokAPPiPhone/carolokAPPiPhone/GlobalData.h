//
//  GlobalData.h
//  carolAPPs
//
//  Created by iscom on 12/10/12.
//
//
/*
 This class is used for all view access
 
 purpose:
 1. Login indicator
 */
#import <Foundation/Foundation.h>

@interface GlobalData : NSObject
{
    BOOL Login;
    NSString *UserID;
    NSString *currentUser;
    NSString *Password;
    NSString *Membership;
    NSString *Point;
    NSString *Timelimits;
    NSString *HasMic;
    NSString *UserNickname;
    NSString *FacebookID;
    BOOL isFristAccount;
}
@property (readwrite) BOOL Login;
@property (nonatomic, retain) NSString *UserID;
@property (nonatomic, retain) NSString *currentUser;
@property (nonatomic, retain) NSString *Password;
@property (nonatomic, retain) NSString *Membership;
@property (nonatomic, retain) NSString *Point;
@property (nonatomic, retain) NSString *Timelimits;
@property (nonatomic, retain) NSString *HasMic;
@property (nonatomic, retain) NSString *UserNickname;
@property (nonatomic, retain) NSString *FacebookID;
@property (readwrite) BOOL isFristAccount;

+ (GlobalData *)getInstance;
@end
