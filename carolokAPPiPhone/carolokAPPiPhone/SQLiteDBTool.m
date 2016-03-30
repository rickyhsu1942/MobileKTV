//
//  SQLiteDBTool.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/17.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import "SQLiteDBTool.h"
//-----Object-----
#import "MySongList.h"
#import "Production.h"
#import "Setting.h"
#import "GlobalData.h"
#import "WebSite.h"

@implementation SQLiteDBTool
static SQLiteDBTool *instance = nil;

#pragma mark -
#pragma mark - init 初始化
- (id)init
{
    self = [super init];
    if (self) {
        isInserted = NO;
        [self openDatabase];
    }
    return self;
}
//share instance
+ (SQLiteDBTool*)shareInstance
{
    @synchronized(self)
    {
        if (instance == nil) {
            instance = [SQLiteDBTool new];
        }
    }
    return instance;
}

#pragma mark -
#pragma mark - Insert 新增
- (BOOL)addUserInfoToAccount:(NSArray *)accInf
{
    //if account information array contain wrong information, return NO
    NSLog(@"%d",[accInf count]);
    if ([accInf count] != 8)
    {
        NSLog(@"Add User with Wrong #:%d", [accInf count]);
        return NO;
    }
    
    NSString *insert_str;
    NSString *isLogin;
    NSString *select_str;
    sqlite3_stmt *statement;
    
    //set all user login out
    statement = [self executeQuery:@"UPDATE account SET Login=0 WHERE 1"];
    int ResultCode = sqlite3_step(statement);
    if ( ResultCode == SQLITE_DONE)
    {
        NSLog(@"Reset All user isLogin = NO");
        //check if user does exist or not
        select_str = [NSString stringWithFormat:@"SELECT Username FROM account WHERE Username COLLATE NOCASE =\"%@\"", [accInf objectAtIndex:1]];
        NSLog(@"SQL: %@", select_str);
        //reset statement
        sqlite3_reset(statement);
        
        statement = [self executeQuery:select_str];
        ResultCode = sqlite3_step(statement);
        if (ResultCode == SQLITE_ROW)
        {
            //if user is already Login once, set user login
            if (sqlite3_column_type(statement, 0) != SQLITE_NULL)
            {
                insert_str = [NSString stringWithFormat:@"UPDATE account SET Login=1,Password=\"%@\",Membership=\"%@\",HasMic=\"%@\",Point=\"%@\",Timelimits=\"%@\",UserNickname=\"%@\"  WHERE UserID=%@ AND Username COLLATE NOCASE =\"%@\"", [accInf objectAtIndex:2], [accInf objectAtIndex:3], [accInf objectAtIndex:4], [accInf objectAtIndex:5], [accInf objectAtIndex:6], [accInf objectAtIndex:7], [accInf objectAtIndex:0],[accInf objectAtIndex:1]];
                
                NSLog(@"%@",insert_str);
                
                //reset statement
                sqlite3_reset(statement);
                
                statement = [self executeQuery:insert_str];
                ResultCode = sqlite3_step(statement);
                if (ResultCode == SQLITE_DONE)
                {
                    sqlite3_finalize(statement);
                    return YES;
                }
                else
                {
                    sqlite3_finalize(statement);
                    return NO;
                }
            }
        }
        //never login, add user info. to account, and set user login
        else
        {
            isLogin = @"1";
            insert_str = [NSString stringWithFormat:@"INSERT INTO account (UserID, Username, Password, Membership, Login, HasMic, Point, Timelimits, UserNickname) VALUES (%@, \"%@\", \"%@\", \"%@\", %@, \"%@\",%@, \"%@\", \"%@\")", [accInf objectAtIndex:0], [accInf objectAtIndex:1], [accInf objectAtIndex:2], [accInf objectAtIndex:3], isLogin, [accInf objectAtIndex:4], [accInf objectAtIndex:5], [accInf objectAtIndex:6], [accInf objectAtIndex:7]];
            //NSLog(@"%@", insert_str);
            const char *insert_stmt = [insert_str UTF8String];
            
            
            //reset statement
            sqlite3_reset(statement);
            
            sqlite3_prepare_v2(database, insert_stmt, -1, &statement, NULL);
            ResultCode = sqlite3_step(statement);
            if (ResultCode == SQLITE_DONE)
            {
                //NSLog(@"insert data into userinformation");
                sqlite3_finalize(statement);
                return YES;
            }
            else
            {
                sqlite3_finalize(statement);
                return NO;
            }
        }
        
    }
    return YES;
}

