//
//  METExerciseVC.m
//  BackgammonGym
//
//  Shared logic for MET Training and Workout. No board here – the task is a
//  match score in text. One numeric field for the leader's match-winning
//  chance. After checking, a "Next →" button appears so the user can study
//  the answer before moving on. Layout follows the pip-count exercise: a
//  scroll view with a content view, so the field stays reachable above the
//  keyboard.
//

#import "METExerciseVC.h"
#import "BGGLocalization.h"
#import "UIViewController+BGGHomeButton.h"
#import "BGGMatchEquityTable.h"
#import "BGGMETSettings.h"
#import "BGGMETHintViews.h"
#import "BGGTimeColor.h"
#import "CoreDataManager.h"

@interface METExerciseVC () <UITextFieldDelegate>

// Scroll container, so the field scrolls clear of the keyboard.
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView       *contentView;

// Optional explanatory line above the question.
@property (nonatomic, strong) UILabel      *infoLabel;

// Progress + timer.
@property (nonatomic, strong) UILabel      *progressLabel;
@property (nonatomic, strong) UILabel      *timerLabel;

// Question block.
@property (nonatomic, strong) UILabel      *scoreLabel;     // big "3 – 1"
@property (nonatomic, strong) UILabel      *matchLabel;     // "in a 7-point match"
@property (nonatomic, strong) UILabel      *promptLabel;    // "Estimate the leader's…"

// Input.
@property (nonatomic, strong) UILabel      *answerLabel;    // "Leader's match-winning chance (%)"
@property (nonatomic, strong) UITextField  *answerField;

// Buttons.
@property (nonatomic, strong) UIButton     *submitButton;
@property (nonatomic, strong) UIButton     *cancelButton;
@property (nonatomic, strong) UIButton     *nextButton;
@property (nonatomic, strong) UIButton     *cancelAfterNextButton;

// Feedback.
@property (nonatomic, strong) UILabel      *feedbackLabel;
@property (nonatomic, strong) UILabel      *timeBadge;
@property (nonatomic, strong) UILabel      *toleranceInfoLabel;   // "Tolerance: ± 1%"

// Hints (Training only). Two toggle buttons and a container that grows
// downwards as hints are switched on. nil in Workout.
@property (nonatomic, strong) UIButton     *neilButton;
@property (nonatomic, strong) UIButton     *janowskiButton;
@property (nonatomic, strong) UIStackView  *hintsStack;
@property (nonatomic, strong) UIView       *neilHintView;
@property (nonatomic, strong) UIView       *janowskiHintView;

// Timer.
@property (nonatomic, strong) NSTimer      *timer;
@property (nonatomic, assign) NSTimeInterval elapsedSeconds;

// Session state.
@property (nonatomic, assign) NSInteger matchLength;   // 5 / 7 / 9 / 11
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger correctCount;
@property (nonatomic, assign) NSInteger totalCount;

// The generated tasks for the running session. Each task is a dictionary:
//   @"leaderScore"   NSNumber  – the higher score (shown left)
//   @"trailerScore"  NSNumber  – the lower score (shown right)
//   @"leaderAway"    NSNumber  – matchLength - leaderScore
//   @"trailerAway"   NSNumber  – matchLength - trailerScore
//   @"correct"       NSNumber  – rounded equity for the leader
@property (nonatomic, strong) NSArray<NSDictionary *> *tasks;

// The Core Data workout for the running session (nil until started).
@property (nonatomic, strong) BGGWorkout *currentWorkout;

@end

@implementation METExerciseVC

- (BOOL)measureTime      { return NO; }
- (BOOL)showsHelpButtons { return NO; }

