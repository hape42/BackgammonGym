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
#import "BGGAchievements.h"
#import "BGGBoardView.h"
#import "BGGBoardIDView.h"
#import "BGGBoardGeometry.h"
#import "BGGBoardState.h"
#import "BGGPosition.h"
#import "PositionDatabase.h"
#import "BGGNumberPad.h"
#import "Tools.h"
#import "BGGTimeColor.h"
#import "CoreDataManager.h"
#import "BGGLocalization.h"

static const CGFloat kWideThreshold = 700.0;

@interface PipCountExerciseVC () <BGGNumberPadDelegate>

// Scroll container. The number pad is laid out inline, so the board no longer
// needs to scroll clear of a system keyboard – but the scroll view stays for
// small screens where board + controls exceed the height.
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

// Input. Two tappable display fields side by side (yellow = opponent, blue =
// me) feed a single shared number pad; whichever is active receives digits.
@property (nonatomic, strong) UILabel       *blueLabel;
@property (nonatomic, strong) UIControl     *blueField;     // tappable display
@property (nonatomic, strong) UILabel       *blueValue;     // digits inside it
@property (nonatomic, strong) UILabel       *yellowLabel;
@property (nonatomic, strong) UIControl     *yellowField;
@property (nonatomic, strong) UILabel       *yellowValue;
@property (nonatomic, strong) BGGNumberPad  *numberPad;
@property (nonatomic, copy)   NSString      *blueInput;
@property (nonatomic, copy)   NSString      *yellowInput;
@property (nonatomic, assign) BOOL           activeIsBlue;  // NO = yellow active

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

// Activity level recorded for the contribution grid when a session finishes.
// 0 = don't count (the default). PipCountTrainingVC overrides this to 2,
// PipCountWorkoutVC to 3. Kept as an override rather than a string check on
// modeIdentifier so it doesn't break if the mode strings ever change.
- (NSInteger)activityLevelForCompletedSession { return 0; }

