//
//  SaveAlertViewController.h
//  carolAPPs
//
//  Created by iscom on 13/3/12.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "KOKSAVMixer.h"
#import "KOKSMP4PlayerViewController.h"

// ------ Jay's Utilities ----------
#import "SQLiteDBTool.h"
#import "Production.h"
// ---------------------------------

@protocol GivingUpSavingDelegate <NSObject>
-(void)DoneSaving;
-(void)retrySinging;
@end

@protocol MJSecondPopupDelegate;

@interface SaveAlertViewController : UIViewController<UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
{
    KOKSMP4PlayerViewController *avPlayerVC;
    KOKSAVMixer          *avMixer;
    AVMutableComposition *outputAVComposition;
    NSString             *outputVocalFileName;
    NSString             *outputVocalFileFullPath;
    NSTimer              *exportTimer;
    AVPlayer             *previewPlayer;
    BOOL                 playing;
    SQLiteDBTool         *database;
    Production           *tmpProduction;    // for write back the SID( song ID ) to DB !
    NSString             *songType;         // "SongBook" , "AVMixer"
    //
    BOOL                 outputMode;
    NSString             *Tracktime;
}
@property (assign, nonatomic) id <MJSecondPopupDelegate>delegate;
@property (nonatomic, retain) KOKSAVMixer          *avMixer;
@property (nonatomic, retain) AVMutableComposition *outputAVComposition;
@property (nonatomic, retain) NSString             *outputVocalFileName;
@property (nonatomic, retain) NSString             *songType;
@property (nonatomic, retain) AVPlayer             *previewPlayer;
@property (nonatomic, strong) MFMailComposeViewController *emailComposer;
@property (nonatomic, strong) NSString             *uploadedMovieURL;
@property (nonatomic, strong) NSString             *Tracktime;
@property (nonatomic, strong) NSString             *SongName;
@property (weak) id GivingUpSavingDelegate;

- (void) storeUploadedMovieURL: (NSString *) movieURL;
- (void) setOutputAVComposition:outputAVComposition;
- (void) setSongType:(NSString *)sType;
- (void) setOutputMode:(BOOL)yesNo;
- (void) setTracktime:(NSString *)Ttime;

@end

@protocol MJSecondPopupDelegate<NSObject>
@optional
- (void)GiveupSavingButtonClicked:(SaveAlertViewController*)secondDetailViewController;
- (void)retrySingingButtonClicked:(SaveAlertViewController*)secondDetailViewController;
@end

