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
#import "BGGAchievements.h"
#import "BGGNumberPad.h"
#import "UIViewController+BGGHomeButton.h"
#import "BGGMatchEquityTable.h"
#import "BGGMETSettings.h"
#import "BGGMETHintViews.h"
#import "BGGTimeColor.h"
#import "CoreDataManager.h"

@interface METExerciseVC () <BGGNumberPadDelegate>

// Scroll container for the question/answer block. No keyboard handling now –
// the number pad is laid out inline, so nothing slides up over the score.
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

// Input. The big display shows the digits typed on the number pad; the pad
// itself replaces the system keyboard so the score above stays visible.
@property (nonatomic, strong) UILabel       *answerLabel;    // "Leader's match-winning chance (%)"
@property (nonatomic, strong) UILabel       *answerDisplay;  // big "73 %"
@property (nonatomic, strong) BGGNumberPad  *numberPad;
@property (nonatomic, copy)   NSString      *currentInput;   // digits typed so far

// Two layout variants for the display + number pad: stacked (iPhone / narrow)
// and side-by-side (iPad / wide). Switched in -applyInputLayoutForWidth:.
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *stackedInputConstraints;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *sideBySideInputConstraints;
@property (nonatomic, assign) BOOL inputLayoutIsSideBySide;

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

// YES once the current question has been checked. Before the check the hint
// pills show only the general method; after it they show the worked example
// with the result, so they never give the answer away while guessing.
@property (nonatomic, assign) BOOL currentChecked;
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

    self.answerDisplay = [[UILabel alloc] init];
    self.answerDisplay.translatesAutoresizingMaskIntoConstraints = NO;
    self.answerDisplay.font          = [UIFont systemFontOfSize:40.0 weight:UIFontWeightMedium];
    self.answerDisplay.textColor     = [UIColor colorNamed:@"AccentColor"];
    self.answerDisplay.textAlignment = NSTextAlignmentCenter;
    self.answerDisplay.adjustsFontSizeToFitWidth = YES;
    self.answerDisplay.minimumScaleFactor = 0.6;
    [self.contentView addSubview:self.answerDisplay];

    self.currentInput = @"";

    self.numberPad = [[BGGNumberPad alloc] initWithFrame:CGRectZero];
    self.numberPad.translatesAutoresizingMaskIntoConstraints = NO;
    self.numberPad.delegate = self;
    [self.contentView addSubview:self.numberPad];

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
    self.submitButton.hidden          = YES;   // replaced by the number pad's OK key
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

        // answerDisplay + numberPad are positioned by a separate, width-
        // dependent set (see -applyInputLayoutForWidth:), because they sit
        // stacked on iPhone and side-by-side on iPad. Everything below still
        // anchors to numberPad.bottomAnchor, which exists in both variants.

        // The Check button is replaced by the pad's OK key; keep it in the
        // hierarchy (always hidden) so the existing show/hide code is untouched.
        [self.submitButton.topAnchor      constraintEqualToAnchor:self.numberPad.bottomAnchor constant:m],
        [self.submitButton.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.submitButton.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],
        [self.submitButton.heightAnchor   constraintEqualToConstant:0.5],

        [self.cancelButton.topAnchor      constraintEqualToAnchor:self.numberPad.bottomAnchor constant:8.0],
        [self.cancelButton.centerXAnchor  constraintEqualToAnchor:c.centerXAnchor],

        // Next + its Cancel occupy the slot below the pad.
        [self.nextButton.topAnchor      constraintEqualToAnchor:self.numberPad.bottomAnchor constant:m],
        [self.nextButton.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.nextButton.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],
        [self.nextButton.heightAnchor   constraintEqualToConstant:50.0],

        [self.cancelAfterNextButton.topAnchor     constraintEqualToAnchor:self.nextButton.bottomAnchor constant:8.0],
        [self.cancelAfterNextButton.centerXAnchor constraintEqualToAnchor:c.centerXAnchor],

        // Feedback sits below the lowest button in the group. cancelAfterNext
        // is the deepest element (it lives under nextButton), so anchoring
        // here keeps the feedback clear of both the question-state Cancel and
        // the answered-state Next + Cancel.
        [self.feedbackLabel.topAnchor      constraintEqualToAnchor:self.cancelAfterNextButton.bottomAnchor constant:m],
        [self.feedbackLabel.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.feedbackLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],

        [self.timeBadge.topAnchor      constraintEqualToAnchor:self.feedbackLabel.bottomAnchor constant:10.0],
        [self.timeBadge.centerXAnchor  constraintEqualToAnchor:c.centerXAnchor],
        [self.timeBadge.heightAnchor   constraintEqualToConstant:28.0],
    ]];

    [self buildInputLayoutSetsWithGuide:c margin:m];
    [self applyInputLayoutForWidth:self.view.bounds.size.width];

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

