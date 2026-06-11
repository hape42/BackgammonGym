//
//  PipCountExerciseVC.m
//  BackgammonGym
//
//  Shared logic for Training and Workout.
//  Layout adapts to available width:
//    Wide (>=700pt): board left, controls right.
//    Narrow: board top, controls below.
//
//  Two pip count fields: Blue (my checkers) and Yellow (opponent).
//  After checking, a "Next →" button appears so the user can study
//  the board as long as needed before moving on.
//

#import "PipCountExerciseVC.h"
#import "UIViewController+BGGHomeButton.h"
#import "BGGBoardView.h"
#import "BGGBoardIDView.h"
#import "BGGBoardGeometry.h"
#import "BGGBoardState.h"
#import "BGGPosition.h"
#import "PositionDatabase.h"
#import "Tools.h"
#import "BGGTimeColor.h"
#import "CoreDataManager.h"

static const CGFloat kWideThreshold = 700.0;

@interface PipCountExerciseVC () <UITextFieldDelegate>

// Scroll container – lets the board scroll up out of the way when the
// keyboard appears, keeping the input fields reachable.
@property (nonatomic, strong) UIScrollView  *scrollView;
@property (nonatomic, strong) UIView        *contentView;

// Optional explanatory line above the board (set from -infoText).
@property (nonatomic, strong) UILabel       *infoLabel;

// Board
@property (nonatomic, strong) BGGBoardView    *boardView;
@property (nonatomic, strong) BGGBoardIDView  *boardIDView;

// Controls container
@property (nonatomic, strong) UIView        *controlsView;

// Progress + timer
@property (nonatomic, strong) UILabel       *progressLabel;
@property (nonatomic, strong) UILabel       *timerLabel;

// Input
@property (nonatomic, strong) UILabel       *blueLabel;
@property (nonatomic, strong) UITextField   *blueField;
@property (nonatomic, strong) UILabel       *yellowLabel;
@property (nonatomic, strong) UITextField   *yellowField;

// Buttons
@property (nonatomic, strong) UIButton      *submitButton;
@property (nonatomic, strong) UIButton      *cancelButton;
@property (nonatomic, strong) UIButton      *nextButton;
@property (nonatomic, strong) UIButton      *cancelAfterNextButton;

// Feedback
@property (nonatomic, strong) UILabel       *feedbackLabel;
@property (nonatomic, strong) UILabel       *timeBadge;

// Timer
@property (nonatomic, strong) NSTimer       *timer;
@property (nonatomic, assign) NSTimeInterval elapsedSeconds;

// Session state
@property (nonatomic, strong) NSArray<BGGPositionEntry *> *positions;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger correctCount;
@property (nonatomic, assign) NSInteger totalCount;

// The Core Data workout for the running session (nil until started).
@property (nonatomic, strong) BGGWorkout *currentWorkout;

// Layout
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *wideConstraints;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *narrowConstraints;
@property (nonatomic, assign) BOOL isWideLayout;

@end

@implementation PipCountExerciseVC

- (BOOL)showsPointNumbers { return NO; }
- (BOOL)measureTime       { return NO; }

// Base implementation – subclasses must override to define their position set.
- (NSArray<NSString *> *)requiredTags { return @[]; }

// Identifiers stored with every workout and attempt. Subclasses override
// modeIdentifier; the module stays "pipcount" across this class family.
- (NSString *)moduleIdentifier { return @"pipcount"; }
- (NSString *)modeIdentifier   { return @"";         }

// Base implementation – no info line. Subclasses override.
- (nullable NSString *)infoText { return nil; }

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self installHomeButton];
    [self buildUI];
    [self registerForKeyboardNotifications];
}

- (void)registerForKeyboardNotifications
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardWillChangeFrame:)
               name:UIKeyboardWillChangeFrameNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:)
               name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.positions == nil)
    {
        [self showCountPicker];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopTimer];
}

#pragma mark - UI

