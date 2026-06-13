//
//  SettingsVC.m
//  BackgammonGym
//

#import "SettingsVC.h"
#import "BGGBoardStyleCell.h"
#import "BGGTimeColor.h"
#import "BGGMETSettings.h"
#import "BGGLocalization.h"
#import "BGGLanguage.h"
#import "BGGLanguagePickerVC.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kCellID = @"BGGBoardStyleCell";

@interface SettingsVC () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView   *tableView;
@property (nonatomic, strong) UILabel       *versionLabel;
@property (nonatomic, strong) NSArray<NSDictionary *> *boardsArray;

// Answer-time threshold badges (seconds).
@property (nonatomic, strong) UILabel    *timeGreenBadge;
@property (nonatomic, strong) UILabel    *timeOrangeBadge;
@property (nonatomic, strong) UILabel    *timeRedBadge;
@property (nonatomic, strong) UIStepper  *timeGreenStepper;
@property (nonatomic, strong) UIStepper  *timeOrangeStepper;

// Hit-rate threshold badges (percent).
@property (nonatomic, strong) UILabel    *rateGreenBadge;
@property (nonatomic, strong) UILabel    *rateOrangeBadge;
@property (nonatomic, strong) UILabel    *rateRedBadge;
@property (nonatomic, strong) UIStepper  *rateGreenStepper;
@property (nonatomic, strong) UIStepper  *rateOrangeStepper;

// MET answer tolerance (percent).
@property (nonatomic, strong) UILabel    *toleranceBadge;
@property (nonatomic, strong) UIStepper  *toleranceStepper;

@end

@implementation SettingsVC

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorNamed:@"ColorViewBackground"];
    self.title = BGGLocalizedString(@"Settings");
    [BGGTimeColor registerDefaults];
    [BGGMETSettings registerDefaults];
    [self setupBoardArray];
    [self setupContent];

    // Re-localize live when the language changes (the picker lives here).
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageDidChange)
                                                 name:BGGLanguageDidChangeNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Rebuild the localized chrome after a language switch. The header view holds
// the group titles; the table holds the section headers and the language row.
- (void)languageDidChange
{
    self.title = BGGLocalizedString(@"Settings");
    self.tableView.tableHeaderView = [self buildHeaderView];
    [self.view setNeedsLayout];
    [self.tableView reloadData];
}

// The table header view uses Auto Layout internally; translate that into a
// concrete height once the bounds are known, otherwise the header collapses.
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    UIView *header = self.tableView.tableHeaderView;
    if (header == nil) { return; }

    CGFloat targetWidth = self.tableView.bounds.size.width;
    if (targetWidth <= 0) { return; }

    CGFloat height = [header systemLayoutSizeFittingSize:
                      CGSizeMake(targetWidth, UILayoutFittingCompressedSize.height)
                              withHorizontalFittingPriority:UILayoutPriorityRequired
                                    verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;

    if (ABS(header.frame.size.height - height) > 0.5 ||
        ABS(header.frame.size.width  - targetWidth) > 0.5)
    {
        CGRect f = header.frame;
        f.size.height = height;
        f.size.width  = targetWidth;
        header.frame  = f;
        self.tableView.tableHeaderView = header;   // re-assign to apply
    }
}

#pragma mark - Version

// "Backgammon Gym Version 1.0 build 356"
- (NSString *)versionString
{
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    NSString *version  = info[@"CFBundleShortVersionString"] ?: @"?";
    NSString *build    = info[@"CFBundleVersion"]            ?: @"?";
    return [NSString stringWithFormat:@"Backgammon Gym Version %@ build %@",
            version, build];
}

#pragma mark - Board data

- (void)setupBoardArray
{
    self.boardsArray = @[
        @{ @"number": @4,  @"name": @"Red / Grey HD",  @"design": @"hape42" },
        @{ @"number": @5,  @"name": @"Wood HD",         @"design": @"darkhelmet" },
        @{ @"number": @6,  @"name": @"Metal HD",        @"design": @"darkhelmet" },
        @{ @"number": @7,  @"name": @"Mono HD",         @"design": @"darkhelmet" },
        @{ @"number": @8,  @"name": @"Unicorn",         @"design": @"Jutta Schneider" },
        @{ @"number": @12, @"name": @"Steampunk",       @"design": @"darkhelmet" },
        @{ @"number": @13, @"name": @"Sea",             @"design": @"darkhelmet" },
        @{ @"number": @14, @"name": @"Traditional",     @"design": @"darkhelmet" },
        @{ @"number": @15, @"name": @"Spring",          @"design": @"darkhelmet" },
    ];
}

