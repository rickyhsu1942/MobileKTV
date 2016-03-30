//
//  SavingFileViewController.m
//  carolAPPs
//
//  Created by iscom on 13/3/28.
//
//

#import "SavingFileViewController.h"
#import "GlobalData.h"

// AMGProgressView
#import "AMGProgressView.h"

@interface SavingFileViewController ()
{
    BOOL removeFile;
    BOOL isViewdidAppear;
    AVAssetExportSession *exportSession;
}
@property (weak, nonatomic) IBOutlet UIButton *btnExitOrCancelSaving;
@property (weak, nonatomic) IBOutlet UILabel *LbexportSessionProgress;
@property (nonatomic, strong) AMGProgressView *progressSaveVocalFile;
@property (weak, nonatomic) IBOutlet UIButton *BtnProgressShadow;

@end

@implementation SavingFileViewController
@synthesize LbexportSessionProgress;
@synthesize btnExitOrCancelSaving,BtnProgressShadow;
@synthesize progressSaveVocalFile;
//--------------------
@synthesize avMixer;
@synthesize outputVocalFileName;
@synthesize previewPlayer;
@synthesize emailComposer;
@synthesize uploadedMovieURL;
@synthesize songType;
@synthesize SavingFileVCDelegate;

- (IBAction)doExitOrCancelSaving:(id)sender {
    // 2c1. if cancel saving, just delete the template files.
    //
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
    NSString *exportPath = [documentsDirectoryPath stringByAppendingPathComponent:@"CarolKOK_tempCapture.mp4" ];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:exportPath error:&error];
    if (error) {
        NSLog(@"[Camera] RemoveItemAtPath %@ with error:%@", exportPath, error);
    }
    else {
        NSLog(@"[Camera] RemoveItemAtPath %@ successfully!", exportPath);
    }
    outputAVComposition = nil;
    outputVocalFileName = nil;
    //
    [exportSession cancelExport];
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissSavingFileView:)]) {
        [self.delegate dismissSavingFileView:self];
    }
}
- (void)doAVMixer {
    
    // in case the AVComposition is lost !?
    if (outputAVComposition == nil) {
        NSLog(@"Error: outputAVComposition is NULL?????");
        return;
    }
    
    // 儲存目錄
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [path objectAtIndex:0];
    NSString *fileName = outputVocalFileName;
    
    // 運用括弧流水號
    NSFileManager *manger = [NSFileManager defaultManager];
    outputVocalFileFullPath = [[NSString alloc] initWithFormat:@"%@/%@",documentDirectory,fileName];
    NSString *OldPath = outputVocalFileFullPath;
    outputVocalFileFullPath = [[OldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    //if file exist at new path, appending number
    if ([manger fileExistsAtPath:outputVocalFileFullPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputVocalFileFullPath error:nil];
    }
    
    // 進行合成!!
    [self doSaveUserVocalMovie];
}

#pragma mark -
#pragma mark Subcode
-(void) doSaveUserVocalMovie {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    exportSession = [[AVAssetExportSession alloc] initWithAsset:outputAVComposition
                                                     presetName:AVAssetExportPresetLowQuality];
    
    if (avMixer) {
        exportSession.videoComposition = avMixer.videoComposition4Export;
    }
    //
    NSLog (@"Can export: %@", exportSession.supportedFileTypes);
    NSURL *exportURL = [NSURL fileURLWithPath:outputVocalFileFullPath];
    exportSession.outputURL = exportURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    
    // 開始將outputAVComposition存入檔案中
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSLog (@"Blocks running(exporting MOV). Status Code is %ld", exportSession.status);
        switch (exportSession.status) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Fail to export MOV file.(%@)",exportSession.error);
                [self showAlertMessage:@"合成失敗" withTitle: @"訊息" buttonText:@"離開"];
                // 刪除失敗檔案
                if ([fileMgr fileExistsAtPath:outputVocalFileFullPath]) {
                    [fileMgr removeItemAtPath:outputVocalFileFullPath error:nil];
                }
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"Export MOV file successfully.");
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[self showAlertMessage:@"成功儲存 MOV ！！" withTitle:@"<<< 成功 >>>" buttonText:@"ＯＫ"];
                    [self showAlertMessage:@"合成成功" withTitle:@"訊息" buttonYesText:@"ＯＫ" buttonNoText:nil];
                    // ------ save to DB ------
                    //[self appendVocalRecordToDB:outputVocalFileFullPath];
                }
                               );
                break;
        }
        //
        [self performSelectorOnMainThread:@selector (doPostExportUICleanup:)
                               withObject:nil
                            waitUntilDone:NO];
    }];
    progressSaveVocalFile.progress = 0.0;
    exportTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                   target:self
                                                 selector:@selector (updateExportProgress:)
                                                 userInfo:exportSession
                                                  repeats:YES];
}

-(void) doPostExportUICleanup: (NSObject*) userInfo {
	progressSaveVocalFile.progress = 1.0f;
    // disable the buttons
    [btnExitOrCancelSaving setEnabled:TRUE];
    [btnExitOrCancelSaving setAlpha:1.0];
    //
	[exportTimer invalidate];
}


-(void) updateExportProgress: (NSTimer*) timer {
    
	AVAssetExportSession *exportSessions = (AVAssetExportSession*) [timer userInfo];
	//progressSaveVocalFile.progress = (exportSessions.progress > 0) ? exportSessions.progress : progressSaveVocalFile.progress;
    progressSaveVocalFile.progress = exportSessions.progress;
    int MixerProgress = progressSaveVocalFile.progress * 100;
    LbexportSessionProgress.text = [NSString stringWithFormat:@"合成中...(%d%%)",MixerProgress];
    
}