- (void)buildUI
{
    CGFloat m = 16.0;

    // Scroll view fills the safe area. All content lives inside contentView.
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
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

        // contentView spans the scroll view's content area and matches its
        // width, so layout is driven vertically and only scrolls when needed.
        [self.contentView.topAnchor      constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor  constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor   constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor    constraintEqualToAnchor:self.scrollView.widthAnchor],
    ]];

    // Optional info line above the board (mode explanation).
    self.infoLabel               = [[UILabel alloc] init];
    self.infoLabel.numberOfLines = 0;
    self.infoLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.infoLabel.textColor     = [UIColor secondaryLabelColor];
    self.infoLabel.text          = [self infoText];
    self.infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.infoLabel];

    // Board view
    self.boardView = [[BGGBoardView alloc] init];
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardView.boardDesign       = [Tools currentBoardDesign];
    self.boardView.showsPointNumbers = self.showsPointNumbers;
    self.boardView.showsCube         = NO;
    self.boardView.showsDice         = NO;
    [self.contentView addSubview:self.boardView];

    CGFloat ratio = kBGGBoardHeight / kBGGBoardWidth;
    [[self.boardView.heightAnchor constraintEqualToAnchor:self.boardView.widthAnchor
                                               multiplier:ratio] setActive:YES];

    // ID view sits directly below the board
    self.boardIDView = [[BGGBoardIDView alloc] init];
    self.boardIDView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.boardIDView];

    // Controls container
    self.controlsView = [[UIView alloc] init];
    self.controlsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.controlsView];

    // Progress label
    self.progressLabel = [[UILabel alloc] init];
    self.progressLabel.font      = [UIFont monospacedDigitSystemFontOfSize:15.0
                                                                    weight:UIFontWeightMedium];
    self.progressLabel.textColor = [UIColor secondaryLabelColor];
    self.progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlsView addSubview:self.progressLabel];

    // Timer label
    self.timerLabel = [[UILabel alloc] init];
    self.timerLabel.font          = [UIFont monospacedDigitSystemFontOfSize:15.0
                                                                     weight:UIFontWeightMedium];
    self.timerLabel.textColor     = [UIColor secondaryLabelColor];
    self.timerLabel.textAlignment = NSTextAlignmentCenter;
    // Timer label – visible only in Workout (live countdown pressure).
    // In Training the time is shown in the feedback after checking.
    self.timerLabel.hidden = !self.measureTime;
    self.timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlsView addSubview:self.timerLabel];

    // Opponent label + field (top – opponent's checkers are at the top of the board)
    self.yellowLabel = [self labelWithText:@"Opponent pip count"];
    [self.controlsView addSubview:self.yellowLabel];
    self.yellowField = [self pipCountField];
    self.yellowField.returnKeyType = UIReturnKeyNext;
    [self.controlsView addSubview:self.yellowField];

    // My label + field (bottom – my checkers are at the bottom of the board)
    self.blueLabel = [self labelWithText:@"My pip count"];
    [self.controlsView addSubview:self.blueLabel];
    self.blueField = [self pipCountField];
    self.blueField.returnKeyType = UIReturnKeyDone;
    [self.controlsView addSubview:self.blueField];

    // Check button
    self.submitButton = [self actionButtonWithTitle:@"Check"
                                             action:@selector(submitTapped)];
    [self.controlsView addSubview:self.submitButton];

    // Cancel button (visible under Check)
    self.cancelButton = [self cancelButtonWithAction:@selector(cancelTapped)];
    [self.controlsView addSubview:self.cancelButton];

    // Feedback label
    self.feedbackLabel = [[UILabel alloc] init];
    self.feedbackLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
    self.feedbackLabel.textAlignment = NSTextAlignmentCenter;
    self.feedbackLabel.numberOfLines = 0;
    self.feedbackLabel.alpha         = 0.0;
    self.feedbackLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlsView addSubview:self.feedbackLabel];

    // Time badge – a coloured pill showing the answer time after a check.
    // Colour comes from BGGTimeColor (green / orange / red by threshold).
    self.timeBadge = [[UILabel alloc] init];
    self.timeBadge.font          = [UIFont monospacedDigitSystemFontOfSize:17.0
                                                                    weight:UIFontWeightSemibold];
    self.timeBadge.textColor     = [UIColor whiteColor];
    self.timeBadge.textAlignment = NSTextAlignmentCenter;
    self.timeBadge.layer.cornerRadius = 11.0;
    self.timeBadge.layer.masksToBounds = YES;
    self.timeBadge.alpha         = 0.0;
    self.timeBadge.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlsView addSubview:self.timeBadge];

    // Next button – hidden until after Check
    self.nextButton = [self actionButtonWithTitle:@"Next →"
                                           action:@selector(nextTapped)];
    self.nextButton.backgroundColor = [UIColor systemGrayColor];
    self.nextButton.hidden = YES;
    [self.controlsView addSubview:self.nextButton];

    // Cancel after Next – hidden until after Check
    self.cancelAfterNextButton = [self cancelButtonWithAction:@selector(cancelTapped)];
    self.cancelAfterNextButton.hidden = YES;
    [self.controlsView addSubview:self.cancelAfterNextButton];

    // Controls internal layout
    [NSLayoutConstraint activateConstraints:@[
        [self.progressLabel.topAnchor     constraintEqualToAnchor:self.controlsView.topAnchor
                                                         constant:m],
        [self.progressLabel.leadingAnchor constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                         constant:m],

        [self.timerLabel.topAnchor        constraintEqualToAnchor:self.controlsView.topAnchor
                                                         constant:m],
        [self.timerLabel.trailingAnchor   constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                         constant:-m],
        [self.timerLabel.leadingAnchor    constraintEqualToAnchor:self.progressLabel.trailingAnchor
                                                         constant:8.0],

        [self.yellowLabel.topAnchor      constraintEqualToAnchor:self.progressLabel.bottomAnchor
                                                        constant:m],
        [self.yellowLabel.leadingAnchor  constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                        constant:m],
        [self.yellowLabel.trailingAnchor constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                        constant:-m],

        [self.yellowField.topAnchor      constraintEqualToAnchor:self.yellowLabel.bottomAnchor
                                                        constant:6.0],
        [self.yellowField.leadingAnchor  constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                        constant:m],
        [self.yellowField.trailingAnchor constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                        constant:-m],
        [self.yellowField.heightAnchor   constraintEqualToConstant:48.0],

        [self.blueLabel.topAnchor        constraintEqualToAnchor:self.yellowField.bottomAnchor
                                                        constant:m],
        [self.blueLabel.leadingAnchor    constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                        constant:m],
        [self.blueLabel.trailingAnchor   constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                        constant:-m],

        [self.blueField.topAnchor        constraintEqualToAnchor:self.blueLabel.bottomAnchor
                                                        constant:6.0],
        [self.blueField.leadingAnchor    constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                        constant:m],
        [self.blueField.trailingAnchor   constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                        constant:-m],
        [self.blueField.heightAnchor     constraintEqualToConstant:48.0],

        [self.submitButton.topAnchor     constraintEqualToAnchor:self.blueField.bottomAnchor
                                                        constant:m],
        [self.submitButton.leadingAnchor constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                        constant:m],
        [self.submitButton.trailingAnchor constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                         constant:-m],
        [self.submitButton.heightAnchor  constraintEqualToConstant:48.0],

        [self.cancelButton.topAnchor     constraintEqualToAnchor:self.submitButton.bottomAnchor
                                                        constant:8.0],
        [self.cancelButton.leadingAnchor constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                        constant:m],
        [self.cancelButton.trailingAnchor constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                         constant:-m],
        [self.cancelButton.heightAnchor  constraintEqualToConstant:44.0],

        [self.feedbackLabel.topAnchor    constraintEqualToAnchor:self.cancelButton.bottomAnchor
                                                        constant:12.0],
        [self.feedbackLabel.leadingAnchor constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                         constant:m],
        [self.feedbackLabel.trailingAnchor constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                          constant:-m],

        // Time badge – centred pill below the feedback line.
        [self.timeBadge.topAnchor        constraintEqualToAnchor:self.feedbackLabel.bottomAnchor
                                                        constant:8.0],
        [self.timeBadge.centerXAnchor    constraintEqualToAnchor:self.controlsView.centerXAnchor],
        [self.timeBadge.heightAnchor     constraintEqualToConstant:30.0],

        [self.nextButton.topAnchor       constraintEqualToAnchor:self.timeBadge.bottomAnchor
                                                        constant:12.0],
        [self.nextButton.leadingAnchor   constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                        constant:m],
        [self.nextButton.trailingAnchor  constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                        constant:-m],
        [self.nextButton.heightAnchor    constraintEqualToConstant:48.0],

        [self.cancelAfterNextButton.topAnchor    constraintEqualToAnchor:self.nextButton.bottomAnchor
                                                                constant:8.0],
        [self.cancelAfterNextButton.leadingAnchor constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                                 constant:m],
        [self.cancelAfterNextButton.trailingAnchor constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                                  constant:-m],
        [self.cancelAfterNextButton.heightAnchor constraintEqualToConstant:44.0],

        // Pin the container's bottom to the last button so controlsView has a
        // defined height from its content. Without this the view collapses
        // inside the scroll view and nothing scrolls. cancelAfterNextButton
        // stays in the layout even while hidden, so this anchor is stable.
        [self.controlsView.bottomAnchor constraintEqualToAnchor:self.cancelAfterNextButton.bottomAnchor
                                                       constant:m],
    ]];

    // Outer layout pins – direction-independent parts.
    // Everything is relative to contentView (the scroll view's content).
    [NSLayoutConstraint activateConstraints:@[
        // Info line spans the full content width at the very top.
        [self.infoLabel.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor     constant:m],
        [self.infoLabel.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:m],
        [self.infoLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-m],

        [self.boardView.topAnchor     constraintEqualToAnchor:self.infoLabel.bottomAnchor    constant:8.0],
        [self.boardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:8.0],

        [self.boardIDView.topAnchor     constraintEqualToAnchor:self.boardView.bottomAnchor
                                                       constant:4.0],
        [self.boardIDView.leadingAnchor constraintEqualToAnchor:self.boardView.leadingAnchor],
        [self.boardIDView.trailingAnchor constraintEqualToAnchor:self.boardView.trailingAnchor],

        // controlsView.top is direction-dependent and set in viewDidLayoutSubviews:
        // wide  -> pinned below the info line (board left, controls right)
        // narrow-> pinned below the board ID view (board on top, controls below)
        [self.controlsView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
    ]];
}

