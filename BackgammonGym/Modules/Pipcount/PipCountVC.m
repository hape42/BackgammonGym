//
//  PipCountVC.m
//  BackgammonGym
//
//  Container view controller for the Pip Count module.
//  Navigation between sections via a UIMenu in the navigation bar –
//  cleaner than a segmented control and scales to any screen width.
//

#import "PipCountVC.h"
#import "UIViewController+BGGHomeButton.h"
#import "PipCountWarmupVC.h"
#import "PipCountClusterVC.h"
#import "PipCountTrainingVC.h"
#import "PipCountWorkoutVC.h"
#import "PipCountProgressVC.h"
#import "BackgammonGym-Swift.h"

typedef NS_ENUM(NSInteger, PipCountSection)
{
    PipCountSectionWarmup   = 0,
    PipCountSectionCluster  = 1,
    PipCountSectionTraining = 2,
    PipCountSectionWorkout  = 3,
    PipCountSectionProgress = 4,
};

// Display names for the menu entries and the nav bar button title.
static NSString * sectionTitle(PipCountSection section)
{
    switch (section)
    {
        case PipCountSectionWarmup:   return @"Warm-up";
        case PipCountSectionCluster:  return @"Cluster";
        case PipCountSectionTraining: return @"Training Pipcount";
        case PipCountSectionWorkout:  return @"Workout Pipcount";
        case PipCountSectionProgress: return @"Progress";
    }
}

// SF Symbol names for each section – adds visual context to the menu.
static NSString * sectionSymbol(PipCountSection section)
{
    switch (section)
    {
        case PipCountSectionWarmup:   return @"book.pages";
        case PipCountSectionCluster:  return @"square.grid.2x2";
        case PipCountSectionTraining: return @"pencil";
        case PipCountSectionWorkout:  return @"dumbbell";
        case PipCountSectionProgress: return @"chart.line.uptrend.xyaxis";
    }
}

@interface PipCountVC ()

@property (nonatomic, strong) UIView           *containerView;
@property (nonatomic, strong) UIViewController *activeChild;
@property (nonatomic, assign) PipCountSection   activeSection;

// Child VCs – created lazily.
@property (nonatomic, strong) PipCountWarmupVC *warmupVC;
@property (nonatomic, strong) PipCountClusterVC *clusterVC;

// Nav bar items kept as properties so showSection: can manage them
// regardless of how many are currently shown.
@property (nonatomic, strong) UIBarButtonItem *menuBarItem;
@property (nonatomic, strong) UIButton        *menuButton;
@property (nonatomic, strong) UIBarButtonItem *chartBarItem;

@end

@implementation PipCountVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Pip Count";

    [self installHomeButton];
    [self setupContainerView];
    [self setupMenuButton];
    [self showSection:PipCountSectionWarmup];
}

#pragma mark - Container

- (void)setupContainerView
{
    self.containerView = [[UIView alloc] init];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.containerView];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.topAnchor      constraintEqualToAnchor:safe.topAnchor],
        [self.containerView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [self.containerView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.containerView.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],
    ]];
}

#pragma mark - Menu button

- (void)setupMenuButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setImage:[UIImage systemImageNamed:@"list.bullet"] forState:UIControlStateNormal];
    button.tintColor = [UIColor colorNamed:@"AccentColor"];
    button.menu = [self buildMenu];
    button.showsMenuAsPrimaryAction = YES;
    self.menuButton = button;

    self.menuBarItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    // Chart button, shown only while the Progress section is active.
    self.chartBarItem = [[UIBarButtonItem alloc]
        initWithImage:[UIImage systemImageNamed:@"chart.bar.xaxis"]
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(showChart)];
    self.chartBarItem.tintColor = [UIColor colorNamed:@"AccentColor"];

    [self updateRightBarButtonsForSection:self.activeSection];
}

// Menu is always present; the chart button only in the Progress section.
- (void)updateRightBarButtonsForSection:(PipCountSection)section
{
    if (section == PipCountSectionProgress)
    {
        self.navigationItem.rightBarButtonItems = @[self.menuBarItem, self.chartBarItem];
    }
    else
    {
        self.navigationItem.rightBarButtonItems = @[self.menuBarItem];
    }
}

