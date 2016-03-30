//
//  ProductPickerViewController.m
//  carolAPPs
//
//  Created by iscom on 2014/6/26.
//
//

#import "ProductPickerViewController.h"

#import "SQLiteDBTool.h"
#import "MySongList.h"
#import "Production.h"

#define tagLbProductName  1

@interface ProductPickerViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray *aryProductList;
    NSMutableArray *arySelectedIndex;
    SQLiteDBTool *database;
}

@property (weak, nonatomic) IBOutlet UITableView *tbProductList;
@end

@implementation ProductPickerViewController
#pragma mark -
#pragma mark - IBAction
- (IBAction)Done:(id)sender {
    NSMutableArray *aryAddVideoToDatabase = [[NSMutableArray alloc] init];
    for (NSIndexPath *index in arySelectedIndex)
    {
        Production *aProduction = [aryProductList objectAtIndex:index.row];
        MySongList *aSong = [[MySongList alloc] init];
        aSong.SongName = aProduction.ProductName;
        aSong.Singer = aProduction.Producer;
        aSong.SongPath = aProduction.ProductPath;
        aSong.TrackTime = aProduction.ProductTracktime;
        aSong.IndexRow = [database getMySongListCount] + 1;
        [aryAddVideoToDatabase addObject:aSong];
    }
    
    if ([aryAddVideoToDatabase count] > 0) {
        [database insertMySonglist:aryAddVideoToDatabase];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self.ProductPickDelegate RefreshTable];
    }];

}

- (IBAction)Cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark - TableView Datasource & Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [aryProductList count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    CellIdentifier = @"ProductCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    Production *aProduction = [aryProductList objectAtIndex:indexPath.row];
    UILabel *lbVideoName = (UILabel *)[cell viewWithTag:tagLbProductName];
    lbVideoName.text = aProduction.ProductName;
    
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
    //-----Init-----
    aryProductList = [[NSMutableArray alloc] init];
    arySelectedIndex = [[NSMutableArray alloc] init];
    database = [[SQLiteDBTool alloc] init];
    
    //-----TableView-----
    self.tbProductList.delegate = self;
    self.tbProductList.dataSource = self;
    
    //-----抓取資料庫-----
    aryProductList = [database getMyProductionData];
    [self.tbProductList reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
