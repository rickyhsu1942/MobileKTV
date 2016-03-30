//
//  ProductViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/25.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

//-----View-----
#import "ProductViewController.h"
#import "KOKSMP4PlayerViewController.h"
#import "ProductPlayerViewController.h"
#import "LoginViewController.h"
#import "ForgetPasswordViewController.h"
#import "AgreeTermsViewController.h"
#import "YoutubeUploadViewController.h"
//-----Tool-----
#import "SQLiteDBTool.h"
#import "AppDelegate.h"
//-----Object-----
#import "Production.h"
#import "GlobalData.h"
#import "Setting.h"
//-----UI-----
#import "UIViewController+MJPopupViewController.h"


#define tagBtnPlay        1
#define tagBtnSing        2
#define tagLbProductName  3
#define tagLbProducer     4
#define tagLbTrackTime    5
#define tagBtnUpload      6

@interface ProductViewController () <UITableViewDelegate,UITableViewDataSource,MJSecondPopupDelegate,FBLoginViewDelegate,UIActionSheetDelegate,MFMailComposeViewControllerDelegate>
{
    NSMutableArray *dataList;
    SQLiteDBTool *database;
    AppDelegate *appDelegate;
    Setting *aSetting;
    NSString *YoutubeUrl;
    int intUploadRow;
    
    BOOL isEditPressed;
}

@property (weak, nonatomic) IBOutlet UITableView *tbProductList;
@property (weak, nonatomic) IBOutlet UIButton *btnDeleteAllProduct;
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
@property (weak, nonatomic) IBOutlet UILabel *lbAccount;
@property (strong, nonatomic) id<FBGraphUser> loggedInUser;
@end

@implementation ProductViewController

#pragma mark -
#pragma mark - IBAction
- (IBAction)LoginPressed:(id)sender {
    UIStoryboard *storyboard = self.storyboard;
    LoginViewController *LoginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginVC"];
    [LoginVC setDelegate:self];
    [self presentPopupViewController:LoginVC animationType:MJPopupViewAnimationSlideBottomTop];
}

- (IBAction)EditPressed:(id)sender
{
    UIButton *btn = sender;
    if (isEditPressed) {
        isEditPressed = NO;
        [btn setImage:[UIImage imageNamed:@"編輯.png"] forState:UIControlStateNormal];
    }
    else {
        isEditPressed = YES;
        [btn setImage:[UIImage imageNamed:@"返回.png"] forState:UIControlStateNormal];
    }
    [self.btnDeleteAllProduct setHidden:!isEditPressed];
    [self.tbProductList reloadData];
}

- (IBAction)DeleteAllProduct:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                    message:@"是否確定要全部移除歌單的歌曲"
                                                   delegate:self
                                          cancelButtonTitle:@"取消"
                                          otherButtonTitles:@"確認", nil];
    [alert show];
}

- (IBAction)PlayProduct:(id)sender
{
    NSIndexPath *indexPath;
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0) && ([[[UIDevice currentDevice] systemVersion] doubleValue]< 8.0))
        indexPath = [self.tbProductList indexPathForCell:(UITableViewCell*)[[[sender superview] superview] superview]];
    else
        indexPath = [self.tbProductList indexPathForCell:(UITableViewCell*)[[sender superview] superview]];
    
    Production *aProduction = [dataList objectAtIndex:indexPath.row];
    if (isEditPressed) {
        //-----刪除檔案-----
        NSError *error;
        NSFileManager *manger = [NSFileManager defaultManager];
        NSString *removedPath = aProduction.ProductPath;
        if ([manger fileExistsAtPath:removedPath]) {
            [manger removeItemAtPath:removedPath
                               error:&error];
            NSLog(@"%@>>>has been removed", removedPath);
        };
        [database deleteSongFromMyProduct:aProduction];
        [dataList removeObjectAtIndex:indexPath.row];
        [self.tbProductList deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    } else {
        //-----播放作品-----
        UIStoryboard *storyboard = self.storyboard;
        ProductPlayerViewController *ProductPlayerVC = [storyboard instantiateViewControllerWithIdentifier:@"ProductPlayerVC"];
        [ProductPlayerVC setSongUrl:[NSURL fileURLWithPath:aProduction.ProductPath]];
        [ProductPlayerVC setStrTitle:[NSString stringWithFormat:@"%@ - %@",aProduction.Producer,aProduction.ProductName]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        BOOL success = [fileManager fileExistsAtPath:aProduction.ProductPath];
        if(!success) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *path = [documentsDirectory stringByAppendingPathComponent:aProduction.ProductName];
            success = [fileManager fileExistsAtPath:path];
            if (success)
                [ProductPlayerVC setSongUrl:[NSURL fileURLWithPath:path]];
            else
                NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
        }
        ProductPlayerVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:ProductPlayerVC animated:YES completion:Nil];
    }
}

