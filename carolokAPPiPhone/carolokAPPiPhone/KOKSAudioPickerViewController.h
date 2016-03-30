//
//  KOKSAudioPickerViewController.h
//  TrySinging
//
//  Created by 國立中興大學 資訊工程學系 國立中興大學 資訊工程學系 on 12/10/18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQLiteDBTool.h"

@interface KOKSAudioPickerViewController : UITableViewController <UITableViewDelegate>
{
    NSString *documentsPath;
    SQLiteDBTool *database1;
}
@property id delegate;
@property (nonatomic, retain) NSMutableArray *data;
@end


@protocol KOKSAudioPickerViewControllerDelegate <NSObject>
-(void) setAudioFilename:(NSArray *) filenames ProductName:(NSString *) productname;
-(void) dismissAudioFilePopover;
@end
