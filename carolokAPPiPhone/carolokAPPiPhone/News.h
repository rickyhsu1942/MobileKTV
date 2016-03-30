//
//  News.h
//  carolAPPs
//
//  Created by iscom on 13/4/8.
//
//

#import <Foundation/Foundation.h>

@interface News : NSObject
@property (nonatomic, retain) NSString *NewID;
@property (nonatomic, retain) NSString *NewTitle;
@property (nonatomic, retain) NSDate *NewDate;
@property (nonatomic, retain) NSDate *EditDate;
@property (nonatomic, retain) NSString *NewKind;

@end
