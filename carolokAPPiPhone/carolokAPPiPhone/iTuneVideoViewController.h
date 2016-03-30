//
//  iTuneVideoViewController.h
//  carolAPPs
//
//  Created by iscom on 2014/5/13.
//
//

#import <UIKit/UIKit.h>


@protocol iTuneDelegate <NSObject>
- (void)RefreshTable;
- (void)videoPicker:(NSMutableArray*)SelectedVideoItem;
@end

@interface iTuneVideoViewController : UIViewController

@property (weak) id iTuneDelegate;
@property (weak,nonatomic) NSString *FromVC;
@end
