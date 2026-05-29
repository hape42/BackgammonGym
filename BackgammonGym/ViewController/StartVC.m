//
//  StartVC.m
//  BackgammonGym
//
//  Created by Peter Schneider on 28.05.26.
//

#import "StartVC.h"
#import "Tools.h"

@interface StartVC ()

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation StartVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorNamed:@"ColorViewBackground"];
    self.title = @"Backgammon Gym";


    [self setupCollectionView];
    [self setupTileArray];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.collectionView reloadData];
}

- (void)setupCollectionView
{
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(100, 100);
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:flowLayout];

    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.contentMode = UIViewContentModeScaleAspectFill;
    self.collectionView.clipsToBounds = YES;

    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        
    [self.view addSubview:self.collectionView];

    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor      constraintEqualToAnchor:self.view.topAnchor],
        [self.collectionView.bottomAnchor   constraintEqualToAnchor:self.view.bottomAnchor],
        [self.collectionView.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
}

- (void)setupTileArray
{
    self.tileArray = [[NSMutableArray alloc]initWithCapacity:5];
    
    NSMutableDictionary *tile = [[NSMutableDictionary alloc] init];
    tile[@"Titel"] = @"Pipcount";
    tile[@"SubTitel"] = @"";
    tile[@"Image"] = [UIImage systemImageNamed:@"sum"];
    tile[@"ImageColor"] = [UIColor colorNamed:@"ColorImages"];
    tile[@"Number"] = [NSString stringWithFormat: @"%d", TILE_PIPCOUNT];
    [self.tileArray addObject:tile];

    tile = [[NSMutableDictionary alloc] init];
    tile[@"Titel"] = @"Match Equity";
    tile[@"SubTitel"] = @"MET Quiz";
    tile[@"Image"] = [UIImage systemImageNamed:@"tablecells"];
    tile[@"ImageColor"] = [UIColor colorNamed:@"ColorImages"];
    tile[@"Number"] = [NSString stringWithFormat: @"%d", TILE_MEQUIZ];
    [self.tileArray addObject:tile];

    tile = [[NSMutableDictionary alloc] init];
    tile[@"Titel"] = @"Collections";
    tile[@"SubTitel"] = @"your positions";
    tile[@"Image"] = [UIImage systemImageNamed:@"folder"];
    tile[@"ImageColor"] = [UIColor colorNamed:@"ColorImages"];
    tile[@"Number"] = [NSString stringWithFormat: @"%d", TILE_COLLECTION];
    [self.tileArray addObject:tile];

    tile = [[NSMutableDictionary alloc] init];
    tile[@"Titel"] = @"Statistics";
    tile[@"SubTitel"] = @"your progress";
    tile[@"Image"] = [UIImage systemImageNamed:@"chart.xyaxis.line"];
    tile[@"ImageColor"] = [UIColor colorNamed:@"ColorImages"];
    tile[@"Number"] = [NSString stringWithFormat: @"%d", TILE_STATISTICS];
    [self.tileArray addObject:tile];

    tile = [[NSMutableDictionary alloc] init];
    tile[@"Titel"] = @"Achievments";
    tile[@"SubTitel"] = @"";
    tile[@"Image"] = [UIImage systemImageNamed:@"trophy"];
    tile[@"ImageColor"] = [UIColor colorNamed:@"ColorImages"];
    tile[@"Number"] = [NSString stringWithFormat: @"%d", TILE_ACHIEVMENTS];
    [self.tileArray addObject:tile];

    tile = [[NSMutableDictionary alloc] init];
    tile[@"Titel"] = @"More soon";
    tile[@"SubTitel"] = @"We welcome your requests";
    tile[@"Image"] = [UIImage systemImageNamed:@"plus"];
    tile[@"ImageColor"] = [UIColor grayColor];
    tile[@"Number"] = [NSString stringWithFormat: @"%d", TILE_FEEDBACK];
    [self.tileArray addObject:tile];
    
    
    //ToDo sort by tile[@"Number"]
}

