//
//  YoutubeUploadViewController.h
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/11.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <UIKit/UIKit.h>
//-----Tool-----
#import "GData.h"
//-----UI-----
#import "AMGProgressView.h"

@protocol FbsharingDelegate <NSObject>
- (void)startFBSharing:(NSString*)youtubeurl;
@end

@protocol MJSecondPopupDelegate;
@interface YoutubeUploadViewController : UIViewController
{
    IBOutlet UIProgressView *mProgressView;
    BOOL mIsPrivate;
    GDataServiceTicket *mUploadTicket;
}
@property (nonatomic, retain) AMGProgressView *mProgressView;
@property (nonatomic, retain) AMGProgressView *progressAVMixer;
@property (nonatomic, retain) NSString *FilePath;
@property (nonatomic, retain) NSString *YoutubeTitle;
@property (nonatomic, retain) NSString *Prodcer;
@property (nonatomic, retain) NSString *ProductID;
@property (weak, nonatomic) IBOutlet UIButton *btnUpload;
@property (weak, nonatomic) IBOutlet UIButton *btnGivingup;
@property (weak, nonatomic) IBOutlet UIImageView *btnShadow;
@property (weak, nonatomic) IBOutlet UIImageView *btnShadow2;
@property (weak, nonatomic) IBOutlet UITextField *txtYoutubeTitle;
@property (weak, nonatomic) IBOutlet UITextField *txtYoutubeDescription;
@property (weak, nonatomic) IBOutlet UITextField *txtYoutubeKeyword;
@property (weak, nonatomic) IBOutlet UILabel *LbProgress;
@property (assign, nonatomic) id <MJSecondPopupDelegate>delegate;
@property (weak) id FbsharingDelegate;


- (IBAction)uploadPressed:(id)sender;

@end

@protocol MJSecondPopupDelegate<NSObject>
@optional
- (void)dismissYoutubeView:(YoutubeUploadViewController*)secondDetailViewController;
@end
