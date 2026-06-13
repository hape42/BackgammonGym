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
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Rebuild the tiles with localized text and reload the grid.
- (void)languageDidChange
{
    self.title = @"Backgammon Gym";   // a proper noun, stays as-is
    [self setupTiles];
    [self.collectionView reloadData];
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

        [BGGStartTile tileWithKind:BGGStartTileKindFeedback
                             title:BGGLocalizedString(@"More soon")
                          subtitle:BGGLocalizedString(@"We welcome your requests")
                          iconName:@"plus"
                         iconColor:disabledColor],
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
    if (width >= 900)       columns = 3;   // iPad landscape
    else if (width >= 600)  columns = 2;   // iPad portrait
    else                    columns = 1;   // iPhone immer 1 Spalte

    CGFloat available = width - (2 * inset) - (spacing * (columns - 1));
    CGFloat itemWidth = available / columns;
    return CGSizeMake(itemWidth, itemWidth * 0.5);
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
            PositionBrowserVC *vc = [[PositionBrowserVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;

        case BGGStartTileKindStatistics:
        {
            StatisticsVC *vc = [[StatisticsVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;

        case BGGStartTileKindAchievements:
            [Tools showNotImplementedAlertFromViewController:self
                                                     feature:@"Achievements"
                                                 description:nil];
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
