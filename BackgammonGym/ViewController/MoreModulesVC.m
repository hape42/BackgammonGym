//
//  MoreModulesVC.m
//  BackgammonGym
//

#import "MoreModulesVC.h"
#import "UIViewController+BGGHomeButton.h"
#import "BGGLocalization.h"
#import <MessageUI/MessageUI.h>

static NSString * const kGitHubURL =
    @"https://github.com/hape42/BackgammonGym/discussions";
static NSString * const kContactEmail = @"BackgammonGym@hape42.de";

@interface MoreModulesVC () <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView       *contentView;

@end

@implementation MoreModulesVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = BGGLocalizedString(@"More modules");
    [self installHomeButton];
    [self setupScrollView];
    [self buildContent];
}

#pragma mark - Scaffolding

- (void)setupScrollView
{
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor      constraintEqualToAnchor:safe.topAnchor],
        [self.scrollView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.scrollView.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],

        [self.contentView.topAnchor      constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor  constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor   constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor    constraintEqualToAnchor:self.scrollView.widthAnchor],
    ]];
}

#pragma mark - Content

- (void)buildContent
{
    // Headline + body paragraphs, then the two action buttons.
    UILabel *headline = [self headlineLabel:
        BGGLocalizedString(@"A community project")];

    UILabel *body = [self bodyLabel:
        BGGLocalizedString(@"moremodules.body")];

    UIButton *emailButton =
        [self filledButton:BGGLocalizedString(@"Email us")
                    action:@selector(emailTapped)];
    UIButton *githubButton =
        [self tintedButton:BGGLocalizedString(@"Open GitHub Discussions")
                    action:@selector(githubTapped)];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        headline, body, emailButton, githubButton
    ]];
    stack.axis    = UILayoutConstraintAxisVertical;
    stack.spacing = 16.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [stack setCustomSpacing:28.0 afterView:body];
    [stack setCustomSpacing:12.0 afterView:emailButton];
    [self.contentView addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor constant:24.0],
        [stack.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:24.0],
        [stack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24.0],
        [stack.bottomAnchor   constraintEqualToAnchor:self.contentView.bottomAnchor constant:-32.0],
    ]];
}

#pragma mark - Actions

- (void)emailTapped
{
    if (![MFMailComposeViewController canSendMail])
    {
        [self githubTapped];   // no mail account: fall back to GitHub
        return;
    }
    MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
    mail.mailComposeDelegate = self;
    [mail setToRecipients:@[kContactEmail]];
    [mail setSubject:@"Backgammon Gym – Feedback"];
    [self presentViewController:mail animated:YES completion:nil];
}

- (void)githubTapped
{
    NSURL *url = [NSURL URLWithString:kGitHubURL];
    if (url != nil)
    {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Builders

- (UILabel *)headlineLabel:(NSString *)text
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text          = text;
    lbl.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    lbl.adjustsFontForContentSizeCategory = YES;
    lbl.numberOfLines = 0;
    return lbl;
}

- (UILabel *)bodyLabel:(NSString *)text
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text          = text;
    lbl.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    lbl.adjustsFontForContentSizeCategory = YES;
    lbl.numberOfLines = 0;
    return lbl;
}

- (UIButton *)filledButton:(NSString *)title action:(SEL)action
{
    UIButtonConfiguration *cfg = [UIButtonConfiguration filledButtonConfiguration];
    cfg.title = title;
    cfg.baseBackgroundColor = [UIColor colorNamed:@"AccentColor"];
    cfg.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.configuration = cfg;
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UIButton *)tintedButton:(NSString *)title action:(SEL)action
{
    UIButtonConfiguration *cfg = [UIButtonConfiguration tintedButtonConfiguration];
    cfg.title = title;
    cfg.baseForegroundColor = [UIColor colorNamed:@"AccentColor"];
    cfg.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.configuration = cfg;
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

@end
