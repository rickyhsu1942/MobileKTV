//
//  AssetCell.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>


// be James Chen
#define CELL_SIZE  75
// -----------------


@interface ELCAssetCell : UITableViewCell

- (id)initWithAssets:(NSArray *)assets reuseIdentifier:(NSString *)identifier;
- (void)setAssets:(NSArray *)assets;

@end