- (UILabel *)labelWithText:(NSString *)text
{
    UILabel *lbl    = [[UILabel alloc] init];
    lbl.text        = text;
    lbl.font        = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
    lbl.textColor   = [UIColor secondaryLabelColor];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    return lbl;
}

- (UITextField *)pipCountField
{
    UITextField *f  = [[UITextField alloc] init];
    f.keyboardType  = UIKeyboardTypeNumberPad;
    f.borderStyle   = UITextBorderStyleRoundedRect;
    f.textAlignment = NSTextAlignmentCenter;
    f.font          = [UIFont monospacedDigitSystemFontOfSize:26.0 weight:UIFontWeightRegular];
    f.placeholder   = @"–";
    f.delegate      = self;
    f.translatesAutoresizingMaskIntoConstraints = NO;
    return f;
}

- (UIButton *)cancelButtonWithAction:(SEL)action
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"Cancel" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor systemGrayColor];
    btn.layer.cornerRadius  = 10.0;
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}
- (UIButton *)actionButtonWithTitle:(NSString *)title action:(SEL)action
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font     = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    btn.backgroundColor     = [UIColor colorNamed:@"AccentColor"] ?: [UIColor systemRedColor];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.layer.cornerRadius  = 10.0;
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

#pragma mark - Adaptive layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    BOOL wide = (self.view.bounds.size.width >= kWideThreshold);
    if (wide == self.isWideLayout && self.wideConstraints != nil) { return; }

    [NSLayoutConstraint deactivateConstraints:self.wideConstraints   ?: @[]];
    [NSLayoutConstraint deactivateConstraints:self.narrowConstraints ?: @[]];
    self.isWideLayout = wide;

    if (wide)
    {
        // Board left, controls right. The board width follows the visible
        // width (safe), but vertical anchors hang off contentView so the
        // scroll view can size its content.
        self.wideConstraints = @[
            [self.controlsView.topAnchor   constraintEqualToAnchor:self.infoLabel.bottomAnchor
                                                          constant:8.0],
            [self.boardView.trailingAnchor constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                          constant:-8.0],
            [self.boardView.widthAnchor    constraintEqualToAnchor:self.contentView.widthAnchor
                                                        multiplier:0.60],
            // Whichever column is taller defines the content height.
            [self.contentView.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.boardView.bottomAnchor
                                                                       constant:8.0],
            [self.contentView.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.controlsView.bottomAnchor
                                                                       constant:8.0],
        ];
        [NSLayoutConstraint activateConstraints:self.wideConstraints];
    }
    else
    {
        // Board on top (full width), ID row, then controls below.
        // controlsView.bottom drives the content height so the page scrolls.
        self.narrowConstraints = @[
            [self.boardView.trailingAnchor  constraintEqualToAnchor:self.contentView.trailingAnchor
                                                           constant:-8.0],
            [self.controlsView.topAnchor    constraintEqualToAnchor:self.boardIDView.bottomAnchor
                                                           constant:8.0],
            [self.controlsView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [self.contentView.bottomAnchor   constraintEqualToAnchor:self.controlsView.bottomAnchor
                                                             constant:8.0],
        ];
        [NSLayoutConstraint activateConstraints:self.narrowConstraints];
    }
}

