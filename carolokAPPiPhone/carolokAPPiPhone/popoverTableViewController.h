//
//  popoverTableViewController.h
//  carolAPPs
//
//  Created by 國立中興大學 資訊工程學系 國立中興大學 資訊工程學系 on 12/7/5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQLiteDBTool.h"

@protocol popOverViewDelegate <NSObject>

- (void)FileSelected:(BOOL)isSelected;

@end
@interface popoverTableViewController : UITableViewController
{
    SQLiteDBTool *database1;
}
@property (nonatomic, retain) NSMutableArray *listData;
@property (nonatomic, retain) id detailItem;

@property (nonatomic, weak)   id<popOverViewDelegate> delegate;
- (void)renewData;
- (void)getRemainTrack : (int) remainTrack;
- (void)SourceController : (NSString*) sourceController;
@end