#pragma mark - Input layout (stacked vs side-by-side)

// Builds both constraint sets once. Stacked: display above, pad below, both
// full width (iPhone). Side-by-side: display left (flexible), pad right at a
// fixed iPhone-like width, equal height (iPad). Everything below the pad keeps
// anchoring to numberPad.bottomAnchor in both variants.
- (void)buildInputLayoutSetsWithGuide:(UIView *)c margin:(CGFloat)m
{
    // Pad sized to roughly 2/3 of the earlier footprint – the full-width pad
    // felt too dominant on both devices.
    CGFloat padHeight = 168.0;
    CGFloat padWidth  = 228.0;

    self.stackedInputConstraints = @[
        [self.answerDisplay.topAnchor      constraintEqualToAnchor:self.answerLabel.bottomAnchor constant:6.0],
        [self.answerDisplay.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.answerDisplay.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-m],
        [self.answerDisplay.heightAnchor   constraintEqualToConstant:56.0],

        // Centered, fixed width (not full width) so the keys aren't huge.
        [self.numberPad.topAnchor       constraintEqualToAnchor:self.answerDisplay.bottomAnchor constant:m],
        [self.numberPad.centerXAnchor   constraintEqualToAnchor:c.centerXAnchor],
        [self.numberPad.widthAnchor     constraintEqualToConstant:padWidth],
        [self.numberPad.heightAnchor    constraintEqualToConstant:padHeight],
    ];

    // Side-by-side: pad pinned to the trailing edge at the same fixed width;
    // the display fills the space to its left and centres vertically.
    self.sideBySideInputConstraints = @[
        [self.numberPad.topAnchor       constraintEqualToAnchor:self.answerLabel.bottomAnchor constant:m],
        [self.numberPad.trailingAnchor  constraintEqualToAnchor:c.trailingAnchor constant:-m],
        [self.numberPad.widthAnchor     constraintEqualToConstant:padWidth],
        [self.numberPad.heightAnchor    constraintEqualToConstant:padHeight],

        [self.answerDisplay.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:m],
        [self.answerDisplay.trailingAnchor constraintEqualToAnchor:self.numberPad.leadingAnchor constant:-m],
        [self.answerDisplay.centerYAnchor  constraintEqualToAnchor:self.numberPad.centerYAnchor],
        [self.answerDisplay.heightAnchor   constraintEqualToConstant:56.0],
    ];
}

// Picks the side-by-side layout on wide screens (iPad), stacked otherwise.
- (void)applyInputLayoutForWidth:(CGFloat)width
{
    BOOL sideBySide = (width >= 600.0);

    BOOL anyActive = self.stackedInputConstraints.firstObject.isActive ||
                     self.sideBySideInputConstraints.firstObject.isActive;
    if (anyActive && sideBySide == self.inputLayoutIsSideBySide)
    {
        return;   // already in the right layout, nothing to do
    }
    self.inputLayoutIsSideBySide = sideBySide;

    [NSLayoutConstraint deactivateConstraints:self.stackedInputConstraints];
    [NSLayoutConstraint deactivateConstraints:self.sideBySideInputConstraints];
    [NSLayoutConstraint activateConstraints:sideBySide
        ? self.sideBySideInputConstraints
        : self.stackedInputConstraints];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    // The width is reliably final here; catch the case where viewDidLoad ran
    // before the view had its real size.
    [self applyInputLayoutForWidth:self.view.bounds.size.width];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> ctx)
    {
        [self applyInputLayoutForWidth:size.width];
    }
                                 completion:nil];
}

