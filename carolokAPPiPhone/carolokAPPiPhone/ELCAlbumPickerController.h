//
//  AlbumPickerController.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCAssetSelectionDelegate.h"
#import <MobileCoreServices/UTCoreTypes.h>

@interface ELCAlbumPickerController : UITableViewController <ELCAssetSelectionDelegate>

@property (nonatomic, assign) id<ELCAssetSelectionDelegate> parent;
@property (nonatomic, retain) NSMutableArray *assetGroups;
// by James Chen
@property (nonatomic, assign) CFStringRef      mediaType ;
//----------------
@end