- (void)insertSettingResolutionWithUserID:(id)item
{
    Setting *aSetting = (Setting*)item;
    //create SQL statement
    NSString *insert_str;
    NSString *select_str;
    sqlite3_stmt    *statement;
    
    //select statement
    select_str=[NSString stringWithFormat:@"SELECT count (*) FROM setting WHERE UserID=%@",aSetting.UserID];
    //NSLog(@"select_str=%@",select_str);
    statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        if ([[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)] integerValue] == 0) {
            sqlite3_reset(statement);
            //insert statement
            insert_str = [NSString stringWithFormat:@"INSERT INTO setting (UserID, Resolution) VALUES (%@, \"400*300\")", aSetting.UserID];
            //convert NSString to the format char for c language
            const char *insert_stmt = [insert_str UTF8String];
            
            //compiler statement into byte-code
            sqlite3_prepare_v2(database, insert_stmt, -1, &statement, NULL);
            
            //execute byte-code from sqlite3_prepare_v2 function
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
                //NSLog(@"data added %@", aLine);
                //NSLog(@"insert data OK!");
            }
        }
    }
    sqlite3_reset(statement);
}

- (void)insertMySonglist:(NSMutableArray*)contentArray
{
    //insert each data into SQLite
    for (MySongList *aSong in contentArray)
    {
        //create SQL statement
        NSString *insert_str;
        sqlite3_stmt *statement;
        
        //insert statement
        insert_str = [NSString stringWithFormat:@"INSERT INTO mysonglist (songname, singer, songpath, source, tracktime, indexrow, randomrow) VALUES (\"%@\", \"%@\", \"%@\", \"iTune\", \"%@\", %d, %d)", aSong.SongName, aSong.Singer, aSong.SongPath, aSong.TrackTime, aSong.IndexRow, aSong.RandomRow];
        NSLog(@"insert = %@", insert_str);
        //convert NSString to the format char for c language
        const char *insert_stmt = [insert_str UTF8String];
        
        //compiler statement into byte-code
        sqlite3_prepare_v2(database, insert_stmt, -1, &statement, NULL);
        
        //execute byte-code from sqlite3_prepare_v2 function
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            //NSLog(@"data added %@", aLine);
            //NSLog(@"insert data OK!");
        }
        sqlite3_reset(statement);
    }
}

- (Production*)addSongToMyProductionWithProduction:(id)item
{
    NSString *insert_str;
    sqlite3_stmt *statement;
    Production *aProduct = (Production*)item;
    NSInteger randomID = arc4random() % 999;
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
    [formatter1 setDateFormat:@"yyyyMMddHHmmss"];
    NSString *valuestr = [formatter1 stringFromDate:[NSDate date]];
    NSString *newid = [valuestr stringByAppendingFormat:@"%03d", randomID];
    //ProductID is Primary and auto inc. so let it be
    insert_str = [NSString stringWithFormat:@"INSERT INTO myproduction (ProductID, ProductName, ProductPath, ProductCreateTime, ProductType, ProductRight, UserID, ProductTracktime, Producer) VALUES (%@, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", %@, \"%@\", \"%@\")", newid, aProduct.ProductName, aProduct.ProductPath, aProduct.ProductCreateTime, aProduct.ProductType, aProduct.ProductRight, aProduct.userID,aProduct.ProductTracktime,aProduct.Producer];
    //NSLog(@"%@", insert_str);
    const char *insert_stmt = [insert_str UTF8String];
    sqlite3_prepare_v2(database, insert_stmt, -1, &statement, NULL);
    if (sqlite3_step(statement) == SQLITE_DONE)
    {
        //NSLog(@"insert data into myproduction success.");
        sqlite3_finalize(statement);
        aProduct.ProductID = newid;
        return  aProduct;
    }
    else if (sqlite3_step(statement) == SQLITE_ERROR)
    {
        NSLog(@"insert into myproduction error.");
    }
    sqlite3_finalize(statement);
    return nil;
    //return NO;
}

- (UInt64)addSongToMyProduction:(id)item
{
    NSString *insert_str;
    //SQLite statement
    sqlite3_stmt *statement;
    //get production
    Production *aProduct = (Production*)item;
    //random Production ID using data and random number
    NSInteger randomID = arc4random() % 999;
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
    [formatter1 setDateFormat:@"yyyyMMddHHmmss"];
    NSString *valuestr = [formatter1 stringFromDate:[NSDate date]];
    NSString *newid = [valuestr stringByAppendingFormat:@"%03d", randomID];
    //ProductID is Primary and auto inc., so do nothing
    insert_str = [NSString stringWithFormat:@"INSERT INTO myproduction (ProductID, ProductName, ProductPath, ProductCreateTime, ProductType, ProductRight, UserID, ProductTracktime, Producer) VALUES (%@, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", %@, \"%@\", \"%@\")", newid, aProduct.ProductName, aProduct.ProductPath, aProduct.ProductCreateTime, aProduct.ProductType, aProduct.ProductRight, aProduct.userID,aProduct.ProductTracktime,aProduct.Producer];
    //NSLog(@"%@", insert_str);
    const char *insert_stmt = [insert_str UTF8String];
    sqlite3_prepare_v2(database, insert_stmt, -1, &statement, NULL);
    if (sqlite3_step(statement) == SQLITE_DONE)
    {
        //NSLog(@"insert data into myproduction success.");
        sqlite3_finalize(statement);
        return  [newid longLongValue];
    }
    else if (sqlite3_step(statement) == SQLITE_ERROR)
    {
        NSLog(@"insert into myproduction error.");
    }
    sqlite3_finalize(statement);
    return 0;
    //return NO;
}