#pragma mark - Count picker

- (void)showCountPicker
{
    NSArray<BGGPositionEntry *> *all = [[PositionDatabase sharedDatabase]
                                        positionsForTags:[self requiredTags]];
    NSInteger available = (NSInteger)all.count;
    NSString *message   = [NSString stringWithFormat:@"%ld positions available", (long)available];

    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"How many positions?"
                                                 message:message
                                          preferredStyle:UIAlertControllerStyleAlert];

    for (NSNumber *n in @[@5, @10, @20])
    {
        NSInteger count = n.integerValue;
        if (count > available) { continue; }
        [alert addAction:[UIAlertAction
                          actionWithTitle:[NSString stringWithFormat:@"%ld positions", (long)count]
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *a)
        {
            [self startSessionWithCount:count positions:all];
        }]];
    }

    [alert addAction:[UIAlertAction
                      actionWithTitle:[NSString stringWithFormat:@"All (%ld)", (long)available]
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *a)
    {
        [self startSessionWithCount:available positions:all];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *a)
    {
        [self returnFromExercise];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Session

- (void)startSessionWithCount:(NSInteger)count
                    positions:(NSArray<BGGPositionEntry *> *)all
{
    NSMutableArray *shuffled = [all mutableCopy];
    for (NSInteger i = (NSInteger)shuffled.count - 1; i > 0; i--)
    {
        NSUInteger j = arc4random_uniform((uint32_t)(i + 1));
        [shuffled exchangeObjectAtIndex:(NSUInteger)i withObjectAtIndex:j];
    }
    self.positions    = [[shuffled subarrayWithRange:NSMakeRange(0, (NSUInteger)count)] copy];
    self.currentIndex = 0;
    self.correctCount = 0;
    self.totalCount   = count;

    // Open a workout for this session. Attempts are added per check.
    self.currentWorkout = [[CoreDataManager sharedManager]
                           createWorkoutWithModule:[self moduleIdentifier]
                                              mode:[self modeIdentifier]
                                        totalCount:count];
    [[CoreDataManager sharedManager] saveContext];

    [self showCurrentPosition];
}

- (void)showCurrentPosition
{
    if (self.currentIndex >= (NSInteger)self.positions.count)
    {
        [self showSummary];
        return;
    }

    BGGPositionEntry *entry   = self.positions[(NSUInteger)self.currentIndex];
    self.boardView.boardState = [entry boardState];
    [self.boardIDView updateWithID:entry.positionID];

    self.progressLabel.text   = [NSString stringWithFormat:@"%ld / %ld",
                                 (long)(self.currentIndex + 1), (long)self.totalCount];
    self.blueField.text       = @"";
    self.yellowField.text     = @"";
    self.feedbackLabel.alpha  = 0.0;
    self.timeBadge.alpha      = 0.0;
    self.submitButton.hidden  = NO;
    self.cancelButton.hidden  = NO;
    self.nextButton.hidden    = YES;
    self.cancelAfterNextButton.hidden = YES;
    self.blueField.enabled    = YES;
    self.yellowField.enabled  = YES;

    // Yellow is the first field (opponent, top of board).
    [self.yellowField becomeFirstResponder];

    // Always measure time. Workout shows it live; Training shows it in the feedback.
    [self startTimer];
}

#pragma mark - Answer

- (void)submitTapped
{
    NSString *blueText   = [self.blueField.text   stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceCharacterSet]];
    NSString *yellowText = [self.yellowField.text stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceCharacterSet]];

    if (yellowText.length == 0) { [self.yellowField becomeFirstResponder]; return; }
    if (blueText.length == 0)   { [self.blueField   becomeFirstResponder]; return; }

    [self stopTimer];
    [self.view endEditing:YES];

    BGGBoardState *state    = [self.positions[(NSUInteger)self.currentIndex] boardState];
    NSInteger correctBlue   = [state pipCountForPlayer:BGGPlayerBlue];
    NSInteger correctYellow = [state pipCountForPlayer:BGGPlayerYellow];
    NSInteger userBlue      = blueText.integerValue;
    NSInteger userYellow    = yellowText.integerValue;

    BOOL blueOK  = (userBlue   == correctBlue);
    BOOL yellowOK= (userYellow == correctYellow);
    BOOL bothOK  = blueOK && yellowOK;

    if (bothOK) { self.correctCount++; }

    // Persist this attempt immediately (crash-safe). Translate the internal
    // Blue/Yellow board sides to the Player/Opponent storage convention:
    // Blue is the user (bottom), Yellow is the opponent (top).
    BGGPositionEntry *entry = self.positions[(NSUInteger)self.currentIndex];
    CoreDataManager *cd = [CoreDataManager sharedManager];
    [cd addAttemptToWorkout:self.currentWorkout
                 positionID:entry.positionID
                  isCorrect:bothOK
                  elapsedMs:(NSInteger)(self.elapsedSeconds * 1000.0)
                 userPlayer:userBlue
               userOpponent:userYellow
              correctPlayer:correctBlue
            correctOpponent:correctYellow];
    [cd saveContext];

    [self showFeedbackBlueOK:blueOK yellowOK:yellowOK
                 correctBlue:correctBlue correctYellow:correctYellow];

    UIImpactFeedbackGenerator *impact = [[UIImpactFeedbackGenerator alloc]
                                          initWithStyle:bothOK
                                                        ? UIImpactFeedbackStyleMedium
                                                        : UIImpactFeedbackStyleRigid];
    [impact impactOccurred];

    // Show Next + CancelAfterNext, hide Check + Cancel.
    self.submitButton.hidden  = YES;
    self.cancelButton.hidden  = YES;
    self.nextButton.hidden    = NO;
    self.cancelAfterNextButton.hidden = NO;
    self.blueField.enabled    = NO;
    self.yellowField.enabled  = NO;
}

