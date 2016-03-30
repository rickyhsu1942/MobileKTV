//
//  AlbumPickerController.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "ELCAssetTablePicker.h"

@interface ELCAlbumPickerController ()

@property (nonatomic, retain) ALAssetsLibrary *library;

@end

@implementation ELCAlbumPickerController

@synthesize parent = _parent;
@synthesize assetGroups = _assetGroups;
@synthesize library = _library;
@synthesize mediaType = _mediaType;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    /*
	[self.navigationItem setTitle:@"Loading..."];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.parent action:@selector(cancelImagePicker)];
	[self.navigationItem setRightBarButtonItem:cancelButton];
	*/
    
    // by James Chen
    [self.navigationItem setTitle:@"載入中 ..."];
    
    // default : Image/Photo !!
    if (_mediaType == nil) {
        _mediaType = kUTTypeImage;
    }
    //UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.parent action:@selector(cancelImagePicker)];
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self.parent
                                                                    action:@selector(cancelImagePicker)];
    [self.navigationItem setRightBarButtonItem:cancelButton];
    //---------------------
    [cancelButton release];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	self.assetGroups = tempArray;
    [tempArray release];
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    self.library = assetLibrary;
    [assetLibrary release];

    // Load Albums into assetGroups
    dispatch_async(dispatch_get_main_queue(), ^
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // Group enumerator Block
        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) 
        {
            if (group == nil) {
                return;
            }
            
            // added fix for camera albums order
            NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
            NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
            
            if ([[sGroupPropertyName lowercaseString] isEqualToString:@"camera roll"] && nType == ALAssetsGroupSavedPhotos) {
                [self.assetGroups insertObject:group atIndex:0];
            }
            else {
                [self.assetGroups addObject:group];
            }

            // Reload albums
            [self performSelectorOnMainThread:@selector(reloadTableView) withObject:nil waitUntilDone:YES];
        };
        
        // Group Enumerator Failure Block
        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
            
            // UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            // By James Chen
            if (error.code == -3311) {
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"錯誤" message:[NSString stringWithFormat:@"無法取用您的照片或視訊，請至「隱私權設定」中啓用存取"] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                // -----------------
                [alert show];
                [alert release];
            } else {
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"錯誤" message:[NSString stringWithFormat:@"讀取分類錯誤: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                // -----------------
                [alert show];
                [alert release];
            }
            
            NSLog(@"A problem occured %@", [error description]);	                                 
        };	
                
        // Enumerate Albums
        [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                               usingBlock:assetGroupEnumerator 
                             failureBlock:assetGroupEnumberatorFailure];
        
        [pool release];
    });    
}

- (void)reloadTableView
{
	[self.tableView reloadData];
	// [self.navigationItem setTitle:@"Select an Album"];
    // By James Chen
    if (_mediaType == kUTTypeVideo)
        [self.navigationItem setTitle:@"影片分類"];
    else
        [self.navigationItem setTitle:@"相簿分類"];
    //----------------
}

- (void)selectedAssets:(NSArray*)assets
{
	[_parent selectedAssets:assets];
}

// by James Chen
-(void)setMediaType:(CFStringRef) type {
    _mediaType = type;
}
//----------------------
#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.assetGroups count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Get count
    ALAssetsGroup *g = (ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row];
    //[g setAssetsFilter:[ALAssetsFilter allPhotos]];
    // by James Chen
    if (_mediaType == kUTTypeVideo)
        [g setAssetsFilter:[ALAssetsFilter allVideos]];
    else
        [g setAssetsFilter:[ALAssetsFilter allPhotos]];
    //----------------------------------

    NSInteger gCount = [g numberOfAssets];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)",[g valueForProperty:ALAssetsGroupPropertyName], gCount];
    [cell.imageView setImage:[UIImage imageWithCGImage:[(ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row] posterImage]]];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//ELCAssetTablePicker *picker = [[ELCAssetTablePicker alloc] initWithNibName: nil bundle: nil];
    // by James Chen
    ELCAssetTablePicker *picker = [[ELCAssetTablePicker alloc] initWithNibName:@"ELCAssetTablePicker" bundle:[NSBundle mainBundle]];
	// -----------
    picker.parent = self;

    
    picker.assetGroup = [self.assetGroups objectAtIndex:indexPath.row];
    //[picker.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    // by James Chen, for Image or Video
    if (_mediaType == kUTTypeVideo) {
        [picker.assetGroup setAssetsFilter:[ALAssetsFilter allVideos]];
        [picker setLimited:15];
    }
    else {
        [picker.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
        [picker setLimited:20];
    }
    //----------------------

	[self.navigationController pushViewController:picker animated:YES];
	[picker release];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return 72;  // 57;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc 
{	
    [_assetGroups release];
    [_library release];
    [super dealloc];
}

// by James Chen
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight ||
            interfaceOrientation == UIInterfaceOrientationLandscapeLeft
            );
}
// -------------

@end

