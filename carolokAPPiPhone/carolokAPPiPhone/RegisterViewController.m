//
//  RegisterViewController.m
//  carolAPPs
//
//  Created by iscom on 13/7/1.
//
//

#import "RegisterViewController.h"
#import "SQLiteDBTool.h"
#import "ASIHttpMethod.h"

@interface RegisterViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>
{
    NSMutableArray *AryPicker;
    NSArray *AryAreaPost;
    short selectItem,SexRow;
    
    int ViewPickerOriginalY;
    
    ASIHttpMethod *httpmethod;
    SQLiteDBTool *database;
}

@property (weak, nonatomic) IBOutlet UITextField *txtAccount;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtPasswordConfirm;
@property (weak, nonatomic) IBOutlet UITextField *txtName;
@property (weak, nonatomic) IBOutlet UILabel *lbSex;
@property (weak, nonatomic) IBOutlet UIPickerView *PickerView;
@property (weak, nonatomic) IBOutlet UIView *ViewPicker;
@property (weak, nonatomic) IBOutlet UILabel *lbErrorPasswordConfirm;
@property (weak, nonatomic) IBOutlet UILabel *lbErrorAccount;
@end

@implementation RegisterViewController
@synthesize txtAccount,txtName,txtPassword,txtPasswordConfirm;
@synthesize lbSex,lbErrorPasswordConfirm,lbErrorAccount;
@synthesize PickerView,ViewPicker;


- (IBAction)textBack:(id)sender {
}

#pragma mark -
#pragma mark IBAction
- (IBAction)SelectSex:(id)sender {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    ViewPicker.frame = CGRectMake(0, ViewPickerOriginalY, ViewPicker.frame.size.width , ViewPicker.frame.size.height);
    // 定義Picker顯示種類(性別、縣市、鄉鎮市區)
    selectItem = 1;
    // 顯示Picker陣列
    [AryPicker removeAllObjects];
    [AryPicker addObject:@"男"];
    [AryPicker addObject:@"女"];
    // 更新Picker內容
    PickerView.dataSource = self;
    // 顯示起始位置
    [PickerView selectRow:SexRow inComponent:0 animated:YES];
    [UIView commitAnimations];
}

- (IBAction)Send:(id)sender {
    if ([txtAccount.text length] <= 0 ||
        [txtName.text length] <= 0 ||
        [txtPassword.text length] <= 0 ||
        [txtPasswordConfirm.text length] <=0) {
        [self showAlertMessage:@"尚有欄位未填" withTitle:@"訊息" buttonText:@"了解"];
        return;
    } else if (lbErrorAccount.alpha == 1) {
        [self showAlertMessage:@"訊息" withTitle:@"帳號格式錯誤，請重新輸入" buttonText:@"了解"];
        return;
    } else if (lbErrorPasswordConfirm.alpha == 1 ||
               [txtPassword.text compare:txtPasswordConfirm.text] != NSOrderedSame) {
        [self showAlertMessage:@"訊息" withTitle:@"密碼不一致，請重新輸入" buttonText:@"了解"];
        return;
    }
    NSString *HttpResult;
    if ([lbSex.text isEqualToString:@"男"]) {
        HttpResult = [httpmethod RegisterServerwithAccount:txtAccount.text Password:txtPassword.text NickName:txtName.text Sex:@"0"];
    } else if ([lbSex.text isEqualToString:@"女"]) {
        HttpResult = [httpmethod RegisterServerwithAccount:txtAccount.text Password:txtPassword.text NickName:txtName.text Sex:@"1"];
    }
    
    if ([HttpResult isEqualToString:@""]) {
        [self showAlertMessage:@"訊息" withTitle:@"網路傳輸失敗" buttonText:@"了解"];
        return;
    }
    
    NSArray *arrayHttpResult = [HttpResult componentsSeparatedByString:@"\n"];
    if ([arrayHttpResult count] >= 2) {
        [self showAlertMessage:[arrayHttpResult objectAtIndex:1] withTitle:@"訊息" buttonText:@"了解"];
        if ([[[arrayHttpResult objectAtIndex:0] substringToIndex:4] isEqualToString:@"succ"]) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    
}
- (IBAction)HidePickerView:(id)sender {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    ViewPicker.frame = CGRectMake(0, ViewPickerOriginalY + ViewPicker.frame.size.height, ViewPicker.frame.size.width , ViewPicker.frame.size.height);
    [UIView commitAnimations];
}

- (IBAction)PasswordCheck:(id)sender {
    // 判斷密碼與重復密碼是否一樣
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    if ([txtPassword.text compare:txtPasswordConfirm.text] != NSOrderedSame) {
        [lbErrorPasswordConfirm setAlpha:1];
    } else {
        [lbErrorPasswordConfirm setAlpha:0];
    }
    [UIView commitAnimations];
}
- (IBAction)AccountCheck:(id)sender {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    if ([self NSStringIsValidEmail:txtAccount.text]) {
        [lbErrorAccount setAlpha:0];
    } else {
        [lbErrorAccount setAlpha:1];
    }
    [UIView commitAnimations];
}

-(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}
#pragma mark -
#pragma mark PickerDelegate
//內建的函式回傳UIPicker共有幾組選項
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

//內建的函式回傳UIPicker每組選項的項目數目
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    //第一組選項由0開始
    switch (component) {
        case 0:
            return [AryPicker count];
            break;
            //如果有一組以上的選項就在這裡以component的值來區分（以本程式碼為例default:永遠不可能被執行
        default:
            return 0;
            break;
    }
}