- (NSString *)moduleIdentifier { return @"met"; }
- (NSString *)modeIdentifier   { return @"";    }
- (NSInteger)activityLevelForCompletedSession { return 0; }
- (nullable NSString *)infoText { return nil; }

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [BGGMETSettings registerDefaults];
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
    if (self.tasks == nil)
    {
        [self showMatchLengthPicker];
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

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    // Info line (optional).
    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.infoLabel.numberOfLines = 0;
    self.infoLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.infoLabel.textColor     = [UIColor secondaryLabelColor];
    self.infoLabel.text          = [self infoText];
    [self.contentView addSubview:self.infoLabel];

    // Progress + timer row.
    self.progressLabel = [[UILabel alloc] init];
    self.progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressLabel.font      = [UIFont monospacedDigitSystemFontOfSize:15.0
                                                                    weight:UIFontWeightSemibold];
    self.progressLabel.textColor = [UIColor secondaryLabelColor];
    [self.contentView addSubview:self.progressLabel];

    self.timerLabel = [[UILabel alloc] init];
    self.timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timerLabel.font          = [UIFont monospacedDigitSystemFontOfSize:15.0
                                                                     weight:UIFontWeightSemibold];
    self.timerLabel.textAlignment = NSTextAlignmentCenter;
    self.timerLabel.hidden        = !self.measureTime;   // live only in Workout
    [self.contentView addSubview:self.timerLabel];

    // Question block.
    self.scoreLabel = [[UILabel alloc] init];
    self.scoreLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.scoreLabel.font          = [UIFont monospacedDigitSystemFontOfSize:48.0
                                                                     weight:UIFontWeightBold];
    self.scoreLabel.textAlignment = NSTextAlignmentCenter;
    self.scoreLabel.textColor     = [UIColor labelColor];
    [self.contentView addSubview:self.scoreLabel];

    self.matchLabel = [[UILabel alloc] init];
    self.matchLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.matchLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    self.matchLabel.textAlignment = NSTextAlignmentCenter;
    self.matchLabel.textColor     = [UIColor secondaryLabelColor];
    [self.contentView addSubview:self.matchLabel];

    self.promptLabel = [[UILabel alloc] init];
    self.promptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.promptLabel.numberOfLines = 0;
    self.promptLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.promptLabel.textAlignment = NSTextAlignmentCenter;
    self.promptLabel.textColor     = [UIColor labelColor];
    self.promptLabel.text          = BGGLocalizedString(@"Estimate the leader's match-winning chances.");
    [self.contentView addSubview:self.promptLabel];

    // Input.
    self.answerLabel = [[UILabel alloc] init];
    self.answerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.answerLabel.font      = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.answerLabel.textColor = [UIColor secondaryLabelColor];
    self.answerLabel.text      = BGGLocalizedString(@"Leader's match-winning chance (%)");
    [self.contentView addSubview:self.answerLabel];

    self.answerField = [self percentField];
    [self.contentView addSubview:self.answerField];

    // Buttons.
    self.submitButton = [self filledButtonWithTitle:BGGLocalizedString(@"Check")
                                             action:@selector(submitTapped)];
    self.cancelButton = [self plainButtonWithTitle:BGGLocalizedString(@"Cancel")
                                            action:@selector(cancelTapped)];
    self.nextButton = [self filledButtonWithTitle:BGGLocalizedString(@"Next →")
                                           action:@selector(nextTapped)];
    self.cancelAfterNextButton = [self plainButtonWithTitle:BGGLocalizedString(@"Cancel")
                                                     action:@selector(cancelTapped)];
    self.nextButton.hidden            = YES;
    self.cancelAfterNextButton.hidden = YES;
    [self.contentView addSubview:self.submitButton];
    [self.contentView addSubview:self.cancelButton];
    [self.contentView addSubview:self.nextButton];
    [self.contentView addSubview:self.cancelAfterNextButton];

    // Feedback.
    self.feedbackLabel = [[UILabel alloc] init];
    self.feedbackLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.feedbackLabel.numberOfLines = 0;
    self.feedbackLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.feedbackLabel.textAlignment = NSTextAlignmentCenter;
    self.feedbackLabel.alpha         = 0.0;
    [self.contentView addSubview:self.feedbackLabel];

    self.timeBadge = [self badge];
    self.timeBadge.alpha = 0.0;
    [self.contentView addSubview:self.timeBadge];

    self.toleranceInfoLabel = [[UILabel alloc] init];
    self.toleranceInfoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.toleranceInfoLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.toleranceInfoLabel.textColor     = [UIColor tertiaryLabelColor];
    self.toleranceInfoLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.toleranceInfoLabel];
    [self refreshToleranceInfo];

    // Hints (Training only): two pill toggles over a container that grows
    // as hints are switched on. Both can be shown at once.
    if (self.showsHelpButtons)
    {
        self.neilButton     = [self hintPillWithTitle:@"Neil's Numbers"
                                               action:@selector(toggleNeil)];
        self.janowskiButton = [self hintPillWithTitle:@"Janowski"
                                               action:@selector(toggleJanowski)];
        [self setPill:self.neilButton on:NO];
        [self setPill:self.janowskiButton on:NO];
        [self.contentView addSubview:self.neilButton];
        [self.contentView addSubview:self.janowskiButton];

        self.hintsStack = [[UIStackView alloc] init];
        self.hintsStack.axis    = UILayoutConstraintAxisVertical;
        self.hintsStack.spacing = 12.0;
        self.hintsStack.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.hintsStack];
    }

    [self activateConstraintsWithMargin:m];
}

