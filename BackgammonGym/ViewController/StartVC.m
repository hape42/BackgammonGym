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
#import "BGGManualVC.h"
#import "BGGAchievements.h"
#import "BGGLocalization.h"
#import "BGGLanguage.h"

#pragma mark - Supplementary view kinds / reuse IDs

static NSString * const kBGGSectionHeaderID = @"SectionHeader";
static NSString * const kBGGStartTileID     = @"StartTile";

#pragma mark - Section model

// One labelled group of tiles on the start screen. Adding a new module is a
// one-line change: append a tile to the right section in -setupSections.
@interface BGGStartSection : NSObject
@property (nonatomic, copy) NSString *title;                  // localized header, nil = no header
@property (nonatomic, copy) NSArray<BGGStartTile *> *tiles;
@end

@implementation BGGStartSection
@end

#pragma mark - Section header (optional welcome intro + section label)

// One header view used for both sections. The first section passes an intro
// (big title + body) that renders above the section label; the second section
// passes intro:nil and only the label shows. Using a single supplementary kind
// keeps it inside what UICollectionViewFlowLayout actually lays out.
@interface BGGSectionHeaderView : UICollectionReusableView
@property (nonatomic, strong) UILabel *introTitleLabel;
@property (nonatomic, strong) UILabel *introBodyLabel;
@property (nonatomic, strong) UILabel *sectionLabel;
@property (nonatomic, strong) NSLayoutConstraint *sectionLabelTopToBody;
@property (nonatomic, strong) NSLayoutConstraint *sectionLabelTopToSelf;
- (void)configureWithSectionTitle:(NSString *)sectionTitle
                       introTitle:(nullable NSString *)introTitle
                        introBody:(nullable NSString *)introBody;
@end

@implementation BGGSectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _introTitleLabel = [[UILabel alloc] init];
        _introTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _introTitleLabel.font = [UIFont boldSystemFontOfSize:26];
        _introTitleLabel.textColor = [UIColor labelColor];
        _introTitleLabel.numberOfLines = 1;
        _introTitleLabel.adjustsFontSizeToFitWidth = YES;
        _introTitleLabel.minimumScaleFactor = 0.7;
        _introTitleLabel.textAlignment = NSTextAlignmentCenter;   // hero block is centred
        [self addSubview:_introTitleLabel];

        _introBodyLabel = [[UILabel alloc] init];
        _introBodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _introBodyLabel.font = [UIFont systemFontOfSize:15];
        _introBodyLabel.textColor = [UIColor secondaryLabelColor];
        _introBodyLabel.numberOfLines = 0;
        _introBodyLabel.textAlignment = NSTextAlignmentCenter;    // hero block is centred
        [self addSubview:_introBodyLabel];

        _sectionLabel = [[UILabel alloc] init];
        _sectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _sectionLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        _sectionLabel.textColor = [UIColor secondaryLabelColor];
        [self addSubview:_sectionLabel];

        // 20pt side padding so header text lines up with the tile column
        // (the flow layout's section inset applies to cells, not headers).
        CGFloat pad = 20.0;

        [NSLayoutConstraint activateConstraints:@[
            [_introTitleLabel.topAnchor      constraintEqualToAnchor:self.topAnchor constant:8.0],
            [_introTitleLabel.leadingAnchor  constraintEqualToAnchor:self.leadingAnchor constant:pad],
            [_introTitleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-pad],

            [_introBodyLabel.topAnchor       constraintEqualToAnchor:_introTitleLabel.bottomAnchor constant:6.0],
            [_introBodyLabel.leadingAnchor   constraintEqualToAnchor:self.leadingAnchor constant:pad],
            [_introBodyLabel.trailingAnchor  constraintEqualToAnchor:self.trailingAnchor constant:-pad],

            [_sectionLabel.leadingAnchor     constraintEqualToAnchor:self.leadingAnchor constant:pad],
            [_sectionLabel.trailingAnchor    constraintEqualToAnchor:self.trailingAnchor constant:-pad],
            [_sectionLabel.bottomAnchor      constraintEqualToAnchor:self.bottomAnchor constant:-6.0],
        ]];

        // The section label sits either below the intro body (section 1) or
        // straight against the top (section 2, no intro). We keep both
        // constraints and toggle which one is active per configuration.
        _sectionLabelTopToBody = [_sectionLabel.topAnchor constraintEqualToAnchor:_introBodyLabel.bottomAnchor constant:18.0];
        _sectionLabelTopToSelf = [_sectionLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:8.0];
    }
    return self;
}

- (void)configureWithSectionTitle:(NSString *)sectionTitle
                       introTitle:(NSString *)introTitle
                        introBody:(NSString *)introBody
{
    self.sectionLabel.text = [sectionTitle uppercaseString];

    BOOL hasIntro = (introTitle.length > 0 || introBody.length > 0);
    self.introTitleLabel.text = introTitle;
    self.introBodyLabel.text  = introBody;
    self.introTitleLabel.hidden = !hasIntro;
    self.introBodyLabel.hidden  = !hasIntro;

    self.sectionLabelTopToBody.active = hasIntro;
    self.sectionLabelTopToSelf.active = !hasIntro;
}