- (void)nextTapped
{
    self.currentIndex++;
    [self showCurrentPosition];
}

// Leaving the exercise – Cancel, the count-picker's Cancel, and Done at the
// end all funnel through here, so they behave the same: hand control back to
// the container to return to the previous section, or pop if used stand-alone.
- (void)returnFromExercise
{
    if (self.exerciseDelegate != nil)
    {
        [self.exerciseDelegate exerciseDidCancel:self];
    }
    else
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)cancelTapped
{
    [self stopTimer];
    [self returnFromExercise];
}

- (void)showFeedbackBlueOK:(BOOL)blueOK
                  yellowOK:(BOOL)yellowOK
               correctBlue:(NSInteger)correctBlue
             correctYellow:(NSInteger)correctYellow
{
    NSMutableString *msg = [NSMutableString string];

    if (blueOK && yellowOK)
    {
        [msg appendFormat:@"✓  Correct!  %ld : %ld",
         (long)correctBlue, (long)correctYellow];
        self.feedbackLabel.textColor = [UIColor systemGreenColor];
    }
    else
    {
        if (!blueOK)
        {
            [msg appendFormat:@"✗  My count: you said %ld, correct: %ld\n",
             (long)self.blueField.text.integerValue, (long)correctBlue];
        }
        if (!yellowOK)
        {
            [msg appendFormat:@"✗  Opponent: you said %ld, correct: %ld",
             (long)self.yellowField.text.integerValue, (long)correctYellow];
        }
        self.feedbackLabel.textColor = [UIColor systemRedColor];
    }

    self.feedbackLabel.text = msg;

    // Show the answer time as a coloured badge in both modes.
    [self showTimeBadge];

    [UIView animateWithDuration:0.2 animations:^{
        self.feedbackLabel.alpha = 1.0;
        self.timeBadge.alpha     = 1.0;
    }];
}

