//
//  BGGLanguagePickerVC.m
//  BackgammonGym
//

#import "BGGLanguagePickerVC.h"
#import "BGGLanguage.h"
#import "BGGLocalization.h"
#import <MessageUI/MessageUI.h>

static NSString * const kCellID = @"LanguageCell";

// GitHub discussions, where translator volunteers can reach out.
static NSString * const kGitHubDiscussionsURL =
    @"https://github.com/hape42/BackgammonGym/discussions";
static NSString * const kContactEmail = @"BackgammonGym@hape42.de";

@interface BGGLanguagePickerVC () <MFMailComposeViewControllerDelegate>

// Section 0: nil (System) + each available code.
@property (nonatomic, copy) NSArray<NSString *> *selectableRows;   // nil entry = System
// Section 1: planned codes (sorted by display name).
@property (nonatomic, copy) NSArray<NSString *> *plannedRows;

@end

@implementation BGGLanguagePickerVC

- (instancetype)init
{
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = BGGLocalizedString(@"Language");

    // "System" is represented by NSNull so the array can hold the "nil" slot.
    NSMutableArray *selectable = [NSMutableArray arrayWithObject:[NSNull null]];
    [selectable addObjectsFromArray:[BGGLanguage availableLanguageCodes]];
    self.selectableRows = selectable;

    // Planned languages, sorted by their display name.
    self.plannedRows = [[BGGLanguage plannedLanguageCodes]
        sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b)
    {
        return [[BGGLanguage displayNameForLanguageCode:a]
                compare:[BGGLanguage displayNameForLanguageCode:b]];
    }];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellID];
}

#pragma mark - Table data

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == 0) ? (NSInteger)self.selectableRows.count
                          : (NSInteger)self.plannedRows.count;
}

- (nullable NSString *)tableView:(UITableView *)tableView
         titleForHeaderInSection:(NSInteger)section
{
    return (section == 0) ? BGGLocalizedString(@"Language")
                          : BGGLocalizedString(@"Coming soon");
}

- (nullable NSString *)tableView:(UITableView *)tableView
         titleForFooterInSection:(NSInteger)section
{
    if (section == 1)
    {
        return BGGLocalizedString(@"These languages aren't ready yet. "
                                  @"Tap one to learn how to help translate.");
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID
                                                           forIndexPath:indexPath];
    cell.accessoryType        = UITableViewCellAccessoryNone;
    cell.textLabel.textColor  = [UIColor labelColor];
    cell.selectionStyle       = UITableViewCellSelectionStyleDefault;

    if (indexPath.section == 0)
    {
        id entry = self.selectableRows[(NSUInteger)indexPath.row];
        NSString *code = [entry isKindOfClass:[NSString class]] ? entry : nil;

        cell.textLabel.text = (code == nil)
            ? BGGLocalizedString(@"System")
            : [BGGLanguage displayNameForLanguageCode:code];

        // Check the active choice. `language` is nil when following the device.
        NSString *chosen = [BGGLanguage sharedLanguage].language;
        BOOL isCurrent = (code == nil) ? (chosen == nil)
                                       : [code isEqualToString:chosen];
        cell.accessoryType = isCurrent ? UITableViewCellAccessoryCheckmark
                                       : UITableViewCellAccessoryNone;
    }
    else
    {
        NSString *code = self.plannedRows[(NSUInteger)indexPath.row];
        cell.textLabel.text      = [BGGLanguage displayNameForLanguageCode:code];
        cell.textLabel.textColor = [UIColor secondaryLabelColor];   // dim = not ready
    }

    return cell;
}

#pragma mark - Selection

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0)
    {
        id entry = self.selectableRows[(NSUInteger)indexPath.row];
        NSString *code = [entry isKindOfClass:[NSString class]] ? entry : nil;

        // nil sets "follow the device"; a code selects that language.
        [BGGLanguage sharedLanguage].language = code;
        [tableView reloadData];   // move the checkmark
    }
    else
    {
        NSString *code = self.plannedRows[(NSUInteger)indexPath.row];
        [self showComingSoonForLanguageCode:code];
    }
}

#pragma mark - Coming soon

- (void)showComingSoonForLanguageCode:(NSString *)code
{
    NSString *title   = [BGGLanguage displayNameForLanguageCode:code];
    NSString *message = [BGGLanguage comingSoonMessageForLanguageCode:code];

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];

    // Email the maintainer.
    [alert addAction:[UIAlertAction actionWithTitle:@"Email"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a)
    {
        [self composeVolunteerEmailForLanguageCode:code];
    }]];

    // Open GitHub discussions.
    [alert addAction:[UIAlertAction actionWithTitle:@"GitHub Discussion"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a)
    {
        NSURL *url = [NSURL URLWithString:kGitHubDiscussionsURL];
        if (url != nil) { [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil]; }
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Close"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)composeVolunteerEmailForLanguageCode:(NSString *)code
{
    if (![MFMailComposeViewController canSendMail])
    {
        // No mail account: fall back to opening GitHub.
        NSURL *url = [NSURL URLWithString:kGitHubDiscussionsURL];
        if (url != nil) { [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil]; }
        return;
    }

    NSString *name = [BGGLanguage displayNameForLanguageCode:code];
    MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
    mail.mailComposeDelegate = self;
    [mail setToRecipients:@[kContactEmail]];
    [mail setSubject:[NSString stringWithFormat:@"Backgammon Gym – Translation help (%@)", name]];
    [mail setMessageBody:[NSString stringWithFormat:
        @"I'd like to help translate Backgammon Gym into %@.\n\n", name]
                  isHTML:NO];
    [self presentViewController:mail animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
