//
//  YoutubeUploadViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/11.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

//-----View-----
#import "YoutubeUploadViewController.h"
//-----Tool-----
#import "GDataServiceGoogleYouTube.h"
#import "GDataEntryYouTubeUpload.h"
#import "SQLiteDBTool.h"
#import "ASIHttpMethod.h"
#import "KOKSAVMixer.h"
//-----Object-----
#import "GlobalData.h"
#import "Setting.h"
#import "Production.h"
//-----UI-----
#import "RESwitch.h"
//-----Define-----
// Developer Key
// To get your developer key go to: http://code.google.com/apis/youtube/dashboard/gwt/index.html#newProduct
#define DEVELOPER_KEY @"AI39si6RR2HMQRUyy2zZIRSAdne-oXSARpKs8VUjoEscJSeoZJpr4Phue_xtOHmlBp9DSdg1Kh1YmzbOqzZHtkxSyKdJigQQgQ"
#define CLIENT_ID @"589076831807-8mmjph2miv8c64rrj53c65gi86t5hodn.apps.googleusercontent.com"


@interface YoutubeUploadViewController (PrivateMethods)

- (GDataServiceTicket *)uploadTicket;
- (void)setUploadTicket:(GDataServiceTicket *)ticket;
- (GDataServiceGoogleYouTube *)youTubeService;
@end

@implementation YoutubeUploadViewController
{
    
    GDataServiceTicket *ticket;
    
    // carolAPP
    GlobalData *globalItem;
    ASIHttpMethod *httpmethod;
    SQLiteDBTool *database;
    Setting *aSetting;
    
    // UI
    RESwitch *SwitchPrivate;
    
    // Youtube網址
    NSString *YoutubeVideoUrl;
    NSString *YoutubeDataPath;
    
    // 影音合成
    KOKSAVMixer     *avMixer;
    NSTimer         *exportTimer;
    AVAssetExportSession *exportSession;
}

@synthesize FilePath,YoutubeTitle,Prodcer,ProductID;
@synthesize btnUpload,btnGivingup,btnShadow,btnShadow2;
@synthesize FbsharingDelegate;
@synthesize txtYoutubeDescription,txtYoutubeKeyword,txtYoutubeTitle;
@synthesize LbProgress;

#pragma mark -
#pragma mark IBAction
- (void)PrivateChanged:(RESwitch *)switchView {
    if (SwitchPrivate.isOn)
        mIsPrivate = NO;
    else
        mIsPrivate = YES;
}

- (IBAction)Exit:(id)sender {
    [exportSession cancelExport];
    [ticket cancelTicket];
    [txtYoutubeTitle resignFirstResponder];
    [txtYoutubeKeyword resignFirstResponder];
    [txtYoutubeDescription resignFirstResponder];
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissYoutubeView:)]) {
        [self.delegate dismissYoutubeView:self];
    }
}

