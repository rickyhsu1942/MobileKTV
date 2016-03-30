//
//  ForgetPasswordViewController.m
//  carolAPPs
//
//  Created by iscom on 13/6/24.
//
//

#import "ForgetPasswordViewController.h"
#import "ASIHttpMethod.h"

@interface ForgetPasswordViewController () <UITextFieldDelegate>
{
    ASIHttpMethod *httpmethod;
}

@property (weak, nonatomic) IBOutlet UITextField *txtAccount;
@property (weak, nonatomic) IBOutlet UILabel *lbErrorAccount;
@end

@implementation ForgetPasswordViewController
@synthesize txtAccount;
@synthesize lbErrorAccount;

#pragma mark -
#pragma mark IBAction
- (IBAction)Exit:(id)sender {
    
    [txtAccount resignFirstResponder];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissForgetPasswordView:)]) {
        [self.delegate dismissForgetPasswordView:self];
    }
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

- (IBAction)Send:(id)sender {
    if ([txtAccount.text length] <=0 ||
        [lbErrorAccount alpha] == 1) {
        [self showAlertMessage:@"訊息" withTitle:@"帳號格式錯誤，請重新輸入" buttonText:@"了解"];
        return;
    }
    
    [txtAccount resignFirstResponder];
    
    NSString *HttpResult = [httpmethod ForgetPasswdToServerByEmail:txtAccount.text];
    NSArray *arrayHttpResult = [HttpResult componentsSeparatedByString:@"\n"];
    if ([arrayHttpResult count] >= 2) {
        [self showAlertMessage:[arrayHttpResult objectAtIndex:1] withTitle:@"訊息" buttonText:@"了解"];
        if ([[[arrayHttpResult objectAtIndex:0] substringToIndex:4] isEqualToString:@"succ"]) {
            [txtAccount resignFirstResponder];
            if (self.delegate && [self.delegate respondsToSelector:@selector(dismissForgetPasswordView:)]) {
                [self.delegate dismissForgetPasswordView:self];
            }
        }
    }
}

#pragma mark -
#pragma mark - TextField Delegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 50,
                                 self.view.frame.size.width, self.view.frame.size.height);
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 50,
                                 self.view.frame.size.width, self.view.frame.size.height);
    [UIView commitAnimations];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark subCode
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
#pragma mark viewDidLoad
- (void)viewDidLoad
{
    [super viewDidLoad];
    //-----初始化-----
    httpmethod = [[ASIHttpMethod alloc] init];
    //-----委託------
    txtAccount.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [self setTxtAccount:nil];
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