#pragma mark -
#pragma mark - Select 查詢
- (BOOL)isFirstLogin
{
    sqlite3_stmt * statement;
    NSString *select_str;
    //search user who is login
    select_str = [NSString stringWithFormat:@"SELECT * FROM account where Login=1"];
    statement = [self executeQuery:select_str];
    if (sqlite3_step(statement) == SQLITE_ROW) {
        //if user exists, assing to global data
        GlobalData *globalItem = [GlobalData getInstance];
        globalItem.UserID = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
        globalItem.currentUser = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
        globalItem.Password = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
        globalItem.Membership = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
        globalItem.Point=[[NSString alloc]initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)];
        globalItem.Timelimits=[[NSString alloc]initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)];
        globalItem.HasMic=[[NSString alloc]initWithUTF8String:(const char *) sqlite3_column_text(statement, 7)];
        globalItem.UserNickname=[[NSString alloc]initWithUTF8String:(const char *) sqlite3_column_text(statement, 8)];
        globalItem.Login = YES;
        sqlite3_finalize(statement);
        return NO;
    }
    //else return YES
    sqlite3_finalize(statement);
    return YES;
}

- (WebSite *) getWebsite
{
    WebSite *website = [[WebSite alloc] init];
    
    NSString *frontend;
    NSString *backend;
    
    NSString *select_str = [NSString stringWithFormat:@"SELECT * FROM website"];
    //NSLog(@"%@",select_str);
    sqlite3_stmt *statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        frontend = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
        backend = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
        
        website.FrontEnd = frontend;
        website.BackEnd = backend;
    }
    
    //self.dataList = array;
    sqlite3_finalize(statement);
    return website;
}

- (NSMutableArray *)getMySongListByOrder:(NSString*)OrderBy
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    NSString *select_str = [NSString stringWithFormat:@"SELECT * FROM mysonglist ORDER BY %@",OrderBy];
    //NSLog(@"%@",select_str);
    sqlite3_stmt *statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        MySongList *aSong = [[MySongList alloc] init];
        aSong.PId = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)] integerValue];
        aSong.SongName = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
        aSong.Singer = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
        aSong.SongPath = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
        aSong.Source = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)];
        aSong.isFavorite = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)];
        aSong.TrackTime = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)];
        aSong.IndexRow = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 7)] integerValue];
        aSong.RandomRow = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 8)] integerValue];
        [array addObject:aSong];
    }
    sqlite3_finalize(statement);
    return array;
}

- (NSInteger)getMySongListCount
{
    NSInteger count = 0;
    NSString *select_str = [NSString stringWithFormat:@"SELECT COUNT (*) FROM mysonglist"];
    //NSLog(@"%@",select_str);
    sqlite3_stmt *statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        count= [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)] integerValue];
    }
    sqlite3_finalize(statement);
    return count;
}

- (Setting *) getSettingWithUserID:(NSString *)userid
{
    Setting *aSetting = [[Setting alloc] init];
    
    NSString *resolution;
    NSString *youtubeenable;
    NSString *youtubeaccount;
    NSString *youtubepasswd;
    NSString *facebookenable;
    NSString *micvolume;
    NSString *vocal;
    NSString *volume;
    NSString *echo;
    
    
    sqlite3_stmt *statement;
    
    NSString *select_str = [NSString stringWithFormat:@"SELECT * FROM setting WHERE UserID=%@", userid];
    //NSLog(@"%@", select_str);
    const char *select_stmt = [select_str UTF8String];
    
    if(sqlite3_prepare_v2(database, select_stmt, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error while creating update statement. '%s'", sqlite3_errmsg(database));
        return NO;
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        userid = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
        resolution = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
        youtubeenable = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
        youtubeaccount = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
        youtubepasswd = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)];
        facebookenable = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)];
        micvolume = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)];
        vocal = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 7)];
        volume = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 8)];
        echo = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 9)];
        
        aSetting.UserID = userid;
        aSetting.Resolution = resolution;
        aSetting.YoutubeEnable = youtubeenable;
        aSetting.YoutubeAccount = youtubeaccount;
        aSetting.YoutubePasswd = youtubepasswd;
        aSetting.FacebookEnable = facebookenable;
        aSetting.MicVolume = micvolume;
        aSetting.Vocal = vocal;
        aSetting.Volume = volume;
        aSetting.Echo = echo;
        
        
    }
    sqlite3_finalize(statement);
    return aSetting;
}

- (NSInteger)getMyProductCount
{
    NSInteger count = 0;
    NSString *select_str = [NSString stringWithFormat:@"SELECT COUNT (*) FROM myproduction"];
    //NSLog(@"%@",select_str);
    sqlite3_stmt *statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        count= [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)] integerValue];
    }
    sqlite3_finalize(statement);
    return count;
}