- (IBAction)uploadPressed:(id)sender {
    
    // 檢查影片名稱是否有輸入
    if ([[txtYoutubeTitle.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                        message:@"請務必影片名稱"
                                                       delegate:nil
                                              cancelButtonTitle:@"了解"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // 收下鍵盤
    [txtYoutubeTitle resignFirstResponder];
    [txtYoutubeKeyword resignFirstResponder];
    [txtYoutubeDescription resignFirstResponder];
    
    // 避免上傳兩次
    [btnUpload setEnabled:NO];
    // 避免更改詳細資料
    [txtYoutubeDescription setEnabled:NO];
    [txtYoutubeKeyword setEnabled:NO];
    [txtYoutubeTitle setEnabled:NO];
    [SwitchPrivate setEnabled:NO];
    
    [LbProgress setHidden:NO];
    
    // 轉檔
    NSString *FileExtension = [FilePath pathExtension];
    if ([FileExtension compare:@"mp3"]==NSOrderedSame || [FileExtension compare:@"caf"]==NSOrderedSame ) {
        // 開始轉圈圈
        //[ActivityProcessing startAnimating];
        //self.progressAVMixer.progress = 0.0;
        self.mProgressView.progress = 0.0;
        // 輸出計數器開始
        exportTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                       target:self
                                                     selector:@selector (updateExportProgress)
                                                     userInfo:nil
                                                      repeats:YES];
        [self performSelectorInBackground:@selector(prepareOutputComposition) withObject:nil];
        
    } else {
        //self.progressAVMixer.progress = 1.0;
        self.mProgressView.progress = 1.0;
        LbProgress.text = @"合成中...(100%)";
        [self StartUploadYoutube:FilePath];
    }
}

- (void)StartUploadYoutube : (NSString *)uploadPath {
    
    NSString *devKey = DEVELOPER_KEY;
    
    GDataServiceGoogleYouTube *service = [self youTubeService];
    [service setYouTubeDeveloperKey:devKey];
    
    // 去除小老鼠的部分
    NSString *username = @"default";
    NSString *clientID = CLIENT_ID;
    
    NSURL *url = [GDataServiceGoogleYouTube youTubeUploadURLForUserID:username
                                                             clientID:clientID];
    
    // load the file data
    NSString *path = uploadPath;
    NSData *data = [NSData dataWithContentsOfMappedFile:path];
    NSString *filename = [path lastPathComponent];
    
    // gather all the metadata needed for the mediaGroup
    //    NSString *titleStr = [mTitleField text];
    NSString *titleStr = txtYoutubeTitle.text;
    GDataMediaTitle *title = [GDataMediaTitle textConstructWithString:titleStr];
    
    //    NSString *categoryStr = [mCategoryField text];
    NSString *categoryStr = @"Music";
    GDataMediaCategory *category = [GDataMediaCategory mediaCategoryWithString:categoryStr];
    [category setScheme:kGDataSchemeYouTubeCategory];
    
    //    NSString *descStr = [mDescriptionField text];
    NSString *descStr = txtYoutubeDescription.text;
    GDataMediaDescription *desc = [GDataMediaDescription textConstructWithString:descStr];
    
    //    NSString *keywordsStr = [mKeywordsField text];
    NSString *keywordsStr =txtYoutubeKeyword.text;
    GDataMediaKeywords *keywords = [GDataMediaKeywords keywordsWithString:keywordsStr];
    
    BOOL isPrivate = mIsPrivate;
    
    GDataYouTubeMediaGroup *mediaGroup = [GDataYouTubeMediaGroup mediaGroup];
    [mediaGroup setMediaTitle:title];
    [mediaGroup setMediaDescription:desc];
    [mediaGroup addMediaCategory:category];
    [mediaGroup setMediaKeywords:keywords];
    [mediaGroup setIsPrivate:isPrivate];
    
    NSString *mimeType = [GDataUtilities MIMETypeForFileAtPath:path
                                               defaultMIMEType:@"video/mp4"];
    
    // create the upload entry with the mediaGroup and the file data
    GDataEntryYouTubeUpload *entry;
    entry = [GDataEntryYouTubeUpload uploadEntryWithMediaGroup:mediaGroup
                                                          data:data
                                                      MIMEType:mimeType
                                                          slug:filename];
    
    SEL progressSel = @selector(ticket:hasDeliveredByteCount:ofTotalByteCount:);
    [service setServiceUploadProgressSelector:progressSel];
    
    ticket = [service fetchEntryByInsertingEntry:entry
                                      forFeedURL:url
                                        delegate:self
                               didFinishSelector:@selector(uploadTicket:finishedWithEntry:error:)];
    [self setUploadTicket:ticket];
}

#pragma mark -
#pragma mark - Google API

// get a YouTube service object with the current username/password
//
// A "service" object handles networking tasks.  Service objects
// contain user authentication information as well as networking
// state information (such as cookies and the "last modified" date for
// fetched data.)

- (GDataServiceGoogleYouTube *)youTubeService {
    
    static GDataServiceGoogleYouTube* service = nil;
    
    if (!service) {
        service = [[GDataServiceGoogleYouTube alloc] init];
        
        [service setShouldCacheDatedData:YES];
        [service setServiceShouldFollowNextLinks:YES];
        [service setIsServiceRetryEnabled:YES];
    }
    
    // update the username/password each time the service is requested
    //NSRange search = [aSetting.YoutubeAccount rangeOfString:@"@"];
    //NSString *username = [aSetting.YoutubeAccount substringToIndex:search.location];
    NSString *username = aSetting.YoutubeAccount;
    NSString *password = aSetting.YoutubePasswd;
    
    if ([username length] > 0 && [password length] > 0) {
        [service setUserCredentialsWithUsername:username
                                       password:password];
    } else {
        // fetch unauthenticated
        [service setUserCredentialsWithUsername:nil
                                       password:nil];
    }
    
    NSString *devKey = DEVELOPER_KEY;
    [service setYouTubeDeveloperKey:devKey];
    
    return service;
}

// progress callback
- (void)ticket:(GDataServiceTicket *)ticket
hasDeliveredByteCount:(unsigned long long)numberOfBytesRead
ofTotalByteCount:(unsigned long long)dataLength {
    
    [self.mProgressView setProgress:(double)numberOfBytesRead / (double)dataLength];
    LbProgress.text = [NSString stringWithFormat:@"上傳中...(%.0f%%)",(double)numberOfBytesRead / (double)dataLength * 100];
}

// upload callback
- (void)uploadTicket:(GDataServiceTicket *)ticket
   finishedWithEntry:(GDataEntryYouTubeVideo *)videoEntry
               error:(NSError *)error {
    if (error == nil) {
        
        // 抓取Youtube網址
        NSRange searchYoutubeUrl = [[NSString stringWithFormat:@"%@",[videoEntry HTMLLink]] rangeOfString:@"http://www.youtube.com/watch?v="];
        YoutubeVideoUrl = [[NSString stringWithFormat:@"%@",[videoEntry HTMLLink]] substringWithRange:NSMakeRange(searchYoutubeUrl.location, 42)];
        NSLog(@"%@",YoutubeVideoUrl);
        // 切溝youtube網址的後面
        NSString *YoutubeVideoKey = [YoutubeVideoUrl substringFromIndex:[YoutubeVideoUrl length] - 11];
        
        // 傳送資料給carol伺服器
        NSString *carolResult = [httpmethod PostYoutubeToSeverWithKey:YoutubeVideoKey YoutubeTitle:txtYoutubeTitle.text Account:globalItem.currentUser Passwd:globalItem.Password isPublic:[NSString stringWithFormat:@"%d",!mIsPrivate] Singer:Prodcer];
        
        UIAlertView *alert;
        if (carolResult.length >= 7) {
            if ([[carolResult substringToIndex:7] isEqualToString:@"success"]) {
                // tell the user that the add worked
                alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                   message:[NSString stringWithFormat:@"「%@」上傳成功",
                                                            [[videoEntry title] stringValue]]
                                                  delegate:self
                                         cancelButtonTitle:@"Ok"
                                         otherButtonTitles:nil];
            } else if ([[carolResult substringToIndex:4] isEqualToString:@"fail"]) {
                // tell the user that the add worked
                alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                   message:[NSString stringWithFormat:@"Carol伺服器上傳錯誤(%@)",[carolResult substringFromIndex:5]]
                                                  delegate:self
                                         cancelButtonTitle:@"Ok"
                                         otherButtonTitles:nil];
            }
        } else {
            alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                               message:@"Carol伺服器上傳錯誤"
                                              delegate:nil
                                     cancelButtonTitle:@"了解"
                                     otherButtonTitles:nil];
        }
        [alert show];
    } else {
        UIAlertView *alert;
        if (error.code == 403) {
            alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error %d",error.code]
                                               message:[NSString stringWithFormat:@"請確認此帳號是否有開通Youtube"]
                                              delegate:nil
                                     cancelButtonTitle:@"Ok"
                                     otherButtonTitles:nil];
        }
        else {
            alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error %d",error.code]
                                               message:[NSString stringWithFormat:@"Error: %@",[error description]]
                                              delegate:nil
                                     cancelButtonTitle:@"Ok"
                                     otherButtonTitles:nil];
        }
        [alert show];
    }
    [self.mProgressView setProgress: 0.0];
    [self.progressAVMixer setProgress: 0.0];
    [btnUpload setEnabled:YES];
    [btnGivingup setEnabled:YES];
    [txtYoutubeDescription setEnabled:YES];
    [txtYoutubeKeyword setEnabled:YES];
    [txtYoutubeTitle setEnabled:YES];
    [SwitchPrivate setEnabled:YES];
    
    [self setUploadTicket:nil];
}

