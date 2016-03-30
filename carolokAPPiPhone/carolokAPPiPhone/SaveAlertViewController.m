//
//  SaveAlertViewController.m
//  carolAPPs
//
//  Created by iscom on 13/3/12.
//
//

#import "SaveAlertViewController.h"
#import "GlobalData.h"

@interface SaveAlertViewController () <UITextFieldDelegate>
{
    BOOL removeFile;
    AVAssetExportSession *exportSession;
}
@property (weak, nonatomic) IBOutlet UIButton *btnExitOrCancelSaving;
@property (weak, nonatomic) IBOutlet UIButton *btnSaveVocal;
@property (weak, nonatomic) IBOutlet UIProgressView *progressSaveVocalFile;
@property (weak, nonatomic) IBOutlet UITextField *textFileName;
@property (weak, nonatomic) IBOutlet UITextField *textProducer;


@end

@implementation SaveAlertViewController
@synthesize btnExitOrCancelSaving,btnSaveVocal;
@synthesize progressSaveVocalFile;
@synthesize textFileName,textProducer;
//--------------------
@synthesize avMixer;
@synthesize outputVocalFileName;
@synthesize previewPlayer;
@synthesize emailComposer;
@synthesize uploadedMovieURL;
@synthesize songType;
@synthesize GivingUpSavingDelegate;
@synthesize SongName;


#pragma mark - 
#pragma mark IBAction

- (IBAction)GiveupSaving:(id)sender {
    [exportSession cancelExport];
    if (self.delegate && [self.delegate respondsToSelector:@selector(GiveupSavingButtonClicked:)]) {
        [self.textFileName resignFirstResponder];
        [self.textProducer resignFirstResponder];
        [self.delegate GiveupSavingButtonClicked:self];
    }
    
}
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(retrySingingButtonClicked:)]) {
        [self.textFileName resignFirstResponder];
        [self.textProducer resignFirstResponder];
        [self.delegate retrySingingButtonClicked:self];
    }
}
- (IBAction)doSaveVocal:(id)sender {
    GlobalData *globalItem = [GlobalData getInstance];
    if ([globalItem.UserID isEqualToString:@"-2"]) {
        textProducer.text = @"未知歌手";
    }
    
    [textFileName resignFirstResponder];
    [textProducer resignFirstResponder];
    
    
    // in case the AVComposition is lost !?re
    if (outputAVComposition == nil) {
        NSLog(@"Error: outputAVComposition is NULL?????");
        return;
    }
    
    // 2c2. Try to export
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
    if ([textFileName.text compare:@""] == NSOrderedSame) {
        textFileName.text = [NSString stringWithFormat:@"%@.mp4",SongName];
    }
    else {
        if ([[[documentsDirectoryPath stringByAppendingPathComponent:textFileName.text] pathExtension] compare:@"mp4"] != NSOrderedSame)
            textFileName.text = [NSString stringWithFormat:@"%@.mp4",textFileName.text];
    }
    
    //預設檔名
    NSInteger randomID = arc4random() % 999;
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
    [formatter1 setDateFormat:@"yyyyMMddHHmmss"];
    NSString *valuestr = [formatter1 stringFromDate:[NSDate date]];
    NSString *fileName = [valuestr stringByAppendingFormat:@"%03d.mp4", randomID];
    outputVocalFileFullPath = [documentsDirectoryPath stringByAppendingPathComponent:fileName];

    // check if file existing !
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:outputVocalFileFullPath]) {
        NSError *error;
        NSInteger count = 0;
        NSString *rename = textFileName.text;
        NSString *newPath = [[outputVocalFileFullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:rename];
        while ([fileMgr fileExistsAtPath:outputVocalFileFullPath])
        {
            count++;
            rename = [NSString stringWithFormat:@"%@(%d).caf", textFileName.text, count];
            newPath = [[outputVocalFileFullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:rename];
        }
        if ([fileMgr fileExistsAtPath:outputVocalFileFullPath]) {
            [fileMgr moveItemAtPath:outputVocalFileFullPath
                            toPath:newPath
                             error:&error];
            NSLog(@"%@>>>%@", outputVocalFileFullPath, newPath);
        };
        //[self showAlertMessage:@"檔案已經存在，你要覆寫舊檔嗎？" withTitle:@"<<< 請確認 >>>" buttonYesText:@"覆蓋" buttonNoText:@"重新輸入"];
    }
    else {
        [self doSaveUserVocalMovie];
        [textFileName setEnabled:NO];
        [textProducer setEnabled:NO];
    }
}

- (IBAction)ProductNameBegin:(id)sender {
    if ([textFileName.text isEqualToString:@""])
        textFileName.text = SongName;
    
}
- (IBAction)ProducerBegin:(id)sender {
    GlobalData *globalItem = [GlobalData getInstance];
    if ([textProducer.text isEqualToString:@""]) 
        textProducer.text = globalItem.UserNickname;
}

#pragma mark -
#pragma mark - Textfield Delegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark Subcode
-(void) doSaveUserVocalMovie {
    // disable the buttons
    [btnSaveVocal setEnabled:FALSE];
    [btnSaveVocal setAlpha:0.3];
    [btnExitOrCancelSaving setEnabled:FALSE];
    [btnExitOrCancelSaving setAlpha:0.3];
    //
    exportSession = [[AVAssetExportSession alloc] initWithAsset:outputAVComposition
                                                                           presetName:AVAssetExportPresetMediumQuality];
    if (avMixer) {
        exportSession.videoComposition = avMixer.videoComposition4Export;
    }
    //
    NSLog (@"Can export: %@", exportSession.supportedFileTypes);  
    NSURL *exportURL = [NSURL fileURLWithPath:outputVocalFileFullPath];
    exportSession.outputURL = exportURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    
    //
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSLog (@"Blocks running(exporting MOV). Status Code is %d", exportSession.status);
        switch (exportSession.status) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Fail to export MOV file.");
                [self showAlertMessage:@"儲存失敗" withTitle: @"訊息" buttonText:@"離開"];
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"Export MOV file successfully.");
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                                    message:@"儲存成功"
                                                                   delegate:self
                                                          cancelButtonTitle:@"ＯＫ"
                                                          otherButtonTitles:nil];
                    [alert show];
                    //[self showAlertMessage:@"成功儲存 MOV ！！" withTitle:@"<<< 成功 >>>" buttonText:@"ＯＫ"];
                    // ------ save to DB ------
                    [self appendVocalRecordToDB:outputVocalFileFullPath];
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
    exportTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                   target:self
                                                 selector:@selector (updateExportProgress:)
                                                 userInfo:exportSession
                                                  repeats:YES];
    //
    btnSaveVocal.enabled = false;
    [btnExitOrCancelSaving setTitle:@"離開" forState:UIControlStateNormal];
}