@end

#pragma mark - StartVC

@interface StartVC () <UICollectionViewDataSource,
                       UICollectionViewDelegate,
                       UICollectionViewDelegateFlowLayout,
                       MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<BGGStartSection *> *sections;

@end

@implementation StartVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:@"AccentColor"];

    self.view.backgroundColor = [UIColor colorNamed:@"ColorViewBackground"];
    self.title = @"Backgammon Gym";
    self.title = nil;
    UIImage *setupImage = [UIImage systemImageNamed:@"gearshape"];

    UIBarButtonItem *setupButton = [[UIBarButtonItem alloc] initWithImage:setupImage
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(setupButtonTapped:)];
    setupButton.tintColor = [UIColor colorNamed:@"AccentColor"];

    // Manual button, sitting to the left of the gear. In a right-side bar
    // button array the first item is outermost (right), so the gear stays on
    // the outside and the manual appears just left of it.
    UIBarButtonItem *manualButton = [[UIBarButtonItem alloc]
        initWithImage:[UIImage systemImageNamed:@"book"]
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(manualButtonTapped:)];
    manualButton.tintColor = [UIColor colorNamed:@"AccentColor"];

    self.navigationItem.rightBarButtonItems = @[setupButton, manualButton];

    [self setupSections];
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

// Rebuild the sections with localized text and reload the grid.
- (void)languageDidChange
{
    self.title = @"Backgammon Gym";   // a proper noun, stays as-is
    self.title = nil;
    [self setupSections];
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

- (void)setupSections
{
    UIColor *accentColor = [UIColor colorNamed:@"AccentColor"];

    // Section 1 – the actual training areas. New training modules go here.
    // Prominent styling: AccentColor fill, grey icon, light text – this is the
    // strongest visual signal that these are the things you came to do.
    BGGStartSection *training = [[BGGStartSection alloc] init];
    training.title = BGGLocalizedString(@"Training");
    training.tiles = @[
        [BGGStartTile tileWithKind:BGGStartTileKindPipCount
                             title:BGGLocalizedString(@"Pipcount")
                          subtitle:BGGLocalizedString(@"count the race")
                          iconName:@"sum"
                         iconColor:accentColor
                         prominent:YES],

        [BGGStartTile tileWithKind:BGGStartTileKindMETQuiz
                             title:BGGLocalizedString(@"Match Equity")
                          subtitle:BGGLocalizedString(@"MET Quiz")
                          iconName:@"tablecells"
                         iconColor:accentColor
                         prominent:YES],
    ];

    // Section 2 – everything that isn't a training area: progress, meta,
    // and the channels for feedback/credits. Plain grey tiles, but with
    // AccentColor icons so the section still feels part of the app.
    BGGStartSection *more = [[BGGStartSection alloc] init];
    more.title = BGGLocalizedString(@"More");
    more.tiles = @[
        [BGGStartTile tileWithKind:BGGStartTileKindStatistics
                             title:BGGLocalizedString(@"Statistics")
                          subtitle:BGGLocalizedString(@"your progress")
                          iconName:@"chart.xyaxis.line"
                         iconColor:accentColor],

        [BGGStartTile tileWithKind:BGGStartTileKindAchievements
                             title:BGGLocalizedString(@"Achievements")
                          subtitle:BGGLocalizedString(@"what you earned")
                          iconName:@"trophy"
                         iconColor:accentColor],

        [BGGStartTile tileWithKind:BGGStartTileKindMoreModules
                             title:BGGLocalizedString(@"More modules")
                          subtitle:BGGLocalizedString(@"We welcome your requests")
                          iconName:@"plus"
                         iconColor:accentColor],

        [BGGStartTile tileWithKind:BGGStartTileKindCredits
                             title:@"Credits"
                          subtitle:BGGLocalizedString(@"who helped")
                          iconName:@"heart"
                         iconColor:accentColor],
        
//        [BGGStartTile tileWithKind:BGGStartTileKindCollection
//                             title:BGGLocalizedString(@"Collections")
//                          subtitle:BGGLocalizedString(@"your positions")
//                          iconName:@"folder"
//                         iconColor:accentColor],
    ];

    self.sections = @[ training, more ];
}

- (BGGStartTile *)tileForIndexPath:(NSIndexPath *)indexPath
{
    BGGStartSection *section = self.sections[indexPath.section];
    return section.tiles[indexPath.item];
}

- (void)setupCollectionView
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame
                                             collectionViewLayout:flowLayout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];

    [self.collectionView registerClass:[BGGStartTileCell class]
            forCellWithReuseIdentifier:kBGGStartTileID];

    // One section header type. The first section's header also carries the
    // welcome intro (big title + body); the second's shows only its label.
    [self.collectionView registerClass:[BGGSectionHeaderView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:kBGGSectionHeaderID];

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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.sections[section].tiles.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BGGStartTileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kBGGStartTileID
                                                                       forIndexPath:indexPath];

    BGGStartTile *tile = [self tileForIndexPath:indexPath];
    [cell configureWithIcon:tile.icon
                  iconColor:tile.iconColor
                      title:tile.title
                   subtitle:tile.subtitle
                  prominent:tile.prominent];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    BGGSectionHeaderView *header =
        [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                           withReuseIdentifier:kBGGSectionHeaderID
                                                  forIndexPath:indexPath];

    BGGStartSection *section = self.sections[indexPath.section];

    // Only the first section carries the welcome intro above its label.
    if (indexPath.section == 0)
    {
        [header configureWithSectionTitle:section.title
                               introTitle:@"Backgammon Gym"   // proper noun, not localized
                                introBody:BGGLocalizedString(@"start.intro.body")];

#if DEBUG
        // Developer-only shortcut: long-press the "Backgammon Gym" title to
        // open the position browser/editor. This is the tool used to maintain
        // positions.json; it is not meant for users, so it is compiled in only
        // for DEBUG builds and cannot appear in a TestFlight/App Store build.
        // (The "Collections" tile stays in the grid as a placeholder for the
        // future user-facing "create your own positions" feature.)
        [self attachDeveloperGestureToTitle:header.introTitleLabel];
#endif
    }
    else
    {
        [header configureWithSectionTitle:section.title
                               introTitle:nil
                                introBody:nil];
    }
    return header;
}