#pragma mark -
#pragma mark Setters

- (GDataServiceTicket *)uploadTicket {
    return mUploadTicket;
}

- (void)setUploadTicket:(GDataServiceTicket *)tickets {
    mUploadTicket = tickets;
}

#pragma mark -
#pragma mark AlertDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (0 == buttonIndex) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] compare:@"Ok"] == NSOrderedSame) {
            [FbsharingDelegate startFBSharing:YoutubeVideoUrl];
            [txtYoutubeTitle resignFirstResponder];
            [txtYoutubeKeyword resignFirstResponder];
            [txtYoutubeDescription resignFirstResponder];
            if (self.delegate && [self.delegate respondsToSelector:@selector(dismissYoutubeView:)]) {
                [self.delegate dismissYoutubeView:self];
            }
        }
    }
}

-(void) showAlertMessage:(NSString *) message withTitle:(NSString *)title buttonYesText:(NSString *) btnYesText buttonNoText:(NSString *) btnNoText{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: title
                          message:message
                          delegate:nil
                          cancelButtonTitle: btnYesText
                          otherButtonTitles: btnNoText, nil];
    [alert show];
}

#pragma mark -
#pragma mark prepareOutputComposition
- (void) prepareOutputComposition {
    CALayer         *currentTitleLayer;
    Production *aProduction = [[Production alloc] init];
    aProduction = [database getMyProductionDataWithProductID:ProductID];
    // 設定影片size
    CGSize outputSize;
    NSArray *ResolutiontArray = [aSetting.Resolution componentsSeparatedByString:@"*"];
    if ([ResolutiontArray count] > 1) {
        outputSize.width = [[ResolutiontArray objectAtIndex:0] intValue];
        outputSize.height = [[ResolutiontArray objectAtIndex:1] intValue];
    }
    else {
        outputSize.width = 400;
        outputSize.height = 300;
    }
    
    // 設定影片標題
    [avMixer setTitle:@"" withSize:80 withShowDuration:5];
    currentTitleLayer = [avMixer getTitleLayerForVideoSize:outputSize forOutput:false];
    NSArray *selectedAudioFiles = [NSArray arrayWithObject:[NSURL fileURLWithPath:FilePath]];
    NSArray *selectedImageFiles = [NSArray arrayWithObject:[UIImage imageNamed:@"影音播放頁面-default畫面.jpg"]];
    // 載入影音合成的相關物件到avMixer
    if (avMixer.outputComposition == nil) {
        [avMixer prepareAVCompositionforPlayback:NO forVideoSize:outputSize withAudio:selectedAudioFiles withPhotos:selectedImageFiles showTime:[self CalculateShowtime:aProduction.ProductTracktime] withVideos:nil];
    }
    // 如果結果是空的，將跳出
    if (avMixer.outputComposition == nil) {
        [exportTimer invalidate];
        // 停止轉動
        //[ActivityProcessing stopAnimating];
        return;
    }
    
    //    // 停止轉動
    //    [ActivityProcessing stopAnimating];
    
    // 儲存目錄
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [path objectAtIndex:0];
    
    // 檔案命名
    NSString *fileName = [NSString stringWithFormat:@"YoutubeMixerUpload.mov"];
    
    // 運用括弧流水號
    NSFileManager *manger = [NSFileManager defaultManager];
    YoutubeDataPath = [[NSString alloc] initWithFormat:@"%@/%@",documentDirectory,fileName];
    NSString *OldPath = YoutubeDataPath;
    YoutubeDataPath = [[OldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    //if file exist at new path, appending number
    if ([manger fileExistsAtPath:YoutubeDataPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:YoutubeDataPath error:nil];
    }
    
    // 開始寫入YoutubeDataPath路徑中
    exportSession = [[AVAssetExportSession alloc] initWithAsset:avMixer.outputComposition
                                                     presetName:AVAssetExportPresetMediumQuality];
    if (avMixer) {
        exportSession.videoComposition = avMixer.videoComposition4Export;
    }
    
    NSLog (@"Can export: %@", exportSession.supportedFileTypes);
    NSURL *exportURL = [NSURL fileURLWithPath:YoutubeDataPath];
    exportSession.outputURL = exportURL;
    exportSession.outputFileType = @"com.apple.quicktime-movie";
    //
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSLog (@"Blocks running(exporting MOV). Status Code is %d", exportSession.status);
        switch (exportSession.status) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Fail to export MOV file.");
                [self showAlertMessage:@"轉檔失敗" withTitle:@"Error" buttonYesText:nil buttonNoText:@"了解"];
                // 停止轉動
                //[ActivityProcessing stopAnimating];
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"Export MOV file successfully.");
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 成功轉換後，開始Youtube上傳
                    [self StartUploadYoutube:YoutubeDataPath];
                    // 停止轉動
                    //[ActivityProcessing stopAnimating];
                }
                               );
                break;
        }
        //
        [self performSelectorOnMainThread:@selector (doPostExportUICleanup:)
                               withObject:nil
                            waitUntilDone:NO];
    }];
}

