//
//  PipCountVC.m
//  BackgammonGym
//
//  Container view controller for the Pip Count module.
//  Navigation between sections via a UIMenu in the navigation bar –
//  cleaner than a segmented control and scales to any screen width.
//

#import "PipCountVC.h"
#import "PipCountWarmupVC.h"
#import "PipCountClusterVC.h"
#import "PipCountTrainingVC.h"
#import "PipCountWorkoutVC.h"

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
        case PipCountSectionTraining: return @"Training";
        case PipCountSectionWorkout:  return @"Workout";
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

@end

@implementation PipCountVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Pip Count";

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
    UIBarButtonItem *item = [[UIBarButtonItem alloc]
                             initWithImage:[UIImage systemImageNamed:@"list.bullet"]
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    item.menu = [self buildMenu];
    item.primaryAction = nil;
    item.tintColor = [UIColor colorNamed:@"AccentColor"];

    self.navigationItem.rightBarButtonItem = item;
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

    // Rebuild the menu so the checkmark moves to the new section.
    self.navigationItem.rightBarButtonItem.menu = [self buildMenu];
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
            return [self placeholderForSection:section
                                       subtitle:@"Your statistics, trends and achievements across all sessions."];
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
