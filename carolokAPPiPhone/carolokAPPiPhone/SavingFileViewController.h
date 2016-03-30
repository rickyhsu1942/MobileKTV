//
//  SavingFileViewController.h
//  carolAPPs
//
//  Created by iscom on 13/3/28.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "KOKSAVMixer.h"

// ------ Jay's Utilities ----------
#import "SQLiteDBTool.h"
#import "Production.h"
// ---------------------------------

@protocol SavingFileVCDelegate <NSObject>
- (void)DoneAVMixandGetProductPath:(NSString*)productPath;
@end

@protocol MJSecondPopupDelegate;
@interface SavingFileViewController : UIViewController <UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
{
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
@property (nonatomic, retain) KOKSAVMixer          *avMixer;
@property (nonatomic, retain) AVMutableComposition *outputAVComposition;
@property (nonatomic, retain) NSString             *outputVocalFileName;
@property (nonatomic, retain) NSString             *songType;
@property (nonatomic, retain) AVPlayer             *previewPlayer;
@property (nonatomic, strong) MFMailComposeViewController *emailComposer;
@property (assign, nonatomic) id <MJSecondPopupDelegate>delegate;
@property (nonatomic, strong) NSString             *uploadedMovieURL;
@property (nonatomic, strong) NSString             *Tracktime;
@property (weak) id SavingFileVCDelegate;

- (void) storeUploadedMovieURL: (NSString *) movieURL;
- (void) setOutputAVComposition:outputAVComposition;
- (void) setSongType:(NSString *)sType;
- (void) setOutputMode:(BOOL)yesNo;
- (void) setTracktime:(NSString *)Ttime;
- (void) disablePreview;

@end

@protocol MJSecondPopupDelegate<NSObject>
@optional
- (void)dismissSavingFileView:(SavingFileViewController*)secondDetailViewController;
@end
