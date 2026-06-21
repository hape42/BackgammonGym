//
//  StartVC.m
//  BackgammonGym
//
//  Created by Peter Schneider on 28.05.26.
//

#import "StartVC.h"
#import "Tools.h"
#import "BGGStartTile.h"
#import "BGGStartTileCell.h"
#import "BGGBoardState.h"
#import "PipCountVC.h"
#import "SettingsVC.h"
#import "PositionBrowserVC.h"
#import <MessageUI/MessageUI.h>
#import "METVC.h"
#import "StatisticsVC.h"
#import "AchievementsVC.h"
#import "MoreModulesVC.h"
#import "CreditsVC.h"
#import "BGGAchievements.h"
#import "BGGLocalization.h"
#import "BGGLanguage.h"

@interface StartVC () <UICollectionViewDataSource,
                       UICollectionViewDelegate,
                       UICollectionViewDelegateFlowLayout,
                       MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<BGGStartTile *> *tiles;

@end

@implementation StartVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:@"AccentColor"];

    self.view.backgroundColor = [UIColor colorNamed:@"ColorViewBackground"];
    self.title = @"Backgammon Gym";

    UIImage *setupImage = [UIImage systemImageNamed:@"gearshape"];
        
    UIBarButtonItem *setupButton = [[UIBarButtonItem alloc] initWithImage:setupImage
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(setupButtonTapped:)];
    setupButton.tintColor = [UIColor colorNamed:@"AccentColor"];

    self.navigationItem.rightBarButtonItem = setupButton;
    
    [self setupTiles];
    [self setupCollectionView];

    // The Settings sheet (which holds the language picker) can sit over this
    // screen on iPad, so re-localize live when the language changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageDidChange)
                                                 name:BGGLanguageDidChangeNotification
                                               object:nil];

    // On every foreground activation (including first launch), award any
    // achievements that became due – activity-streak ones can fall due just
    // from opening the app on consecutive days, with no workout to trigger a
    // check – and celebrate the newly earned ones while this screen is on top.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkAchievementsOnActivate)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// On rotation (or any size change) the tile sizes depend on the new width,
// so invalidate the flow layout once the new size is in effect. Without this
// the layout keeps the column count from before the rotation.
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> ctx)
    {
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
                                 completion:nil];
}

// Rebuild the tiles with localized text and reload the grid.
- (void)languageDidChange
{
    self.title = @"Backgammon Gym";   // a proper noun, stays as-is
    [self setupTiles];
    [self.collectionView reloadData];
}

#pragma mark - Achievement check on activation