//內建函式印出字串在Picker上以免出現"?"
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch (component) {
        case 0:
            return [AryPicker objectAtIndex:row];
            break;
            //如果有一組以上的選項就在這裡以component的值來區分（以本程式碼為例default:永遠不可能被執行）
        default:
            return @"Error";
            break;
    }
}

//選擇UIPickView中的項目時會出發的內建函式
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    switch (selectItem) {
        case 1:   //性別
            lbSex.text = [NSString stringWithFormat:@"%@",[AryPicker objectAtIndex:row]];
            // 讓點選「性別」時，picker知道預設位置
            SexRow = row;
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark - TextField Delegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark viewDidLoad
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0) && ([[[UIDevice currentDevice] systemVersion] doubleValue]< 8.0))
        ViewPickerOriginalY = [[UIScreen mainScreen] bounds].size.height - ViewPicker.frame.size.height;
    else
        ViewPickerOriginalY = [[UIScreen mainScreen] bounds].size.height - ViewPicker.frame.size.height - 44;
    
    // 隱藏PickerView
    ViewPicker.frame = CGRectMake(0, ViewPickerOriginalY + ViewPicker.frame.size.height, ViewPicker.frame.size.width , ViewPicker.frame.size.height);
    // 代理PickerView內建函式
    PickerView.delegate = self;
    // 初始化
    database = [[SQLiteDBTool alloc] init];
    httpmethod = [[ASIHttpMethod alloc] init];
    AryPicker = [[NSMutableArray alloc] init];
    SexRow = 0;
    
    // 委託
    txtAccount.delegate = self;
    txtName.delegate = self;
    txtPassword.delegate = self;
    txtPasswordConfirm.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [self setTxtAccount:nil];
    [self setTxtPassword:nil];
    [self setTxtPasswordConfirm:nil];
    [self setTxtName:nil];
    [self setLbSex:nil];
    [self setPickerView:nil];
    [self setViewPicker:nil];
    [self setLbErrorPasswordConfirm:nil];
    [self setLbErrorAccount:nil];
    [super viewDidUnload];
}
#pragma mark -
#pragma mark Display message
-(void) showAlertMessage:(NSString *) message withTitle:(NSString *)title buttonText:(NSString *) btnCancelText {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: title
                          message:message
                          delegate:nil
                          cancelButtonTitle: btnCancelText
                          otherButtonTitles: nil];
    [alert show];
}
@end