- (NSInteger)currentBoardSchema
{
    NSInteger schema = [[NSUserDefaults standardUserDefaults] integerForKey:@"BoardSchema"];
    return (schema < 4) ? 4 : schema;
}

#pragma mark - UI setup

- (void)setupContent
{
    // Done button
    UIBarButtonItem *done = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                 target:self
                                                 action:@selector(doneButtonTapped)];
    done.tintColor = [UIColor colorNamed:@"AccentColor"];
    self.navigationItem.rightBarButtonItem = done;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // Version / build label (pinned at the very bottom)
    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.text          = [self versionString];
    self.versionLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.versionLabel.textColor     = [UIColor secondaryLabelColor];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.versionLabel];

    // Table view (board styles). The two threshold groups + the "Select Board
    // Style" header live in the table's header view, so everything scrolls
    // together without nesting scroll views.
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate   = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight  = 100.0;
    [self.tableView registerClass:[BGGBoardStyleCell class]
           forCellReuseIdentifier:kCellID];
    [self.view addSubview:self.tableView];

    self.tableView.tableHeaderView = [self buildHeaderView];

    // The table is centered and capped at 400pt on wide screens, but on
    // narrow phones it must shrink to fit inside the safe area with a margin,
    // otherwise the header content (titles, steppers) gets clipped at the edges.
    NSLayoutConstraint *maxWidth =
        [self.tableView.widthAnchor constraintEqualToConstant:400.0];
    maxWidth.priority = UILayoutPriorityDefaultHigh;   // yields when too wide

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor        constraintEqualToAnchor:safe.topAnchor constant:10.0],
        [self.tableView.bottomAnchor     constraintEqualToAnchor:self.versionLabel.topAnchor constant:-10.0],
        [self.tableView.centerXAnchor    constraintEqualToAnchor:safe.centerXAnchor],
        [self.tableView.leadingAnchor    constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:16.0],
        [self.tableView.trailingAnchor   constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-16.0],
        maxWidth,

        [self.versionLabel.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor constant:-8.0],
        [self.versionLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:16.0],
        [self.versionLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16.0],
    ]];
}

#pragma mark - Header view (threshold groups + board section title)

- (UIView *)buildHeaderView
{
    UIView *header = [[UIView alloc] init];
    // A starting frame; the real height is computed in viewDidLayoutSubviews.
    header.frame = CGRectMake(0, 0, 400, 400);

    UIView *timeGroup = [self buildTimeGroup];
    UIView *rateGroup = [self buildRateGroup];
    UIView *tolGroup  = [self buildToleranceGroup];

    timeGroup.translatesAutoresizingMaskIntoConstraints = NO;
    rateGroup.translatesAutoresizingMaskIntoConstraints = NO;
    tolGroup.translatesAutoresizingMaskIntoConstraints  = NO;

    // Full-width hairlines between the groups. "Select Board Style" and
    // "Language" are now table section headers, so the header view ends after
    // the tolerance group.
    UIView *sep1 = [self separatorView];   // time | rate
    UIView *sep2 = [self separatorView];   // rate | tolerance

    [header addSubview:timeGroup];
    [header addSubview:sep1];
    [header addSubview:rateGroup];
    [header addSubview:sep2];
    [header addSubview:tolGroup];

    NSLayoutConstraint *timeTrailing =
        [timeGroup.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-4.0];
    NSLayoutConstraint *rateTrailing =
        [rateGroup.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-4.0];
    NSLayoutConstraint *tolTrailing =
        [tolGroup.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-4.0];

    timeTrailing.priority  = 999;
    rateTrailing.priority  = 999;
    tolTrailing.priority   = 999;

    // The separators span the same width as the groups; their trailing edges
    // yield for the same brief width==0 layout pass.
    NSLayoutConstraint *sep1Trailing =
        [sep1.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-4.0];
    NSLayoutConstraint *sep2Trailing =
        [sep2.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-4.0];
    sep1Trailing.priority = 999;
    sep2Trailing.priority = 999;

    // The header is created with a placeholder height of 400; UIKit imposes
    // that as UIView-Encapsulated-Layout-Height during the first layout pass,
    // before viewDidLayoutSubviews computes the real height. The bottom pin
    // below would conflict with that placeholder for one frame, so let it
    // yield instead of logging. Once the real height is set it satisfies.
    NSLayoutConstraint *tolBottom =
        [tolGroup.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-10.0];
    tolBottom.priority = 999;

    [NSLayoutConstraint activateConstraints:@[
        [timeGroup.topAnchor      constraintEqualToAnchor:header.topAnchor constant:6.0],
        [timeGroup.leadingAnchor  constraintEqualToAnchor:header.leadingAnchor constant:4.0],
        timeTrailing,

        [sep1.topAnchor           constraintEqualToAnchor:timeGroup.bottomAnchor constant:16.0],
        [sep1.leadingAnchor       constraintEqualToAnchor:header.leadingAnchor constant:4.0],
        sep1Trailing,
        [sep1.heightAnchor        constraintEqualToConstant:1.0],

        [rateGroup.topAnchor      constraintEqualToAnchor:sep1.bottomAnchor constant:16.0],
        [rateGroup.leadingAnchor  constraintEqualToAnchor:header.leadingAnchor constant:4.0],
        rateTrailing,

        [sep2.topAnchor           constraintEqualToAnchor:rateGroup.bottomAnchor constant:16.0],
        [sep2.leadingAnchor       constraintEqualToAnchor:header.leadingAnchor constant:4.0],
        sep2Trailing,
        [sep2.heightAnchor        constraintEqualToConstant:1.0],

        [tolGroup.topAnchor       constraintEqualToAnchor:sep2.bottomAnchor constant:16.0],
        [tolGroup.leadingAnchor   constraintEqualToAnchor:header.leadingAnchor constant:4.0],
        tolTrailing,
        tolBottom,
    ]];

    return header;
}

