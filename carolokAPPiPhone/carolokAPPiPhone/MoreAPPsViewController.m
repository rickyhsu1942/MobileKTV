//
//  MoreAPPsViewController.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/7/13.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

//-----View-----
#import "MoreAPPsViewController.h"
//-----UI-----
#import "HVTableView.h"

#define lbTitleTag              1
#define expandGlyphTag          7
#define purchaseButtonTag       10
#define TvSynopsisTag           11
#define TvSynopsisPart2Tag      12

@interface MoreAPPsViewController () <HVTableViewDelegate, HVTableViewDataSource>
@end

@implementation MoreAPPsViewController
{
    HVTableView* myTable;
	NSArray* cellTitles;
	NSArray* cellImages;
    NSArray* cellExpandedImages;
    NSArray* cellDetailTextLabel;
    NSArray* cellDetailTextView;
    NSArray* cellDetail2TextView;
    CGSize mainScreen;
    
}

#pragma mark -
#pragma mark - IBAction
- (IBAction)backPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:Nil];
}

- (void)DownloadPressed:(id)sender {
    UIButton *btn = sender;
    NSIndexPath *indexPath;
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0) && ([[[UIDevice currentDevice] systemVersion] doubleValue]< 8.0))
        indexPath = [myTable indexPathForCell:(UITableViewCell*)[[[btn superview] superview] superview]];
    else
        indexPath = [myTable indexPathForCell:(UITableViewCell*)[[btn superview] superview]];
    
    if (indexPath.row == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/tw/app/id779341315"]];
    } else if (indexPath.row == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/tw/app/id893024910"]];
    }
}

#pragma mark - 
#pragma mark - TableView Delegate
-(void)tableView:(UITableView *)tableView expandCell:(UITableViewCell *)cell withIndexPath:(NSIndexPath *)indexPath
{
	[[cell.contentView viewWithTag:TvSynopsisTag] removeFromSuperview];
    UITextView *TvSynopsis = [[UITextView alloc] initWithFrame:CGRectMake(5, 75, 300, 78)];
    TvSynopsis.editable = false;
    TvSynopsis.text = [cellDetailTextView objectAtIndex:indexPath.row];
    TvSynopsis.textColor = [UIColor colorWithRed:90/255.0 green:90/255.0 blue:90/255.0 alpha:1];
    TvSynopsis.backgroundColor = [UIColor whiteColor];
    TvSynopsis.tag = TvSynopsisTag;
	[cell.contentView addSubview:TvSynopsis];

    
    [[cell.contentView viewWithTag:TvSynopsisPart2Tag] removeFromSuperview];
    UITextView *TvSynopsisPart2 = [[UITextView alloc] initWithFrame:CGRectMake(5, 165, 300, 105)];
    TvSynopsisPart2.editable = false;
    TvSynopsisPart2.text = [cellDetail2TextView objectAtIndex:indexPath.row];
    TvSynopsisPart2.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    TvSynopsisPart2.tag = TvSynopsisPart2Tag;
    //設定邊框粗細
    [[TvSynopsisPart2 layer] setBorderWidth:1.0];
    //邊框顏色
    [[TvSynopsisPart2 layer] setBorderColor:[UIColor clearColor].CGColor];
    //將超出邊框的部份做遮罩
    [[TvSynopsisPart2 layer] setMasksToBounds:YES];
    //設定圓角程度
    [[TvSynopsisPart2 layer] setCornerRadius:5.0];
    [cell.contentView addSubview:TvSynopsisPart2];
    
   	[UIView animateWithDuration:.5 animations:^{
		cell.detailTextLabel.text = [cellDetailTextLabel objectAtIndex:indexPath.row];
		[cell.contentView viewWithTag:expandGlyphTag].transform = CGAffineTransformMakeRotation(3.14);
	}];
}