#pragma mark - Reusable builders

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
        // Before the check: show the general method only (no answer). After
        // the check: show the worked example for the current score.
        if (self.currentChecked)
        {
            NSDictionary *task = self.tasks[(NSUInteger)self.currentIndex];
            self.neilHintView = [BGGMETHintViews
                neilsNumbersViewForLeaderAway:[task[@"leaderAway"] integerValue]
                                  trailerAway:[task[@"trailerAway"] integerValue]];
        }
        else
        {
            self.neilHintView = [BGGMETHintViews neilsNumbersView];
        }
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
        if (self.currentChecked)
        {
            NSDictionary *task = self.tasks[(NSUInteger)self.currentIndex];
            self.janowskiHintView = [BGGMETHintViews
                janowskiFormulaViewForLeaderAway:[task[@"leaderAway"] integerValue]
                                     trailerAway:[task[@"trailerAway"] integerValue]];
        }
        else
        {
            self.janowskiHintView = [BGGMETHintViews janowskiFormulaView];
        }
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
    // Explain why a length is chosen at all: a session has a fixed length so
    // it ends with a recorded result and stats (issue #12).
    NSString *message = [NSString stringWithFormat:
                         BGGLocalizedString(@"%ld-point match"), (long)length];
    message = [message stringByAppendingFormat:@"\n\n%@",
               BGGLocalizedString(@"session.fixedlength.hint")];

    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:BGGLocalizedString(@"How many questions?")
                                                 message:message
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

    // Track which score pairs we have already used, so the same match score
    // does not repeat while unused ones remain. The pool of distinct non-
    // diagonal pairs for an L-point match is L*(L-1)/2 (order does not
    // matter: leader is always the higher score). If `count` exceeds that
    // pool, we allow repeats again once every distinct pair has been shown.
    NSMutableSet<NSString *> *usedPairs = [NSMutableSet set];
    NSInteger poolSize = length * (length - 1) / 2;

    NSInteger guard = 0;
    while ((NSInteger)out.count < count && guard < count * 200)
    {
        guard++;

        NSInteger a = (NSInteger)arc4random_uniform((uint32_t)length);   // 0...length-1
        NSInteger b = (NSInteger)arc4random_uniform((uint32_t)length);
        if (a == b) { continue; }   // skip 50% diagonal

        NSInteger leaderScore  = MAX(a, b);
        NSInteger trailerScore = MIN(a, b);

        // Skip a score pair we have already used, but only while there are
        // still unused pairs to draw from. Once the pool is exhausted (more
        // questions requested than distinct pairs), stop filtering so the
        // loop can fill the rest with repeats.
        NSString *pairKey = [NSString stringWithFormat:@"%ld-%ld",
                             (long)leaderScore, (long)trailerScore];
        if ((NSInteger)usedPairs.count < poolSize && [usedPairs containsObject:pairKey])
        {
            continue;
        }
        [usedPairs addObject:pairKey];

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

    // Big score, then the away count smaller and muted right after it, e.g.
    // "3 – 1  (2 away – 4 away)".
    //
    // The away conversion is a learning aid: at a real tournament table it
    // isn't shown, so we only append it in modes that offer aids (Training).
    // In Workout the score line stays bare ("3 – 1"), matching the existing
    // Training/Workout philosophy (board numbers and MET hints in Training,
    // none in Workout). The match length stays visible below either way.
    NSString *scoreText = [NSString stringWithFormat:@"%ld – %ld",
                           (long)leaderScore, (long)trailerScore];

    NSMutableAttributedString *score =
        [[NSMutableAttributedString alloc] initWithString:scoreText
            attributes:@{ NSForegroundColorAttributeName: [UIColor labelColor] }];

    NSInteger leaderAway  = [task[@"leaderAway"] integerValue];
    NSInteger trailerAway = [task[@"trailerAway"] integerValue];

    if (self.showsHelpButtons)
    {
        NSString *awayText = [NSString stringWithFormat:@"  (%ld %@ – %ld %@)",
                              (long)leaderAway,  BGGLocalizedString(@"away"),
                              (long)trailerAway, BGGLocalizedString(@"away")];
        [score appendAttributedString:
            [[NSAttributedString alloc] initWithString:awayText
                attributes:@{
                    NSForegroundColorAttributeName: [UIColor secondaryLabelColor],
                    NSFontAttributeName: [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular],
                    // Lift the smaller text so it sits roughly mid-height of the
                    // big score instead of clinging to its baseline.
                    NSBaselineOffsetAttributeName: @(8.0),
                }]];
    }

    // When either player is 1-away, the next game is the Crawford game (no
    // cube). The equity at 1-away is the Crawford value, so flag it on the
    // task. Unlike the away hint, this is shown in BOTH modes: Crawford is a
    // property of the position a player always knows at the table, not a
    // learning aid. "Crawford" is a proper noun and stays untranslated.
    if (leaderAway == 1 || trailerAway == 1)
    {
        NSString *crawfordText = [NSString stringWithFormat:@"  · %@",
                                  BGGLocalizedString(@"Crawford")];
        [score appendAttributedString:
            [[NSAttributedString alloc] initWithString:crawfordText
                attributes:@{
                    NSForegroundColorAttributeName: [UIColor colorNamed:@"AccentColor"],
                    NSFontAttributeName: [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold],
                    NSBaselineOffsetAttributeName: @(8.0),
                }]];
    }

    self.scoreLabel.attributedText = score;

    self.matchLabel.text = [NSString stringWithFormat:BGGLocalizedString(@"in a %ld-point match"),
                            (long)self.matchLength];

    self.progressLabel.text = [NSString stringWithFormat:@"%ld / %ld",
                               (long)(self.currentIndex + 1), (long)self.totalCount];

    self.currentInput = @"";
    [self refreshAnswerDisplay];
    self.feedbackLabel.alpha = 0.0;
    self.timeBadge.alpha     = 0.0;
    self.submitButton.hidden = YES;   // replaced by the pad's OK key
    self.cancelButton.hidden = NO;
    self.nextButton.hidden   = YES;
    self.cancelAfterNextButton.hidden = YES;
    self.numberPad.enabled   = YES;

    [self resetHints];

    [self startTimer];
}

