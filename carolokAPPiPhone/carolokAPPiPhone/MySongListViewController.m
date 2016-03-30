//
//  MySongListViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/6/17.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
//-----View-----
#import "MySongListViewController.h"
#import "KOKSMP4PlayerViewController.h"
#import "iTuneVideoViewController.h"
#import "ProductPickerViewController.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"
#import "LoginViewController.h"
#import "ForgetPasswordViewController.h"
#import "AgreeTermsViewController.h"
//-----Tool-----
#import "SQLiteDBTool.h"
//-----Object-----
#import "GlobalData.h"
#import "MySongList.h"
//-----UI-----
#import "UIViewController+MJPopupViewController.h"

#define tagBtnSing       1
#define tagLbSongName    2
#define tagLbSinger      3
#define tagLbTrackTime   4

@interface MySongListViewController () <UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate,MPMediaPickerControllerDelegate,ELCImagePickerControllerDelegate,MJSecondPopupDelegate>
{
    SQLiteDBTool *database;
    NSMutableArray *dataList;
    
    BOOL isEditPressed;
}

@property (weak, nonatomic) IBOutlet UIView *viewTable;
@property (weak, nonatomic) IBOutlet UITableView *tbSonglist;
@property (weak, nonatomic) IBOutlet UIView *viewEditPressed;
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
@property (weak, nonatomic) IBOutlet UILabel *lbAccount;
@end

@implementation MySongListViewController

#pragma mark -
#pragma mark - IBAction
- (IBAction)LoginPressed:(id)sender {
    UIStoryboard *storyboard = self.storyboard;
    LoginViewController *LoginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginVC"];
    [LoginVC setDelegate:self];
    [self presentPopupViewController:LoginVC animationType:MJPopupViewAnimationSlideBottomTop];
}

- (IBAction)EditPressed:(id)sender {
    UIButton *btn = sender;
    if (isEditPressed) {
        isEditPressed = NO;
        [btn setImage:[UIImage imageNamed:@"編輯.png"] forState:UIControlStateNormal];
    }
    else {
        isEditPressed = YES;
        [btn setImage:[UIImage imageNamed:@"返回.png"] forState:UIControlStateNormal];
    }
    
    [self.viewEditPressed setHidden:!isEditPressed];
    
    [self.tbSonglist reloadData];
}

- (IBAction)DeleteAllSongPressed:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                    message:@"是否確定要全部移除歌單的歌曲"
                                                   delegate:self
                                          cancelButtonTitle:@"取消"
                                          otherButtonTitles:@"確認", nil];
    [alert show];
}

- (IBAction)StartSingingPressed:(id)sender
{
    NSMutableArray *arySong = [[NSMutableArray alloc] init];
    for (MySongList *aSong in [database getMySongListByOrder:@"Indexrow"])
    {
        [arySong addObject:aSong];
    }
    
    if ([arySong count] > 0) {
        UIStoryboard *storyboard = self.storyboard;
        KOKSMP4PlayerViewController *MP4PlayerVC = [storyboard instantiateViewControllerWithIdentifier:@"SingRightNow"];
        MP4PlayerVC.aryPlaylist = arySong;
        MP4PlayerVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:MP4PlayerVC animated:YES completion:Nil];
    } else {
        [self showAlertMessage:@"播放清單未有歌曲" withTitle:@"訊息" buttonText:@"了解"];
    }
}

- (IBAction)ImportSongPressed:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    [actionSheet addButtonWithTitle:@"本機音樂"];
    [actionSheet addButtonWithTitle:@"本機影片"];
    [actionSheet addButtonWithTitle:@"影音作品"];
    [actionSheet addButtonWithTitle:@"本機照片"];
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"取消"];
    actionSheet.delegate = self;
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (IBAction)SingOneSongPressed:(id)sender
{
    NSIndexPath *indexPath;
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0) && ([[[UIDevice currentDevice] systemVersion] doubleValue]< 8.0))
        indexPath = [self.tbSonglist indexPathForCell:(UITableViewCell*)[[[sender superview] superview] superview]];
    else
        indexPath = [self.tbSonglist indexPathForCell:(UITableViewCell*)[[sender superview] superview]];
    
    MySongList *aSong = [dataList objectAtIndex:indexPath.row];
    
    if (isEditPressed)
    {
        //-----刪除此歌曲資訊-----
        if([database deleteMySonglistWithPId:aSong.PId]){
            //-----修正mysonglist的indexrow數值-----
            [database updateMySonglistIndexrowWithIndexRow:aSong.IndexRow];
        }
        [dataList removeObjectAtIndex:indexPath.row];
        [self.tbSonglist deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];

    }
    else
    {
        //------歡唱單曲-----
        [self PrepareReadytoSing:aSong];
    }
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

#pragma mark -
#pragma mark - UIAlert Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.message isEqualToString:@"是否確定要全部移除歌單的歌曲"])
    {
        if ([[alertView buttonTitleAtIndex:buttonIndex] compare:@"確認"] == NSOrderedSame)
        {
            [database deleteAllMySonglist];
            [dataList removeAllObjects];
            [self.tbSonglist reloadData];
        }
    }
}