- (Production *)getMyProductionDataWithProductID:(NSString*)ProductID
{
    Production *aProduct = [[Production alloc] init];
    NSString *productid;
    NSString *productname;
    NSString *productPath;
    NSString *productcreatetime;
    NSString *producttype;
    NSString *productright;
    NSString *userid;
    NSString *mw_id;
    NSString *filestate;
    NSString *productTracktime;
    NSString *producer;
    
    NSString *select_str = [NSString stringWithFormat:@"SELECT * FROM myproduction WHERE ProductID=%@",ProductID];
    
    sqlite3_stmt *statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        productid = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
        productname = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
        productPath = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
        productcreatetime = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
        producttype = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)];
        productright = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)];
        userid = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)];
        mw_id=[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 8)];
        filestate=[[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 9)];
        productTracktime=[[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 10)];
        producer=[[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 11)];
        
        
        aProduct.ProductID = productid;
        aProduct.userID = userid;
        aProduct.ProductName = productname;
        aProduct.ProductPath = productPath;
        aProduct.ProductCreateTime = (NSDate*)productcreatetime;
        aProduct.ProductType = producttype;
        aProduct.ProductRight = productright;
        aProduct.mw_id = mw_id;
        aProduct.FileState = filestate;
        aProduct.ProductTracktime = productTracktime;
        aProduct.Producer = producer;
    }
    sqlite3_finalize(statement);
    return aProduct;
}


- (NSMutableArray *)getMyProductionData
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    NSString *productid;
    NSString *productname;
    NSString *productPath;
    NSString *productcreatetime;
    NSString *producttype;
    NSString *productright;
    NSString *userid;
    NSString *mw_id;
    NSString *filestate;
    NSString *productTracktime;
    NSString *producer;
    
    
    sqlite3_stmt *statement = [self executeQuery:@"SELECT * FROM myproduction Where Producer != \"(null)\""];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        productid = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
        productname = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
        productPath = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
        productcreatetime = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
        producttype = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)];
        productright = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)];
        userid = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)];
        mw_id = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 8)];
        filestate = [[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 9)];
        productTracktime = [[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 10)];
        producer = [[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 11)];
        Production *aProduct = [[Production alloc] init];
        
        aProduct.ProductID = productid;
        aProduct.userID = userid;
        aProduct.ProductName = productname;
        aProduct.ProductPath = productPath;
        aProduct.ProductCreateTime = (NSDate*)productcreatetime;
        aProduct.ProductType = producttype;
        aProduct.ProductRight = productright;
        aProduct.mw_id = mw_id;
        aProduct.FileState = filestate;
        aProduct.ProductTracktime = productTracktime;
        aProduct.Producer = producer;
        
        [array addObject:aProduct];
    }
    sqlite3_finalize(statement);
    return array;
}

- (NSMutableArray *)getMyProductionDataWithType:(NSString*)type
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    NSString *productid;
    NSString *productname;
    NSString *productPath;
    NSString *productcreatetime;
    NSString *producttype;
    NSString *productright;
    NSString *userid;
    NSString *mw_id;
    NSString *filestate;
    NSString *productTracktime;
    NSString *producer;
    
    NSString *select_str = [NSString stringWithFormat:@"SELECT * FROM myproduction WHERE ProductType=\"%@\" And Producer != \"(null)\"", type];
    sqlite3_stmt *statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        productid = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
        productname = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
        productPath = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
        productcreatetime = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
        producttype = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)];
        productright = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)];
        userid = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)];
        mw_id=[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 8)];
        filestate=[[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 9)];
        productTracktime=[[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 10)];
        producer=[[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(statement, 11)];
        Production *aProduct = [[Production alloc] init];
        
        aProduct.ProductID = productid;
        aProduct.userID = userid;
        aProduct.ProductName = productname;
        aProduct.ProductPath = productPath;
        aProduct.ProductCreateTime = (NSDate*)productcreatetime;
        aProduct.ProductType = producttype;
        aProduct.ProductRight = productright;
        aProduct.mw_id = mw_id;
        aProduct.FileState = filestate;
        aProduct.ProductTracktime = productTracktime;
        aProduct.Producer = producer;
        
        [array addObject:aProduct];
    }
    sqlite3_finalize(statement);
    return array;
}