// Collapse any open hint and reset the pill titles to plain (no result yet)
// for a fresh question.
- (void)resetHints
{
    if (!self.showsHelpButtons) { return; }

    self.currentChecked = NO;

    if (self.neilHintView)
    {
        [self.hintsStack removeArrangedSubview:self.neilHintView];
        [self.neilHintView removeFromSuperview];
        self.neilHintView = nil;
        [self setPill:self.neilButton on:NO];
    }
    if (self.janowskiHintView)
    {
        [self.hintsStack removeArrangedSubview:self.janowskiHintView];
        [self.janowskiHintView removeFromSuperview];
        self.janowskiHintView = nil;
        [self setPill:self.janowskiButton on:NO];
    }

    [self.neilButton     setTitle:@"Neil's Numbers" forState:UIControlStateNormal];
    [self.janowskiButton setTitle:@"Janowski"       forState:UIControlStateNormal];
}

// One decimal, localized separator – mirrors BGGMETHintViews so the pill
// title matches the worked example.
- (NSString *)oneDecimalString:(double)value
{
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    nf.minimumFractionDigits = 1;
    nf.maximumFractionDigits = 1;
    nf.usesGroupingSeparator = NO;
    return [nf stringFromNumber:@(value)];
}

#pragma mark - Answer

- (void)submitTapped
{
    NSString *text = self.currentInput;
    if (text.length == 0) { return; }   // nothing typed yet

    [self stopTimer];

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

    // Distinct haptics for right vs. wrong: a success pattern for a correct
    // answer, an error pattern for a wrong one. The previous impact styles
    // (medium vs. rigid) felt almost identical; success/error are clearly
    // different (issue #28). Matches the success haptic already used when an
    // achievement is earned.
    UINotificationFeedbackGenerator *haptic = [[UINotificationFeedbackGenerator alloc] init];
    [haptic notificationOccurred:ok ? UINotificationFeedbackTypeSuccess
                                    : UINotificationFeedbackTypeError];

    self.submitButton.hidden = YES;
    self.cancelButton.hidden = YES;
    self.nextButton.hidden   = NO;
    self.cancelAfterNextButton.hidden = NO;
    self.numberPad.enabled   = NO;

    self.currentChecked = YES;
    [self updateHintResultsForTask:task];
}

