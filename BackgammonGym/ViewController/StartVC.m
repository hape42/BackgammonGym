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

@interface StartVC () <UICollectionViewDataSource,
                       UICollectionViewDelegate,
                       UICollectionViewDelegateFlowLayout>

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
    
    BGGBoardState *test = [BGGBoardState startingPosition];
    NSLog(@"Blau gesamt: %ld", (long)[test totalCheckersForPlayer:BGGPlayerBlue]);
    NSLog(@"Gültig: %d", [test isValidCheckerCount]);
}

#pragma mark - Setup

- (void)setupTiles
{
    UIColor *iconColor     = [UIColor colorNamed:@"ColorImages"];
    UIColor *disabledColor = [UIColor grayColor];

    self.tiles = @[
        [BGGStartTile tileWithKind:BGGStartTileKindPipCount
                             title:@"Pipcount"
                          subtitle:nil
                          iconName:@"sum"
                         iconColor:iconColor],

        [BGGStartTile tileWithKind:BGGStartTileKindMETQuiz
                             title:@"Match Equity"
                          subtitle:@"MET Quiz"
                          iconName:@"tablecells"
                         iconColor:iconColor],

        [BGGStartTile tileWithKind:BGGStartTileKindCollection
                             title:@"Collections"
                          subtitle:@"your positions"
                          iconName:@"folder"
                         iconColor:iconColor],

        [BGGStartTile tileWithKind:BGGStartTileKindStatistics
                             title:@"Statistics"
                          subtitle:@"your progress"
                          iconName:@"chart.xyaxis.line"
                         iconColor:iconColor],

        [BGGStartTile tileWithKind:BGGStartTileKindAchievements
                             title:@"Achievements"
                          subtitle:nil
                          iconName:@"trophy"
                         iconColor:iconColor],

        [BGGStartTile tileWithKind:BGGStartTileKindFeedback
                             title:@"More soon"
                          subtitle:@"We welcome your requests"
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
            [Tools showNotImplementedAlertFromViewController:self
                                                     feature:@"Match Equity"
                                                 description:nil];
            break;

        case BGGStartTileKindCollection:
            [Tools showNotImplementedAlertFromViewController:self
                                                     feature:@"Collections"
                                                 description:@"Here's where you can save your own positions"];
            break;

        case BGGStartTileKindStatistics:
            [Tools showNotImplementedAlertFromViewController:self
                                                     feature:@"Statistics"
                                                 description:nil];
            break;

        case BGGStartTileKindAchievements:
            [Tools showNotImplementedAlertFromViewController:self
                                                     feature:@"Achievements"
                                                 description:nil];
            break;

        case BGGStartTileKindFeedback:
            [Tools showNotImplementedAlertFromViewController:self
                                                     feature:@"Feedback"
                                                 description:nil];
            break;
    }
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
