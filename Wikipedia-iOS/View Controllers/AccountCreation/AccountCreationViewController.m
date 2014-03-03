//  Created by Monte Hurd on 2/21/14.

#import "AccountCreationViewController.h"
#import "NavController.h"
#import "QueuesSingleton.h"
#import "SessionSingleton.h"
#import "UIViewController+Alert.h"
#import "AccountCreationOp.h"
#import "CaptchaResetOp.h"
#import "UIScrollView+ScrollSubviewToLocation.h"
#import "UIButton+ColorMask.h"

#define NAV ((NavController *)self.navigationController)

@interface AccountCreationViewController ()

@property (nonatomic) BOOL showCaptchaContainer;
@property (strong, nonatomic) CaptchaViewController *captchaViewController;

@property (strong, nonatomic) NSString *captchaId;
@property (strong, nonatomic) NSString *captchaUrl;
@property (strong, nonatomic) NSString *token;

@end

@implementation AccountCreationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.captchaId = @"";
    self.captchaUrl = @"";
    self.token = @"";
    
    self.navigationItem.hidesBackButton = YES;
    
    [self.usernameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [self.passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [self.passwordRepeatField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [self.emailField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.showCaptchaContainer = NO;

    NAV.navBarMode = NAVBAR_MODE_CREATE_ACCOUNT;
    
    [self highlightCheckButton:NO];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(navItemTappedNotification:) name:@"NavItemTapped" object:nil];
    
    [self.usernameField becomeFirstResponder];

    //[self prepopulateTextFieldsForDebugging];
}

-(void)textFieldDidChange:(id)sender
{
    BOOL shouldHighlight = (
        (self.usernameField.text.length > 0) &&
        (self.passwordField.text.length > 0) &&
        (self.passwordRepeatField.text.length > 0) &&
        //(self.emailField.text.length > 0) &&
        [self.passwordField.text isEqualToString:self.passwordRepeatField.text]
    ) ? YES : NO;
    
    [self highlightCheckButton:shouldHighlight];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    }else if(textField == self.passwordField) {
        [self.passwordRepeatField becomeFirstResponder];
    }else if(textField == self.passwordRepeatField) {
        [self.emailField becomeFirstResponder];
    }else if(textField == self.emailField) {
        [self.realnameField becomeFirstResponder];
    }else if((textField == self.realnameField) || (textField == self.captchaViewController.captchaTextBox)) {
        [self save];
    }
    return YES;
}

-(void)highlightCheckButton:(BOOL)highlight
{
    UIButton *checkButton = (UIButton *)[NAV getNavBarItem:NAVBAR_BUTTON_CHECK];
    
    checkButton.backgroundColor = highlight ?
        [UIColor colorWithRed:0.00 green:0.51 blue:0.96 alpha:1.0]
        :
        [UIColor clearColor];
    
    [checkButton maskButtonImageWithColor: highlight ?
        [UIColor whiteColor]
        :
        [UIColor blackColor]
     ];
}

-(void)prepopulateTextFieldsForDebugging
{
    self.usernameField.text = @"acct_creation_test_010";
    self.passwordField.text = @"";
    self.passwordRepeatField.text = @"";
    self.realnameField.text = @"monte hurd";
    self.emailField.text = @"mhurd@wikimedia.org";
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NavItemTapped" object:nil];

    NAV.navBarMode = NAVBAR_MODE_SEARCH;

    [self highlightCheckButton:NO];

    [super viewWillDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString: @"AccountCreation_Captcha_Embed"]) {
		self.captchaViewController = (CaptchaViewController *) [segue destinationViewController];
	}
}

-(void)setShowCaptchaContainer:(BOOL)showCaptchaContainer
{
    self.captchaContainer.hidden = !showCaptchaContainer;
    if (_showCaptchaContainer != showCaptchaContainer) {
        _showCaptchaContainer = showCaptchaContainer;
        if (showCaptchaContainer){
            [self.captchaViewController.captchaTextBox performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4f];
        }
    }
}

-(void)setCaptchaUrl:(NSString *)captchaUrl
{
    if (![_captchaUrl isEqualToString:captchaUrl]) {
        _captchaUrl = captchaUrl;
        if (captchaUrl && (captchaUrl.length > 0)) {
            [self refreshCaptchaImage];
        }
    }
}

