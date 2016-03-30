//
//  ASIHttpMethod.h
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/8.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ASIHttpMethod : NSObject

//-----登入-----
- (NSString *)LoginServerwithAccount:(NSString*)name Password:(NSString*)passwd;
- (NSString *)RegisterForFBwithAccount:(NSString*)MailAddr NickName:(NSString*)nickname Sex:(NSString*)sex;
//-----忘記密碼-----
- (NSString *)ForgetPasswdToServerByEmail:(NSString*)MailAddr;
//-----註冊-----
- (NSString *)RegisterServerwithAccount:(NSString*)MailAddr Password:(NSString*)passwd NickName:(NSString*)nickname Sex:(NSString*)sex;
//-----Youtube上傳通知-----
-(NSString*)PostYoutubeToSeverWithKey:(NSString*)youtubekey YoutubeTitle:(NSString*)youtubetitle Account:(NSString*)username Passwd:(NSString*)passwd isPublic:(NSString*)ispublic Singer:(NSString*)singer;
@end
