
#import "WMFWelcomeAnalyticsViewController.h"
#import "Wikipedia-Swift.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"

@import HockeySDK;

@interface WMFWelcomeAnalyticsViewController ()
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* subTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel* toggleLabel;
@property (strong, nonatomic) IBOutlet UIView* dividerAboveNextStepButton;
@property (strong, nonatomic) IBOutlet UIButton* nextStepButton;
@property (strong, nonatomic) IBOutlet UISwitch* toggle;
@property (strong, nonatomic) IBOutlet UIButton* buttonCaretLeft;

@end

@implementation WMFWelcomeAnalyticsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleLabel.text  = [MWLocalizedString(@"welcome-volunteer-title", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.subTitleLabel.text = MWLocalizedString(@"welcome-volunteer-sub-title", nil);
    self.toggleLabel.text = MWLocalizedString(@"welcome-volunteer-send-usage-reports", nil);
    [self updateNextStepButtonStyleForUsageReportsIsOn:NO];

    //Set state of the toggle. Also make sure crash manager setting is in sync with this setting - likely to happen on first launch or for previous users.
    if ([[NSUserDefaults standardUserDefaults] wmf_sendUsageReports]) {
        self.toggle.on                                                           = YES;
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAutoSend;
    } else {
        self.toggle.on                                                           = NO;
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;
    }

    [self.buttonCaretLeft setTintColor:[UIColor wmf_blueTintColor]];
    [self.buttonCaretLeft wmf_setButtonType:WMFButtonTypeCaretLeft];
}

- (IBAction)toggleAnalytics:(UISwitch*)sender {
    if ([sender isOn]) {
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAutoSend;
        [[NSUserDefaults standardUserDefaults] wmf_setSendUsageReports:YES];
    } else {
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;
        [[NSUserDefaults standardUserDefaults] wmf_setSendUsageReports:NO];
    }
    [self updateNextStepButtonStyleForUsageReportsIsOn:[sender isOn]];
}

- (IBAction)showPrivacyPolicy:(id)sender {
    [self wmf_openExternalUrl:[NSURL URLWithString:URL_PRIVACY_POLICY]];
}

-(void)updateNextStepButtonStyleForUsageReportsIsOn:(BOOL)isOn {
    NSString* buttonTitle = isOn ? [MWLocalizedString(@"welcome-volunteer-thanks-button", nil) stringByReplacingOccurrencesOfString:@"$1" withString:@"😀"] : MWLocalizedString(@"welcome-volunteer-continue-button", nil);

    [self.nextStepButton setTitle:[buttonTitle uppercaseStringWithLocale:[NSLocale currentLocale]]
                         forState:UIControlStateNormal];
    
    self.nextStepButton.backgroundColor = isOn ? [UIColor wmf_welcomeThanksButtonBackgroundColor] : [UIColor wmf_welcomeNextButtonBackgroundColor];
    
    [self.nextStepButton setTitleColor:(isOn ? [UIColor wmf_green] : [UIColor wmf_blueTintColor]) forState:UIControlStateNormal];
    
    self.dividerAboveNextStepButton.backgroundColor = isOn ? [UIColor wmf_welcomeThanksButtonDividerBackgroundColor] : [UIColor wmf_welcomeNextButtonDividerBackgroundColor];
}

@end