- (IBAction)SingProduct:(id)sender {
    NSIndexPath *indexPath;
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0) && ([[[UIDevice currentDevice] systemVersion] doubleValue]< 8.0))
        indexPath = [self.tbProductList indexPathForCell:(UITableViewCell*)[[[sender superview] superview] superview]];
    else
        indexPath = [self.tbProductList indexPathForCell:(UITableViewCell*)[[sender superview] superview]];
    
    Production *aProduction = [dataList objectAtIndex:indexPath.row];
    UIStoryboard *storyboard = self.storyboard;
    KOKSMP4PlayerViewController *MP4PlayerVC = [storyboard instantiateViewControllerWithIdentifier:@"SingRightNow"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager fileExistsAtPath:aProduction.ProductPath];
    if(success) {
        //aProduction.ProductPath = @"/Users/iscom/Library/Application Support/iPhone Simulator/7.1/Applications/ED0B9E38-79FB-463C-A6F6-FCC976EDD551/Library/Caches/23589_700k.mp4";
        [MP4PlayerVC setSongUrl:[NSURL fileURLWithPath:aProduction.ProductPath]];
        [MP4PlayerVC setSongName:aProduction.ProductName];
        [MP4PlayerVC setSinger:aProduction.Producer];
        MP4PlayerVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:MP4PlayerVC animated:YES completion:Nil];
    } else {
        [self showAlertMessage:@"找不到此檔案" withTitle:@"訊息" buttonText:@"了解"];
    }
}

- (IBAction)UploadProduct:(id)sender {
    
    GlobalData *globalItem = [GlobalData getInstance];
    //-----判斷是否登入-----
    if ([globalItem.UserID isEqualToString:@"-2"])
    {
        [self LoginPressed:nil];
        return;
    }
    //-----判斷網路是否連接-----
    else if ([appDelegate getInternetStatus] == 0)
    {
        [self showAlertMessage:@"請確認網路是否已連線" withTitle:@"Warning" buttonText:@"了解"];
        return;
    }
    
    UIButton *btn = (UIButton*) sender;
    NSIndexPath *indexPath;
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0) && ([[[UIDevice currentDevice] systemVersion] doubleValue]< 8.0))
        indexPath = [self.tbProductList indexPathForCell:(UITableViewCell*)[[[btn superview] superview] superview]];
    else
        indexPath = [self.tbProductList indexPathForCell:(UITableViewCell*)[[btn superview] superview]];
    intUploadRow = indexPath.row;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    [actionSheet addButtonWithTitle:@"Email"];
    [actionSheet addButtonWithTitle:@"Youtube"];
    [actionSheet addButtonWithTitle:@"相簿"];
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"取消"];
    actionSheet.delegate = self;
    [actionSheet showInView:self.view];
}


#pragma mark -
#pragma mark ActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Email"]) {
        [self EmailUploadAction];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Youtube"]) {
        [self YoutubeUploadAction];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"相簿"]) {
        [self AlbumUploadAciton];
    }
}