#pragma mark - Time threshold group

- (UIView *)buildTimeGroup
{
    UIView *group = [[UIView alloc] init];

    UILabel *title = [[UILabel alloc] init];
    title.text = BGGLocalizedString(@"Answer time thresholds");
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [group addSubview:title];

    self.timeGreenBadge  = [self badge];
    self.timeOrangeBadge = [self badge];
    self.timeRedBadge    = [self badge];

    self.timeGreenStepper = [self stepperWithMin:1 max:300
                                           value:(double)[BGGTimeColor greenMax]
                                          action:@selector(timeGreenChanged)];
    self.timeOrangeStepper = [self stepperWithMin:2 max:600
                                            value:(double)[BGGTimeColor orangeMax]
                                           action:@selector(timeOrangeChanged)];

    UIView *good = [self rowWithTitle:[self rowTitle:BGGLocalizedString(@"Good")] badge:self.timeGreenBadge
                              stepper:self.timeGreenStepper];
    UIView *ok   = [self rowWithTitle:[self rowTitle:BGGLocalizedString(@"OK")]   badge:self.timeOrangeBadge
                              stepper:self.timeOrangeStepper];
    UIView *bad  = [self rowWithTitle:[self rowTitle:BGGLocalizedString(@"Bad")]  badge:self.timeRedBadge
                              stepper:nil];

    [self stackGroup:group title:title good:good ok:ok bad:bad];
    [self refreshTimeValues];
    return group;
}

#pragma mark - Rate threshold group

- (UIView *)buildRateGroup
{
    UIView *group = [[UIView alloc] init];

    UILabel *title = [[UILabel alloc] init];
    title.text = BGGLocalizedString(@"Hit rate thresholds");
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [group addSubview:title];

    self.rateGreenBadge  = [self badge];
    self.rateOrangeBadge = [self badge];
    self.rateRedBadge    = [self badge];

    self.rateGreenStepper = [self stepperWithMin:2 max:100
                                           value:(double)[BGGTimeColor rateGreenMin]
                                          action:@selector(rateGreenChanged)];
    self.rateOrangeStepper = [self stepperWithMin:1 max:99
                                            value:(double)[BGGTimeColor rateOrangeMin]
                                           action:@selector(rateOrangeChanged)];

    UIView *good = [self rowWithTitle:[self rowTitle:BGGLocalizedString(@"Good")] badge:self.rateGreenBadge
                              stepper:self.rateGreenStepper];
    UIView *ok   = [self rowWithTitle:[self rowTitle:BGGLocalizedString(@"OK")]   badge:self.rateOrangeBadge
                              stepper:self.rateOrangeStepper];
    UIView *bad  = [self rowWithTitle:[self rowTitle:BGGLocalizedString(@"Bad")]  badge:self.rateRedBadge
                              stepper:nil];

    [self stackGroup:group title:title good:good ok:ok bad:bad];
    [self refreshRateValues];
    return group;
}