// After a check, show each method's estimate in its pill title (e.g.
// "Neil's Numbers 69,5%"), and if a hint is already open, rebuild it so the
// worked example matches the score just checked.
- (void)updateHintResultsForTask:(NSDictionary *)task
{
    if (!self.showsHelpButtons) { return; }

    NSInteger leaderAway  = [task[@"leaderAway"] integerValue];
    NSInteger trailerAway = [task[@"trailerAway"] integerValue];

    double neil = [BGGMETHintViews neilEquityForLeaderAway:leaderAway
                                               trailerAway:trailerAway];
    double jan  = [BGGMETHintViews janowskiEquityForLeaderAway:leaderAway
                                                   trailerAway:trailerAway];

    [self.neilButton setTitle:[NSString stringWithFormat:@"Neil's Numbers  %@%%",
                               [self oneDecimalString:neil]]
                     forState:UIControlStateNormal];
    [self.janowskiButton setTitle:[NSString stringWithFormat:@"Janowski  %@%%",
                                   [self oneDecimalString:jan]]
                         forState:UIControlStateNormal];

    // If a hint is already expanded, rebuild it for the new score.
    if (self.neilHintView)
    {
        UIView *fresh = [BGGMETHintViews neilsNumbersViewForLeaderAway:leaderAway
                                                          trailerAway:trailerAway];
        NSUInteger idx = [self.hintsStack.arrangedSubviews indexOfObject:self.neilHintView];
        [self.hintsStack removeArrangedSubview:self.neilHintView];
        [self.neilHintView removeFromSuperview];
        if (idx == NSNotFound) { idx = 0; }
        [self.hintsStack insertArrangedSubview:fresh atIndex:idx];
        self.neilHintView = fresh;
    }
    if (self.janowskiHintView)
    {
        UIView *fresh = [BGGMETHintViews janowskiFormulaViewForLeaderAway:leaderAway
                                                             trailerAway:trailerAway];
        NSUInteger idx = [self.hintsStack.arrangedSubviews indexOfObject:self.janowskiHintView];
        [self.hintsStack removeArrangedSubview:self.janowskiHintView];
        [self.janowskiHintView removeFromSuperview];
        if (idx == NSNotFound) { idx = self.hintsStack.arrangedSubviews.count; }
        [self.hintsStack insertArrangedSubview:fresh atIndex:idx];
        self.janowskiHintView = fresh;
    }
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

#pragma mark - BGGNumberPadDelegate

- (void)numberPad:(BGGNumberPad *)pad didTapDigit:(NSInteger)digit
{
    // Max two digits (the answer is 1–99; 0% and 100% can't occur). Leading
    // zero is not useful, so ignore a 0 typed into an empty display.
    if (self.currentInput.length >= 2) { return; }
    if (self.currentInput.length == 0 && digit == 0) { return; }

    self.currentInput = [self.currentInput stringByAppendingFormat:@"%ld", (long)digit];
    [self refreshAnswerDisplay];
}

- (void)numberPadDidTapDelete:(BGGNumberPad *)pad
{
    if (self.currentInput.length == 0) { return; }
    self.currentInput = [self.currentInput substringToIndex:self.currentInput.length - 1];
    [self refreshAnswerDisplay];
}

- (void)numberPadDidTapOK:(BGGNumberPad *)pad
{
    [self submitTapped];
}

// Shows the typed digits with a trailing "%", or a muted placeholder when
// empty.
- (void)refreshAnswerDisplay
{
    if (self.currentInput.length == 0)
    {
        self.answerDisplay.text      = @"–";
        self.answerDisplay.textColor = [UIColor tertiaryLabelColor];
    }
    else
    {
        self.answerDisplay.text      = [self.currentInput stringByAppendingString:@" %"];
        self.answerDisplay.textColor = [UIColor colorNamed:@"AccentColor"];
    }
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

@end
