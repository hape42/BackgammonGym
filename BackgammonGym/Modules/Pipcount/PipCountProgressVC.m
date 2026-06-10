//
//  PipCountProgressVC.m
//  BackgammonGym
//

#import "PipCountProgressVC.h"
#import "BGGSessionCell.h"
#import "CoreDataManager.h"

static NSString * const kCellID = @"BGGSessionCell";

@interface PipCountProgressVC () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel     *emptyLabel;
@property (nonatomic, copy)   NSArray<BGGWorkout *> *workouts;

@end

@implementation PipCountProgressVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self setupTableView];
    [self setupEmptyLabel];

    // Reload when another device syncs changes in.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:@"RefreshAllViews"
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Reload every time the section becomes visible, so a session just played
// shows up immediately.
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reload];
}

#pragma mark - Setup

- (void)setupTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                  style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate   = self;
    self.tableView.rowHeight  = 72.0;
    [self.tableView registerClass:[BGGSessionCell class] forCellReuseIdentifier:kCellID];
    [self.view addSubview:self.tableView];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor      constraintEqualToAnchor:safe.topAnchor],
        [self.tableView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.tableView.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],
    ]];
}

- (void)setupEmptyLabel
{
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.text          = @"No sessions yet.\nPlay a Training or Workout to see your history here.";
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.textColor     = [UIColor tertiaryLabelColor];
    self.emptyLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.emptyLabel.hidden        = YES;
    [self.view addSubview:self.emptyLabel];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyLabel.centerXAnchor  constraintEqualToAnchor:safe.centerXAnchor],
        [self.emptyLabel.centerYAnchor  constraintEqualToAnchor:safe.centerYAnchor],
        [self.emptyLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:32.0],
        [self.emptyLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-32.0],
    ]];
}

#pragma mark - Data

- (void)reload
{
    self.workouts = [[CoreDataManager sharedManager] getAllWorkouts];

    BOOL empty = (self.workouts.count == 0);
    self.emptyLabel.hidden = !empty;
    self.tableView.hidden  = empty;

    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)self.workouts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BGGSessionCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID
                                                           forIndexPath:indexPath];
    BGGWorkout *workout = self.workouts[(NSUInteger)indexPath.row];

    // Compute hit rate and average time from the workout's attempts.
    NSArray *attempts = workout.attempts.allObjects;
    NSInteger correct = 0;
    NSInteger totalMs = 0;
    for (BGGAttempt *a in attempts)
    {
        if (a.isCorrect) { correct++; }
        totalMs += a.elapsedMs;
    }
    NSInteger count   = (NSInteger)attempts.count;
    NSInteger avgMs   = (count > 0) ? (totalMs / count) : 0;
    BOOL isComplete   = (workout.finishedAt != nil);

    [cell configureWithDate:workout.startedAt
                       mode:workout.mode
               correctCount:correct
                 totalCount:count
              averageMillis:avgMs
                 isComplete:isComplete];
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section
{
    return @"Session history";
}

// Swipe to delete a session.
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        BGGWorkout *workout = self.workouts[(NSUInteger)indexPath.row];
        [[CoreDataManager sharedManager] deleteWorkout:workout];
        [self reload];
    }
}

@end