#pragma mark -
#pragma mark ActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"本機音樂"]) {
        [self ImportiTuneAudio];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"本機影片"]) {
        [self ImportiTuneVideo];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"影音作品"]) {
        [self ImportProduct];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"本機照片"]) {
        [self ImportAlbum];
    }
}

#pragma mark -
#pragma mark - MPMediaPickerControllerDelegate
- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection
{
    NSMutableArray *aryMySongList = [[NSMutableArray alloc] init];
    for (MPMediaItem *anItem in mediaItemCollection.items)
    {
        MySongList *aSong = [[MySongList alloc] init];
        aSong.SongName = [anItem valueForKey:MPMediaItemPropertyTitle];
        aSong.Singer = [anItem valueForKey:MPMediaItemPropertyArtist];
        aSong.SongPath = [anItem valueForProperty: MPMediaItemPropertyAssetURL];
        int minute = 0;
        int second = 0;
        minute = [[anItem valueForKey:MPMediaItemPropertyPlaybackDuration] floatValue] / 60;
        second = [[NSString stringWithFormat:@"%f",[[anItem valueForKey:MPMediaItemPropertyPlaybackDuration] floatValue]] intValue] % 60;
        aSong.TrackTime = [NSString stringWithFormat:@"%02d:%02d", minute, second];
        aSong.IndexRow = [database getMySongListCount] + 1;
        aSong.RandomRow = 0;
        [aryMySongList addObject:aSong];
    }
    
    if ([aryMySongList count] > 0)
    {
        [database insertMySonglist:aryMySongList];
        [self OrderByIndexRow];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark - Image/Video Picker
// mediaType : kUTTypeImage or kUTTypeVideo
-(void) launchImageVideoPicker:(CFStringRef) mediaType { // mediaType : kUTTypeImage or kUTTypeVideo
    ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] initWithNibName:@"ELCAlbumPickerController" bundle:[NSBundle mainBundle]];
    albumController.mediaType = mediaType;
	ELCImagePickerController *elcImagePicker = [[ELCImagePickerController alloc] initWithRootViewController:albumController];
    [albumController setParent:elcImagePicker];
	[elcImagePicker setDelegate:self];
    
    [self presentViewController:elcImagePicker animated:YES completion:nil];
}

#pragma mark -
#pragma mark - ELCImagePickerControllerDelegate Methods
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    NSMutableArray *aryMySongList = [[NSMutableArray alloc] init];
    for(NSDictionary *dict in info)
    {
        MySongList *aVideo = [[MySongList alloc] init];
        aVideo.SongPath = [dict objectForKey:UIImagePickerControllerReferenceURL];
        
        ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *imageAsset)
        {
            ALAssetRepresentation *videoRep = [imageAsset defaultRepresentation];
            [database updateMySonglistSongName:[videoRep filename] SongPath:[NSString stringWithFormat:@"%@",[videoRep url]]];
            [self OrderByIndexRow];
            NSLog(@"Add Video File: %@ ",[videoRep filename]);
        };
        ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:[dict objectForKey:UIImagePickerControllerReferenceURL] resultBlock:resultblock failureBlock:nil];
        
        AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:[dict objectForKey:UIImagePickerControllerReferenceURL] options:nil];
        CMTime duration = sourceAsset.duration;
        float videoDuration = CMTimeGetSeconds(duration);
        int minute = videoDuration / 60;
        int second = [[NSString stringWithFormat:@"%f",videoDuration] intValue] % 60;
        aVideo.TrackTime = [NSString stringWithFormat:@"%02d:%02d", minute, second];
        aVideo.Singer = @"我的相簿";
        aVideo.IndexRow = [database getMySongListCount] + 1;
        [aryMySongList addObject:aVideo];
    }
    
    if ([aryMySongList count] > 0)
    {
        [database insertMySonglist:aryMySongList];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark - TableView Delegate & DataSource
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
    CellIdentifier = @"SongListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    tableView.editing = YES;
    
    UIButton *btnSing = (UIButton *)[cell viewWithTag:tagBtnSing];
    UILabel *lbSongName = (UILabel *)[cell viewWithTag:tagLbSongName];
    UILabel *lbSinger = (UILabel *)[cell viewWithTag:tagLbSinger];
    UILabel *lbTrackTime = (UILabel *)[cell viewWithTag:tagLbTrackTime];
    
    if (isEditPressed) {
        [btnSing setImage:[UIImage imageNamed:@"刪除.png"] forState:UIControlStateNormal];
    } else {
        [btnSing setImage:[UIImage imageNamed:@"麥克風.png"] forState:UIControlStateNormal];
    }
    
    lbSongName.adjustsFontSizeToFitWidth = YES;
    lbSinger.adjustsFontSizeToFitWidth = YES;
    
    MySongList *aSong = [dataList objectAtIndex:indexPath.row];
    lbSongName.text = aSong.SongName;
    lbSinger.text = aSong.Singer;
    lbTrackTime.text = aSong.TrackTime;
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete)  {
        //write delete code.
        //[arry removeObjectAtIndex:indexPath.row];
        
        //[Table reloadData];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    MySongList *aFromSong = [dataList objectAtIndex:fromIndexPath.row];
    [dataList removeObjectAtIndex:fromIndexPath.row];
    [dataList insertObject:aFromSong atIndex:toIndexPath.row];
    
    //-----按照新的順序更改MySonglist的IndexRow-----
    int IndexRow = 0;
    for (MySongList *aSong in dataList)
    {
        IndexRow++;
        [database updateMySonglistIndexRow:IndexRow ByPid:aSong.PId];
    }
}