-(void) doPostExportUICleanup: (NSObject*) userInfo {
	progressSaveVocalFile.progress = 1.0f;
    // disable the buttons
    [btnSaveVocal setEnabled:TRUE];
    [btnSaveVocal setAlpha:1.0];
    [btnExitOrCancelSaving setEnabled:TRUE];
    [btnExitOrCancelSaving setAlpha:1.0];
    //
	[exportTimer invalidate];
}


-(void) updateExportProgress: (NSTimer*) timer {
	AVAssetExportSession *exportSession = (AVAssetExportSession*) [timer userInfo];
	progressSaveVocalFile.progress = exportSession.progress;
    
}

// ------ from Jay's isRecordeViewController.m --------------
-(void) appendVocalRecordToDB:(NSString *) destinationFilePath {
    //get global item
    
    GlobalData *globalItem = [GlobalData getInstance];
    NSDate *now = [NSDate date];
    //generate db object
    Production *item = [[Production alloc] init];
    
    item.ProductName = textFileName.text;
    item.ProductPath = destinationFilePath;
    if ([textProducer.text compare:@""] != NSOrderedSame)
        item.Producer = textProducer.text;
    else
        item.Producer = globalItem.UserNickname;
    item.ProductCreateTime = now;
    item.ProductRight = @"私人";
    item.ProductType = @"影片";
    item.ProductTracktime = Tracktime;
    item.userID = [globalItem.currentUser compare:@""] == NSOrderedSame ? @"guest": globalItem.UserID;
    //push into db
    //get ProductID
    // productionId = [database addSongToMyProduction:item];
    if (removeFile) {
        [database deleteSongFromMyProductWithProductPath:item];
        removeFile=NO;
    }
    tmpProduction = [database addSongToMyProductionWithProduction:item];
    if (tmpProduction.ProductID != nil) {
        NSLog(@"SQLite==> UserId: %@, Pid: %@", globalItem.currentUser, tmpProduction.ProductID );
        NSLog(@">>> filename: %@, full_filepath:%@", [destinationFilePath lastPathComponent], destinationFilePath);
        
        NSLog(@"Successfully insert the data into the SQLite DB!");
    }
    else {
        NSLog(@"Fail to insert the data into the SQLite DB!");
    }
}
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([alertView.message isEqualToString:@"加入CarolOK網站會員完全免費，是否註冊會員"]) {
        return;
    }
    
    NSLog(@"Press button %i", buttonIndex);
    if (buttonIndex == 0) // over-write
    {
        
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"ＯＫ"]) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(GiveupSavingButtonClicked:)]) {
                [self.delegate GiveupSavingButtonClicked:self];
            }
        }
        else {
            [[NSFileManager defaultManager] removeItemAtPath:outputVocalFileFullPath error:nil];
            [self doSaveUserVocalMovie];
            removeFile=YES;
        }
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
    textFileName.text = outputVocalFileName;
    
    // 2. setup the AVPlayer
    if (!outputMode) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(playerItemDidReachedEnd:)
         name:AVPlayerItemDidPlayToEndTimeNotification
         object:[previewPlayer currentItem]];
    }
    //
    playing = false;
    
    // -----
    // Do any additional setup after loading the view.
    database = [[SQLiteDBTool alloc] init];
    removeFile=NO;
    
    avPlayerVC = [[KOKSMP4PlayerViewController alloc]initWithNibName:@"KOKSMP4PlayerViewController" bundle:[NSBundle mainBundle]];
    
    // 一開始就顯示歌名與歌手
    GlobalData *globalItem = [GlobalData getInstance];
    textFileName.text = SongName;
    textProducer.text = globalItem.UserNickname;
    textFileName.delegate = self;
    textProducer.delegate = self;
    
    NSAttributedString *FileNamePlaceholder = [[NSAttributedString alloc] initWithString:@"輸入影音名稱" attributes:@{ NSForegroundColorAttributeName :[UIColor darkGrayColor]}];
    NSAttributedString *ProducerPlaceholder = [[NSAttributedString alloc] initWithString:@"輸入影音製作人姓名" attributes:@{ NSForegroundColorAttributeName :[UIColor darkGrayColor]}];
    textFileName.attributedPlaceholder = FileNamePlaceholder;
    textProducer.attributedPlaceholder = ProducerPlaceholder;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidUnload {
    [self setTextProducer:nil];
    [super viewDidUnload];
}
@end