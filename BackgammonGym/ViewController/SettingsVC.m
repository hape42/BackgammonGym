//
//  SettingsVC.m
//  BackgammonGym
//

#import "SettingsVC.h"
#import "BGGBoardStyleCell.h"
#import "BGGTimeColor.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kCellID = @"BGGBoardStyleCell";

@interface SettingsVC () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView   *tableView;
@property (nonatomic, strong) UILabel       *versionLabel;
@property (nonatomic, strong) UILabel       *selectBoard;
@property (nonatomic, strong) NSArray<NSDictionary *> *boardsArray;

// Timing thresholds
@property (nonatomic, strong) UILabel    *timingHeader;
@property (nonatomic, strong) UILabel    *greenBadge;
@property (nonatomic, strong) UILabel    *orangeBadge;
@property (nonatomic, strong) UILabel    *redBadge;
@property (nonatomic, strong) UIStepper  *greenStepper;
@property (nonatomic, strong) UIStepper  *orangeStepper;
@property (nonatomic, strong) UIView     *timingGroup;

@end

@implementation SettingsVC

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorNamed:@"ColorViewBackground"];
    self.title = @"Settings";
    [BGGTimeColor registerDefaults];
    [self setupBoardArray];
    [self setupContent];
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

    // Version / build label
    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.text          = [self versionString];
    self.versionLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.versionLabel.textColor     = [UIColor secondaryLabelColor];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.versionLabel];

    // Timing thresholds group (two stepper rows)
    [self setupTimingGroup];

    // Header label
    self.selectBoard = [[UILabel alloc] init];
    self.selectBoard.text = @"Select Board Style";
    self.selectBoard.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.selectBoard];

    // Table view
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate   = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight  = 100.0;
    self.tableView.layer.borderWidth  = 1.0;
    self.tableView.layer.cornerRadius = 14.0;
    self.tableView.layer.borderColor  = [UIColor colorNamed:@"ColorImages"].CGColor;
    [self.tableView registerClass:[BGGBoardStyleCell class]
           forCellReuseIdentifier:kCellID];
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.timingGroup.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:10.0],
        [self.timingGroup.centerXAnchor  constraintEqualToAnchor:safe.centerXAnchor],
        [self.timingGroup.widthAnchor    constraintEqualToConstant:400.0],

        [self.selectBoard.topAnchor      constraintEqualToAnchor:self.timingGroup.bottomAnchor constant:18.0],
        [self.selectBoard.centerXAnchor  constraintEqualToAnchor:safe.centerXAnchor],
        [self.selectBoard.heightAnchor   constraintEqualToConstant:35.0],

        [self.versionLabel.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor constant:-8.0],
        [self.versionLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:16.0],
        [self.versionLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16.0],

        [self.tableView.topAnchor        constraintEqualToAnchor:self.selectBoard.bottomAnchor constant:10.0],
        [self.tableView.bottomAnchor     constraintEqualToAnchor:self.versionLabel.topAnchor constant:-10.0],
        [self.tableView.centerXAnchor    constraintEqualToAnchor:safe.centerXAnchor],
        [self.tableView.widthAnchor      constraintEqualToConstant:400.0],
    ]];
}

#pragma mark - Timing group

