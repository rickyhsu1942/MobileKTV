//
//  ELCImagePickerController.m
//  ELCImagePickerDemo
//
//  Created by ELC on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import "ELCImagePickerController.h"
#import "ELCAsset.h"
#import "ELCAssetCell.h"
#import "ELCAssetTablePicker.h"
#import "ELCAlbumPickerController.h"

@implementation ELCImagePickerController

@synthesize delegate = _myDelegate;

- (void)cancelImagePicker
{
	if([_myDelegate respondsToSelector:@selector(elcImagePickerControllerDidCancel:)]) {
		[_myDelegate performSelector:@selector(elcImagePickerControllerDidCancel:) withObject:self];
	}
}

- (void)selectedAssets:(NSArray *)assets
{
	NSMutableArray *returnArray = [[[NSMutableArray alloc] init] autorelease];
	//
    NSLog(@"Original selected media: %d", assets.count);
    //
    int i=0;
	for (ALAsset *asset in assets) {
        // by James Chen, 2013/7/9
        @try {
            NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
            [workingDictionary setObject:[asset valueForProperty:ALAssetPropertyType] forKey:@"UIImagePickerControllerMediaType"];
            ALAssetRepresentation *assetRep = [asset defaultRepresentation];
            
            CGImageRef imgRef = [assetRep fullScreenImage];
            UIImage *img = [UIImage imageWithCGImage:imgRef
                                               scale:[UIScreen mainScreen].scale
                                         orientation:UIImageOrientationUp];
            [workingDictionary setObject:img forKey:@"UIImagePickerControllerOriginalImage"];
            [workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]] forKey:@"UIImagePickerControllerReferenceURL"];
            
            [returnArray addObject:workingDictionary];
            
            [workingDictionary release];
            
            // by James Chen
            NSLog(@"#%03d, MediaType: %@", ++i, [asset valueForProperty:ALAssetPropertyType]);
            // -------------------
        }
        @catch (NSException *ex) {
            NSLog(@"ELCImagePickerController_selectedAssets Error: %@", ex.reason);
            NSLog(@"The TROUBLE MAKER(Asset) is: %@", asset);
        }
        @finally {
            // NSLog(@"MediaType: %@", [asset valueForProperty:ALAssetPropertyType]);
        }
	}
    // by James Chen, 2013/7/9
    NSLog(@"FINAL processed UIImage objects: %d", returnArray.count);
    //
    
    //---    ----
	if(_myDelegate != nil && [_myDelegate respondsToSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:)]) {
		[_myDelegate performSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:) withObject:self withObject:[NSArray arrayWithArray:returnArray]];
	} else {
        [self popToRootViewControllerAnimated:NO];
    }
}

/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}
 */

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    NSLog(@"ELC Image Picker received memory warning.");
    
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc
{
    NSLog(@"deallocing ELCImagePickerController");
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight ||
            interfaceOrientation == UIInterfaceOrientationLandscapeLeft
            );
}


@end