#pragma mark -
#pragma mark - Update 修改
- (BOOL)UpdateNewPathForiOS8:(NSString*)newPath
{
    sqlite3_stmt *statement;
    sqlite3_stmt *statement2;
    
    //更改mysonglist的歌曲路徑
    statement = [self executeQuery:[NSString stringWithFormat:@"UPDATE mysonglist SET songpath = REPLACE(songpath,SUBSTR(songpath,1,%d),'%@') WHERE SUBSTR(songpath,1,6) = '/Users' or SUBSTR(songpath,1,4) = '/var'",newPath.length,newPath]];
    //更改myproduction的歌曲路徑
    statement2 = [self executeQuery:[NSString stringWithFormat:@"UPDATE myproduction SET ProductPath = REPLACE(ProductPath,SUBSTR(ProductPath,1,%d),'%@') WHERE SUBSTR(ProductPath,1,6)= '/Users' or SUBSTR(ProductPath,1,4) = '/var'",newPath.length,newPath]];
    int ResultCode = sqlite3_step(statement);
    if ( ResultCode == SQLITE_DONE)
    {
        if (sqlite3_step(statement2)) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)LoginOutAllUser
{
    sqlite3_stmt *statement;
    
    //set all user login out
    statement = [self executeQuery:@"UPDATE account SET Login=0 WHERE 1"];
    int ResultCode = sqlite3_step(statement);
    if ( ResultCode == SQLITE_DONE)
    {
        return YES;
    }
    return NO;
}

- (BOOL)updateWebSiteWithFrontEnd:(NSString*)frontend BackEnd:(NSString*)backend
{
    NSString *update_str;
    sqlite3_stmt *statement;
    
    update_str = [NSString stringWithFormat:@"UPDATE website SET FrontEnd=\"%@\", BackEnd=\"%@\"", frontend, backend];
    //NSLog(@"%@", update_str);
    const char *update_stmt = [update_str UTF8String];
    //sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL);
    
    if(sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error while creating update statement. '%s'", sqlite3_errmsg(database));
        return NO;
    }
    int ResultCode = sqlite3_step(statement);
    
    if (ResultCode == SQLITE_DONE)
    {
        //NSLog(@"Update data into website success.");
        sqlite3_finalize(statement);
        return  YES;
    }
    else if (ResultCode == SQLITE_ERROR)
    {
        NSLog(@"Update into myproduction error.");
    }
    sqlite3_finalize(statement);
    return NO;
}

- (BOOL)updateMySonglistSongName:(NSString *)songname SongPath:(NSString *)songpath
{
    NSString *update_str;
    sqlite3_stmt *statement;
    
    
    update_str = [NSString stringWithFormat:@"UPDATE mysonglist SET SongName=\"%@\" WHERE SongPath = \"%@\"", songname, songpath];
    //NSLog(@"%@", update_str);
    const char *update_stmt = [update_str UTF8String];
    //sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL);
    
    if(sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error while creating update statement. '%s'", sqlite3_errmsg(database));
        return NO;
    }
    int ResultCode = sqlite3_step(statement);
    
    if (ResultCode == SQLITE_DONE)
    {
        //NSLog(@"Update data into myproduction success.");
        sqlite3_finalize(statement);
        return  YES;
    }
    else if (ResultCode == SQLITE_ERROR)
    {
        NSLog(@"Update into myproduction error.");
    }
    sqlite3_finalize(statement);
    return NO;
}

- (BOOL)updateMySonglistIndexRow:(NSInteger)indexrow ByPid:(NSInteger)pid
{
    NSString *update_str;
    sqlite3_stmt *statement;
    
    update_str = [NSString stringWithFormat:@"UPDATE mysonglist SET indexrow = %d WHERE pid = %d", indexrow, pid];
    //NSLog(@"%@", update_str);
    const char *update_stmt = [update_str UTF8String];
    //sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL);
    
    if(sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error while creating update statement. '%s'", sqlite3_errmsg(database));
        return NO;
    }
    int ResultCode = sqlite3_step(statement);
    
    if (ResultCode == SQLITE_DONE)
    {
        //NSLog(@"Update data into myproduction success.");
        sqlite3_finalize(statement);
        return  YES;
    }
    else if (ResultCode == SQLITE_ERROR)
    {
        NSLog(@"Update into myproduction error.");
    }
    sqlite3_finalize(statement);
    return NO;
}

- (BOOL)updateMySonglistIndexrowWithIndexRow:(NSInteger)indexrow
{
    NSString *update_str;
    sqlite3_stmt *statement;
    
    update_str = [NSString stringWithFormat:@"UPDATE mysonglist SET indexrow = indexrow - 1 WHERE indexrow > %d", indexrow];
    //NSLog(@"%@", update_str);
    const char *update_stmt = [update_str UTF8String];
    //sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL);
    
    if(sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error while creating update statement. '%s'", sqlite3_errmsg(database));
        return NO;
    }
    int ResultCode = sqlite3_step(statement);
    
    if (ResultCode == SQLITE_DONE)
    {
        //NSLog(@"Update data into myproduction success.");
        sqlite3_finalize(statement);
        return  YES;
    }
    else if (ResultCode == SQLITE_ERROR)
    {
        NSLog(@"Update into myproduction error.");
    }
    sqlite3_finalize(statement);
    return NO;
}

- (void)updateSettingSingingDefaultWithUserID:(id)item
{
    Setting *aSetting = (Setting*)item;
    //create SQL statement
    NSString *select_str;
    NSString *update_str;
    sqlite3_stmt    *statement;
    
    //select statement
    select_str=[NSString stringWithFormat:@"SELECT count (*) FROM setting WHERE UserID=%@",aSetting.UserID];
    NSLog(@"select_SingingDefault=%@",select_str);
    statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        sqlite3_reset(statement);
        //update statement
        update_str=[NSString stringWithFormat:@"UPDATE setting SET MicVolume=\"%@\" ,Vocal=\"%@\" ,Volume=\"%@\" ,Echo=\"%@\" WHERE UserID=%@",aSetting.MicVolume,aSetting.Vocal,aSetting.Volume,aSetting.Echo,aSetting.UserID];
        //convert NSString to the format char for c language
        //NSLog(@"update_str=%@",update_str);
        const char *update_stmt = [update_str UTF8String];
        
        //compiler statement into byte-code
        sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL);
        
        //execute byte-code from sqlite3_prepare_v2 function
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            //NSLog(@"data added %@", aLine);
            //NSLog(@"update data OK!");
        }
    }
    sqlite3_reset(statement);
}