// Fills the time badge with the elapsed time and colours it by threshold.
- (void)showTimeBadge
{
    NSInteger s = (NSInteger)self.elapsedSeconds;
    // Leading/trailing spaces give the pill some horizontal padding,
    // since UILabel has no intrinsic inset.
    self.timeBadge.text            = [NSString stringWithFormat:@"  ⏱ %lds  ", (long)s];
    self.timeBadge.backgroundColor = [BGGTimeColor colorForSeconds:s];
}

#pragma mark - Keyboard

// When the keyboard appears, inset the scroll view by the part of the scroll
// view that the keyboard actually covers, then scroll the active field into
// view. The overlap is measured against the scroll view's frame in its own
// superview, which correctly accounts for the safe-area pin at the bottom.
- (void)keyboardWillChangeFrame:(NSNotification *)note
{
    CGRect kbScreen = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    // Keyboard frame in the scroll view's superview coordinate space.
    UIView *refView = self.scrollView.superview;
    CGRect kbInRef  = [refView convertRect:kbScreen fromView:nil];

    // How far the keyboard reaches up into the scroll view's frame.
    CGFloat overlap = CGRectGetMaxY(self.scrollView.frame) - CGRectGetMinY(kbInRef);
    if (overlap < 0.0) { overlap = 0.0; }

    self.scrollView.contentInset =
        UIEdgeInsetsMake(0.0, 0.0, overlap, 0.0);
    self.scrollView.verticalScrollIndicatorInsets =
        UIEdgeInsetsMake(0.0, 0.0, overlap, 0.0);

    // Scroll so the whole controls block (fields + buttons) is reachable.
    // Using controlsView guarantees the buttons below the active field are
    // included, not just the field itself.
    [self.view layoutIfNeeded];

    CGRect r = [self.contentView convertRect:self.controlsView.frame
                                    fromView:self.controlsView.superview];
    [self.scrollView scrollRectToVisible:r animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.verticalScrollIndicatorInsets = UIEdgeInsetsZero;
}

#pragma mark - Timer

- (void)startTimer
{
    self.elapsedSeconds = 0;
    [self updateTimerLabel];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(timerTick)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stopTimer  { [self.timer invalidate]; self.timer = nil; }
- (void)timerTick  { self.elapsedSeconds += 1.0; [self updateTimerLabel]; }

- (void)updateTimerLabel
{
    NSInteger s = (NSInteger)self.elapsedSeconds;

    // Workout shows the timer live and colours it by the current band.
    // Training keeps the timer hidden, so this only affects the workout.
    if (self.measureTime)
    {
        self.timerLabel.text = [NSString stringWithFormat:@"%ld:%02ld",
                                (long)(s / 60), (long)(s % 60)];
        self.timerLabel.textColor       = [UIColor whiteColor];
        self.timerLabel.backgroundColor = [BGGTimeColor colorForSeconds:s];
        self.timerLabel.layer.cornerRadius  = 8.0;
        self.timerLabel.layer.masksToBounds = YES;
    }
    else
    {
        self.timerLabel.text = [NSString stringWithFormat:@"%ld:%02ld",
                                (long)(s / 60), (long)(s % 60)];
    }
}

#pragma mark - Summary

- (void)showSummary
{
    // The session ran to the end: stamp the workout as finished.
    if (self.currentWorkout != nil)
    {
        self.currentWorkout.finishedAt = [NSDate date];
        [[CoreDataManager sharedManager] saveContext];
    }

    NSString *message = [NSString stringWithFormat:
                         @"%ld of %ld correct (%.0f%%)",
                         (long)self.correctCount, (long)self.totalCount,
                         self.totalCount > 0
                             ? (double)self.correctCount / self.totalCount * 100.0
                             : 0.0];

    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Session complete"
                                                 message:message
                                          preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Again"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a)
    {
        [self showCountPicker];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Done"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *a)
    {
        [self returnFromExercise];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.yellowField)
    {
        // Yellow is first – Return moves to blue (my count).
        [self.blueField becomeFirstResponder];
    }
    else
    {
        [self submitTapped];
    }
    return NO;
}

@end