#pragma mark -
#pragma mark - view life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    
    //-----初始化-----
    database = [[SQLiteDBTool alloc] init];
    dataList = [[NSMutableArray alloc] init];
    self.lbAccount.adjustsFontSizeToFitWidth = YES;
    
    //-----抓取資料庫-----
    dataList =  [database getMySongListByOrder:@"Indexrow"];
    
    //-----繼承TableView-----
    self.tbSonglist.delegate = self;
    self.tbSonglist.dataSource = self;
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
    
    //-----確認歌單中的iTune原檔案是否存在-----
    [self DeleteNotExistMediaItems];
    
    //-----監聽回到前台的時候-----
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:NULL];
}

- (void)viewDidDisappear:(BOOL)animated
{
    //-----移除監聽回到前台的時候-----
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)applicationWillEnterForeground
{
    //-----確認歌單中的iTune原檔案是否存在-----
    [self performSelector:@selector(DeleteNotExistMediaItems) withObject:nil afterDelay:0.5];
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

- (void)OrderByIndexRow
{
    //-----抓取資料庫並重新刷新tableview-----
    dataList =  [database getMySongListByOrder:@"Indexrow"];
    [self.tbSonglist reloadData];
}

- (void)ImportiTuneAudio
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
    picker.delegate                    = self;
    picker.allowsPickingMultipleItems  = YES;
    picker.prompt                      = NSLocalizedString(@"AddSongsPrompt", @"Prompt to user to choose some songs to play");
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)ImportiTuneVideo {
    UIStoryboard *storyboard = self.storyboard;
    iTuneVideoViewController *iTuneVideoVC  = [storyboard instantiateViewControllerWithIdentifier:@"iTuneVideoVC"];
    [iTuneVideoVC setValue:self forKey:@"iTuneDelegate"];
    iTuneVideoVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:iTuneVideoVC animated:YES completion:Nil];
}

- (void)ImportProduct {
    UIStoryboard *storyboard = self.storyboard;
    ProductPickerViewController *ProductPickerVC  = [storyboard instantiateViewControllerWithIdentifier:@"ProductPickerVC"];
    [ProductPickerVC setValue:self forKey:@"ProductPickDelegate"];
    ProductPickerVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:ProductPickerVC animated:YES completion:Nil];
}

- (void)ImportAlbum
{
    [self launchImageVideoPicker:kUTTypeVideo];
}

- (void)DeleteNotExistMediaItems
{
    MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeAny] forProperty:MPMediaItemPropertyMediaType];
    
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    [query addFilterPredicate:predicate];
    
    NSArray *items = [query items];
    NSString *allMediaPath = @"";
    
    //-----將目前iTune有的媒體路徑存入allMediaPath-----
    for (MPMediaItem* item in items)
    {
        allMediaPath = [NSString stringWithFormat:@"%@\n ● %@",allMediaPath,[item valueForProperty:MPMediaItemPropertyAssetURL]];
    }
    NSLog(@"%@",allMediaPath);
    
    //-----開始檢查我的歌單中的檔案-----
    for (MySongList *aSong in dataList)
    {
        //-----排除非來源iTune的媒體-----
        if (![aSong.SongPath hasPrefix:@"ipod-library"]){
            continue;
        }
        
        //-----判斷此歌曲路徑是否還存在allMediaPath中，如果沒有將會刪除-----
        if([allMediaPath rangeOfString:aSong.SongPath].length == 0)
        {
            //-----刪除此歌曲資訊-----
            if([database deleteMySonglistWithPId:aSong.PId]){
                //-----修正mysonglist的indexrow數值-----
                [database updateMySonglistIndexrowWithIndexRow:aSong.IndexRow];
            }
            [self OrderByIndexRow];
        }
    }
}

-(void)PrepareReadytoSing:(MySongList*)aSong
{
    UIStoryboard *storyboard = self.storyboard;
    KOKSMP4PlayerViewController *MP4PlayerVC = [storyboard instantiateViewControllerWithIdentifier:@"SingRightNow"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager fileExistsAtPath:aSong.SongPath];
    if(success) {
        [MP4PlayerVC setSongUrl:[NSURL fileURLWithPath:aSong.SongPath]];
    } else {
        [MP4PlayerVC setSongUrl:[NSURL URLWithString:aSong.SongPath]];
    }
    [MP4PlayerVC setSongName:aSong.SongName];
    [MP4PlayerVC setSinger:aSong.Singer];
    MP4PlayerVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:MP4PlayerVC animated:YES completion:Nil];
}

- (void)RefreshTable
{
    [self OrderByIndexRow];
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