#pragma mark - CollectionView dataSource


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.tileArray.count;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 20.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 20.0;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(300, 240);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    for (UIView *subview in [cell.contentView subviews])
    {
        if ([subview isKindOfClass:[UILabel class]])
        {
            [subview removeFromSuperview];
        }
        if ([subview isKindOfClass:[UIImageView class]])
        {
            [subview removeFromSuperview];
        }

   }
    cell.layer.cornerRadius = 14.0f;
    cell.layer.masksToBounds = YES;
    cell.backgroundColor = [UIColor colorNamed:@"ColorCV"];


    NSMutableDictionary *tileDict = self.tileArray[indexPath.row];
    
    float edge = 30;
    float gap = 5;
    float x = edge;
    float y = edge;
    float maxWidth = cell.frame.size.width - edge - edge;
    
    cell.backgroundColor = [UIColor colorNamed:@"ColorCV"];
    
    int titelFontSize = 40;
    int subTitelFontSize = 30;
    y =  edge;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y ,50,50)];
    imageView.tintColor = [tileDict objectForKey:@"ImageColor"];

    UIImage *image = [tileDict objectForKey:@"Image"];
    if (image != nil)
        imageView.image = image;
    else
        imageView.image = nil;
    [cell.contentView addSubview:imageView];
    y += 50 + gap;

    UILabel *titelLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y ,maxWidth,50)];
    titelLabel.textAlignment = NSTextAlignmentCenter;
    [titelLabel setFont:[UIFont boldSystemFontOfSize: titelFontSize]];
    titelLabel.numberOfLines = 0;
    titelLabel.text = [tileDict objectForKey:@"Titel"];
    titelLabel.adjustsFontSizeToFitWidth = YES;
    titelLabel.textColor = [UIColor blackColor];
    [cell.contentView addSubview:titelLabel];
    y += 50 + gap;
                
    UILabel *subTitelLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y ,maxWidth,30)];
    subTitelLabel.textAlignment = NSTextAlignmentCenter;
    subTitelLabel.adjustsFontSizeToFitWidth = YES;
    [subTitelLabel setFont:[UIFont boldSystemFontOfSize: subTitelFontSize]];
    subTitelLabel.numberOfLines = 0;
    subTitelLabel.text = [tileDict objectForKey:@"SubTitel"];
    subTitelLabel.textColor = [UIColor darkGrayColor];
    subTitelLabel.adjustsFontSizeToFitWidth = YES;
    [cell.contentView addSubview:subTitelLabel];
    y += 30 + gap;


    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    // Für Sektion 0: 20 Punkte links, 10 Punkte rechts
    if (section == 0)
    {
        return UIEdgeInsetsMake(10.0, 20.0, 10.0, 20.0);
    }
    
    // Standard für alle anderen Sektionen
    return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
}

#pragma mark - CollectionView delegate
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.navigationController.navigationBar.topItem.title = nil;

    NSMutableDictionary *tileDict = self.tileArray[indexPath.row];

    switch ([[tileDict objectForKey:@"Number"]intValue])
    {
        case TILE_PIPCOUNT:
        {
            [Tools showNotImplementedAlertFromViewController:self feature:@"Pipcount" description:nil];
        }
            break;
        case TILE_MEQUIZ:
        {
            [Tools showNotImplementedAlertFromViewController:self feature:@"Match Equity" description:nil];
        }
            break;
        case TILE_STATISTICS:
        {
            [Tools showNotImplementedAlertFromViewController:self feature:@"Statistics" description:nil];
        }
            break;
        case TILE_ACHIEVMENTS:
        {
            [Tools showNotImplementedAlertFromViewController:self feature:@"Achievments" description:nil];
        }
            break;
        case TILE_COLLECTION:
        {
            [Tools showNotImplementedAlertFromViewController:self feature:@"Collections" description:@"Here's where you can save your own positions"];
        }
            break;
        case TILE_FEEDBACK:
        {
            [Tools showNotImplementedAlertFromViewController:self feature:@"Feedback" description:nil];
        }
            break;

       default:
             break;
     }

    return;

}
@end