//// ------ from Jay's isRecordeViewController.m --------------
//-(void) appendVocalRecordToDB:(NSString *) destinationFilePath {
//    //get global item
//
//    GlobalData *globalItem = [GlobalData getInstance];
//    NSDate *now = [NSDate date];
//    //generate db object
//    Production *item = [[Production alloc] init];
//
//    item.ProductName = [destinationFilePath lastPathComponent];
//    item.ProductPath = destinationFilePath;
//    if ([textProducer.text compare:@""] != NSOrderedSame)
//        item.Producer = textProducer.text;
//    else
//        item.Producer = globalItem.currentUser;
//    item.ProductCreateTime = now;
//    item.ProductRight = @"私人";
//    item.ProductType = @"影片";
//    item.ProductTracktime = Tracktime;
//    item.userID = [globalItem.currentUser compare:@""] == NSOrderedSame ? @"guest": globalItem.UserID;
//    //push into db
//    //get ProductID
//    // productionId = [database addSongToMyProduction:item];
//    if (removeFile) {
//        [database deleteSongFromMyProductWithProductPath:item];
//        removeFile=NO;
//    }
//    tmpProduction = [database addSongToMyProductionWithProduction:item];
//    if (tmpProduction.ProductID != nil) {
//        NSLog(@"SQLite==> UserId: %@, Pid: %@", globalItem.currentUser, tmpProduction.ProductID );
//        NSLog(@">>> filename: %@, full_filepath:%@", [destinationFilePath lastPathComponent], destinationFilePath);
//
//        NSLog(@"Successfully insert the data into the SQLite DB!");
//    }
//    else {
//        NSLog(@"Fail to insert the data into the SQLite DB!");
//    }
//}
//--------------------------------------------------------
- (void) setOutputMode:(BOOL)yesNo {
    outputMode = yesNo;
}

- (void) setOutputAVComposition:currentAVComposition {
    outputAVComposition = currentAVComposition;
}

- (void) setTracktime:(NSString *)Ttime {
    Tracktime = Ttime;
}

- (void) disablePreview {
    CGRect compactSize = CGRectMake(0, 0, 540, 220);
    [self.view setFrame:compactSize];
}

#pragma mark -
#pragma mark AlertMessage
-(void) showAlertMessage:(NSString *) message withTitle:(NSString *)title buttonText:(NSString *) btnCancelText {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: title
                          message:message
                          delegate:nil
                          cancelButtonTitle: btnCancelText
                          otherButtonTitles: nil];
    [alert show];
}

-(void) showAlertMessage:(NSString *) message withTitle:(NSString *)title buttonYesText:(NSString *) btnYesText buttonNoText:(NSString *) btnNoText{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: title
                          message:message
                          delegate:self
                          cancelButtonTitle: btnYesText
                          otherButtonTitles: btnNoText, nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"Press button %i", buttonIndex);
    if (buttonIndex == 0) // over-write
    {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"ＯＫ"]) {
            // 成功檔案另一個存檔名稱
            NSString *newPath = [[outputVocalFileFullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"CarolAVMixerCompletedResult.mp4"];
            NSFileManager *manger = [NSFileManager defaultManager];
            if ([manger fileExistsAtPath:newPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:newPath error:nil];
            }
            [manger moveItemAtPath:outputVocalFileFullPath
                            toPath:newPath
                             error:nil];
            NSLog(@"%@ >>> %@", outputVocalFileFullPath, newPath);
            // 將新名稱路徑傳回AVMixer
            [SavingFileVCDelegate DoneAVMixandGetProductPath:newPath];
            // 消失
            if (self.delegate && [self.delegate respondsToSelector:@selector(dismissSavingFileView:)]) {
                [self.delegate dismissSavingFileView:self];
            }
            return;
        }
        [[NSFileManager defaultManager] removeItemAtPath:outputVocalFileFullPath error:nil];
        [self doSaveUserVocalMovie];
        removeFile=YES;
    }
    else {
        // nothing to do !?
    }
}


#pragma mark -
#pragma mark viewDidload
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    // 1. set the dimension of window
    
    // 2. setup the AVPlayer
    if (!outputMode) {
    }
    
    // 新增custom的Progress
    progressSaveVocalFile= [[AMGProgressView alloc] initWithFrame:CGRectMake(10, 80, 260, 50)];
    progressSaveVocalFile.gradientColors = @[[UIColor colorWithRed:80.0/255 green:132.0/255 blue:193.0/255 alpha:1.0], [UIColor colorWithRed:113.0/255 green:185.0/255 blue:233.0/255 alpha:1.0]];
    progressSaveVocalFile.maximumValue = 1.0f;
    progressSaveVocalFile.minimumValue = 0.0f;
    progressSaveVocalFile.progress = 0.0f;
    [self.view addSubview:progressSaveVocalFile];
    // 將陰影移動到最上面
    [self.view bringSubviewToFront:BtnProgressShadow];
    
    //
    playing = false;
    
    // -----
    // Do any additional setup after loading the view.
    //database = [[SQLiteDBTool alloc] init];
    removeFile=NO;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!isViewdidAppear) {
        [self doAVMixer];
    }
    isViewdidAppear = YES;
}


- (void)viewDidUnload {
    [self setLbexportSessionProgress:nil];
    [self setBtnProgressShadow:nil];
    [super viewDidUnload];
}
@end
