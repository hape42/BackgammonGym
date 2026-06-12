//
//  METProgressVC.m
//  BackgammonGym
//

#import "METProgressVC.h"
#import "BGGSessionCell.h"
#import "CoreDataManager.h"

static NSString * const kCellID = @"BGGSessionCell";

@interface METProgressVC () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel     *emptyLabel;
@property (nonatomic, copy)   NSArray<BGGWorkout *> *workouts;

@end

@implementation METProgressVC

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
    // Only MET workouts here, newest first.
    self.workouts = [[CoreDataManager sharedManager] getWorkoutsForModule:@"met" mode:nil];

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

    // Compute hit rate and average time from the workout's MET attempts.
    NSArray *attempts = workout.metAttempts.allObjects;
    NSInteger correct = 0;
    NSInteger totalMs = 0;
    for (BGGMETAttempt *a in attempts)
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

// Swipe reveals a Delete action that asks for confirmation first.
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    UIContextualAction *delete = [UIContextualAction
        contextualActionWithStyle:UIContextualActionStyleDestructive
                            title:@"Delete"
                          handler:^(UIContextualAction *action,
                                    UIView *sourceView,
                                    void (^completion)(BOOL))
    {
        [weakSelf confirmDeleteAtIndexPath:indexPath completion:completion];
    }];

    UISwipeActionsConfiguration *config =
        [UISwipeActionsConfiguration configurationWithActions:@[delete]];
    // Don't delete on a full swipe – always go through the confirmation.
    config.performsFirstActionWithFullSwipe = NO;
    return config;
}

- (void)confirmDeleteAtIndexPath:(NSIndexPath *)indexPath
                      completion:(void (^)(BOOL))completion
{
    BGGWorkout *workout = self.workouts[(NSUInteger)indexPath.row];

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Delete session?"
                         message:@"This permanently removes the session and its attempts."
                  preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *a)
    {
        // Dismiss the swipe without deleting.
        if (completion) { completion(NO); }
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Delete"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *a)
    {
        [[CoreDataManager sharedManager] deleteWorkout:workout];
        if (completion) { completion(YES); }
        [self reload];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