- (void)activateConstraintsWithMargin:(CGFloat)m
{
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    UIView *c  = self.contentView;
    UIScrollView *s = self.scrollView;

    [NSLayoutConstraint activateConstraints:@[
        [s.topAnchor      constraintEqualToAnchor:safe.topAnchor],
        [s.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [s.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [s.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],

        // contentView spans the scroll view's content area and matches its width.
        [c.topAnchor      constraintEqualToAnchor:s.contentLayoutGuide.topAnchor],
        [c.leadingAnchor  constraintEqualToAnchor:s.contentLayoutGuide.leadingAnchor],
        [c.trailingAnchor constraintEqualToAnchor:s.contentLayoutGuide.trailingAnchor],
        [c.bottomAnchor   constraintEqualToAnchor:s.contentLayoutGuide.bottomAnchor],
        [c.widthAnchor    constraintEqualToAnchor:s.frameLayoutGuide.widthAnchor],

        [self.infoLabel.topAnchor      constraintEqualToAnchor:c.topAnchor constant:m],
        [self.infoLabel.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.infoLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],

        [self.progressLabel.topAnchor      constraintEqualToAnchor:self.infoLabel.bottomAnchor constant:m],
        [self.progressLabel.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],

        [self.timerLabel.centerYAnchor  constraintEqualToAnchor:self.progressLabel.centerYAnchor],
        [self.timerLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],
        [self.timerLabel.widthAnchor    constraintGreaterThanOrEqualToConstant:54.0],
        [self.timerLabel.heightAnchor   constraintEqualToConstant:28.0],

        [self.scoreLabel.topAnchor      constraintEqualToAnchor:self.progressLabel.bottomAnchor constant:m + 8.0],
        [self.scoreLabel.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.scoreLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],

        [self.matchLabel.topAnchor      constraintEqualToAnchor:self.scoreLabel.bottomAnchor constant:2.0],
        [self.matchLabel.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.matchLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],

        [self.promptLabel.topAnchor      constraintEqualToAnchor:self.matchLabel.bottomAnchor constant:m],
        [self.promptLabel.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.promptLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],

        [self.toleranceInfoLabel.topAnchor      constraintEqualToAnchor:self.promptLabel.bottomAnchor constant:6.0],
        [self.toleranceInfoLabel.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.toleranceInfoLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],

        [self.answerLabel.topAnchor      constraintEqualToAnchor:self.toleranceInfoLabel.bottomAnchor constant:m + 8.0],
        [self.answerLabel.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.answerLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],

        [self.answerField.topAnchor      constraintEqualToAnchor:self.answerLabel.bottomAnchor constant:6.0],
        [self.answerField.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.answerField.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],
        [self.answerField.heightAnchor   constraintEqualToConstant:48.0],

        [self.submitButton.topAnchor      constraintEqualToAnchor:self.answerField.bottomAnchor constant:m],
        [self.submitButton.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.submitButton.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],
        [self.submitButton.heightAnchor   constraintEqualToConstant:50.0],

        [self.cancelButton.topAnchor      constraintEqualToAnchor:self.submitButton.bottomAnchor constant:8.0],
        [self.cancelButton.centerXAnchor  constraintEqualToAnchor:c.centerXAnchor],

        // Next + its Cancel occupy the same slot as Check + Cancel.
        [self.nextButton.topAnchor      constraintEqualToAnchor:self.answerField.bottomAnchor constant:m],
        [self.nextButton.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.nextButton.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],
        [self.nextButton.heightAnchor   constraintEqualToConstant:50.0],

        [self.cancelAfterNextButton.topAnchor     constraintEqualToAnchor:self.nextButton.bottomAnchor constant:8.0],
        [self.cancelAfterNextButton.centerXAnchor constraintEqualToAnchor:c.centerXAnchor],

        [self.feedbackLabel.topAnchor      constraintEqualToAnchor:self.cancelButton.bottomAnchor constant:m],
        [self.feedbackLabel.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.feedbackLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],

        [self.timeBadge.topAnchor      constraintEqualToAnchor:self.feedbackLabel.bottomAnchor constant:10.0],
        [self.timeBadge.centerXAnchor  constraintEqualToAnchor:c.centerXAnchor],
        [self.timeBadge.heightAnchor   constraintEqualToConstant:28.0],
    ]];

    if (self.showsHelpButtons)
    {
        [NSLayoutConstraint activateConstraints:@[
            [self.neilButton.topAnchor         constraintEqualToAnchor:self.timeBadge.bottomAnchor constant:m],
            [self.neilButton.leadingAnchor     constraintEqualToAnchor:c.leadingAnchor constant:m],

            [self.janowskiButton.topAnchor     constraintEqualToAnchor:self.neilButton.topAnchor],
            [self.janowskiButton.leadingAnchor constraintEqualToAnchor:self.neilButton.trailingAnchor constant:m],
            [self.janowskiButton.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],
            // Equal widths so neither pill crowds the other.
            [self.janowskiButton.widthAnchor   constraintEqualToAnchor:self.neilButton.widthAnchor],

            [self.hintsStack.topAnchor      constraintEqualToAnchor:self.neilButton.bottomAnchor constant:12.0],
            [self.hintsStack.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
            [self.hintsStack.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],

            // Pin the hints stack to the content bottom so the scroll height
            // grows and shrinks with the hints.
            [self.hintsStack.bottomAnchor constraintEqualToAnchor:c.bottomAnchor constant:-m],
        ]];
    }
    else
    {
        // No hints (Workout): the time badge is the last element.
        [self.timeBadge.bottomAnchor constraintEqualToAnchor:c.bottomAnchor constant:-m].active = YES;
    }
}

#pragma mark - Reusable builders

- (UITextField *)percentField
{
    UITextField *field = [[UITextField alloc] init];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    field.borderStyle      = UITextBorderStyleRoundedRect;
    field.keyboardType     = UIKeyboardTypeNumberPad;
    field.textAlignment    = NSTextAlignmentCenter;
    field.font             = [UIFont monospacedDigitSystemFontOfSize:22.0
                                                              weight:UIFontWeightSemibold];
    field.placeholder      = @"%";
    field.delegate         = self;
    field.returnKeyType    = UIReturnKeyDone;
    return field;
}

- (UIButton *)filledButtonWithTitle:(NSString *)title action:(SEL)action
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font     = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    btn.backgroundColor     = [UIColor colorNamed:@"AccentColor"];
    btn.layer.cornerRadius  = 10.0;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (UIButton *)plainButtonWithTitle:(NSString *)title action:(SEL)action
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor colorNamed:@"AccentColor"] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

// A rounded pill toggle for the hints. The on/off state is shown by tint and
// a leading eye / eye-slash icon, not by changing the label. The title stays
// constant so the control reads as one toggle, not a question.
- (UIButton *)hintPillWithTitle:(NSString *)title action:(SEL)action
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    btn.titleLabel.minimumScaleFactor        = 0.7;

    // Small gap between the icon and the title. The *EdgeInsets API is
    // deprecated since iOS 15, but it is the simplest way to nudge a plain
    // UIButton's icon/title here and there is no UIButtonConfiguration in
    // play that it would conflict with.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    btn.imageEdgeInsets   = UIEdgeInsetsMake(0, -4, 0, 4);
    btn.titleEdgeInsets   = UIEdgeInsetsMake(0,  4, 0, -4);
    btn.contentEdgeInsets = UIEdgeInsetsMake(10, 14, 10, 14);
#pragma clang diagnostic pop

    btn.layer.cornerRadius  = 18.0;
    btn.layer.borderWidth   = 0.5;
    btn.layer.masksToBounds = YES;

    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

// Applies the on/off look to a hint pill.
- (void)setPill:(UIButton *)pill on:(BOOL)on
{
    UIColor *accent = [UIColor colorNamed:@"AccentColor"];

    if (on)
    {
        UIImage *eye = [UIImage systemImageNamed:@"eye"];
        [pill setImage:eye forState:UIControlStateNormal];
        pill.tintColor               = accent;
        [pill setTitleColor:accent forState:UIControlStateNormal];
        pill.backgroundColor         = [accent colorWithAlphaComponent:0.12];
        pill.layer.borderColor       = accent.CGColor;
    }
    else
    {
        UIImage *eyeOff = [UIImage systemImageNamed:@"eye.slash"];
        [pill setImage:eyeOff forState:UIControlStateNormal];
        pill.tintColor               = [UIColor tertiaryLabelColor];
        [pill setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
        pill.backgroundColor         = [UIColor secondarySystemBackgroundColor];
        pill.layer.borderColor       = [UIColor separatorColor].CGColor;
    }
}

// A coloured pill with white text, matching the pip-count time badge.
- (UILabel *)badge
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.font          = [UIFont monospacedDigitSystemFontOfSize:15.0
                                                         weight:UIFontWeightSemibold];
    lbl.textColor     = [UIColor whiteColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.layer.cornerRadius  = 10.0;
    lbl.layer.masksToBounds = YES;
    return lbl;
}

- (void)refreshToleranceInfo
{
    NSInteger tol = [BGGMETSettings tolerancePercent];
    if (tol == 0)
    {
        self.toleranceInfoLabel.text = BGGLocalizedString(@"Tolerance: exact");
    }
    else
    {
        self.toleranceInfoLabel.text = [NSString stringWithFormat:BGGLocalizedString(@"Tolerance: ± %ld%%"), (long)tol];
    }
}

#pragma mark - Hint toggles

- (void)toggleNeil
{
    if (self.neilHintView == nil)
    {
        // Switch on: build and insert the grid at the top of the stack.
        self.neilHintView = [BGGMETHintViews neilsNumbersView];
        [self.hintsStack insertArrangedSubview:self.neilHintView atIndex:0];
        [self setPill:self.neilButton on:YES];
    }
    else
    {
        // Switch off: remove it.
        [self.hintsStack removeArrangedSubview:self.neilHintView];
        [self.neilHintView removeFromSuperview];
        self.neilHintView = nil;
        [self setPill:self.neilButton on:NO];
    }
}

- (void)toggleJanowski
{
    if (self.janowskiHintView == nil)
    {
        self.janowskiHintView = [BGGMETHintViews janowskiFormulaView];
        // Append below Neil's grid if that is showing, else it is the only one.
        [self.hintsStack addArrangedSubview:self.janowskiHintView];
        [self setPill:self.janowskiButton on:YES];
    }
    else
    {
        [self.hintsStack removeArrangedSubview:self.janowskiHintView];
        [self.janowskiHintView removeFromSuperview];
        self.janowskiHintView = nil;
        [self setPill:self.janowskiButton on:NO];
    }
}

#pragma mark - Match length picker

- (void)showMatchLengthPicker
{
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:BGGLocalizedString(@"Match length?")
                                                 message:BGGLocalizedString(@"Pick the match length to train.")
                                          preferredStyle:UIAlertControllerStyleAlert];

    for (NSNumber *n in @[@5, @7, @9, @11])
    {
        NSInteger length = n.integerValue;
        [alert addAction:[UIAlertAction
                          actionWithTitle:[NSString stringWithFormat:BGGLocalizedString(@"%ld-point match"), (long)length]
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *a)
        {
            [self showCountPickerForLength:length];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:BGGLocalizedString(@"Cancel")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *a)
    {
        [self returnFromExercise];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Count picker

- (void)showCountPickerForLength:(NSInteger)length
{
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:BGGLocalizedString(@"How many questions?")
                                                 message:[NSString stringWithFormat:
                                                          BGGLocalizedString(@"%ld-point match"), (long)length]
                                          preferredStyle:UIAlertControllerStyleAlert];

    for (NSNumber *n in @[@5, @10, @20])
    {
        NSInteger count = n.integerValue;
        [alert addAction:[UIAlertAction
                          actionWithTitle:[NSString stringWithFormat:BGGLocalizedString(@"%ld questions"), (long)count]
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *a)
        {
            [self startSessionWithLength:length count:count];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:BGGLocalizedString(@"Cancel")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *a)
    {
        [self returnFromExercise];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Session

- (void)startSessionWithLength:(NSInteger)length count:(NSInteger)count
{
    self.matchLength  = length;
    self.tasks        = [self generateTasksForLength:length count:count];
    self.currentIndex = 0;
    self.correctCount = 0;
    self.totalCount   = count;

    self.currentWorkout = [[CoreDataManager sharedManager]
                           createWorkoutWithModule:[self moduleIdentifier]
                                              mode:[self modeIdentifier]
                                        totalCount:count];
    [[CoreDataManager sharedManager] saveContext];

    [self refreshToleranceInfo];
    [self showCurrentTask];
}

// Builds `count` random non-diagonal scores for an `length`-point match.
// Scores run 0...length-1 (both players still need at least one point).
// The diagonal (equal scores → 50%) is skipped. The leader is the higher
// score; the stored correct value is the rounded equity for the leader.
- (NSArray<NSDictionary *> *)generateTasksForLength:(NSInteger)length count:(NSInteger)count
{
    BGGMatchEquityTable *met = [BGGMatchEquityTable sharedTable];
    NSMutableArray<NSDictionary *> *out = [NSMutableArray arrayWithCapacity:(NSUInteger)count];

    NSInteger guard = 0;
    while ((NSInteger)out.count < count && guard < count * 200)
    {
        guard++;

        NSInteger a = (NSInteger)arc4random_uniform((uint32_t)length);   // 0...length-1
        NSInteger b = (NSInteger)arc4random_uniform((uint32_t)length);
        if (a == b) { continue; }   // skip 50% diagonal

        NSInteger leaderScore  = MAX(a, b);
        NSInteger trailerScore = MIN(a, b);
        NSInteger leaderAway   = length - leaderScore;    // 1...length
        NSInteger trailerAway  = length - trailerScore;

        NSInteger correct = [met roundedEquityForPlayerAway:leaderAway
                                               opponentAway:trailerAway];

        [out addObject:@{
            @"leaderScore":  @(leaderScore),
            @"trailerScore": @(trailerScore),
            @"leaderAway":   @(leaderAway),
            @"trailerAway":  @(trailerAway),
            @"correct":      @(correct),
        }];
    }
    return [out copy];
}

- (void)showCurrentTask
{
    if (self.currentIndex >= (NSInteger)self.tasks.count)
    {
        [self showSummary];
        return;
    }

    NSDictionary *task = self.tasks[(NSUInteger)self.currentIndex];
    NSInteger leaderScore  = [task[@"leaderScore"] integerValue];
    NSInteger trailerScore = [task[@"trailerScore"] integerValue];

    self.scoreLabel.text = [NSString stringWithFormat:@"%ld – %ld",
                            (long)leaderScore, (long)trailerScore];
    self.matchLabel.text = [NSString stringWithFormat:BGGLocalizedString(@"in a %ld-point match"),
                            (long)self.matchLength];

    self.progressLabel.text = [NSString stringWithFormat:@"%ld / %ld",
                               (long)(self.currentIndex + 1), (long)self.totalCount];

    self.answerField.text    = @"";
    self.feedbackLabel.alpha = 0.0;
    self.timeBadge.alpha     = 0.0;
    self.submitButton.hidden = NO;
    self.cancelButton.hidden = NO;
    self.nextButton.hidden   = YES;
    self.cancelAfterNextButton.hidden = YES;
    self.answerField.enabled = YES;

    [self.answerField becomeFirstResponder];
    [self startTimer];
}

#pragma mark - Answer

- (void)submitTapped
{
    NSString *text = [self.answerField.text stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceCharacterSet]];
    if (text.length == 0) { [self.answerField becomeFirstResponder]; return; }

    [self stopTimer];
    [self.view endEditing:YES];

    NSDictionary *task   = self.tasks[(NSUInteger)self.currentIndex];
    NSInteger correct    = [task[@"correct"] integerValue];
    NSInteger userValue  = text.integerValue;
    NSInteger tolerance  = [BGGMETSettings tolerancePercent];
    BOOL ok = (labs((long)(userValue - correct)) <= tolerance);

    if (ok) { self.correctCount++; }

    // Persist this attempt immediately (crash-safe).
    CoreDataManager *cd = [CoreDataManager sharedManager];
    [cd addMETAttemptToWorkout:self.currentWorkout
                    playerAway:[task[@"leaderAway"] integerValue]
                  opponentAway:[task[@"trailerAway"] integerValue]
                    userEquity:userValue
                 correctEquity:correct
                 toleranceUsed:tolerance
                     isCorrect:ok
                     elapsedMs:(NSInteger)(self.elapsedSeconds * 1000.0)];
    [cd saveContext];

    [self showFeedbackOK:ok userValue:userValue correct:correct];

    UIImpactFeedbackGenerator *impact = [[UIImpactFeedbackGenerator alloc]
                                          initWithStyle:ok
                                                        ? UIImpactFeedbackStyleMedium
                                                        : UIImpactFeedbackStyleRigid];
    [impact impactOccurred];

    self.submitButton.hidden = YES;
    self.cancelButton.hidden = YES;
    self.nextButton.hidden   = NO;
    self.cancelAfterNextButton.hidden = NO;
    self.answerField.enabled = NO;
}

- (void)nextTapped
{
    self.currentIndex++;
    [self showCurrentTask];
}

- (void)showFeedbackOK:(BOOL)ok
             userValue:(NSInteger)userValue
               correct:(NSInteger)correct
{
    if (ok)
    {
        self.feedbackLabel.text      = [NSString stringWithFormat:BGGLocalizedString(@"✓  Correct!  %ld%%"), (long)correct];
        self.feedbackLabel.textColor = [UIColor systemGreenColor];
    }
    else
    {
        self.feedbackLabel.text      = [NSString stringWithFormat:
                                        BGGLocalizedString(@"✗  You said %ld%%, correct: %ld%%"),
                                        (long)userValue, (long)correct];
        self.feedbackLabel.textColor = [UIColor systemRedColor];
    }

    [self showTimeBadge];

    [UIView animateWithDuration:0.2 animations:^{
        self.feedbackLabel.alpha = 1.0;
        self.timeBadge.alpha     = 1.0;
    }];
}

- (void)showTimeBadge
{
    NSInteger s = (NSInteger)self.elapsedSeconds;
    self.timeBadge.text            = [NSString stringWithFormat:@"  ⏱ %lds  ", (long)s];
    self.timeBadge.backgroundColor = [BGGTimeColor colorForSeconds:s];
}

#pragma mark - Leaving

// Cancel, the pickers' Cancel, and Done at the end all funnel through here.
- (void)returnFromExercise
{
    if (self.exerciseDelegate != nil)
    {
        [self.exerciseDelegate metExerciseDidCancel:self];
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

#pragma mark - Keyboard

- (void)keyboardWillChangeFrame:(NSNotification *)note
{
    CGRect kbScreen = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    UIView *refView = self.scrollView.superview;
    CGRect kbInRef  = [refView convertRect:kbScreen fromView:nil];

    CGFloat overlap = CGRectGetMaxY(self.scrollView.frame) - CGRectGetMinY(kbInRef);
    if (overlap < 0.0) { overlap = 0.0; }

    self.scrollView.contentInset =
        UIEdgeInsetsMake(0.0, 0.0, overlap, 0.0);
    self.scrollView.verticalScrollIndicatorInsets =
        UIEdgeInsetsMake(0.0, 0.0, overlap, 0.0);

    [self.view layoutIfNeeded];

    CGRect r = [self.contentView convertRect:self.submitButton.frame
                                    fromView:self.submitButton.superview];
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

- (void)stopTimer { [self.timer invalidate]; self.timer = nil; }
- (void)timerTick { self.elapsedSeconds += 1.0; [self updateTimerLabel]; }

- (void)updateTimerLabel
{
    NSInteger s = (NSInteger)self.elapsedSeconds;
    self.timerLabel.text = [NSString stringWithFormat:@"%ld:%02ld",
                            (long)(s / 60), (long)(s % 60)];

    // Workout shows the timer live and colours it by the current band.
    if (self.measureTime)
    {
        self.timerLabel.textColor       = [UIColor whiteColor];
        self.timerLabel.backgroundColor = [BGGTimeColor colorForSeconds:s];
        self.timerLabel.layer.cornerRadius  = 8.0;
        self.timerLabel.layer.masksToBounds = YES;
    }
}

#pragma mark - Summary

- (void)showSummary
{
    if (self.currentWorkout != nil)
    {
        self.currentWorkout.finishedAt = [NSDate date];
        [[CoreDataManager sharedManager] saveContext];
    }

    NSInteger activityLevel = [self activityLevelForCompletedSession];
    if (activityLevel > 0)
    {
        [[CoreDataManager sharedManager] bumpTodayActivityToLevel:activityLevel];
    }

    NSString *message = [NSString stringWithFormat:
                         BGGLocalizedString(@"%ld of %ld correct (%.0f%%)"),
                         (long)self.correctCount, (long)self.totalCount,
                         self.totalCount > 0
                             ? (double)self.correctCount / self.totalCount * 100.0
                             : 0.0];

    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:BGGLocalizedString(@"Session complete")
                                                 message:message
                                          preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BGGLocalizedString(@"Again")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a)
    {
        [self showMatchLengthPicker];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:BGGLocalizedString(@"Done")
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
    [self submitTapped];
    return NO;
}

@end