- (BOOL)updateInformationFromMyProduction:(id)item
{
    NSString *update_str;
    sqlite3_stmt *statement;
    Production *aProduct = (Production*)item;
    //check if SID exists
    if (aProduct.SID == nil) {
        //NSLog(@"SID not exitst: %@", aProduct.SID);
        update_str = [NSString stringWithFormat:@"UPDATE myproduction SET ProductName = \"%@\", ProductPath = \"%@\", ProductCreateTime = \"%@\", ProductType = \"%@\", ProductRight = \"%@\", Producer = \"%@\", ProductTracktime = \"%@\", UserID=%@ WHERE ProductID=%@", aProduct.ProductName, aProduct.ProductPath, aProduct.ProductCreateTime, aProduct.ProductType, aProduct.ProductRight,aProduct.Producer,aProduct.ProductTracktime, aProduct.userID, aProduct.ProductID];
    }
    else {
        //NSLog(@"SID exists: %@", aProduct.SID);
        update_str = [NSString stringWithFormat:@"UPDATE myproduction SET ProductName = \"%@\", ProductPath = \"%@\", ProductCreateTime = \"%@\", ProductType = \"%@\", ProductRight = \"%@\", SID = \"%@\", Producer = \"%@\", ProductTracktime = \"%@\", UserID=%@ WHERE ProductID=\"%@\"", aProduct.ProductName, aProduct.ProductPath, aProduct.ProductCreateTime, aProduct.ProductType, aProduct.ProductRight, aProduct.SID,aProduct.Producer,aProduct.ProductTracktime, aProduct.userID, aProduct.ProductID];
    }
    //ProductID is Primary and auto inc. so let it be
    
    //NSLog(@"%@", update_str);
    const char *update_stmt = [update_str UTF8String];
    //sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL);
    
    if(sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error while creating update statement. '%s'", sqlite3_errmsg(database));
        return NO;
    }
    int ResultCode = sqlite3_step(statement);
    
    if (ResultCode == SQLITE_DONE)
    {
        //NSLog(@"Update data into myproduction success.");
        sqlite3_finalize(statement);
        return  YES;
    }
    else if (ResultCode == SQLITE_ERROR)
    {
        NSLog(@"Update into myproduction error.");
    }
    sqlite3_finalize(statement);
    return NO;
}

- (void)updateSettingResolutionWithUserID:(id)item
{
    Setting *aSetting = (Setting*)item;
    //create SQL statement
    NSString *insert_str;
    NSString *select_str;
    NSString *update_str;
    sqlite3_stmt    *statement;
    
    //select statement
    select_str=[NSString stringWithFormat:@"SELECT count (*) FROM setting WHERE UserID=%@",aSetting.UserID];
    NSLog(@"select_Resolution=%@",select_str);
    statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        if ([[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)] integerValue] == 0) {
            sqlite3_reset(statement);
            //insert statement
            insert_str = [NSString stringWithFormat:@"INSERT INTO setting (UserID, Resolution) VALUES (%@, \"400*300\")", aSetting.UserID];
            //convert NSString to the format char for c language
            const char *insert_stmt = [insert_str UTF8String];
            
            //compiler statement into byte-code
            sqlite3_prepare_v2(database, insert_stmt, -1, &statement, NULL);
            
            //execute byte-code from sqlite3_prepare_v2 function
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
                //NSLog(@"data added %@", aLine);
                //NSLog(@"insert data OK!");
            }
        }
        else {
            sqlite3_reset(statement);
            //update statement
            update_str=[NSString stringWithFormat:@"UPDATE setting SET Resolution=\"%@\" WHERE UserID=%@",aSetting.Resolution,aSetting.UserID];
            //convert NSString to the format char for c language
            //NSLog(@"update_str=%@",update_str);
            const char *update_stmt = [update_str UTF8String];
            
            //compiler statement into byte-code
            sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL);
            
            //execute byte-code from sqlite3_prepare_v2 function
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
                //NSLog(@"data added %@", aLine);
                //NSLog(@"update data OK!");
            }
        }
    }
    sqlite3_reset(statement);
}

