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
#import "BGGBoardView.h"
#import "BGGBoardGeometry.h"
#import "BGGBoardState.h"
#import "BGGPosition.h"
#import "PositionDatabase.h"
#import "Tools.h"

static const CGFloat kWideThreshold = 700.0;

@interface PipCountExerciseVC () <UITextFieldDelegate>

// Board
@property (nonatomic, strong) BGGBoardView  *boardView;

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
@property (nonatomic, strong) UIButton      *nextButton;

// Feedback
@property (nonatomic, strong) UILabel       *feedbackLabel;

// Timer
@property (nonatomic, strong) NSTimer       *timer;
@property (nonatomic, assign) NSTimeInterval elapsedSeconds;

// Session state
@property (nonatomic, strong) NSArray<BGGPositionEntry *> *positions;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger correctCount;
@property (nonatomic, assign) NSInteger totalCount;

// Layout
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *wideConstraints;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *narrowConstraints;
@property (nonatomic, assign) BOOL isWideLayout;

@end

@implementation PipCountExerciseVC

- (BOOL)showsPointNumbers { return NO; }
- (BOOL)measureTime       { return NO; }

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self buildUI];
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
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    CGFloat m = 16.0;

    // Board view
    self.boardView = [[BGGBoardView alloc] init];
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardView.boardDesign       = [Tools currentBoardDesign];
    self.boardView.showsPointNumbers = self.showsPointNumbers;
    self.boardView.showsCube         = NO;
    self.boardView.showsDice         = NO;
    [self.view addSubview:self.boardView];

    CGFloat ratio = kBGGBoardHeight / kBGGBoardWidth;
    [[self.boardView.heightAnchor constraintEqualToAnchor:self.boardView.widthAnchor
                                               multiplier:ratio] setActive:YES];

    // Controls container
    self.controlsView = [[UIView alloc] init];
    self.controlsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.controlsView];

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
    self.timerLabel.textAlignment = NSTextAlignmentRight;
    // Timer label – visible only in Workout (live countdown pressure).
    // In Training the time is shown in the feedback after checking.
    self.timerLabel.hidden = !self.measureTime;
    self.timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlsView addSubview:self.timerLabel];

    // Blue label + field
    self.blueLabel = [self labelWithText:@"My pip count"];
    [self.controlsView addSubview:self.blueLabel];
    self.blueField = [self pipCountField];
    self.blueField.returnKeyType = UIReturnKeyNext;
    [self.controlsView addSubview:self.blueField];

    // Yellow label + field
    self.yellowLabel = [self labelWithText:@"Opponent pip count"];
    [self.controlsView addSubview:self.yellowLabel];
    self.yellowField = [self pipCountField];
    self.yellowField.returnKeyType = UIReturnKeyDone;
    [self.controlsView addSubview:self.yellowField];

    // Check button
    self.submitButton = [self actionButtonWithTitle:@"Check"
                                             action:@selector(submitTapped)];
    [self.controlsView addSubview:self.submitButton];

    // Feedback label
    self.feedbackLabel = [[UILabel alloc] init];
    self.feedbackLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
    self.feedbackLabel.textAlignment = NSTextAlignmentCenter;
    self.feedbackLabel.numberOfLines = 0;
    self.feedbackLabel.alpha         = 0.0;
    self.feedbackLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlsView addSubview:self.feedbackLabel];

    // Next button – hidden until after Check
    self.nextButton = [self actionButtonWithTitle:@"Next →"
                                           action:@selector(nextTapped)];
    self.nextButton.backgroundColor = [UIColor systemGrayColor];
    self.nextButton.hidden = YES;
    [self.controlsView addSubview:self.nextButton];

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

        [self.blueLabel.topAnchor        constraintEqualToAnchor:self.progressLabel.bottomAnchor
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

        [self.yellowLabel.topAnchor      constraintEqualToAnchor:self.blueField.bottomAnchor
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

        [self.submitButton.topAnchor     constraintEqualToAnchor:self.yellowField.bottomAnchor
                                                        constant:m],
        [self.submitButton.leadingAnchor constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                        constant:m],
        [self.submitButton.trailingAnchor constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                         constant:-m],
        [self.submitButton.heightAnchor  constraintEqualToConstant:48.0],

        [self.feedbackLabel.topAnchor    constraintEqualToAnchor:self.submitButton.bottomAnchor
                                                        constant:12.0],
        [self.feedbackLabel.leadingAnchor constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                         constant:m],
        [self.feedbackLabel.trailingAnchor constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                          constant:-m],

        [self.nextButton.topAnchor       constraintEqualToAnchor:self.feedbackLabel.bottomAnchor
                                                        constant:12.0],
        [self.nextButton.leadingAnchor   constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                        constant:m],
        [self.nextButton.trailingAnchor  constraintEqualToAnchor:self.controlsView.trailingAnchor
                                                        constant:-m],
        [self.nextButton.heightAnchor    constraintEqualToConstant:48.0],
    ]];

    // Outer layout pins – direction-independent parts
    [NSLayoutConstraint activateConstraints:@[
        [self.boardView.topAnchor     constraintEqualToAnchor:safe.topAnchor    constant:8.0],
        [self.boardView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:8.0],
        [self.controlsView.topAnchor  constraintEqualToAnchor:safe.topAnchor],
        [self.controlsView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
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

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    if (wide)
    {
        self.wideConstraints = @[
            [self.boardView.trailingAnchor constraintEqualToAnchor:self.controlsView.leadingAnchor
                                                          constant:-8.0],
            [self.boardView.bottomAnchor   constraintLessThanOrEqualToAnchor:safe.bottomAnchor
                                                                     constant:-8.0],
            [self.boardView.widthAnchor    constraintEqualToAnchor:safe.widthAnchor
                                                        multiplier:0.60],
            [self.controlsView.bottomAnchor constraintLessThanOrEqualToAnchor:safe.bottomAnchor],
        ];
        [NSLayoutConstraint activateConstraints:self.wideConstraints];
    }
    else
    {
        self.narrowConstraints = @[
            [self.boardView.trailingAnchor  constraintEqualToAnchor:safe.trailingAnchor
                                                           constant:-8.0],
            [self.controlsView.topAnchor    constraintEqualToAnchor:self.boardView.bottomAnchor
                                                           constant:8.0],
            [self.controlsView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
            [self.controlsView.bottomAnchor  constraintLessThanOrEqualToAnchor:safe.bottomAnchor],
        ];
        [NSLayoutConstraint activateConstraints:self.narrowConstraints];
    }
}

#pragma mark - Count picker

- (void)showCountPicker
{
    NSArray<BGGPositionEntry *> *all = [[PositionDatabase sharedDatabase]
                                        positionsForTag:@"pipcount"];
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
        [self.navigationController popViewControllerAnimated:YES];
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

    self.progressLabel.text   = [NSString stringWithFormat:@"%ld / %ld",
                                 (long)(self.currentIndex + 1), (long)self.totalCount];
    self.blueField.text       = @"";
    self.yellowField.text     = @"";
    self.feedbackLabel.alpha  = 0.0;
    self.submitButton.hidden  = NO;
    self.nextButton.hidden    = YES;
    self.blueField.enabled    = YES;
    self.yellowField.enabled  = YES;

    [self.blueField becomeFirstResponder];

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

    if (blueText.length == 0)   { [self.blueField   becomeFirstResponder]; return; }
    if (yellowText.length == 0) { [self.yellowField becomeFirstResponder]; return; }

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

    [self showFeedbackBlueOK:blueOK yellowOK:yellowOK
                 correctBlue:correctBlue correctYellow:correctYellow];

    UIImpactFeedbackGenerator *impact = [[UIImpactFeedbackGenerator alloc]
                                          initWithStyle:bothOK
                                                        ? UIImpactFeedbackStyleMedium
                                                        : UIImpactFeedbackStyleRigid];
    [impact impactOccurred];

    // Show Next button, hide Check button.
    // User decides when to move on.
    self.submitButton.hidden = YES;
    self.nextButton.hidden   = NO;
    self.blueField.enabled   = NO;
    self.yellowField.enabled = NO;
}

- (void)nextTapped
{
    self.currentIndex++;
    [self showCurrentPosition];
}

- (void)showFeedbackBlueOK:(BOOL)blueOK
                  yellowOK:(BOOL)yellowOK
               correctBlue:(NSInteger)correctBlue
             correctYellow:(NSInteger)correctYellow
{
    NSMutableString *msg = [NSMutableString string];

    if (blueOK && yellowOK)
    {
        NSString *timeStr = !self.measureTime
            ? [NSString stringWithFormat:@"  ⏱ %lds", (long)self.elapsedSeconds]
            : @"";
        [msg appendFormat:@"✓  Correct!  %ld : %ld%@",
         (long)correctBlue, (long)correctYellow, timeStr];
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
        if (!self.measureTime)
        {
            [msg appendFormat:@"\n⏱ %lds", (long)self.elapsedSeconds];
        }
        self.feedbackLabel.textColor = [UIColor systemRedColor];
    }

    self.feedbackLabel.text = msg;
    [UIView animateWithDuration:0.2 animations:^{ self.feedbackLabel.alpha = 1.0; }];
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
    self.timerLabel.text = [NSString stringWithFormat:@"%ld:%02ld",
                            (long)(s / 60), (long)(s % 60)];
}

#pragma mark - Summary

- (void)showSummary
{
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
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.blueField)
    {
        [self.yellowField becomeFirstResponder];
    }
    else
    {
        [self submitTapped];
    }
    return NO;
}

@end
