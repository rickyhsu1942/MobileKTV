//
//  PlayList.h
//  carolAPPs
//
//  Created by iscom on 2014/3/30.
//
//

#import <Foundation/Foundation.h>

@interface PlayList : NSObject
@property (nonatomic) NSInteger PId;
@property (nonatomic) NSInteger SongId;
@property (nonatomic,strong) NSString *SongName;
@property (nonatomic,strong) NSString *Singer;
@property (nonatomic,strong) NSString *SongPath;
@property (nonatomic) NSInteger IndexRow;
@property (nonatomic) NSInteger RandomRow;
@end
