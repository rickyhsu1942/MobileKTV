//
//  ProductPickerViewController.h
//  carolAPPs
//
//  Created by iscom on 2014/6/26.
//
//

#import <UIKit/UIKit.h>

@protocol ProductPickDelegate <NSObject>
- (void)RefreshTable;
@end

@interface ProductPickerViewController : UIViewController

@property (weak) id ProductPickDelegate;
@end