- (void)checkAchievementsOnActivate
{
    NSArray<BGGAchievementDefinition *> *newlyEarned =
        [[BGGAchievements sharedAchievements] checkAndAwardForModule:nil];
    if (newlyEarned.count == 0) { return; }

    // Only celebrate while the start screen is actually on top – otherwise an
    // alert would barge in over a workout the user returned to. presentedVC
    // being nil means nothing is shown over us; navigationController.topVC
    // being self means no module is pushed.
    if (self.presentedViewController != nil) { return; }
    if (self.navigationController != nil &&
        self.navigationController.topViewController != self) { return; }

    UINotificationFeedbackGenerator *gen = [[UINotificationFeedbackGenerator alloc] init];
    [gen notificationOccurred:UINotificationFeedbackTypeSuccess];

    NSMutableString *message = [NSMutableString string];
    for (BGGAchievementDefinition *def in newlyEarned)
    {
        if (message.length > 0) { [message appendString:@"\n"]; }
        [message appendString:BGGLocalizedString(def.titleKey)];
    }

    NSString *title = [NSString stringWithFormat:@"🏆 %@",
                       BGGLocalizedString(@"New achievement!")];
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Setup

- (void)setupTiles
{
    UIColor *iconColor     = [UIColor colorNamed:@"ColorImages"];
    UIColor *disabledColor = [UIColor grayColor];

    self.tiles = @[
        [BGGStartTile tileWithKind:BGGStartTileKindPipCount
                             title:BGGLocalizedString(@"Pipcount")
                          subtitle:nil
                          iconName:@"sum"
                         iconColor:iconColor],

        [BGGStartTile tileWithKind:BGGStartTileKindMETQuiz
                             title:BGGLocalizedString(@"Match Equity")
                          subtitle:BGGLocalizedString(@"MET Quiz")
                          iconName:@"tablecells"
                         iconColor:iconColor],

        [BGGStartTile tileWithKind:BGGStartTileKindCollection
                             title:BGGLocalizedString(@"Collections")
                          subtitle:BGGLocalizedString(@"your positions")
                          iconName:@"folder"
                         iconColor:iconColor],

        [BGGStartTile tileWithKind:BGGStartTileKindStatistics
                             title:BGGLocalizedString(@"Statistics")
                          subtitle:BGGLocalizedString(@"your progress")
                          iconName:@"chart.xyaxis.line"
                         iconColor:iconColor],

        [BGGStartTile tileWithKind:BGGStartTileKindAchievements
                             title:BGGLocalizedString(@"Achievements")
                          subtitle:nil
                          iconName:@"trophy"
                         iconColor:iconColor],

        [BGGStartTile tileWithKind:BGGStartTileKindMoreModules
                             title:BGGLocalizedString(@"More modules")
                          subtitle:BGGLocalizedString(@"We welcome your requests")
                          iconName:@"plus"
                         iconColor:disabledColor],

        [BGGStartTile tileWithKind:BGGStartTileKindCredits
                             title:@"Credits"
                          subtitle:BGGLocalizedString(@"who helped")
                          iconName:@"heart"
                         iconColor:iconColor],
    ];
}

- (void)setupCollectionView
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame
                                             collectionViewLayout:flowLayout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];

    [self.collectionView registerClass:[BGGStartTileCell class]
            forCellWithReuseIdentifier:@"StartTile"];

    self.collectionView.delegate   = self;
    self.collectionView.dataSource = self;

    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor      constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.collectionView.bottomAnchor   constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [self.collectionView.leadingAnchor  constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
    ]];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.tiles.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BGGStartTileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"StartTile"
                                                                       forIndexPath:indexPath];

    BGGStartTile *tile = self.tiles[indexPath.row];
    [cell configureWithIcon:tile.icon
                  iconColor:tile.iconColor
                      title:tile.title
                   subtitle:tile.subtitle];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)layout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = collectionView.bounds.size.width;
    CGFloat inset = 20.0;
    CGFloat spacing = 20.0;

    NSInteger columns;
    if (width >= 900)       columns = 4;   // iPad landscape
    else if (width >= 600)  columns = 3;   // iPad portrait
    else                    columns = 2;   // iPhone: 2 Spalten

    CGFloat available = width - (2 * inset) - (spacing * (columns - 1));
    CGFloat itemWidth = available / columns;
    // Height follows width at a constant ratio, so tiles keep the same shape
    // on every device – they just scale up on iPad where the columns are
    // wider. 0.6 matches the iPhone proportion (≈165 wide, ≈100 tall).
    CGFloat itemHeight = itemWidth * 0.6;
    return CGSizeMake(itemWidth, itemHeight);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 20.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 20.0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10.0, 20.0, 10.0, 20.0);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:@"AccentColor"];

    BGGStartTile *tile = self.tiles[indexPath.row];

    switch (tile.kind)
    {
        case BGGStartTileKindPipCount:
        {
            PipCountVC *vc = [[PipCountVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;

        case BGGStartTileKindMETQuiz:
        {
            METVC *vc = [[METVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;

        case BGGStartTileKindCollection:
        {
            // The position browser is a developer-only editor for
            // positions.json; it must not ship to testers. Show a
            // "coming soon" alert until the real user-facing collections
            // feature exists. (Re-enable the browser locally by pushing
            // PositionBrowserVC here during development.)
            UIAlertController *alert = [UIAlertController
                alertControllerWithTitle:BGGLocalizedString(@"Coming soon")
                                 message:BGGLocalizedString(@"This feature isn't available yet.")
                          preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
            break;

        case BGGStartTileKindStatistics:
        {
            StatisticsVC *vc = [[StatisticsVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;

        case BGGStartTileKindAchievements:
        {
            AchievementsVC *vc = [[AchievementsVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;

        case BGGStartTileKindMoreModules:
        {
            MoreModulesVC *vc = [[MoreModulesVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;

        case BGGStartTileKindCredits:
        {
            CreditsVC *vc = [[CreditsVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;

        case BGGStartTileKindFeedback:
            [self presentFeedbackMail];
            break;
    }
}


#pragma mark - Feedback mail

// "Backgammon Gym Version 1.0 build 36"
- (NSString *)versionString
{
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    NSString *version  = info[@"CFBundleShortVersionString"] ?: @"?";
    NSString *build    = info[@"CFBundleVersion"]            ?: @"?";
    return [NSString stringWithFormat:@"Backgammon Gym Version %@ build %@",
            version, build];
}

- (void)presentFeedbackMail
{
    if (![MFMailComposeViewController canSendMail])
    {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:BGGLocalizedString(@"No Mail Account")
                             message:BGGLocalizedString(@"Please set up a mail account, or write to "
                                     @"BackgammonGym@hape42.de from your device.")
                      preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
    mail.mailComposeDelegate = self;
    [mail setToRecipients:@[@"BackgammonGym@hape42.de"]];
    [mail setSubject:@"Backgammon Gym – Feedback"];

    // Pre-fill the body with a blank line for the user and the version line
    // at the bottom, so I know which build a report refers to.
    NSString *body = [NSString stringWithFormat:@"\n\n\n—\n%@", [self versionString]];
    [mail setMessageBody:body isHTML:NO];

    [self presentViewController:mail animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupButtonTapped:(UIBarButtonItem *)sender
{
    
    SettingsVC *settingsVC = [[SettingsVC alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    // Sheet-Größe konfigurieren
    UISheetPresentationController *sheet = nav.sheetPresentationController;
    sheet.detents = @[
        [UISheetPresentationControllerDetent mediumDetent],
        [UISheetPresentationControllerDetent largeDetent]
    ];
    sheet.prefersGrabberVisible = YES;

    [self presentViewController:nav animated:YES completion:nil];
}

@end