#pragma mark - MET tolerance group

- (UIView *)buildToleranceGroup
{
    UIView *group = [[UIView alloc] init];

    UILabel *title = [[UILabel alloc] init];
    title.text = BGGLocalizedString(@"MET answer tolerance");
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [group addSubview:title];

    self.toleranceBadge   = [self badge];
    self.toleranceStepper = [self stepperWithMin:0 max:3
                                           value:(double)[BGGMETSettings tolerancePercent]
                                          action:@selector(toleranceChanged)];

    UIView *row = [self rowWithTitle:[self rowTitle:BGGLocalizedString(@"Accepted deviation")]
                               badge:self.toleranceBadge
                             stepper:self.toleranceStepper];
    [group addSubview:row];

    // A single row under the title – no Good/OK/Bad triple here.
    NSLayoutConstraint *titleTrailing =
        [title.trailingAnchor constraintEqualToAnchor:group.trailingAnchor];
    NSLayoutConstraint *rowTrailing =
        [row.trailingAnchor constraintEqualToAnchor:group.trailingAnchor];
    titleTrailing.priority = 999;
    rowTrailing.priority   = 999;

    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor     constraintEqualToAnchor:group.topAnchor],
        [title.leadingAnchor constraintEqualToAnchor:group.leadingAnchor],
        titleTrailing,

        [row.topAnchor       constraintEqualToAnchor:title.bottomAnchor constant:10.0],
        [row.leadingAnchor   constraintEqualToAnchor:group.leadingAnchor],
        rowTrailing,
        [row.heightAnchor    constraintEqualToConstant:38.0],

        [group.bottomAnchor  constraintEqualToAnchor:row.bottomAnchor],
    ]];

    [self refreshToleranceValue];
    return group;
}

// Lays out a group: header title, then three rows stacked below it.
- (void)stackGroup:(UIView *)group
             title:(UILabel *)title
              good:(UIView *)good
                ok:(UIView *)ok
               bad:(UIView *)bad
{
    [group addSubview:good];
    [group addSubview:ok];
    [group addSubview:bad];

    // Trailing constraints kept just below required, for the same reason as in
    // buildHeaderView: during the table's first layout pass the header (and thus
    // these nested groups) is briefly forced to width 0, which would otherwise
    // make leading and trailing conflict and log noise.
    NSLayoutConstraint *titleTrailing = [title.trailingAnchor constraintEqualToAnchor:group.trailingAnchor];
    NSLayoutConstraint *goodTrailing  = [good.trailingAnchor  constraintEqualToAnchor:group.trailingAnchor];
    NSLayoutConstraint *okTrailing    = [ok.trailingAnchor    constraintEqualToAnchor:group.trailingAnchor];
    NSLayoutConstraint *badTrailing   = [bad.trailingAnchor   constraintEqualToAnchor:group.trailingAnchor];
    titleTrailing.priority = 999;
    goodTrailing.priority  = 999;
    okTrailing.priority    = 999;
    badTrailing.priority   = 999;

    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor      constraintEqualToAnchor:group.topAnchor],
        [title.leadingAnchor  constraintEqualToAnchor:group.leadingAnchor],
        titleTrailing,

        [good.topAnchor       constraintEqualToAnchor:title.bottomAnchor constant:10.0],
        [good.leadingAnchor   constraintEqualToAnchor:group.leadingAnchor],
        goodTrailing,
        [good.heightAnchor    constraintEqualToConstant:38.0],

        [ok.topAnchor         constraintEqualToAnchor:good.bottomAnchor constant:8.0],
        [ok.leadingAnchor     constraintEqualToAnchor:group.leadingAnchor],
        okTrailing,
        [ok.heightAnchor      constraintEqualToConstant:38.0],

        [bad.topAnchor        constraintEqualToAnchor:ok.bottomAnchor constant:8.0],
        [bad.leadingAnchor    constraintEqualToAnchor:group.leadingAnchor],
        badTrailing,
        [bad.heightAnchor     constraintEqualToConstant:38.0],

        [group.bottomAnchor   constraintEqualToAnchor:bad.bottomAnchor],
    ]];
}

#pragma mark - Reusable builders

