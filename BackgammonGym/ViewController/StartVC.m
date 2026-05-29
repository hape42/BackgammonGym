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

    self.view.backgroundColor = [UIColor colorNamed:@"ColorViewBackground"];
    self.title = @"Backgammon Gym";

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
    CGFloat available = collectionView.bounds.size.width - 40; // Insets links/rechts
    CGFloat spacing = 20;
    NSInteger columns = (collectionView.bounds.size.width > 700) ? 3 : 2;
    if (collectionView.bounds.size.width < 400) columns = 1; // iPhone Portrait

    CGFloat itemWidth = (available - spacing * (columns - 1)) / columns;
    return CGSizeMake(itemWidth, itemWidth * 0.65); // Verhältnis
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
    BGGStartTile *tile = self.tiles[indexPath.row];

    switch (tile.kind)
    {
        case BGGStartTileKindPipCount:
            [Tools showNotImplementedAlertFromViewController:self
                                                     feature:@"Pipcount"
                                                 description:nil];
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

@end
