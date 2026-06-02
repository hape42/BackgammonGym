//
//  PipCountExerciseVC.m
//  BackgammonGym
//
//  Shared logic for Training and Workout:
//  position sequence, answer input, correct/wrong feedback,
//  session summary.
//

#import "PipCountExerciseVC.h"
#import "BGGBoardView.h"
#import "BGGBoardState.h"
#import "BGGPosition.h"
#import "PositionDatabase.h"
#import "Tools.h"
#import "BGGBoardGeometry.h"

// How many seconds between showing the result and loading the next position.
static const NSTimeInterval kNextPositionDelay = 1.2;

@interface PipCountExerciseVC () <UITextFieldDelegate>

// Board
@property (nonatomic, strong) BGGBoardView  *boardView;

// Input area
@property (nonatomic, strong) UITextField   *answerField;
@property (nonatomic, strong) UIButton      *submitButton;

// Feedback
@property (nonatomic, strong) UILabel       *feedbackLabel;   // "Correct!" / "Wrong – 142"
@property (nonatomic, strong) UILabel       *progressLabel;   // "3 / 10"

// Timer (Workout only)
@property (nonatomic, strong) UILabel       *timerLabel;
@property (nonatomic, strong) NSTimer       *timer;
@property (nonatomic, assign) NSTimeInterval elapsedSeconds;

// Session state
@property (nonatomic, strong) NSArray<BGGPositionEntry *> *positions;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger correctCount;
@property (nonatomic, assign) NSInteger totalCount;

@end

@implementation PipCountExerciseVC

// Subclasses override these.
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
    // Present the picker after the VC is fully in the hierarchy.
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

#pragma mark - UI setup