- (void)showChart
{
    PipTrendHostController *vc = [[PipTrendHostController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

// Rebuild the menu so the checkmark reflects the current section.
- (UIMenu *)buildMenu
{
    NSMutableArray<UIAction *> *actions = [NSMutableArray array];

    for (NSInteger i = PipCountSectionWarmup; i <= PipCountSectionProgress; i++)
    {
        PipCountSection section = (PipCountSection)i;
        BOOL isActive = (section == self.activeSection);

        UIAction *action = [UIAction
            actionWithTitle:sectionTitle(section)
                      image:[UIImage systemImageNamed:sectionSymbol(section)]
                 identifier:nil
                    handler:^(__kindof UIAction *a)
            {
                [self showSection:section];
            }];

        action.state = isActive ? UIMenuElementStateOn : UIMenuElementStateOff;
        [actions addObject:action];
    }

    return [UIMenu menuWithTitle:@""
                           image:nil
                      identifier:nil
                         options:UIMenuOptionsDisplayInline
                        children:actions];
}

#pragma mark - Section switching

- (void)showSection:(PipCountSection)section
{
    UIViewController *newChild = [self childForSection:section];
    if (newChild == self.activeChild) { return; }

    // Remove current child.
    if (self.activeChild != nil)
    {
        [self.activeChild willMoveToParentViewController:nil];
        [self.activeChild.view removeFromSuperview];
        [self.activeChild removeFromParentViewController];
    }

    // Add new child.
    [self addChildViewController:newChild];
    newChild.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:newChild.view];

    [NSLayoutConstraint activateConstraints:@[
        [newChild.view.topAnchor      constraintEqualToAnchor:self.containerView.topAnchor],
        [newChild.view.leadingAnchor  constraintEqualToAnchor:self.containerView.leadingAnchor],
        [newChild.view.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        [newChild.view.bottomAnchor   constraintEqualToAnchor:self.containerView.bottomAnchor],
    ]];

    [newChild didMoveToParentViewController:self];
    self.activeChild   = newChild;
    self.activeSection = section;

    // Show the section name in the navigation bar.
    self.navigationItem.title = sectionTitle(section);

    // Rebuild the menu so the checkmark moves to the new section, and show
    // the chart button only in the Progress section.
    self.menuButton.menu = [self buildMenu];
    [self updateRightBarButtonsForSection:section];
}

- (UIViewController *)childForSection:(PipCountSection)section
{
    switch (section)
    {
        case PipCountSectionWarmup:
            if (self.warmupVC == nil)
            {
                self.warmupVC = [[PipCountWarmupVC alloc] init];
            }
            return self.warmupVC;

        case PipCountSectionCluster:
            if (self.clusterVC == nil)
            {
                self.clusterVC = [[PipCountClusterVC alloc] init];
            }
            return self.clusterVC;

        case PipCountSectionTraining:
            return [[PipCountTrainingVC alloc] init];

        case PipCountSectionWorkout:
            return [[PipCountWorkoutVC alloc] init];
            
        case PipCountSectionProgress:
            return [[PipCountProgressVC alloc] init];
    }
}

#pragma mark - Placeholder child

- (UIViewController *)placeholderForSection:(PipCountSection)section
                                   subtitle:(NSString *)subtitle
{
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor systemBackgroundColor];

    UIImageView *icon = [[UIImageView alloc]
                         initWithImage:[UIImage systemImageNamed:sectionSymbol(section)]];
    icon.tintColor = [UIColor tertiaryLabelColor];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.preferredSymbolConfiguration =
        [UIImageSymbolConfiguration configurationWithPointSize:48.0
                                                        weight:UIImageSymbolWeightThin];
    [vc.view addSubview:icon];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text          = sectionTitle(section);
    titleLabel.textColor     = [UIColor secondaryLabelColor];
    titleLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [vc.view addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text          = subtitle;
    subtitleLabel.textColor     = [UIColor tertiaryLabelColor];
    subtitleLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.numberOfLines = 0;
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [vc.view addSubview:subtitleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [icon.centerXAnchor   constraintEqualToAnchor:vc.view.centerXAnchor],
        [icon.centerYAnchor   constraintEqualToAnchor:vc.view.centerYAnchor constant:-44.0],

        [titleLabel.topAnchor     constraintEqualToAnchor:icon.bottomAnchor     constant:12.0],
        [titleLabel.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor constant:32.0],
        [titleLabel.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor constant:-32.0],

        [subtitleLabel.topAnchor     constraintEqualToAnchor:titleLabel.bottomAnchor constant:8.0],
        [subtitleLabel.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor   constant:32.0],
        [subtitleLabel.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor constant:-32.0],
    ]];

    return vc;
}

@end