//perform your collapse stuff (may include animation) for cell here. It will be called when the user touches an expanded cell so it gets collapsed or the table is in the expandOnlyOneCell satate and the user touches another item, So the last expanded item has to collapse
-(void)tableView:(UITableView *)tableView collapseCell:(UITableViewCell *)cell withIndexPath:(NSIndexPath *)indexPath
{
	[[cell.contentView viewWithTag:TvSynopsisTag] removeFromSuperview];
	[[cell.contentView viewWithTag:TvSynopsisPart2Tag] removeFromSuperview];
	[cell.contentView viewWithTag:expandGlyphTag].transform = CGAffineTransformMakeRotation(0);
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [cellTitles count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath isExpanded:(BOOL)isexpanded
{
	//you can define different heights for each cell. (then you probably have to calculate the height or e.g. read pre-calculated heights from an array
	if (isexpanded) {
		return 280;
    }
	return 78;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath isExpanded:(BOOL)isExpanded
{
	static NSString *CellIdentifier = @"aCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		UIImageView* expandGlyph = [[UIImageView alloc] initWithFrame:CGRectMake(280, 20, 15, 10)];
		NSString* bundlePath = [[NSBundle mainBundle] bundlePath];
		expandGlyph.image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", bundlePath, @"expandGlyph.png"]];
		
		expandGlyph.tag = expandGlyphTag;
		[cell.contentView addSubview:expandGlyph];
		cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
		cell.detailTextLabel.numberOfLines = 0;
	}
    
    
	NSString* imageFileName = [cellImages objectAtIndex:indexPath.row];
    UIImageView *CellImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageFileName]];
    CellImage.frame = CGRectMake(5, 5, 65, 65);
    [cell.contentView addSubview:CellImage];
    
	[[cell.contentView viewWithTag:lbTitleTag] removeFromSuperview];
    UILabel *lbTitle = [[UILabel alloc] initWithFrame:CGRectMake(75, 0, 150, 30)];
    lbTitle.text = [cellTitles objectAtIndex:indexPath.row];
    lbTitle.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    lbTitle.adjustsFontSizeToFitWidth = YES;
    lbTitle.tag = lbTitleTag;
    [cell.contentView addSubview:lbTitle];
    
	[[cell.contentView viewWithTag:purchaseButtonTag] removeFromSuperview];
	UIButton *purchaseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	purchaseButton.frame = CGRectMake(((lbTitle.frame.size.width / 2) + lbTitle.frame.origin.x) - 30, 35, 60, 26);
	purchaseButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
	[purchaseButton setTintColor:[UIColor whiteColor]];
	purchaseButton.tag = purchaseButtonTag;
	[cell.contentView addSubview:purchaseButton];
    
    if (indexPath.row == 0)
    {
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb1393938564186680://"]]) {
            NSLog(@"installed");
            [purchaseButton setTitle:@"已安裝" forState:UIControlStateNormal];
            purchaseButton.backgroundColor = [UIColor colorWithRed:79/255.0 green:132/255.0 blue:195/255.0 alpha:1];
        } else {
            NSLog(@"Not installed");
            [purchaseButton setTitle:@"安裝" forState:UIControlStateNormal];
            purchaseButton.backgroundColor = [UIColor colorWithRed:255/255.0 green:0/255.0 blue:0/255.0 alpha:1];
            [purchaseButton addTarget:self action:@selector(DownloadPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    else if (indexPath.row == 1)
    {
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb534109316692962://"]]) {
            NSLog(@"installed");
            [purchaseButton setTitle:@"已安裝" forState:UIControlStateNormal];
            purchaseButton.backgroundColor = [UIColor colorWithRed:79/255.0 green:132/255.0 blue:195/255.0 alpha:1];
        } else {
            NSLog(@"Not installed");
            [purchaseButton setTitle:@"安裝" forState:UIControlStateNormal];
            purchaseButton.backgroundColor = [UIColor colorWithRed:255/255.0 green:0/255.0 blue:0/255.0 alpha:1];
            [purchaseButton addTarget:self action:@selector(DownloadPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
	//alternative background colors for better division ;)
    /*
	NSString* bundlePath = [[NSBundle mainBundle] bundlePath];
	NSString* imageFileName = [cellImages objectAtIndex:indexPath.row];
	cell.textLabel.text = [cellTitles objectAtIndex:indexPath.row];
	cell.imageView.image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", bundlePath, imageFileName]];
     */
//    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 0, 50, 50)];
//    imageView.image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", bundlePath, imageFileName]];
//    [cell.contentView addSubview:imageView];
    
    
	if (!isExpanded) //prepare the cell as if it was collapsed! (without any animation!)
	{
		cell.detailTextLabel.text = @"";
		[cell.contentView viewWithTag:expandGlyphTag].transform = CGAffineTransformMakeRotation(0);
	}
	else ///prepare the cell as if it was expanded! (without any animation!)
	{
		cell.detailTextLabel.text = [cellDetailTextLabel objectAtIndex:indexPath.row];
        //cell.imageView.image = [UIImage imageNamed:[cellExpandedImages objectAtIndex:indexPath.row]];
		[cell.contentView viewWithTag:expandGlyphTag].transform = CGAffineTransformMakeRotation(3.14);
		
        [[cell.contentView viewWithTag:TvSynopsisTag] removeFromSuperview];
        UITextView *TvSynopsis = [[UITextView alloc] initWithFrame:CGRectMake(5, 75, 300, 78)];
        TvSynopsis.editable = false;
        TvSynopsis.textColor = [UIColor colorWithRed:90/255.0 green:90/255.0 blue:90/255.0 alpha:1];
        TvSynopsis.text = [cellDetailTextView objectAtIndex:indexPath.row];
        TvSynopsis.backgroundColor = [UIColor whiteColor];
        TvSynopsis.tag = TvSynopsisTag;
        [cell.contentView addSubview:TvSynopsis];
        
        
        [[cell.contentView viewWithTag:TvSynopsisPart2Tag] removeFromSuperview];
        UITextView *TvSynopsisPart2 = [[UITextView alloc] initWithFrame:CGRectMake(5, 165, 300, 105)];
        TvSynopsisPart2.editable = false;
        TvSynopsisPart2.text = [cellDetail2TextView objectAtIndex:indexPath.row];
        TvSynopsisPart2.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
        TvSynopsisPart2.tag = TvSynopsisPart2Tag;
        //設定邊框粗細
        [[TvSynopsisPart2 layer] setBorderWidth:1.0];
        //邊框顏色
        [[TvSynopsisPart2 layer] setBorderColor:[UIColor clearColor].CGColor];
        //將超出邊框的部份做遮罩
        [[TvSynopsisPart2 layer] setMasksToBounds:YES];
        //設定圓角程度
        [[TvSynopsisPart2 layer] setCornerRadius:5.0];
        [cell.contentView addSubview:TvSynopsisPart2];
	}
	return cell;
}

#pragma mark -
#pragma mark - View Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    mainScreen = [[UIScreen mainScreen] bounds].size;
    
    myTable = [[HVTableView alloc] initWithFrame:CGRectMake(0, 54, mainScreen.width, 209) expandOnlyOneCell:YES enableAutoScroll:YES];
    myTable.HVTableViewDelegate = self;
    myTable.HVTableViewDataSource = self;
    [myTable reloadData];
    [self.view addSubview:myTable];
    
    
    [myTable setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint* myTableWidthCon = [NSLayoutConstraint constraintWithItem:myTable attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:mainScreen.width - 6];
    NSLayoutConstraint* myTableBottomCon = [NSLayoutConstraint constraintWithItem:myTable attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-25];
    NSLayoutConstraint* myTableCenterXCon = [NSLayoutConstraint constraintWithItem:myTable attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    NSLayoutConstraint* myTableTopCon;
    CGSize ScreenSize = [[UIScreen mainScreen] bounds].size;
    if (ScreenSize.height > 480) {
        myTableTopCon = [NSLayoutConstraint constraintWithItem:myTable attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:64];
    } else {
        myTableTopCon = [NSLayoutConstraint constraintWithItem:myTable attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:55];
    }
    [self.view addConstraints:@[myTableBottomCon, myTableCenterXCon, myTableWidthCon, myTableTopCon]];
    
    cellTitles = @[@"CarolOK雲端行動KTV", @"CarolOK錄音室"];
    cellImages = @[@"CarolIcon.png", @"Carolok錄音室icon.png"];
    //cellExpandedImages = @[@"CarolIcon2.png", @"錄音室icon2.png"];
    cellDetailTextLabel = nil;
    cellDetailTextView = @[@"功能簡介：\n1.合法授權的影音伴唱檔案，每月更新歌單\n2.聲道分離功能，獨立調整原聲、背景、麥克風聲音\n3.聲音優化去除多餘的雜音\n4.三段式迴音選擇，歌聲更佳動人具臨場感\n5.同步錄音功能，可將錄音檔上傳網路分享\n6.搭配CAROL KTV麥克風轉接器，就變成行動伴唱機\n", @"功能簡介：\n1.具備直接錄音、四聲軌混音、影音合成三項功能\n2.針對收音品質進行調校，錄製效果更好\n3.混音來源可來自於直接錄音或是手持設備的檔案\n4.影音合成可幫錄影檔配樂，豐富影音內容\n5.配合CAROL動圈式麥克風轉接器錄音品質更精純"];
    cellDetail2TextView = @[@"說明：\nCarolOK雲端行動KTV是一個具有合法影音授權的KTV APP，每個月更新線上歌曲，提供線上盡情歡唱。影音動畫更接近專業KTV的播放效果，滿足視覺與聽覺上的雙重享受。\n\n搭配佳樂CAROL佳樂電子「KTV麥克風轉換器」，可以使用KTV專業級的動圈式麥克風歌唱，效果比使用耳麥式麥克風更好，同時歌唱聲音可以同步透過外接喇叭播出，娛樂效果更貼近KTV與點唱機，但是卻只需支付更低廉的費用。\n\n比起KTV單純的唱歌以外，CarolOK雲端行動KTV可以同步錄音，使用專業級的麥克風所錄製的效果，比使用耳麥式的麥克風更細緻，如同在專業錄音室的演唱，所錄製的檔案可以上傳到Yuotube與好友們一起分享，當然也可設定為不公開，或編輯成自己的專輯。", @"說明：\nCarolOK錄音室是一款提供直接錄音、四音軌混音與影音合成三項功能，且相當有趣的小APP，豐富的聲音玩樂功能，搭配不同的素材，可以玩出不同的效果。\n\n直接錄音功能可選擇CAROL佳樂電子所生產的動圈式麥克風轉接器，讓手持裝置可以使用動圈式麥克風進行收音，CAROL佳樂電子具有各式各樣高品質的麥克風，無論是人聲、樂器、舞蹈等，CAROL均有對應的麥克風可供選用，CarolOK錄音室特別針對收音品質進行調校，過濾收錄的聲音雜訊，比使用耳麥所錄製更接近原來的聲音。\n\n四聲道音軌可選擇聲音來源，不管是自行錄音的檔案，或是存放於手持裝置內的聲音檔案，均可匯入進行混音，每一個音軌都提供獨立的音量調整與暫停按鍵，可變化出無窮的聲音效果，可做不同的應用，例如錄製個人廣播節目、廣告帶、聲音卡片等，讓生活聲音更加豐富。\n\n影音合成提供相當便利的方式，只要導入影片檔與聲音檔，即可以進行合成，可將單調的生活錄影檔加上動人的配樂，也可為影片加上人聲解說，只要在平凡單調的錄影檔加入一點點的配樂或聲音，立刻就能達到畫龍點睛的效果，重要的是，不需要使用太複雜的軟體，當然如果選用CAROL佳樂電子的動圈式麥克風轉換器，就可以錄得更精純的聲音來源，有效降低所合成檔案的雜音。"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //-----監聽回到前台的時候-----
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:NULL];
}

- (void)viewDidDisappear:(BOOL)animated
{
    //-----移除監聽回到前台的時候-----
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - screen control
//- (BOOL)shouldAutorotate {
//    return NO;
//}
//
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    return UIInterfaceOrientationLandscapeRight;
//}


#pragma mark -
#pragma mark - MySubCode
- (void)applicationWillEnterForeground
{
    [myTable reloadData];
}

@end