- (void)AlbumUploadAciton {
    Production *aProduction = [dataList objectAtIndex:intUploadRow];
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:aProduction.ProductPath] options:nil];
    NSArray *visualTracks = [sourceAsset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
    if ((!visualTracks) || ([visualTracks count] == 0)) { // 判斷是否音訊檔案
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                        message:@"很抱歉，此檔案為音訊檔案\n請利用影音合成產生影片檔案再匯出"
                                                       delegate:nil
                                              cancelButtonTitle:@"了解"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        UISaveVideoAtPathToSavedPhotosAlbum(aProduction.ProductPath, self, @selector(video:didFinishSavingWithError:contextInfo:) , nil);
    }
}

- (void)video:(NSData *)video didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    UIAlertView *alert;
    //以error參數判斷是否成功儲存影像
    if (error) {
        alert = [[UIAlertView alloc] initWithTitle:@"錯誤"
                                           message:[error description]
                                          delegate:self
                                 cancelButtonTitle:@"確定"
                                 otherButtonTitles:nil];
    } else {
        alert = [[UIAlertView alloc] initWithTitle:@"成功"
                                           message:@"影像已存入相簿中"
                                          delegate:self
                                 cancelButtonTitle:@"確定"
                                 otherButtonTitles:nil];
    }
    //顯示警告訊息
    [alert show];
}

- (void)YoutubeUploadAction
{
    //-----判斷Youtube是否開啟-----
    if (![aSetting.YoutubeEnable boolValue]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                        message:@"請到設定將Youtube開啟"
                                                       delegate:nil
                                              cancelButtonTitle:@"了解"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    Production *aProduction = [dataList objectAtIndex:intUploadRow];
    UIStoryboard *storyboard = self.storyboard;
    YoutubeUploadViewController *YoutubeUploadVC  = [storyboard instantiateViewControllerWithIdentifier:@"YoutubeUploadVC"];
    [YoutubeUploadVC setValue:self forKey:@"FbsharingDelegate"];
    [YoutubeUploadVC setFilePath:aProduction.ProductPath];
    [YoutubeUploadVC setProdcer:aProduction.Producer];
    [YoutubeUploadVC setYoutubeTitle:aProduction.ProductName];
    [YoutubeUploadVC setProductID:aProduction.ProductID];
    [YoutubeUploadVC setDelegate:self];
    [self presentPopupViewController:YoutubeUploadVC animationType:MJPopupViewAnimationSlideBottomTop];
}

- (void)EmailUploadAction
{
    //-----抓取目前帳號資訊-----
    GlobalData *globalItem = [GlobalData getInstance];
    //-----抓取作品資訊-----
    Production *aProduction = [dataList objectAtIndex:intUploadRow];
    //-----抓取作品檔案-----
    NSURL    *fileURL = [[NSURL alloc] initFileURLWithPath:aProduction.ProductPath];
    NSData *musicData = [[NSData alloc] initWithContentsOfURL:fileURL];
    //-----判斷此作品為影片或音樂-----
    AVAsset *asset = [AVAsset assetWithURL:fileURL];
    BOOL hasVideo = [asset tracksWithMediaType:AVMediaTypeVideo].count > 0;
    //-----判定是否可以Email-----
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
        [composeViewController setMailComposeDelegate:self];
        //-----設定收件者-----
        [composeViewController setToRecipients:@[globalItem.currentUser]];
        //-----判斷音樂或影片-----
        if (hasVideo) {
            //-----添加影片檔案-----
            [composeViewController addAttachmentData:musicData mimeType:@"video/mp4" fileName:aProduction.ProductName];
        } else {
            //-----添加音樂檔案-----
            [composeViewController addAttachmentData:musicData mimeType:@"audio/mpeg" fileName:aProduction.ProductName];
        }
        //-----設定Email主題-----
        [composeViewController setSubject:@"CarolOK影音作品"];
        //-----設定內容-----
        [composeViewController setMessageBody:@"本作品使用 CarolOK APP 製作(http://www.carolok.com.tw)。" isHTML:NO];
        [self presentViewController:composeViewController animated:YES completion:nil];
    } else {
        [self showAlertMessage:@"您的硬體未設定郵件帳號" withTitle:@"錯誤" buttonText:@"了解"];
        return;
    }
}

