//
//  SaveStudioAlertViewController.h
//  carolAPPs
//
//  Created by iscom on 13/4/17.
//
//

#import <UIKit/UIKit.h>
#import "Production.h"

@protocol CheckMicCheckMicDelegate <NSObject>
- (void)AutoCheckMic;
- (void)SavingDidEnd:(BOOL)isGiveUp;
- (void)DoneSaving;
- (void)GiveupSaving;
- (void)DoneSavingAndGetSongPath:(NSString*)ProductPath;
@end

@protocol MJSecondPopupDelegate;
@interface SaveStudioAlertViewController : UIViewController


@property (assign, nonatomic) id <MJSecondPopupDelegate>delegate;
@property (nonatomic, retain) Production *aProduction;
@property (nonatomic, retain) NSString *SourceMachine;
@property (weak) id CheckMicDelegate;
@end

@protocol MJSecondPopupDelegate<NSObject>
@optional
- (void)dismissSavingView:(SaveStudioAlertViewController*)secondDetailViewController;
@end