- (void)updateSettingYoutubeEnableWithUserID:(id)item
{
    Setting *aSetting = (Setting*)item;
    //create SQL statement
    NSString *select_str;
    NSString *update_str;
    sqlite3_stmt    *statement;
    
    //select statement
    select_str=[NSString stringWithFormat:@"SELECT count (*) FROM setting WHERE UserID=%@",aSetting.UserID];
    NSLog(@"select_YoutubeEnable=%@",select_str);
    statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        sqlite3_reset(statement);
        //update statement
        update_str=[NSString stringWithFormat:@"UPDATE setting SET YoutubeEnable=\"%@\" WHERE UserID=%@",aSetting.YoutubeEnable,aSetting.UserID];
        //convert NSString to the format char for c language
        //NSLog(@"update_str=%@",update_str);
        const char *update_stmt = [update_str UTF8String];
        
        //compiler statement into byte-code
        sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL);
        
        //execute byte-code from sqlite3_prepare_v2 function
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            //NSLog(@"data added %@", aLine);
            //NSLog(@"update data OK!");
        }
    }
    sqlite3_reset(statement);
}

- (void)updateSettingFacebookEnableWithUserID:(id)item
{
    Setting *aSetting = (Setting*)item;
    //create SQL statement
    NSString *select_str;
    NSString *update_str;
    sqlite3_stmt    *statement;
    
    //select statement
    select_str=[NSString stringWithFormat:@"SELECT count (*) FROM setting WHERE UserID=%@",aSetting.UserID];
    NSLog(@"select_FacebookEnable=%@",select_str);
    statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        sqlite3_reset(statement);
        //update statement
        update_str=[NSString stringWithFormat:@"UPDATE setting SET FacebookEnable=\"%@\" WHERE UserID=%@",aSetting.FacebookEnable,aSetting.UserID];
        //convert NSString to the format char for c language
        NSLog(@"update_str=%@",update_str);
        const char *update_stmt = [update_str UTF8String];
        
        //compiler statement into byte-code
        sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL);
        
        //execute byte-code from sqlite3_prepare_v2 function
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            //NSLog(@"data added %@", aLine);
            //NSLog(@"update data OK!");
        }
    }
    sqlite3_reset(statement);
}

- (void)updateSettingYoutubeAccountWithUserID:(id)item
{
    Setting *aSetting = (Setting*)item;
    //create SQL statement
    NSString *select_str;
    NSString *update_str;
    sqlite3_stmt *statement;
    
    //select statement
    select_str=[NSString stringWithFormat:@"SELECT count (*) FROM setting WHERE UserID=%@",aSetting.UserID];
    NSLog(@"select_YoutubeAccount=%@",select_str);
    statement = [self executeQuery:select_str];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        sqlite3_reset(statement);
        //update statement
        update_str=[NSString stringWithFormat:@"UPDATE setting SET YoutubeAccount=\"%@\", YoutubePasswd=\"%@\" WHERE UserID=%@",aSetting.YoutubeAccount,aSetting.YoutubePasswd,aSetting.UserID];
        //convert NSString to the format char for c language
        //NSLog(@"update_str=%@",update_str);
        const char *update_stmt = [update_str UTF8String];
        
        //compiler statement into byte-code
        sqlite3_prepare_v2(database, update_stmt, -1, &statement, NULL);
        
        //execute byte-code from sqlite3_prepare_v2 function
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            //NSLog(@"data added %@", aLine);
            //NSLog(@"update data OK!");
        }
    }
    sqlite3_reset(statement);
}

