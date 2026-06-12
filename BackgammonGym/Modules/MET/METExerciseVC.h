//
//  METExerciseVC.h
//  BackgammonGym
//
//  Abstract base class for MET Training and Workout. Presents a match score
//  ("Match Score is 3–1 in a 7-point match"), asks the user to estimate the
//  leader's match-winning chance, checks the typed percentage against the
//  Rockwell-Kazaross table within the configured tolerance, and stores each
//  attempt. Subclasses configure timing and (later) the on-board help
//  buttons; the same Player/Opponent storage convention as the pip-count
//  module is reused via BGGWorkout + BGGMETAttempt.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class METExerciseVC;

// Lets the container (METVC) react when the user cancels a running session,
// so it can return to the previously active section instead of leaving the
// module. Mirrors PipCountExerciseDelegate.
@protocol METExerciseDelegate <NSObject>
- (void)metExerciseDidCancel:(METExerciseVC *)exercise;
@end

@interface METExerciseVC : UIViewController

// Notified when the user cancels the session.
@property (nonatomic, weak) id<METExerciseDelegate> exerciseDelegate;

// Override in subclasses to enable timing.
// Training: NO   Workout: YES
@property (nonatomic, assign, readonly) BOOL measureTime;

// Override in subclasses – whether the Neils Numbers / Janowski help buttons
// are offered. Training: YES   Workout: NO. The base returns NO; the buttons
// themselves are wired in a later step.
@property (nonatomic, assign, readonly) BOOL showsHelpButtons;

// Override in subclasses – a short explanatory line shown above the question
// describing the mode. The base implementation returns nil (no info line).
- (nullable NSString *)infoText;

// Identifiers stored with every workout and attempt for later filtering.
// Base: module "met", empty mode. Subclasses override modeIdentifier
// ("training" / "workout").
- (NSString *)moduleIdentifier;
- (NSString *)modeIdentifier;

// Override in subclasses – the activity level recorded for the contribution
// grid when a session finishes (training = 2, workout = 3). The base
// implementation returns 0, meaning the session is not counted.
- (NSInteger)activityLevelForCompletedSession;

@end

NS_ASSUME_NONNULL_END