- (void)buildUI
{
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    CGFloat margin = 16.0;

    // Progress label (top left)
    self.progressLabel = [[UILabel alloc] init];
    self.progressLabel.font      = [UIFont monospacedDigitSystemFontOfSize:15.0
                                                                    weight:UIFontWeightMedium];
    self.progressLabel.textColor = [UIColor secondaryLabelColor];
    self.progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.progressLabel];

    // Timer label (top right, Workout only)
    self.timerLabel = [[UILabel alloc] init];
    self.timerLabel.font      = [UIFont monospacedDigitSystemFontOfSize:15.0
                                                                 weight:UIFontWeightMedium];
    self.timerLabel.textColor = [UIColor secondaryLabelColor];
    self.timerLabel.textAlignment = NSTextAlignmentRight;
    self.timerLabel.hidden    = !self.measureTime;
    self.timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.timerLabel];

    // Board view
    CGFloat ratio = kBGGBoardHeight / kBGGBoardWidth;
    self.boardView = [[BGGBoardView alloc] init];
    self.boardView.boardDesign       = [Tools currentBoardDesign];
    self.boardView.showsPointNumbers = self.showsPointNumbers;
    self.boardView.showsCube         = NO;
    self.boardView.showsDice         = NO;
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.boardView];

    // Answer text field (numeric pad)
    self.answerField = [[UITextField alloc] init];
    self.answerField.keyboardType        = UIKeyboardTypeNumberPad;
    self.answerField.borderStyle         = UITextBorderStyleRoundedRect;
    self.answerField.textAlignment       = NSTextAlignmentCenter;
    self.answerField.font                = [UIFont monospacedDigitSystemFontOfSize:28.0
                                                                            weight:UIFontWeightRegular];
    self.answerField.placeholder         = @"Pip count";
    self.answerField.returnKeyType       = UIReturnKeyDone;
    self.answerField.delegate            = self;
    self.answerField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.answerField];

    // Submit button
    self.submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.submitButton setTitle:@"Check" forState:UIControlStateNormal];
    self.submitButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.submitButton.backgroundColor = [UIColor colorNamed:@"AccentColor"]
                                     ?: [UIColor systemRedColor];
    [self.submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.submitButton.layer.cornerRadius = 10.0;
    self.submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.submitButton addTarget:self
                          action:@selector(submitTapped)
                forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.submitButton];

    // Feedback label
    self.feedbackLabel = [[UILabel alloc] init];
    self.feedbackLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    self.feedbackLabel.textAlignment = NSTextAlignmentCenter;
    self.feedbackLabel.alpha         = 0.0;
    self.feedbackLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.feedbackLabel];

    // Layout
    [NSLayoutConstraint activateConstraints:@[
        // Progress top left
        [self.progressLabel.topAnchor    constraintEqualToAnchor:safe.topAnchor    constant:8.0],
        [self.progressLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:margin],

        // Timer top right
        [self.timerLabel.topAnchor       constraintEqualToAnchor:safe.topAnchor    constant:8.0],
        [self.timerLabel.trailingAnchor  constraintEqualToAnchor:safe.trailingAnchor constant:-margin],
        [self.timerLabel.leadingAnchor   constraintEqualToAnchor:self.progressLabel.trailingAnchor constant:8.0],

        // Board below progress label, full width with margin
        [self.boardView.topAnchor        constraintEqualToAnchor:self.progressLabel.bottomAnchor constant:8.0],
        [self.boardView.leadingAnchor    constraintEqualToAnchor:safe.leadingAnchor constant:margin],
        [self.boardView.trailingAnchor   constraintEqualToAnchor:safe.trailingAnchor constant:-margin],
        [self.boardView.heightAnchor     constraintEqualToAnchor:self.boardView.widthAnchor
                                                      multiplier:ratio],

        // Answer field below board
        [self.answerField.topAnchor      constraintEqualToAnchor:self.boardView.bottomAnchor constant:16.0],
        [self.answerField.centerXAnchor  constraintEqualToAnchor:safe.centerXAnchor],
        [self.answerField.widthAnchor    constraintEqualToConstant:160.0],
        [self.answerField.heightAnchor   constraintEqualToConstant:52.0],

        // Submit button right of answer field
        [self.submitButton.centerYAnchor constraintEqualToAnchor:self.answerField.centerYAnchor],
        [self.submitButton.leadingAnchor constraintEqualToAnchor:self.answerField.trailingAnchor constant:12.0],
        [self.submitButton.widthAnchor   constraintEqualToConstant:90.0],
        [self.submitButton.heightAnchor  constraintEqualToConstant:52.0],

        // Feedback below input
        [self.feedbackLabel.topAnchor    constraintEqualToAnchor:self.answerField.bottomAnchor constant:16.0],
        [self.feedbackLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:margin],
        [self.feedbackLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-margin],
    ]];
}

#pragma mark - Count picker

