//
//  iTuneVideoViewController.m
//  carolAPPs
//
//  Created by iscom on 2014/5/13.
//
//

#import <MediaPlayer/MediaPlayer.h>
#import "iTuneVideoViewController.h"

#import "SQLiteDBTool.h"
#import "MySongList.h"


#define VideoName_Tag    1
@interface iTuneVideoViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    NSArray *aryVideoList;
    NSMutableArray *arySelectedIndex;
    NSIndexPath *checkedIndexPath;
    SQLiteDBTool *database;
}

@property (weak, nonatomic) IBOutlet UITableView *tbVideoList;
@end

@implementation iTuneVideoViewController

#pragma mark -
#pragma mark - IBAction
- (IBAction)cancelPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)donePressed:(id)sender
{
    //-----判斷從哪個畫面呼叫的-----
    if ([self.FromVC isEqualToString:@"AVMixer"])
    {
        
        NSMutableArray *aryAllSelectedItem = [[NSMutableArray alloc] init];
        for (NSIndexPath *index in arySelectedIndex)
        {
            MPMediaItem *anItem = [aryVideoList objectAtIndex:index.row];
            [aryAllSelectedItem addObject:anItem];
        }
        
        //-----如果未選取檔案，直接離開畫面-----
        if (aryAllSelectedItem.count > 0)
        {
            [self dismissViewControllerAnimated:YES completion:^{
                [self.iTuneDelegate videoPicker:aryAllSelectedItem];
            }];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    else
    {
        NSMutableArray *aryAddVideoToDatabase = [[NSMutableArray alloc] init];
        for (NSIndexPath *index in arySelectedIndex)
        {
            MPMediaItem *anItem = [aryVideoList objectAtIndex:index.row];
            MySongList *aSong = [[MySongList alloc] init];
            aSong.SongName = [anItem valueForKey:MPMediaItemPropertyTitle];
            if ([anItem valueForKey:MPMediaItemPropertyArtist] == nil)
                aSong.Singer = @"未知歌手";
            else
                aSong.Singer = [anItem valueForKey:MPMediaItemPropertyArtist];
            aSong.SongPath = [anItem valueForProperty: MPMediaItemPropertyAssetURL];
            int minute = 0;
            int second = 0;
            minute = [[anItem valueForKey:MPMediaItemPropertyPlaybackDuration] floatValue] / 60;
            second = [[NSString stringWithFormat:@"%f",[[anItem valueForKey:MPMediaItemPropertyPlaybackDuration] floatValue]] intValue] % 60;
            aSong.TrackTime = [NSString stringWithFormat:@"%02d:%02d", minute, second];
            aSong.IndexRow = [database getMySongListCount] + 1;
            [aryAddVideoToDatabase addObject:aSong];
        }
        
        if ([aryAddVideoToDatabase count] > 0) {
            [database insertMySonglist:aryAddVideoToDatabase];
        }
        
        [self dismissViewControllerAnimated:YES completion:^{
            [self.iTuneDelegate RefreshTable];
        }];
    }
}


#pragma mark -
#pragma mark - TableView Datasource & Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [aryVideoList count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    CellIdentifier = @"videoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    MPMediaItem* itemVideo = [aryVideoList objectAtIndex:indexPath.row];
    UILabel *lbVideoName = (UILabel *)[cell viewWithTag:VideoName_Tag];
    lbVideoName.text = [itemVideo valueForProperty:MPMediaItemPropertyTitle];
    
    lbVideoName.adjustsFontSizeToFitWidth = YES;
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cellCheck = [tableView
                                  cellForRowAtIndexPath:indexPath];
    if (cellCheck.accessoryType == UITableViewCellAccessoryNone) {
        cellCheck.accessoryType = UITableViewCellAccessoryCheckmark;
        [arySelectedIndex addObject:indexPath];
    } else {
        cellCheck.accessoryType = UITableViewCellAccessoryNone;
        [arySelectedIndex removeObject:indexPath];
    }
}

#pragma mark -
#pragma mark - view life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //-----TableView-----
    self.tbVideoList.delegate = self;
    self.tbVideoList.dataSource = self;
    
    //-----iTuneVideo-----
    MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeAnyVideo] forProperty:MPMediaItemPropertyMediaType];
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    [query addFilterPredicate:predicate];
    aryVideoList = [query items];
    
    //-----Init-----
    arySelectedIndex = [[NSMutableArray alloc] init];
    database = [[SQLiteDBTool alloc] init];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
