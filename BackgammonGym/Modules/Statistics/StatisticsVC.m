//
//  StatisticsVC.m
//  BackgammonGym
//

#import "StatisticsVC.h"
#import "BGGActivityGridView.h"
#import "BGGModuleStatsCard.h"
#import "UIViewController+BGGHomeButton.h"
#import "BGGLocalization.h"

@interface StatisticsVC ()

@property (nonatomic, strong) UIScrollView         *scrollView;
@property (nonatomic, strong) UIView               *contentView;
@property (nonatomic, strong) BGGActivityGridView  *activityGrid;
@property (nonatomic, strong) UISegmentedControl   *rangeControl;
@property (nonatomic, strong) NSArray<BGGModuleStatsCard *> *statCards;

@end

@implementation StatisticsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Statistics";
    [self installHomeButton];
    [self setupScrollView];
    [self buildContent];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refresh)
                                                 name:@"RefreshAllViews"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refresh
{
    [self.activityGrid reload];
    for (BGGModuleStatsCard *card in self.statCards)
    {
        [card reload];
    }
}

#pragma mark - Scaffolding

- (void)setupScrollView
{
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor      constraintEqualToAnchor:safe.topAnchor],
        [self.scrollView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.scrollView.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],

        [self.contentView.topAnchor      constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor  constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor   constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor    constraintEqualToAnchor:self.scrollView.widthAnchor],
    ]];
}

#pragma mark - Content

- (void)buildContent
{
    UILabel *gridTitle = [self headlineLabel:BGGLocalizedString(@"Activity")];

    UILabel *gridHint = [self captionLabel:
        BGGLocalizedString(@"Your last 12 months. Each square is a day, coloured by your highest "
        @"activity that day.")];

    self.activityGrid = [[BGGActivityGridView alloc] initWithFrame:CGRectZero];
    self.activityGrid.translatesAutoresizingMaskIntoConstraints = NO;

    // Range switcher for the grid. More months = smaller cells; fewer months
    // = larger, easier-to-read cells. Only useful on a narrow (iPhone) screen,
    // so it is hidden on wide layouts (see -updateRangeControlVisibility).
    // Order: 12 / 6 / 3, with 12 (the full range) selected by default.
    self.rangeControl = [[UISegmentedControl alloc] initWithItems:@[
        BGGLocalizedString(@"12 months"),
        BGGLocalizedString(@"6 months"),
        BGGLocalizedString(@"3 months"),
    ]];
    self.rangeControl.selectedSegmentIndex = 0;
    self.rangeControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.rangeControl addTarget:self
                          action:@selector(rangeChanged:)
                forControlEvents:UIControlEventValueChanged];

    // Per-module cumulative stats below the grid. "Pip Count" / "MET" are
    // brand language; the module identifiers match the Core Data records.
    UILabel *moduleTitle = [self headlineLabel:BGGLocalizedString(@"Per module")];

    BGGModuleStatsCard *pipCard =
        [[BGGModuleStatsCard alloc] initWithTitle:@"Pip Count" module:@"pipcount"];
    BGGModuleStatsCard *metCard =
        [[BGGModuleStatsCard alloc] initWithTitle:@"MET" module:@"met"];
    self.statCards = @[pipCard, metCard];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        gridTitle, gridHint, self.rangeControl, self.activityGrid,
        moduleTitle, pipCard, metCard
    ]];
    stack.axis    = UILayoutConstraintAxisVertical;
    stack.spacing = 8.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [stack setCustomSpacing:14.0 afterView:gridHint];
    [stack setCustomSpacing:14.0 afterView:self.rangeControl];
    [stack setCustomSpacing:28.0 afterView:self.activityGrid];
    [stack setCustomSpacing:12.0 afterView:moduleTitle];
    [stack setCustomSpacing:12.0 afterView:pipCard];
    [self.contentView addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor constant:20.0],
        [stack.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:20.0],
        [stack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20.0],
        [stack.bottomAnchor   constraintEqualToAnchor:self.contentView.bottomAnchor constant:-28.0],
    ]];
}

#pragma mark - Range control

- (void)rangeChanged:(UISegmentedControl *)sender
{
    NSInteger months;
    switch (sender.selectedSegmentIndex)
    {
        case 1:  months = 6;  break;
        case 2:  months = 3;  break;
        default: months = 12; break;
    }
    self.activityGrid.monthsToShow = months;
}

// The range switcher only helps on a narrow screen, where shrinking the range
// enlarges the cells. On a wide (iPad) layout the cells are already big, so
// hide the control and keep the grid at the full 12 months.
- (void)updateRangeControlVisibility
{
    BOOL wide = (self.view.bounds.size.width >= 700.0);
    self.rangeControl.hidden = wide;

    if (wide && self.activityGrid.monthsToShow != 12)
    {
        self.rangeControl.selectedSegmentIndex = 0;
        self.activityGrid.monthsToShow = 12;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateRangeControlVisibility];
}

#pragma mark - Label helpers

- (UILabel *)headlineLabel:(NSString *)text
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text          = text;
    lbl.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    lbl.numberOfLines = 0;
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    return lbl;
}

- (UILabel *)captionLabel:(NSString *)text
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text          = text;
    lbl.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    lbl.textColor     = [UIColor secondaryLabelColor];
    lbl.numberOfLines = 0;
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    return lbl;
}

@end
