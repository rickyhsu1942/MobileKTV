//
//  KOKSAudioPickerViewController.m
//  TrySinging
//
//  Created by 國立中興大學 資訊工程學系 國立中興大學 資訊工程學系 on 12/10/18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "KOKSAudioPickerViewController.h"
#import "GlobalData.h"
#import "Production.h"

@interface KOKSAudioPickerViewController ()
{
    Production *aProduct;
}

@end

@implementation KOKSAudioPickerViewController
@synthesize delegate;
@synthesize data=_data;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    database1 = [[SQLiteDBTool alloc] init];
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    _data= [[NSMutableArray alloc] init];
    _data = [database1 getMyProductionData];
    [self.tableView reloadData];
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    documentsPath = [_data objectAtIndex:row];
    aProduct= [_data objectAtIndex:row];
    NSLog(@"Selection is: %@", [_data objectAtIndex:indexPath.row]);
    NSURL *filePath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@", aProduct.ProductPath]];
    [delegate setAudioFilename:[NSArray arrayWithObject: filePath] ProductName:aProduct.ProductName];
    
    //[delegate dismissAudioFilePopover];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell==nil) {
        cell= [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }    
    //
    
    NSUInteger row = [indexPath row];
    
    aProduct= [_data objectAtIndex:row];
    cell.textLabel.text = aProduct.ProductName;
    //cell.textLabel.text=[_data objectAtIndex:indexPath.row];
    
    if (indexPath.row % 2 == 0)
        //cell.textLabel.backgroundColor = [UIColor grayColor];
        cell.textLabel.textColor = [UIColor grayColor];
    else
        //cell.textLabel.backgroundColor = [UIColor redColor];
        cell.textLabel.textColor = [UIColor darkGrayColor];
    
    return cell;
}

- (void)viewDidUnload
{
    _data = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight ||
            interfaceOrientation == UIInterfaceOrientationLandscapeLeft
            );
}

@end
