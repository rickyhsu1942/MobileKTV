//
//  SQLiteDBTool.h
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/17.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#define databaseName @"carol_db.sqlite"

@class Production;
@class Setting;
@class WebSite;

@interface SQLiteDBTool : NSObject
{
    sqlite3 *database;
    BOOL isInserted;
}

+ (SQLiteDBTool*)shareInstance;

//-----新增-----
- (BOOL)addUserInfoToAccount:(NSArray *)accInf;
- (void)insertSettingResolutionWithUserID:(id)item;
- (void)insertMySonglist:(NSMutableArray*)contentArray;
- (Production*)addSongToMyProductionWithProduction:(id)item;
- (UInt64)addSongToMyProduction:(id)item;

//-----查詢-----
- (BOOL)UpdateNewPathForiOS8:(NSString*)newPath;
- (BOOL)isFirstLogin;
- (WebSite *) getWebsite;
- (NSMutableArray *)getMySongListByOrder:(NSString*)OrderBy;
- (NSInteger)getMySongListCount;
- (Production *)getMyProductionDataWithProductID:(NSString*)ProductID;
- (Setting *) getSettingWithUserID:(NSString *)userid;
- (NSInteger)getMyProductCount;
- (NSMutableArray *)getMyProductionData;
- (NSMutableArray *)getMyProductionDataWithType:(NSString*)type;

//-----修改-----
- (BOOL)LoginOutAllUser;
- (BOOL)updateWebSiteWithFrontEnd:(NSString*)frontend BackEnd:(NSString*)backend;
- (BOOL)updateMySonglistSongName:(NSString *)songname SongPath:(NSString *)songpath;
- (BOOL)updateMySonglistIndexRow:(NSInteger)indexrow ByPid:(NSInteger)pid;
- (BOOL)updateMySonglistIndexrowWithIndexRow:(NSInteger)indexrow;
- (void)updateSettingSingingDefaultWithUserID:(id)item;
- (BOOL)updateInformationFromMyProduction:(id)item;
- (void)updateSettingResolutionWithUserID:(id)item;
- (void)updateSettingYoutubeEnableWithUserID:(id)item;
- (void)updateSettingFacebookEnableWithUserID:(id)item;
- (void)updateSettingYoutubeAccountWithUserID:(id)item;

//-----刪除-----
- (BOOL)deleteAllMySonglist;
- (BOOL)deleteMySonglistWithPId:(NSInteger)pid;
- (BOOL)deleteSongFromMyProductWithProductPath:(id)item;
- (BOOL)deleteSongFromMyProduct:(id)item;
- (BOOL)deleteAllProduct;

@end