// Base implementation – no info line. Subclasses override.
- (nullable NSString *)infoText { return nil; }

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self installHomeButton];
    [self buildUI];
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

    // Opponent label + field (opponent's checkers are at the top of the board)
    self.yellowLabel = [self labelWithText:BGGLocalizedString(@"Opponent pip count")];
    self.yellowLabel.textAlignment = NSTextAlignmentCenter;
    [self.controlsView addSubview:self.yellowLabel];
    self.yellowField = [self displayFieldIntoValue:&_yellowValue];
    [self.yellowField addTarget:self action:@selector(yellowFieldTapped)
               forControlEvents:UIControlEventTouchUpInside];
    [self.controlsView addSubview:self.yellowField];

    // My label + field (my checkers are at the bottom of the board)
    self.blueLabel = [self labelWithText:BGGLocalizedString(@"My pip count")];
    self.blueLabel.textAlignment = NSTextAlignmentCenter;
    [self.controlsView addSubview:self.blueLabel];
    self.blueField = [self displayFieldIntoValue:&_blueValue];
    [self.blueField addTarget:self action:@selector(blueFieldTapped)
             forControlEvents:UIControlEventTouchUpInside];
    [self.controlsView addSubview:self.blueField];

    // Shared number pad – writes into whichever field is active.
    self.numberPad = [[BGGNumberPad alloc] initWithFrame:CGRectZero];
    self.numberPad.translatesAutoresizingMaskIntoConstraints = NO;
    self.numberPad.delegate = self;
    [self.controlsView addSubview:self.numberPad];

    self.blueInput   = @"";
    self.yellowInput = @"";

    // Check button
    self.submitButton = [self actionButtonWithTitle:BGGLocalizedString(@"Check")
                                             action:@selector(submitTapped)];
    self.submitButton.hidden = YES;   // replaced by the pad's OK key
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
    self.nextButton = [self actionButtonWithTitle:BGGLocalizedString(@"Next →")
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

        // Two fields side by side: yellow (opponent) left, blue (me) right.
        [self.yellowLabel.topAnchor      constraintEqualToAnchor:self.progressLabel.bottomAnchor
                                                        constant:m],
        [self.yellowLabel.leadingAnchor  constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                        constant:m],
        [self.yellowLabel.trailingAnchor constraintEqualToAnchor:self.controlsView.centerXAnchor
                                                        constant:-6.0],

        [self.blueLabel.topAnchor        constraintEqualToAnchor:self.yellowLabel.topAnchor],
        [self.blueLabel.leadingAnchor    constraintEqualToAnchor:self.controlsView.centerXAnchor
                                                        constant:6.0],
        [self.blueLabel.trailingAnchor   constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                        constant:-m],

        [self.yellowField.topAnchor      constraintEqualToAnchor:self.yellowLabel.bottomAnchor
                                                        constant:6.0],
        [self.yellowField.leadingAnchor  constraintEqualToAnchor:self.yellowLabel.leadingAnchor],
        [self.yellowField.trailingAnchor constraintEqualToAnchor:self.yellowLabel.trailingAnchor],
        [self.yellowField.heightAnchor   constraintEqualToConstant:52.0],

        [self.blueField.topAnchor        constraintEqualToAnchor:self.yellowField.topAnchor],
        [self.blueField.leadingAnchor    constraintEqualToAnchor:self.blueLabel.leadingAnchor],
        [self.blueField.trailingAnchor   constraintEqualToAnchor:self.blueLabel.trailingAnchor],
        [self.blueField.heightAnchor     constraintEqualToConstant:52.0],

        // Number pad, centered below the fields (fixed ≈2/3 size like MET).
        [self.numberPad.topAnchor        constraintEqualToAnchor:self.yellowField.bottomAnchor
                                                        constant:m],
        [self.numberPad.centerXAnchor    constraintEqualToAnchor:self.controlsView.centerXAnchor],
        [self.numberPad.widthAnchor      constraintEqualToConstant:228.0],
        [self.numberPad.heightAnchor     constraintEqualToConstant:168.0],

        // Check button replaced by the pad's OK key; kept hidden (0.5pt) so the
        // existing show/hide logic stays untouched.
        [self.submitButton.topAnchor     constraintEqualToAnchor:self.numberPad.bottomAnchor
                                                        constant:m],
        [self.submitButton.leadingAnchor constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                        constant:m],
        [self.submitButton.trailingAnchor constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                         constant:-m],
        [self.submitButton.heightAnchor  constraintEqualToConstant:0.5],

        [self.cancelButton.topAnchor     constraintEqualToAnchor:self.numberPad.bottomAnchor
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

// A tappable, non-editable display field: a bordered box with a centered
// value label inside. The value label pointer is handed back so the caller
// can keep a reference for updating the digits. Active state is shown by
// -setActiveField: via the border.
- (UIControl *)displayFieldIntoValue:(UILabel * __strong *)outValue
{
    UIControl *field = [[UIControl alloc] init];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    field.layer.cornerRadius = 8.0;
    field.layer.borderWidth  = 0.5;
    field.layer.borderColor  = [UIColor separatorColor].CGColor;
    field.backgroundColor    = [UIColor secondarySystemBackgroundColor];

    UILabel *value = [[UILabel alloc] init];
    value.translatesAutoresizingMaskIntoConstraints = NO;
    value.textAlignment = NSTextAlignmentCenter;
    value.font          = [UIFont monospacedDigitSystemFontOfSize:26.0 weight:UIFontWeightRegular];
    value.textColor     = [UIColor tertiaryLabelColor];
    value.text          = @"–";
    value.userInteractionEnabled = NO;
    [field addSubview:value];
    [NSLayoutConstraint activateConstraints:@[
        [value.centerXAnchor constraintEqualToAnchor:field.centerXAnchor],
        [value.centerYAnchor constraintEqualToAnchor:field.centerYAnchor],
    ]];

    *outValue = value;
    return field;
}

- (UIButton *)cancelButtonWithAction:(SEL)action
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:BGGLocalizedString(@"Cancel") forState:UIControlStateNormal];
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
    NSString *message   = [NSString stringWithFormat:BGGLocalizedString(@"%ld positions available"), (long)available];

    // Explain why a length is chosen at all: a session has a fixed length so
    // it ends with a recorded result and stats (issue #12).
    message = [message stringByAppendingFormat:@"\n\n%@",
               BGGLocalizedString(@"session.fixedlength.hint")];

    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:BGGLocalizedString(@"How many positions?")
                                                 message:message
                                          preferredStyle:UIAlertControllerStyleAlert];

    for (NSNumber *n in @[@5, @10, @20])
    {
        NSInteger count = n.integerValue;
        if (count > available) { continue; }
        [alert addAction:[UIAlertAction
                          actionWithTitle:[NSString stringWithFormat:BGGLocalizedString(@"%ld positions"), (long)count]
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *a)
        {
            [self startSessionWithCount:count positions:all];
        }]];
    }

    [alert addAction:[UIAlertAction
                      actionWithTitle:[NSString stringWithFormat:BGGLocalizedString(@"All (%ld)"), (long)available]
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *a)
    {
        [self startSessionWithCount:available positions:all];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:BGGLocalizedString(@"Cancel")
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
    self.blueInput            = @"";
    self.yellowInput          = @"";
    [self refreshFieldDisplays];
    self.feedbackLabel.alpha  = 0.0;
    self.timeBadge.alpha      = 0.0;
    self.submitButton.hidden  = YES;   // replaced by the pad's OK key
    self.cancelButton.hidden  = NO;
    self.nextButton.hidden    = YES;
    self.cancelAfterNextButton.hidden = YES;
    self.numberPad.enabled    = YES;

    // Yellow is the first field (opponent, top of board).
    [self setActiveFieldBlue:NO];

    // Each new position should start at the top, showing the board to count –
    // after a check we scrolled down to the result, so Next must bring the
    // view back up rather than leaving the user at the input pad. No-op when
    // already at the top (first task) or when nothing scrolls (wide/iPad).
    [self scrollToTop];

    // Always measure time. Workout shows it live; Training shows it in the feedback.
    [self startTimer];
}

// Scrolls the view back to its top edge, accounting for the safe-area inset.
- (void)scrollToTop
{
    [self.contentView layoutIfNeeded];
    CGFloat topY = -self.scrollView.adjustedContentInset.top;
    [self.scrollView setContentOffset:CGPointMake(0.0, topY) animated:YES];
}

#pragma mark - Field selection + number pad

- (void)yellowFieldTapped { [self setActiveFieldBlue:NO]; }
- (void)blueFieldTapped   { [self setActiveFieldBlue:YES]; }

// Switches which field receives digits and updates the border highlight.
- (void)setActiveFieldBlue:(BOOL)blue
{
    self.activeIsBlue = blue;

    UIColor *accent = [UIColor colorNamed:@"AccentColor"];
    self.blueField.layer.borderColor   = blue ? accent.CGColor : [UIColor separatorColor].CGColor;
    self.blueField.layer.borderWidth   = blue ? 2.0 : 0.5;
    self.yellowField.layer.borderColor = blue ? [UIColor separatorColor].CGColor : accent.CGColor;
    self.yellowField.layer.borderWidth = blue ? 0.5 : 2.0;
}

- (NSString *)activeInput { return self.activeIsBlue ? self.blueInput : self.yellowInput; }

- (void)setActiveInput:(NSString *)value
{
    if (self.activeIsBlue) { self.blueInput = value; }
    else                   { self.yellowInput = value; }
    [self refreshFieldDisplays];
}

// Mirrors the two input strings into the value labels, with a muted dash when
// a field is empty.
- (void)refreshFieldDisplays
{
    self.yellowValue.text      = self.yellowInput.length ? self.yellowInput : @"–";
    self.yellowValue.textColor = self.yellowInput.length
        ? [UIColor labelColor] : [UIColor tertiaryLabelColor];
    self.blueValue.text        = self.blueInput.length ? self.blueInput : @"–";
    self.blueValue.textColor   = self.blueInput.length
        ? [UIColor labelColor] : [UIColor tertiaryLabelColor];
}

#pragma mark - BGGNumberPadDelegate

- (void)numberPad:(BGGNumberPad *)pad didTapDigit:(NSInteger)digit
{
    NSString *cur = [self activeInput];
    if (cur.length == 0 && digit == 0) { return; }   // no leading zero
    if (cur.length >= 3) { return; }                 // pip counts are <= 3 digits
    [self setActiveInput:[cur stringByAppendingFormat:@"%ld", (long)digit]];
}

- (void)numberPadDidTapDelete:(BGGNumberPad *)pad
{
    NSString *cur = [self activeInput];
    if (cur.length == 0) { return; }
    [self setActiveInput:[cur substringToIndex:cur.length - 1]];
}

- (void)numberPadDidTapOK:(BGGNumberPad *)pad
{
    // Variant 1: check when both fields are filled; otherwise jump to the
    // empty one.
    if (self.yellowInput.length == 0) { [self setActiveFieldBlue:NO];  return; }
    if (self.blueInput.length == 0)   { [self setActiveFieldBlue:YES]; return; }
    [self submitTapped];
}

#pragma mark - Answer

- (void)submitTapped
{
    NSString *blueText   = self.blueInput;
    NSString *yellowText = self.yellowInput;

    if (yellowText.length == 0) { [self setActiveFieldBlue:NO];  return; }
    if (blueText.length == 0)   { [self setActiveFieldBlue:YES]; return; }

    [self stopTimer];

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

    // Distinct haptics for right vs. wrong: a success pattern for a correct
    // answer, an error pattern for a wrong one. The previous impact styles
    // (medium vs. rigid) felt almost identical; success/error are clearly
    // different (issue #28). Matches the success haptic already used when an
    // achievement is earned.
    UINotificationFeedbackGenerator *haptic = [[UINotificationFeedbackGenerator alloc] init];
    [haptic notificationOccurred:bothOK ? UINotificationFeedbackTypeSuccess
                                        : UINotificationFeedbackTypeError];

    // Show Next + CancelAfterNext, hide Check + Cancel.
    self.submitButton.hidden  = YES;
    self.cancelButton.hidden  = YES;
    self.nextButton.hidden    = NO;
    self.cancelAfterNextButton.hidden = NO;
    self.numberPad.enabled    = NO;

    // On a small portrait screen the feedback, Next and Cancel sit below the
    // board and the input pad, i.e. off-screen after answering – it's easy to
    // miss them and think nothing happened (issue #29). Scroll the bottom of
    // the control group into view so the result and Next are visible without
    // the user hunting for them. On wide/iPad layouts everything is already
    // on screen, so this is a harmless no-op.
    [self scrollResultIntoView];
}

// Bring the just-revealed result/Next/Cancel group into the visible area.
- (void)scrollResultIntoView
{
    // The buttons were just un-hidden; force a layout pass so their frames are
    // final before we compute the rect to scroll to.
    [self.contentView layoutIfNeeded];

    UIView *target = self.cancelAfterNextButton;   // lowest item of the group
    CGRect rect = [self.scrollView convertRect:target.bounds fromView:target];

    // A little breathing room below the target so it doesn't sit flush at the
    // very bottom edge.
    rect = CGRectInset(rect, 0.0, -12.0);

    [self.scrollView scrollRectToVisible:rect animated:YES];
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
        [msg appendFormat:BGGLocalizedString(@"✓  Correct!  %ld : %ld"),
         (long)correctBlue, (long)correctYellow];
        self.feedbackLabel.textColor = [UIColor systemGreenColor];
    }
    else
    {
        if (!blueOK)
        {
            [msg appendFormat:BGGLocalizedString(@"✗  My count: you said %ld, correct: %ld\n"),
             (long)self.blueInput.integerValue, (long)correctBlue];
        }
        if (!yellowOK)
        {
            [msg appendFormat:BGGLocalizedString(@"✗  Opponent: you said %ld, correct: %ld"),
             (long)self.yellowInput.integerValue, (long)correctYellow];
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

    // Record the day's activity for the contribution grid. The level is
    // defined by the subclass (training = 2, workout = 3); the base class
    // returns 0, meaning "don't count". The bump only ever raises the day's
    // level, so opening (1) earlier today is not lost.
    NSInteger activityLevel = [self activityLevelForCompletedSession];
    if (activityLevel > 0)
    {
        [[CoreDataManager sharedManager] bumpTodayActivityToLevel:activityLevel];
    }

    // Only a finished workout (level 3) feeds the achievements. The check is
    // retroactive over the whole history and idempotent; it returns just the
    // ones newly earned this run, so they can be celebrated once.
    NSArray<BGGAchievementDefinition *> *newlyEarned = @[];
    if (activityLevel >= 3)
    {
        newlyEarned = [[BGGAchievements sharedAchievements]
                       checkAndAwardForModule:[self moduleIdentifier]];
    }

    NSString *message = [NSString stringWithFormat:
                         BGGLocalizedString(@"%ld of %ld correct (%.0f%%)"),
                         (long)self.correctCount, (long)self.totalCount,
                         self.totalCount > 0
                             ? (double)self.correctCount / self.totalCount * 100.0
                             : 0.0];

    // If this workout unlocked new achievements, name them under the result
    // and give a success haptic. Brand/medal names are localized in the
    // catalogue's title keys.
    if (newlyEarned.count > 0)
    {
        NSMutableString *extra = [NSMutableString stringWithFormat:@"\n\n🏆 %@",
                                  BGGLocalizedString(@"New achievement!")];
        for (BGGAchievementDefinition *def in newlyEarned)
        {
            [extra appendFormat:@"\n%@", BGGLocalizedString(def.titleKey)];
        }
        message = [message stringByAppendingString:extra];

        UINotificationFeedbackGenerator *gen = [[UINotificationFeedbackGenerator alloc] init];
        [gen notificationOccurred:UINotificationFeedbackTypeSuccess];
    }

    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:BGGLocalizedString(@"Session complete")
                                                 message:message
                                          preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BGGLocalizedString(@"Again")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a)
    {
        [self showCountPicker];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:BGGLocalizedString(@"Done")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *a)
    {
        [self returnFromExercise];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
