//
//  MySongList.h
//  carolAPPs
//
//  Created by iscom on 2014/3/27.
//
//

#import <Foundation/Foundation.h>

@interface MySongList : NSObject
@property (nonatomic) NSInteger PId;
@property (nonatomic,strong) NSString *SongName;
@property (nonatomic,strong) NSString *Singer;
@property (nonatomic,strong) NSString *SongPath;
@property (nonatomic,strong) NSString *Source;
@property (nonatomic,strong) NSString *isFavorite;
@property (nonatomic,strong) NSString *TrackTime;
@property (nonatomic) NSInteger IndexRow;
@property (nonatomic) NSInteger RandomRow;
@end
