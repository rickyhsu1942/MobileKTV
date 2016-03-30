//
//  popoverTableViewController.m
//  carolAPPs
//
//  Created by 國立中興大學 資訊工程學系 國立中興大學 資訊工程學系 on 12/7/5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "popoverTableViewController.h"
#import "Production.h"
#import "GlobalData.h"
@interface popoverTableViewController () {
    int RemainTracks;
    NSString *SourceController;
}

@end

@implementation popoverTableViewController
@synthesize listData;
@synthesize detailItem;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)renewData
{
    
    //get current user information
    self.listData = [database1 getMyProductionDataWithType:@"聲音"];
    [self.tableView reloadData];
}

- (void)getRemainTrack : (int) remainTrack {
    RemainTracks = remainTrack;
}


- (void)SourceController : (NSString*) sourceController {
    SourceController = sourceController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //database = [[DBTool alloc] init];
    database1 = [[SQLiteDBTool alloc] init];
    
    //self.listData = [database getData];
    //self.listData = [database1 getMyProductionData];
    [self renewData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [listData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSUInteger row = [indexPath row];
    
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    //VoiceFile *item = [listData objectAtIndex:row];
    Production *aProduct = [listData objectAtIndex:row];
    //cell.textLabel.text = item.fileName;
    cell.textLabel.text = aProduct.ProductName;
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    
    self.detailItem = [listData objectAtIndex:row];
    if ([SourceController isEqualToString:@"Record"]) {
    } else {
        // 設限20分鐘音訊檔案
        Production *aProduct = self.detailItem;
        int min = [[aProduct.ProductTracktime substringToIndex:2] intValue];
        int sec = [[aProduct.ProductTracktime substringFromIndex:aProduct.ProductTracktime.length - 2] intValue];
        
        //        if ((min * 60) + sec > RemainTracks) {
        //            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
        //                                                            message:@"已超過總音軌長度80分鐘"
        //                                                           delegate:nil
        //                                                  cancelButtonTitle:@"了解"
        //                                                  otherButtonTitles:nil];
        //            [alert show];
        //            return;
        //        }
        //        else
        if ((min * 60) + sec > 1200) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                            message:@"請選擇20分鐘以內的音訊檔案"
                                                           delegate:nil
                                                  cancelButtonTitle:@"了解"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    
    [self.delegate FileSelected:YES];
}

@end