#if DEBUG
// Wires (or re-wires) the long-press recognizer on a recycled header's title
// label. Header views are reused, so we remove any previous recognizer first
// to avoid stacking several on the same label.
- (void)attachDeveloperGestureToTitle:(UILabel *)titleLabel
{
    for (UIGestureRecognizer *g in [titleLabel.gestureRecognizers copy])
    {
        [titleLabel removeGestureRecognizer:g];
    }
    titleLabel.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *lp =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(developerTitleLongPressed:)];
    lp.minimumPressDuration = 1.5;   // long enough not to trigger by accident
    [titleLabel addGestureRecognizer:lp];
}

- (void)developerTitleLongPressed:(UILongPressGestureRecognizer *)gesture
{
    // Fire once, when the press is first recognized.
    if (gesture.state != UIGestureRecognizerStateBegan) { return; }

    PositionBrowserVC *browser = [[PositionBrowserVC alloc] init];
    [self.navigationController pushViewController:browser animated:YES];
}
#endif

#pragma mark - UICollectionViewDelegateFlowLayout

- (NSInteger)columnsForWidth:(CGFloat)width
{
    if (width >= 900)       return 4;   // iPad landscape
    else if (width >= 600)  return 3;   // iPad portrait
    else                    return 2;   // iPhone: 2 columns
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)layout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = collectionView.bounds.size.width;
    CGFloat inset = 20.0;
    CGFloat spacing = 20.0;

    NSInteger columns = [self columnsForWidth:width];

    CGFloat available = width - (2 * inset) - (spacing * (columns - 1));
    CGFloat itemWidth = available / columns;
    // Height follows width at a constant ratio, so tiles keep the same shape
    // on every device. 0.68 (up from 0.6) gives the second text line – the
    // subtitle – room to breathe under the title without crowding the icon.
    CGFloat itemHeight = itemWidth * 0.68;
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

// Section header height: section 0 includes the welcome intro (title + body,
// whose height depends on how the body wraps at the current width), section 1
// only its label.
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
    CGFloat width = collectionView.bounds.size.width;

    if (section != 0)
    {
        return CGSizeMake(width, 34.0);
    }

    // Measure the intro body at the available text width (full width minus the
    // 20pt section insets on each side) so the header is tall enough.
    CGFloat textWidth = width - 40.0;
    if (textWidth < 1.0) { textWidth = 1.0; }

    NSString *body = BGGLocalizedString(@"start.intro.body");
    UIFont *bodyFont = [UIFont systemFontOfSize:15];
    CGRect bodyRect = [body boundingRectWithSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{ NSFontAttributeName: bodyFont }
                                         context:nil];

    // 8 (top) + ~31 (intro title) + 6 (gap) + body + 18 (gap) + ~16 (label) + 6.
    CGFloat height = 8.0 + 31.0 + 6.0 + ceil(bodyRect.size.height) + 18.0 + 16.0 + 6.0;
    return CGSizeMake(width, height);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:@"AccentColor"];

    BGGStartTile *tile = [self tileForIndexPath:indexPath];

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
            /**/
            UIAlertController *alert = [UIAlertController
                alertControllerWithTitle:BGGLocalizedString(@"Coming soon")
                                 message:BGGLocalizedString(@"This feature isn't available yet.")
                          preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
             /**/

//            PositionBrowserVC *vc = [[PositionBrowserVC alloc] init];
//            [self.navigationController pushViewController:vc animated:YES];
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

- (void)manualButtonTapped:(UIBarButtonItem *)sender
{
    // The manual is a content page with a Home button, like Credits, so it is
    // pushed onto the navigation stack rather than presented as a sheet.
    BGGManualVC *manualVC = [[BGGManualVC alloc] init];
    [self.navigationController pushViewController:manualVC animated:YES];
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