- (int) CalculateShowtime : (NSString*)showtime {
    if (showtime == nil)
        return 0;
    
    int min = [[showtime substringToIndex:2] integerValue];
    int sec = [[showtime substringFromIndex:[showtime length] - 2] integerValue];
    return min * 60 + sec;
}


- (void) updateExportProgress {
	//self.progressAVMixer.progress = exportSession.progress;
    self.mProgressView.progress = exportSession.progress;
    LbProgress.text = [NSString stringWithFormat:@"合成中...(%.0f%%)",exportSession.progress * 100];
}

-(void) doPostExportUICleanup: (NSObject*) userInfo {
	//self.progressAVMixer.progress = 1.0f;
    self.mProgressView.progress = 1.0f;
	[exportTimer invalidate];
}

#pragma mark - 
#pragma mark - View Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [super viewDidLoad];
    
    globalItem = [GlobalData getInstance];
    database = [[SQLiteDBTool alloc] init];
    httpmethod = [[ASIHttpMethod alloc] init];
    //抓取設定的值
    aSetting = [database getSettingWithUserID:globalItem.UserID];
    //影音合成
    CGSize videoSize;
    NSArray *ResolutiontArray = [aSetting.Resolution componentsSeparatedByString:@"*"];
    if ([ResolutiontArray count] > 1) {
        videoSize.width = [[ResolutiontArray objectAtIndex:0] intValue];
        videoSize.height = [[ResolutiontArray objectAtIndex:1] intValue];
    }
    else {
        videoSize.width = 400;
        videoSize.height = 300;
    }
    avMixer = [[KOKSAVMixer alloc] initWithVideoSize:videoSize];
    
    NSAttributedString *FileNamePlaceholder = [[NSAttributedString alloc] initWithString:@"輸入影片名稱" attributes:@{ NSForegroundColorAttributeName :[UIColor darkGrayColor]}];
    NSAttributedString *FileDescriptionPlaceholder = [[NSAttributedString alloc] initWithString:@"輸入影片描述" attributes:@{ NSForegroundColorAttributeName :[UIColor darkGrayColor]}];
    NSAttributedString *KeyWordPlaceholder = [[NSAttributedString alloc] initWithString:@"輸入影片關鍵字" attributes:@{ NSForegroundColorAttributeName :[UIColor darkGrayColor]}];
    
    txtYoutubeTitle.attributedPlaceholder = FileNamePlaceholder;
    txtYoutubeDescription.attributedPlaceholder = FileDescriptionPlaceholder;
    txtYoutubeKeyword.attributedPlaceholder = KeyWordPlaceholder;
    
    // 輸入筐預設值
    txtYoutubeTitle.text = YoutubeTitle;
    txtYoutubeDescription.text = [NSString stringWithFormat:@"此歌曲由%@製作",Prodcer];
    txtYoutubeKeyword.text = @"CarolOK";
    
    // SwitchPrivate
    SwitchPrivate = [[RESwitch alloc] initWithFrame:CGRectMake(212, 225, 60, 31)];
    [SwitchPrivate setBackgroundImage:[UIImage imageNamed:@"btn-onoff顯示"]];
    [SwitchPrivate setKnobImage:[UIImage imageNamed:@"btn-拉把"]];
    [SwitchPrivate setOverlayImage:nil];
    [SwitchPrivate setHighlightedKnobImage:nil];
    [SwitchPrivate setCornerRadius:0];
    [SwitchPrivate setKnobOffset:CGSizeMake(0, 0)];
    [SwitchPrivate setTextShadowOffset:CGSizeMake(0, 0)];
    [SwitchPrivate setFont:[UIFont boldSystemFontOfSize:14]];
    [SwitchPrivate setTextOffset:CGSizeMake(0, 2) forLabel:RESwitchLabelOn];
    [SwitchPrivate setTextOffset:CGSizeMake(3, 2) forLabel:RESwitchLabelOff];
    [SwitchPrivate setTextColor:[UIColor clearColor] forLabel:RESwitchLabelOn];
    [SwitchPrivate setTextColor:[UIColor clearColor] forLabel:RESwitchLabelOff];
    [self.view addSubview:SwitchPrivate];
    [SwitchPrivate addTarget:self action:@selector(PrivateChanged:) forControlEvents:UIControlEventValueChanged];
    
    // mProgressView
    self.mProgressView= [[AMGProgressView alloc] initWithFrame:CGRectMake(12, 266, 276, 10)];
    self.mProgressView.gradientColors = @[[UIColor colorWithRed:80.0/255 green:132.0/255 blue:193.0/255 alpha:1.0], [UIColor colorWithRed:113.0/255 green:185.0/255 blue:233.0/255 alpha:1.0]];
    self.mProgressView.maximumValue = 1.0f;
    self.mProgressView.minimumValue = 0.0f;
    [self.view addSubview:self.mProgressView];
    
    // progressAVMixer
    self.progressAVMixer= [[AMGProgressView alloc] initWithFrame:CGRectMake(12, 250, 276, 10)];
    self.progressAVMixer.gradientColors = @[[UIColor colorWithRed:80.0/255 green:132.0/255 blue:193.0/255 alpha:1.0], [UIColor colorWithRed:113.0/255 green:185.0/255 blue:233.0/255 alpha:1.0]];
    self.progressAVMixer.maximumValue = 1.0f;
    self.progressAVMixer.minimumValue = 0.0f;
    [self.view addSubview:self.progressAVMixer];
    [self.progressAVMixer setHidden:YES];
    
    // 將陰影移動到最上面
    [self.view bringSubviewToFront:btnShadow];
    [self.view bringSubviewToFront:btnShadow2];
    [btnShadow setHidden:YES];
    
    
    // 預設公開影片為ON
    [SwitchPrivate setOn:YES];
    mIsPrivate = NO;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
