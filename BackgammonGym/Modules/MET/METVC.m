//
//  METVC.m
//  BackgammonGym
//
//  Container view controller for the Match Equity Table module.
//  Navigation between sections via a UIMenu in the navigation bar –
//  same pattern as PipCountVC.
//

#import "METVC.h"
#import "UIViewController+BGGHomeButton.h"
#import "METWarmupVC.h"

typedef NS_ENUM(NSInteger, METSection)
{
    METSectionWarmup   = 0,
    METSectionTraining = 1,
    METSectionWorkout  = 2,
    METSectionProgress = 3,
};

// Display names for the menu entries and the nav bar title.
static NSString * sectionTitle(METSection section)
{
    switch (section)
    {
        case METSectionWarmup:   return @"Warm-up";
        case METSectionTraining: return @"Training MET";
        case METSectionWorkout:  return @"Workout MET";
        case METSectionProgress: return @"Progress";
    }
}

// SF Symbol names for each section.
static NSString * sectionSymbol(METSection section)
{
    switch (section)
    {
        case METSectionWarmup:   return @"book.pages";
        case METSectionTraining: return @"pencil";
        case METSectionWorkout:  return @"dumbbell";
        case METSectionProgress: return @"chart.line.uptrend.xyaxis";
    }
}

@interface METVC ()

@property (nonatomic, strong) UIView           *containerView;
@property (nonatomic, strong) UIViewController *activeChild;
@property (nonatomic, assign) METSection        activeSection;

// Warm-up is created lazily and kept alive (it builds the whole table).
@property (nonatomic, strong) METWarmupVC      *warmupVC;

// Nav bar items kept as properties so showSection: can manage them
// regardless of how many are currently shown.
@property (nonatomic, strong) UIBarButtonItem *menuBarItem;
@property (nonatomic, strong) UIButton        *menuButton;
@property (nonatomic, strong) UIBarButtonItem *chartBarItem;

@end

@implementation METVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Match Equity";

    [self installHomeButton];
    [self setupContainerView];
    [self setupMenuButton];
    [self showSection:METSectionWarmup];
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
- (void)updateRightBarButtonsForSection:(METSection)section
{
    if (section == METSectionProgress)
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
    // MET trend chart comes later, together with the Progress section.
}

// Rebuild the menu so the checkmark reflects the current section.
- (UIMenu *)buildMenu
{
    NSMutableArray<UIAction *> *actions = [NSMutableArray array];

    for (NSInteger i = METSectionWarmup; i <= METSectionProgress; i++)
    {
        METSection section = (METSection)i;
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

- (void)showSection:(METSection)section
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

- (UIViewController *)childForSection:(METSection)section
{
    switch (section)
    {
        case METSectionWarmup:
            if (self.warmupVC == nil)
            {
                self.warmupVC = [[METWarmupVC alloc] init];
            }
            return self.warmupVC;

        case METSectionTraining:
            return [self placeholderForSection:section
                                      subtitle:@"Guided practice with the table visible. Coming soon."];

        case METSectionWorkout:
            return [self placeholderForSection:section
                                      subtitle:@"Recall the equities under real conditions. Coming soon."];

        case METSectionProgress:
            return [self placeholderForSection:section
                                      subtitle:@"Your MET results and trends. Coming soon."];
    }
}

#pragma mark - Placeholder child

- (UIViewController *)placeholderForSection:(METSection)section
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