- (void)setupTimingGroup
{
    self.timingGroup = [[UIView alloc] init];
    self.timingGroup.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.timingGroup];

    // Group header
    self.timingHeader = [[UILabel alloc] init];
    self.timingHeader.text      = @"Answer time thresholds";
    self.timingHeader.font      = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.timingHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.timingGroup addSubview:self.timingHeader];

    // Badges show the time range in the matching colour.
    self.greenBadge  = [self badge];
    self.orangeBadge = [self badge];
    self.redBadge    = [self badge];

    // Good row: green badge + stepper
    self.greenStepper = [[UIStepper alloc] init];
    self.greenStepper.minimumValue = 1;
    self.greenStepper.maximumValue = 300;
    self.greenStepper.stepValue    = 1;
    self.greenStepper.value        = (double)[BGGTimeColor greenMax];
    self.greenStepper.tintColor    = [UIColor colorNamed:@"AccentColor"];
    [self.greenStepper addTarget:self action:@selector(greenStepperChanged)
                forControlEvents:UIControlEventValueChanged];

    UIView *goodRow = [self rowWithTitle:[self rowTitle:@"Good"]
                                   badge:self.greenBadge
                                 stepper:self.greenStepper];
    [self.timingGroup addSubview:goodRow];

    // OK row: orange badge + stepper
    self.orangeStepper = [[UIStepper alloc] init];
    self.orangeStepper.minimumValue = 2;
    self.orangeStepper.maximumValue = 600;
    self.orangeStepper.stepValue    = 1;
    self.orangeStepper.value        = (double)[BGGTimeColor orangeMax];
    self.orangeStepper.tintColor    = [UIColor colorNamed:@"AccentColor"];
    [self.orangeStepper addTarget:self action:@selector(orangeStepperChanged)
                 forControlEvents:UIControlEventValueChanged];

    UIView *okRow = [self rowWithTitle:[self rowTitle:@"OK"]
                                 badge:self.orangeBadge
                               stepper:self.orangeStepper];
    [self.timingGroup addSubview:okRow];

    // Bad row: red badge, no stepper (follows automatically from the OK value).
    UIView *badRow = [self rowWithTitle:[self rowTitle:@"Bad"]
                                  badge:self.redBadge
                                stepper:nil];
    [self.timingGroup addSubview:badRow];

    [NSLayoutConstraint activateConstraints:@[
        [self.timingHeader.topAnchor      constraintEqualToAnchor:self.timingGroup.topAnchor],
        [self.timingHeader.leadingAnchor  constraintEqualToAnchor:self.timingGroup.leadingAnchor],
        [self.timingHeader.trailingAnchor constraintEqualToAnchor:self.timingGroup.trailingAnchor],

        [goodRow.topAnchor       constraintEqualToAnchor:self.timingHeader.bottomAnchor constant:10.0],
        [goodRow.leadingAnchor   constraintEqualToAnchor:self.timingGroup.leadingAnchor],
        [goodRow.trailingAnchor  constraintEqualToAnchor:self.timingGroup.trailingAnchor],
        [goodRow.heightAnchor    constraintEqualToConstant:38.0],

        [okRow.topAnchor         constraintEqualToAnchor:goodRow.bottomAnchor constant:8.0],
        [okRow.leadingAnchor     constraintEqualToAnchor:self.timingGroup.leadingAnchor],
        [okRow.trailingAnchor    constraintEqualToAnchor:self.timingGroup.trailingAnchor],
        [okRow.heightAnchor      constraintEqualToConstant:38.0],

        [badRow.topAnchor        constraintEqualToAnchor:okRow.bottomAnchor constant:8.0],
        [badRow.leadingAnchor    constraintEqualToAnchor:self.timingGroup.leadingAnchor],
        [badRow.trailingAnchor   constraintEqualToAnchor:self.timingGroup.trailingAnchor],
        [badRow.heightAnchor     constraintEqualToConstant:38.0],

        [self.timingGroup.bottomAnchor constraintEqualToAnchor:badRow.bottomAnchor],
    ]];

    [self refreshTimingValues];
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
        // No stepper: align the badge where the others' badges sit, by
        // pinning its trailing edge to the row's trailing edge minus a
        // typical stepper width so all three badges line up.
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

// A coloured pill with white text, holding a time range.
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

// Reflects the current thresholds in the three badges.
- (void)refreshTimingValues
{
    NSInteger green  = [BGGTimeColor greenMax];
    NSInteger orange = [BGGTimeColor orangeMax];

    // Leading/trailing spaces pad the pill (UILabel has no intrinsic inset).
    self.greenBadge.text  = [NSString stringWithFormat:@"  ≤ %ld seconds  ", (long)green];
    self.orangeBadge.text = [NSString stringWithFormat:@"  ≤ %ld seconds  ", (long)orange];
    self.redBadge.text    = [NSString stringWithFormat:@"  > %ld seconds  ", (long)orange];

    self.greenBadge.backgroundColor  = [UIColor systemGreenColor];
    self.orangeBadge.backgroundColor = [UIColor systemOrangeColor];
    self.redBadge.backgroundColor    = [UIColor systemRedColor];
}

- (void)greenStepperChanged
{
    [BGGTimeColor setGreenMax:(NSInteger)self.greenStepper.value];
    // The setter may clamp; reflect the stored value back into the stepper.
    self.greenStepper.value = (double)[BGGTimeColor greenMax];
    [self refreshTimingValues];
}

- (void)orangeStepperChanged
{
    [BGGTimeColor setOrangeMax:(NSInteger)self.orangeStepper.value];
    self.orangeStepper.value  = (double)[BGGTimeColor orangeMax];
    // Green may have been clamped relative to orange; keep its stepper in sync.
    self.greenStepper.value   = (double)[BGGTimeColor greenMax];
    [self refreshTimingValues];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)self.boardsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
