//
//  SaveStudioAlertViewController.m
//  carolAPPs
//
//  Created by iscom on 13/4/17.
//
//

#import "SaveStudioAlertViewController.h"
#import "GlobalData.h"
#import "SQLiteDBTool.h"


@interface SaveStudioAlertViewController () <UITextFieldDelegate>
{
    SQLiteDBTool *database;
}

@property (weak, nonatomic) IBOutlet UITextField *txtProductName;
@property (weak, nonatomic) IBOutlet UITextField *txtPrducer;
@end

@implementation SaveStudioAlertViewController
@synthesize aProduction,SourceMachine;
@synthesize txtPrducer,txtProductName;
@synthesize CheckMicDelegate;


#pragma mark -
#pragma mark IBAction
- (IBAction)Back:(id)sender {
    if ([SourceMachine isEqualToString:@"Recording"]) {
        [CheckMicDelegate SavingDidEnd:YES];
    }
    else if ([SourceMachine isEqualToString:@"Mixer"]) {
        [CheckMicDelegate GiveupSaving];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissSavingView:)]) {
        [self.delegate dismissSavingView:self];
    }
}

- (IBAction)Saving:(id)sender {
    
    [self.txtPrducer resignFirstResponder];
    [self.txtProductName resignFirstResponder];
    
    if ([SourceMachine isEqualToString:@"Recording"]) {
        [CheckMicDelegate SavingDidEnd:NO];
    }
    NSString *FileNameExtension;
    if ([SourceMachine isEqualToString:@"AVMixer"]) {
        FileNameExtension = @"mp4";
    } else {
        FileNameExtension = @"caf";
    }
    //取得輸入檔案名稱
    NSString *rename;
    NSString *renameProducer;
    BOOL DefaultName;
    GlobalData *globalItem = [GlobalData getInstance];
    if ([txtPrducer.text compare:@""] == NSOrderedSame) {
        if ([globalItem.UserID isEqualToString:@"-2"])
            renameProducer = @"未知歌手";
        else
            renameProducer = globalItem.UserNickname;
    }
    else {
        renameProducer = txtPrducer.text;
    }
    
    if ([txtProductName.text compare:@""] == NSOrderedSame) {
        rename = aProduction.ProductName;
    }
    else {
        if (txtProductName.text.length >= 4) {
            if ([[txtProductName.text substringFromIndex:txtProductName.text.length - 4] isEqualToString:[NSString stringWithFormat:@".%@",FileNameExtension]]) {
                rename = txtProductName.text;
            } else {
                rename = [NSString stringWithFormat:@"%@.%@", txtProductName.text,FileNameExtension];
            }
        } else {
            rename = [NSString stringWithFormat:@"%@.%@", txtProductName.text,FileNameExtension];
        }
    }
    
    // 判斷是否為預設名稱
    if ([aProduction.ProductName isEqualToString:rename])
        DefaultName = YES;
    else
        DefaultName = NO;
    
    // 來源為AVMixer不用判斷預設名稱
    if ([SourceMachine isEqualToString:@"AVMixer"])
        DefaultName = NO;
    
    // 檢測自定名稱是否有重復
    NSError *error;
    NSFileManager *manger = [NSFileManager defaultManager];
    NSString *reFileName = [rename substringToIndex:rename.length - 4];
    NSString *oldPath = aProduction.ProductPath;
    NSString *newPath = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:rename];
    //if file exist at new path, appending number
    NSInteger count = 0;
    if (!DefaultName) {
        while ([manger fileExistsAtPath:newPath])
        {
            count++;
            rename = [NSString stringWithFormat:@"%@(%d).%@", reFileName, count,FileNameExtension];
            newPath = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:rename];
        }
        if ([manger fileExistsAtPath:oldPath]) {
            [manger moveItemAtPath:oldPath
                            toPath:newPath
                             error:&error];
            NSLog(@"%@>>>%@", oldPath, newPath);
        };
    }
    aProduction.ProductPath = newPath;
    aProduction.ProductName = rename;
    aProduction.userID = globalItem.UserID;
    NSLog(@"%@",renameProducer);
    aProduction.Producer = renameProducer;
    [database addSongToMyProductionWithProduction:aProduction];
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"訊息"
                                                    message:@"已儲存成功"
                                                   delegate:self
                                          cancelButtonTitle:@"了解"
                                          otherButtonTitles:nil];
    [alert show];
    
}

#pragma mark -
#pragma mark - Textfield Delegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark viewDidLoad
- (void)viewDidLoad
{
    [super viewDidLoad];
    database = [[SQLiteDBTool alloc] init];
    GlobalData *globalItem = [GlobalData getInstance];
    
    // 預設作品名稱與製作人顯示
    txtPrducer.text = globalItem.UserNickname;
    txtProductName.text = aProduction.ProductName;
    
    //-----繼承UITextfile方法-----
    txtProductName.delegate = self;
    txtPrducer.delegate = self;
    
    NSAttributedString *FileNamePlaceholder = [[NSAttributedString alloc] initWithString:@"輸入影音名稱" attributes:@{ NSForegroundColorAttributeName :[UIColor darkGrayColor]}];
    NSAttributedString *ProducerPlaceholder = [[NSAttributedString alloc] initWithString:@"輸入影音製作人姓名" attributes:@{ NSForegroundColorAttributeName :[UIColor darkGrayColor]}];
    txtPrducer.attributedPlaceholder = FileNamePlaceholder;
    txtProductName.attributedPlaceholder = ProducerPlaceholder;
}

- (void)viewDidUnload {
    [self setTxtProductName:nil];
    [self setTxtPrducer:nil];
    [super viewDidUnload];
}

-(void)viewDidDisappear:(BOOL)animated {
    if (![SourceMachine isEqualToString:@"AVMixer"]) {
        [CheckMicDelegate AutoCheckMic];
    }
}

#pragma mark -
#pragma mark Alert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (0 == buttonIndex) {
        if ([SourceMachine isEqualToString:@"Mixer"]) {
            [CheckMicDelegate DoneSaving];
        } else if ([SourceMachine isEqualToString:@"AVMixer"]) {
            [CheckMicDelegate DoneSavingAndGetSongPath:aProduction.ProductPath];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(dismissSavingView:)]) {
            [self.delegate dismissSavingView:self];
        }
    }
}
@end