//-----當寄信結束後呼叫此函數-----
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -
#pragma mark - Fbsharing Delegate
- (void)startFBSharing:(NSString*)youtubeurl {
    
    if (self.loggedInUser != nil) {
        YoutubeUrl = youtubeurl;
        [self performSelector:@selector(FBSharingWithYoutubeUrl) withObject:nil afterDelay:.5];
    }
}

- (void)FBSharingWithYoutubeUrl {
    
    // Put together the dialog parameters
    NSMutableDictionary *params =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     @"CarolOK~卡拉處處都OK", @"name",
     @"經典MV~盡在CarolOK KTV PLAYER", @"caption",
     [NSString stringWithFormat:@"歡唱成果：\n%@", YoutubeUrl], @"description",
     YoutubeUrl, @"link",
     @"http://cdn5.iconfinder.com/data/icons/MediaPack_ICON/128/Microphone.png", @"picture",
     nil];
    // Invoke the dialog
    [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                           parameters:params
                                              handler:
     ^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
         if (error) {
             // Error launching the dialog or publishing a story.
             NSLog(@"Error publishing story.");
         } else {
             if (result == FBWebDialogResultDialogNotCompleted) {
                 // User clicked the "x" icon
                 NSLog(@"User canceled story publishing.");
             } else {
                 // Handle the publish feed callback
                 NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                 if (![urlParams valueForKey:@"post_id"]) {
                     // User clicked the Cancel button
                     NSLog(@"User canceled story publishing.");
                 } else {
                     // User clicked the Share button
                     NSString *msg = [NSString stringWithFormat:
                                      @"Posted story, id: %@",
                                      [urlParams valueForKey:@"post_id"]];
                     NSLog(@"%@", msg);
                     // Show the result in an alert
                     [[[UIAlertView alloc] initWithTitle:@"Result"
                                                 message:msg
                                                delegate:nil
                                       cancelButtonTitle:@"OK!"
                                       otherButtonTitles:nil]
                      show];
                 }
             }
         }
     }];
}

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

#pragma mark -
#pragma mark FaceBook Delegate
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    self.loggedInUser = user;
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    // test to see if we can use the share dialog built into the Facebook application
    FBShareDialogParams *p = [[FBShareDialogParams alloc] init];
    p.link = [NSURL URLWithString:@"http://developers.facebook.com/ios"];
#ifdef DEBUG
    [FBSettings enableBetaFeatures:FBBetaFeaturesShareDialog];
#endif
    self.loggedInUser = nil;
}

#pragma mark -
#pragma mark MJSecondPopupDelegateDelegate
- (void)dismissLoginView:(LoginViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)LoginSuccess:(LoginViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    //-----變更登入與帳號顯示-----
    GlobalData *globalItem = [GlobalData getInstance];
    if ([globalItem.UserID isEqualToString:@"-2"]) {
        [self.lbAccount setHidden:YES];
        [self.btnLogin setHidden:NO];
    } else {
        [self.lbAccount setHidden:NO];
        [self.btnLogin setHidden:YES];
    }
    self.lbAccount.text = globalItem.UserNickname;
}

- (void)ForgetPasswordPressed:(LoginViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    [self performSelector:@selector(presentPopupForgetPasswordView) withObject:nil afterDelay:.5];
}

- (void)dismissForgetPasswordView:(ForgetPasswordViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)RegisterPressed:(LoginViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    [self performSelector:@selector(presentPopupRegisterView) withObject:nil afterDelay:.5];
}


- (void)dismissYoutubeView:(YoutubeUploadViewController*)secondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

#pragma mark -
#pragma mark - UIAlert Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.message isEqualToString:@"是否確定要全部移除歌單的歌曲"])
    {
        if ([[alertView buttonTitleAtIndex:buttonIndex] compare:@"確認"] == NSOrderedSame)
        {
            for (Production *aProduction in dataList)
            {
                //-----刪除檔案-----
                NSError *error;
                NSFileManager *manger = [NSFileManager defaultManager];
                NSString *removedPath = aProduction.ProductPath;
                if ([manger fileExistsAtPath:removedPath]) {
                    [manger removeItemAtPath:removedPath
                                       error:&error];
                    NSLog(@"%@>>>has been removed", removedPath);
                };
                [database deleteSongFromMyProduct:aProduction];
            }
            [dataList removeAllObjects];
            [self.tbProductList reloadData];
        }
    }
}