// Let the user pick how many positions to practice before starting.
- (void)showCountPicker
{
    NSArray<BGGPositionEntry *> *all = [[PositionDatabase sharedDatabase]
                                        positionsForTag:@"pipcount"];
    NSInteger available = (NSInteger)all.count;

    NSString *title   = @"How many positions?";
    NSString *message = [NSString stringWithFormat:@"%ld available", (long)available];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    NSArray<NSNumber *> *counts = @[@5, @10, @20];
    for (NSNumber *n in counts)
    {
        NSInteger count = n.integerValue;
        if (count > available) { continue; }
        NSString *label = [NSString stringWithFormat:@"%ld positions", (long)count];
        [alert addAction:[UIAlertAction actionWithTitle:label
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *a) {
            [self startSessionWithCount:count positions:all];
        }]];
    }

    // "All" option
    NSString *allLabel = [NSString stringWithFormat:@"All (%ld)", (long)available];
    [alert addAction:[UIAlertAction actionWithTitle:allLabel
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a) {
        [self startSessionWithCount:available positions:all];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *a) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Session

- (void)startSessionWithCount:(NSInteger)count
                    positions:(NSArray<BGGPositionEntry *> *)all
{
    // Shuffle and trim to requested count.
    NSMutableArray *shuffled = [all mutableCopy];
    for (NSInteger i = shuffled.count - 1; i > 0; i--)
    {
        NSInteger j = arc4random_uniform((uint32_t)(i + 1));
        [shuffled exchangeObjectAtIndex:(NSUInteger)i withObjectAtIndex:(NSUInteger)j];
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

    BGGPositionEntry *entry = self.positions[(NSUInteger)self.currentIndex];
    self.boardView.boardState = [entry boardState];

    self.progressLabel.text = [NSString stringWithFormat:@"%ld / %ld",
                               (long)(self.currentIndex + 1), (long)self.totalCount];
    self.answerField.text   = @"";
    self.feedbackLabel.alpha = 0.0;
    self.submitButton.enabled = YES;

    [self.answerField becomeFirstResponder];

    if (self.measureTime)
    {
        [self startTimer];
    }
}

#pragma mark - Answer handling

- (void)submitTapped
{
    NSString *text = [self.answerField.text stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceCharacterSet]];
    if (text.length == 0) { return; }

    [self stopTimer];
    self.submitButton.enabled = NO;

    NSInteger userAnswer    = text.integerValue;
    NSInteger correctAnswer = [self correctAnswerForCurrentPosition];
    BOOL isCorrect          = (userAnswer == correctAnswer);

    if (isCorrect) { self.correctCount++; }

    [self showFeedback:isCorrect correctAnswer:correctAnswer];

    // Haptic feedback
    UIImpactFeedbackGenerator *impact = [[UIImpactFeedbackGenerator alloc]
                                          initWithStyle:isCorrect
                                                        ? UIImpactFeedbackStyleMedium
                                                        : UIImpactFeedbackStyleRigid];
    [impact impactOccurred];

    // Advance after a short delay.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(kNextPositionDelay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        self.currentIndex++;
        [self showCurrentPosition];
    });
}

- (NSInteger)correctAnswerForCurrentPosition
{
    BGGPositionEntry *entry = self.positions[(NSUInteger)self.currentIndex];
    BGGBoardState *state    = [entry boardState];
    return [state totalCheckersForPlayer:BGGPlayerBlue] > 0
        ? [state pipCountForPlayer:BGGPlayerBlue]
        : 0;
}

- (void)showFeedback:(BOOL)isCorrect correctAnswer:(NSInteger)correct
{
    if (isCorrect)
    {
        self.feedbackLabel.text      = @"✓  Correct!";
        self.feedbackLabel.textColor = [UIColor systemGreenColor];
    }
    else
    {
        self.feedbackLabel.text      = [NSString stringWithFormat:
                                        @"✗  Wrong – correct answer: %ld", (long)correct];
        self.feedbackLabel.textColor = [UIColor systemRedColor];
    }

    [UIView animateWithDuration:0.2 animations:^{
        self.feedbackLabel.alpha = 1.0;
    }];
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

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)timerTick
{
    self.elapsedSeconds += 1.0;
    [self updateTimerLabel];
}

- (void)updateTimerLabel
{
    NSInteger secs = (NSInteger)self.elapsedSeconds;
    self.timerLabel.text = [NSString stringWithFormat:@"%ld:%02ld",
                            (long)(secs / 60), (long)(secs % 60)];
}

#pragma mark - Summary

- (void)showSummary
{
    [self.answerField resignFirstResponder];

    NSString *message = [NSString stringWithFormat:
                         @"%ld of %ld correct (%.0f%%)",
                         (long)self.correctCount,
                         (long)self.totalCount,
                         self.totalCount > 0
                             ? (double)self.correctCount / self.totalCount * 100.0
                             : 0.0];

    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Session complete"
                                                 message:message
                                          preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Again"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *a) {
        [self showCountPicker];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Done"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *a) {
        [self.navigationController popViewControllerAnimated:YES];
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