- (UIStepper *)stepperWithMin:(double)min max:(double)max
                        value:(double)value action:(SEL)action
{
    UIStepper *s = [[UIStepper alloc] init];
    s.minimumValue = min;
    s.maximumValue = max;
    s.stepValue    = 1;
    s.value        = value;
    s.tintColor    = [UIColor colorNamed:@"AccentColor"];
    [s addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    return s;
}

// One row: title on the left, coloured badge + optional stepper on the right.
- (UIView *)rowWithTitle:(UILabel *)title
                   badge:(UILabel *)badge
                 stepper:(nullable UIStepper *)stepper
{
    UIView *row = [[UIView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;

    title.translatesAutoresizingMaskIntoConstraints = NO;
    badge.translatesAutoresizingMaskIntoConstraints = NO;

    [row addSubview:title];
    [row addSubview:badge];

    NSMutableArray *cons = [NSMutableArray arrayWithArray:@[
        [title.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [title.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],

        [badge.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [badge.heightAnchor  constraintEqualToConstant:28.0],
    ]];

    if (stepper != nil)
    {
        stepper.translatesAutoresizingMaskIntoConstraints = NO;
        [row addSubview:stepper];
        [cons addObjectsFromArray:@[
            [stepper.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
            [stepper.centerYAnchor  constraintEqualToAnchor:row.centerYAnchor],
            [badge.trailingAnchor   constraintEqualToAnchor:stepper.leadingAnchor constant:-12.0],
        ]];
    }
    else
    {
        // No stepper: align the badge under the others by leaving a typical
        // stepper width on the right.
        [cons addObject:
         [badge.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-106.0]];
    }

    [NSLayoutConstraint activateConstraints:cons];
    return row;
}

- (UILabel *)rowTitle:(NSString *)text
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text      = text;
    lbl.font      = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    lbl.textColor = [UIColor labelColor];
    return lbl;
}

// A 1px hairline used to separate the setting groups in the header view.
- (UIView *)separatorView
{
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor separatorColor];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    return line;
}

// A coloured pill with white text.
- (UILabel *)badge
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.font          = [UIFont monospacedDigitSystemFontOfSize:15.0
                                                         weight:UIFontWeightSemibold];
    lbl.textColor     = [UIColor whiteColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.layer.cornerRadius  = 10.0;
    lbl.layer.masksToBounds = YES;
    return lbl;
}

#pragma mark - Time values

- (void)refreshTimeValues
{
    NSInteger green  = [BGGTimeColor greenMax];
    NSInteger orange = [BGGTimeColor orangeMax];

    self.timeGreenBadge.text  = [NSString stringWithFormat:@"  ≤ %ld seconds  ", (long)green];
    self.timeOrangeBadge.text = [NSString stringWithFormat:@"  ≤ %ld seconds  ", (long)orange];
    self.timeRedBadge.text    = [NSString stringWithFormat:@"  > %ld seconds  ", (long)orange];

    self.timeGreenBadge.backgroundColor  = [UIColor systemGreenColor];
    self.timeOrangeBadge.backgroundColor = [UIColor systemOrangeColor];
    self.timeRedBadge.backgroundColor    = [UIColor systemRedColor];
}

- (void)timeGreenChanged
{
    [BGGTimeColor setGreenMax:(NSInteger)self.timeGreenStepper.value];
    self.timeGreenStepper.value = (double)[BGGTimeColor greenMax];
    [self refreshTimeValues];
}

- (void)timeOrangeChanged
{
    [BGGTimeColor setOrangeMax:(NSInteger)self.timeOrangeStepper.value];
    self.timeOrangeStepper.value = (double)[BGGTimeColor orangeMax];
    self.timeGreenStepper.value  = (double)[BGGTimeColor greenMax];
    [self refreshTimeValues];
}

#pragma mark - Rate values

- (void)refreshRateValues
{
    NSInteger green  = [BGGTimeColor rateGreenMin];
    NSInteger orange = [BGGTimeColor rateOrangeMin];

    self.rateGreenBadge.text  = [NSString stringWithFormat:@"  ≥ %ld%%  ", (long)green];
    self.rateOrangeBadge.text = [NSString stringWithFormat:@"  ≥ %ld%%  ", (long)orange];
    self.rateRedBadge.text    = [NSString stringWithFormat:@"  < %ld%%  ", (long)orange];

    self.rateGreenBadge.backgroundColor  = [UIColor systemGreenColor];
    self.rateOrangeBadge.backgroundColor = [UIColor systemOrangeColor];
    self.rateRedBadge.backgroundColor    = [UIColor systemRedColor];
}

- (void)rateGreenChanged
{
    [BGGTimeColor setRateGreenMin:(NSInteger)self.rateGreenStepper.value];
    self.rateGreenStepper.value = (double)[BGGTimeColor rateGreenMin];
    [self refreshRateValues];
}

- (void)rateOrangeChanged
{
    [BGGTimeColor setRateOrangeMin:(NSInteger)self.rateOrangeStepper.value];
    self.rateOrangeStepper.value = (double)[BGGTimeColor rateOrangeMin];
    self.rateGreenStepper.value  = (double)[BGGTimeColor rateGreenMin];
    [self refreshRateValues];
}

#pragma mark - Tolerance value

- (void)refreshToleranceValue
{
    NSInteger tol = [BGGMETSettings tolerancePercent];

    if (tol == 0)
    {
        self.toleranceBadge.text = [NSString stringWithFormat:@"  %@  ",
                                    BGGLocalizedString(@"exact")];
    }
    else
    {
        self.toleranceBadge.text = [NSString stringWithFormat:@"  ± %ld%%  ", (long)tol];
    }
    self.toleranceBadge.backgroundColor = [UIColor colorNamed:@"AccentColor"];
}

- (void)toleranceChanged
{
    [BGGMETSettings setTolerancePercent:(NSInteger)self.toleranceStepper.value];
    self.toleranceStepper.value = (double)[BGGMETSettings tolerancePercent];
    [self refreshToleranceValue];
}

#pragma mark - UITableViewDataSource

// Section 0: language picker (one row). Section 1: board styles.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == 0) ? 1 : (NSInteger)self.boardsArray.count;
}

// Custom section headers in the same bold Headline style as the threshold
// group titles in the table header view, so "Language" and "Select Board
// Style" match "MET answer tolerance" etc. rather than the small grey system
// header style.
- (nullable UIView *)tableView:(UITableView *)tableView
        viewForHeaderInSection:(NSInteger)section
{
    NSString *text = (section == 0) ? BGGLocalizedString(@"Language")
                                    : BGGLocalizedString(@"Select Board Style");

    UIView *container = [[UIView alloc] init];

    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    label.textColor = [UIColor labelColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:label];

    // Align with the inset-grouped card edge and give it breathing room.
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor  constraintEqualToAnchor:container.layoutMarginsGuide.leadingAnchor],
        [label.trailingAnchor constraintEqualToAnchor:container.layoutMarginsGuide.trailingAnchor],
        [label.topAnchor      constraintEqualToAnchor:container.topAnchor constant:8.0],
        [label.bottomAnchor   constraintEqualToAnchor:container.bottomAnchor constant:-6.0],
    ]];

    return container;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        static NSString * const kLangCellID = @"LanguageRow";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLangCellID];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                          reuseIdentifier:kLangCellID];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.textLabel.text = BGGLocalizedString(@"Language");

        // Show the current choice on the right: the chosen language's own
        // name, or "System" when following the device.
        NSString *chosen = [BGGLanguage sharedLanguage].language;
        cell.detailTextLabel.text = (chosen == nil)
            ? BGGLocalizedString(@"System")
            : [BGGLanguage displayNameForLanguageCode:chosen];
        return cell;
    }

    BGGBoardStyleCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID
                                                              forIndexPath:indexPath];
    NSDictionary *dict   = self.boardsArray[(NSUInteger)indexPath.row];
    NSInteger schema     = [dict[@"number"] integerValue];
    BOOL isSelected      = (schema == [self currentBoardSchema]);

    [cell configureWithSchema:schema
                         name:dict[@"name"]
                     designer:dict[@"design"]
                   isSelected:isSelected];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0)
    {
        BGGLanguagePickerVC *picker = [[BGGLanguagePickerVC alloc] init];
        [self.navigationController pushViewController:picker animated:YES];
        return;
    }

    NSDictionary *dict = self.boardsArray[(NSUInteger)indexPath.row];
    [[NSUserDefaults standardUserDefaults] setInteger:[dict[@"number"] integerValue]
                                               forKey:@"BoardSchema"];
    [tableView reloadData];
}

#pragma mark - Actions

- (void)doneButtonTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

NS_ASSUME_NONNULL_END