#pragma mark -
#pragma mark - Delete 刪除
- (BOOL)deleteAllMySonglist
{
    NSString *delete_str;
    sqlite3_stmt *statement = nil;
    delete_str = [NSString stringWithFormat:@"DELETE FROM mysonglist"];
    if(statement == nil) {
        const char *delete_stmt = [delete_str UTF8String];
        if(sqlite3_prepare_v2(database, delete_stmt, -1, &statement, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating delete statement. '%s'", sqlite3_errmsg(database));
    }
    
    //When binding parameters, index starts from 1 and not zero.
    //sqlite3_bind_int(statement, 1, coffeeID);
    
    if (SQLITE_DONE != sqlite3_step(statement))
    {
        NSAssert1(0, @"Error while deleting. '%s'", sqlite3_errmsg(database));
        return NO;
    }
    else
    {
        //NSLog(@"delete from playlist success!");
    }
    sqlite3_finalize(statement);
    //sqlite3_reset(statement);
    return YES;
}

- (BOOL)deleteMySonglistWithPId:(NSInteger)pid
{
    NSString *delete_str;
    sqlite3_stmt *statement = nil;
    delete_str = [NSString stringWithFormat:@"DELETE FROM mysonglist WHERE pid=%d", pid];
    if(statement == nil) {
        const char *delete_stmt = [delete_str UTF8String];
        if(sqlite3_prepare_v2(database, delete_stmt, -1, &statement, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating delete statement. '%s'", sqlite3_errmsg(database));
    }
    
    //When binding parameters, index starts from 1 and not zero.
    //sqlite3_bind_int(statement, 1, coffeeID);
    
    if (SQLITE_DONE != sqlite3_step(statement))
    {
        NSAssert1(0, @"Error while deleting. '%s'", sqlite3_errmsg(database));
        return NO;
    }
    else
    {
        NSLog(@"delete from mysonglist success!");
    }
    sqlite3_finalize(statement);
    //sqlite3_reset(statement);
    return YES;
}

- (BOOL)deleteSongFromMyProductWithProductPath:(id)item
{
    NSString *delete_str;
    sqlite3_stmt *statement = nil;
    Production *aProduct = (Production*)item;
    // 2013/05/24 從ProductName修改為ProductPath
    delete_str = [NSString stringWithFormat:@"DELETE FROM myproduction where ProductPath = \"%@\"", aProduct.ProductPath];
    if(statement == nil) {
        const char *delete_stmt = [delete_str UTF8String];
        if(sqlite3_prepare_v2(database, delete_stmt, -1, &statement, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating delete statement. '%s'", sqlite3_errmsg(database));
    }
    
    //When binding parameters, index starts from 1 and not zero.
    //sqlite3_bind_int(statement, 1, coffeeID);
    
    if (SQLITE_DONE != sqlite3_step(statement))
    {
        NSAssert1(0, @"Error while deleting. '%s'", sqlite3_errmsg(database));
        return NO;
    }
    else
    {
        NSLog(@"delete from songbook success!");
    }
    //sqlite3_finalize(statement);
    sqlite3_reset(statement);
    return YES;
}

- (BOOL)deleteSongFromMyProduct:(id)item
{
    NSString *delete_str;
    sqlite3_stmt *statement = nil;
    Production *aProduct = (Production*)item;
    delete_str = [NSString stringWithFormat:@"DELETE FROM myproduction where ProductID = %@ AND UserID = %@", aProduct.ProductID, aProduct.userID];
    if(statement == nil) {
        const char *delete_stmt = [delete_str UTF8String];
        if(sqlite3_prepare_v2(database, delete_stmt, -1, &statement, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating delete statement. '%s'", sqlite3_errmsg(database));
    }
    
    //When binding parameters, index starts from 1 and not zero.
    //sqlite3_bind_int(statement, 1, coffeeID);
    
    if (SQLITE_DONE != sqlite3_step(statement))
    {
        NSAssert1(0, @"Error while deleting. '%s'", sqlite3_errmsg(database));
        return NO;
    }
    else
    {
        NSLog(@"delete from songbook success!");
    }
    //sqlite3_finalize(statement);
    sqlite3_reset(statement);
    return YES;
}

- (BOOL)deleteAllProduct
{
    NSString *delete_str;
    sqlite3_stmt *statement = nil;
    delete_str = [NSString stringWithFormat:@"DELETE FROM myproduction"];
    if(statement == nil) {
        const char *delete_stmt = [delete_str UTF8String];
        if(sqlite3_prepare_v2(database, delete_stmt, -1, &statement, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating delete statement. '%s'", sqlite3_errmsg(database));
    }
    
    //When binding parameters, index starts from 1 and not zero.
    //sqlite3_bind_int(statement, 1, coffeeID);
    
    if (SQLITE_DONE != sqlite3_step(statement))
    {
        NSAssert1(0, @"Error while deleting. '%s'", sqlite3_errmsg(database));
        return NO;
    }
    else
    {
        //NSLog(@"delete from myproduction success!");
    }
    sqlite3_finalize(statement);
    //sqlite3_reset(statement);
    return YES;
}

#pragma mark -
#pragma mark - database create and open
- (void)openDatabase{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", databaseName]];
    
    if (!database){
        [self copyDatabaseIfNeeded];
        int result = sqlite3_open([path UTF8String], &database);
        if (result != SQLITE_OK){
            NSAssert(0, @"Failed to open database");
        }
    }
}
- (void)copyDatabaseIfNeeded{
    //target path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", databaseName]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL success = [fileManager fileExistsAtPath:path];
    
    if(!success) {
        
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", databaseName]];
        success = [fileManager copyItemAtPath:defaultDBPath toPath:path error:&error];
        NSLog(@"Database file copied from bundle to %@", path);
        
        if (!success){
            NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
        }
        
    } else {
        //NSLog(@"Database file found at path %@", path);
        //isInserted = YES;
        //[fileManager removeItemAtPath:path error:nil];
    }
}
- (void) closeDatabase{
    if (database){
        sqlite3_close(database);
    }
}

#pragma mark -
#pragma mark - database query
- (sqlite3_stmt *)executeQuery:(NSString *) query{
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil);
    return statement;
}

- (void)dealloc
{
    [self closeDatabase];
}

#pragma mark -
#pragma mark - subCode
- (NSInteger)checkInt :(NSString*)number
{
    if (number == nil || number.length < 1) {
        return 0;
    } else {
        return [number integerValue];
    }
}

- (float)checkFloat :(NSString*)number
{
    if (number == nil || number.length < 1) {
        return 0;
    } else {
        return [number floatValue];
    }
}

- (NSString *)checkNull : (const char *)sqlchar
{
    const char* date = sqlchar;
    NSString *enddate = date == NULL ? nil : [[NSString alloc] initWithUTF8String:date]; // 判定sqlchar是否為null
    return enddate;
}


@end