-(void)refreshCaptchaImage
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        // Background thread
        NSURL *captchaImageUrl = [NSURL URLWithString:
                                  [NSString stringWithFormat:@"https://%@.m.%@%@",
                                   [SessionSingleton sharedInstance].domain,
                                   [SessionSingleton sharedInstance].site,
                                   self.captchaUrl
                                   ]
                                  ];
        
        UIImage *captchaImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:captchaImageUrl]];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            // Main thread
            self.captchaViewController.captchaTextBox.text = @"";
            self.captchaViewController.captchaImageView.image = captchaImage;
            [self.scrollView scrollSubViewToTop:self.captchaContainer];
            //[self highlightCheckButton:NO];
        });
    });
}

- (void)reloadCaptchaPushed:(id)sender
{
    self.captchaViewController.captchaTextBox.text = @"";

    [self showAlert:@"Obtaining a new captcha."];
    [self showAlert:@""];

    CaptchaResetOp *captchaResetOp =
    [[CaptchaResetOp alloc] initWithDomain: [SessionSingleton sharedInstance].domain
                           completionBlock: ^(NSDictionary *result){
                               
                               self.captchaId = result[@"index"];
                               
                               NSString *oldCaptchaUrl = self.captchaUrl;
                               
                               NSError *error = nil;
                               NSRegularExpression *regex =
                               [NSRegularExpression regularExpressionWithPattern: @"wpCaptchaId=([^&]*)"
                                                                         options: NSRegularExpressionCaseInsensitive
                                                                           error: &error];
                               if (!error) {
                                   NSString *newCaptchaUrl =
                                   [regex stringByReplacingMatchesInString: oldCaptchaUrl
                                                                   options: 0
                                                                     range: NSMakeRange(0, [oldCaptchaUrl length])
                                                              withTemplate: [NSString stringWithFormat:@"wpCaptchaId=%@", self.captchaId]];
                                   
                                   self.captchaUrl = newCaptchaUrl;
                               }
                               
                           } cancelledBlock: ^(NSError *error){
                               
                               [self showAlert:@""];
                               
                           } errorBlock: ^(NSError *error){
                               [self showAlert:error.localizedDescription];
                               
                           }];
    
    captchaResetOp.delegate = self;

    [[QueuesSingleton sharedInstance].accountCreationQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].accountCreationQ addOperation:captchaResetOp];
}

// Handle nav bar taps.
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_CHECK:
            [self save];
            break;
        case NAVBAR_BUTTON_ARROW_LEFT:
            [self hide];
            break;
        default:
            break;
    }
}

-(void)save
{
    static BOOL isAleadySaving = NO;
    if (isAleadySaving) return;
    isAleadySaving = YES;

    // Verify passwords fields match.
    if (![self.passwordField.text isEqualToString:self.passwordRepeatField.text]) {
        [self showAlert:@"Password fields do not match."];
        isAleadySaving = NO;
        return;
    }

    // Save!
    [self showAlert:@"Saving..."];

    AccountCreationOp *accountCreationOp =
    [[AccountCreationOp alloc] initWithDomain: [SessionSingleton sharedInstance].domain
                                     userName: self.usernameField.text
                                     password: self.passwordField.text
                                     realName: self.realnameField.text
                                        email: self.emailField.text
                                        token: self.token
                                    captchaId: self.captchaId
                                  captchaWord: self.captchaViewController.captchaTextBox.text
     
                              completionBlock: ^(NSString *result){
                                  
                                  //NSLog(@"AccountCreationOp result = %@", result);
                                  
                                  dispatch_async(dispatch_get_main_queue(), ^(){
                                      [self showAlert:result];
                                      [self showAlert:@""];
                                      [self performSelector:@selector(hide) withObject:nil afterDelay:1.0f];
                                      isAleadySaving = NO;
                                  });
                                  
                              } cancelledBlock: ^(NSError *error){
                                  
                                  [self showAlert:@""];
                                  isAleadySaving = NO;
                                  
                              } errorBlock: ^(NSError *error){
                                  [self showAlert:error.localizedDescription];
                                  
                                  if (error.code == ACCOUNT_CREATION_ERROR_NEEDS_TOKEN) {
                                      self.captchaId = error.userInfo[@"captchaId"];
                                      self.token = error.userInfo[@"token"];
                                      
                                      dispatch_async(dispatch_get_main_queue(), ^(){
                                          self.captchaUrl = error.userInfo[@"captchaUrl"];
                                          self.showCaptchaContainer = YES;
                                      });
                                  }
                                  isAleadySaving = NO;
                              }];

    accountCreationOp.delegate = self;

    [[QueuesSingleton sharedInstance].accountCreationQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].accountCreationQ addOperation:accountCreationOp];
}

-(void)hide
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