#pragma mark -
#pragma mark - Tableview Datasource & Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [dataList count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 62;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    CellIdentifier = @"ProductListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIButton *btnPlay = (UIButton*)[cell viewWithTag:tagBtnPlay];
    UILabel *lbProductName = (UILabel*)[cell viewWithTag:tagLbProductName];
    UILabel *lbProducer = (UILabel*)[cell viewWithTag:tagLbProducer];
    UILabel *lbTrackTime = (UILabel*)[cell viewWithTag:tagLbTrackTime];
    
    if (isEditPressed)
        [btnPlay setImage:[UIImage imageNamed:@"刪除.png"] forState:UIControlStateNormal];
    else
        [btnPlay setImage:[UIImage imageNamed:@"播放按鈕.png"] forState:UIControlStateNormal];
    lbProductName.adjustsFontSizeToFitWidth = YES;
    lbProducer.adjustsFontSizeToFitWidth = YES;
    
    Production *aProduct = [dataList objectAtIndexedSubscript:indexPath.row];
    lbProductName.text = aProduct.ProductName;
    lbProducer.text = aProduct.Producer;
    lbTrackTime.text = aProduct.ProductTracktime;
    
    return cell;
}

#pragma mark -
#pragma mark - view life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //-----初始化-----
    dataList = [[NSMutableArray alloc] init];
    database = [[SQLiteDBTool alloc] init];
    aSetting = [[Setting alloc] init];
    appDelegate = [[UIApplication sharedApplication] delegate];
    self.lbAccount.adjustsFontSizeToFitWidth = YES;
    
    
    //-----繼承TableView-----
    self.tbProductList.delegate = self;
    self.tbProductList.dataSource = self;
    
    //-----臉書要增加才會呼叫，我也不懂為何-----
    FBLoginView *loginview = [[FBLoginView alloc] init];
    loginview.frame = CGRectOffset(loginview.frame, 5, 5);
    loginview.delegate = self;
    [self.view addSubview:loginview];
    [loginview setAlpha:0];
    [loginview sizeToFit];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //-----變更登入與帳號顯示-----
    GlobalData *globalItem = [GlobalData getInstance];
    if ([globalItem.UserID isEqualToString:@"-2"]) {
        [self.lbAccount setHidden:YES];
        [self.btnLogin setHidden:NO];
    } else {
        [self.lbAccount setHidden:NO];
        [self.btnLogin setHidden:YES];
    }
    self.lbAccount.text = globalItem.UserNickname;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //-----抓取資料庫-----
    dataList = [database getMyProductionData];
    
    //-----抓取帳號的設定值-----
    GlobalData *globaItem = [GlobalData getInstance];
    aSetting = [database getSettingWithUserID:globaItem.UserID];
    
    [self.tbProductList reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - 
#pragma mark - MySubCode
-(void) showAlertMessage:(NSString *) message withTitle:(NSString *)title buttonText:(NSString *) btnCancelText {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: title
                          message:message
                          delegate:nil
                          cancelButtonTitle: btnCancelText
                          otherButtonTitles: nil];
    [alert show];
}

- (void)presentPopupForgetPasswordView
{
    //-----開始忘記密碼視窗-----
    UIStoryboard *storyboard = self.storyboard;
    ForgetPasswordViewController *ForgetPasswordVC = [storyboard instantiateViewControllerWithIdentifier:@"ForgetPasswordVC"];
    [ForgetPasswordVC setDelegate:self];
    [self presentPopupViewController:ForgetPasswordVC animationType:MJPopupViewAnimationFade];
}

- (void)presentPopupRegisterView
{
    //-----開始忘記密碼視窗-----
    UIStoryboard *storyboard = self.storyboard;
    AgreeTermsViewController *AgreeTermsVC = [storyboard instantiateViewControllerWithIdentifier:@"AgreeTermsNC"];
    [self presentViewController:AgreeTermsVC animated:YES completion:nil];
}


@end
