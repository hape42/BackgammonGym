//
//  PipCountExerciseVC.h
//  BackgammonGym
//
//  Abstract base class for Training and Workout.
//  Manages the position sequence, answer input and result display.
//  Subclasses configure the board display and timing behaviour.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PipCountExerciseVC;

// Lets the container (PipCountVC) react when the user cancels a running
// Training or Workout session, e.g. to return to the previously active
// section instead of falling back to the start screen.
@protocol PipCountExerciseDelegate <NSObject>
- (void)exerciseDidCancel:(PipCountExerciseVC *)exercise;
@end

@interface PipCountExerciseVC : UIViewController

// Notified when the user cancels the session.
@property (nonatomic, weak) id<PipCountExerciseDelegate> exerciseDelegate;

// Override in subclasses to control board display.
// Training: YES  Workout: NO
@property (nonatomic, assign, readonly) BOOL showsPointNumbers;

// Override in subclasses to enable timing.
// Training: NO   Workout: YES
@property (nonatomic, assign, readonly) BOOL measureTime;

// Override in subclasses – defines which tags filter the positions for
// this module. Combined with logical AND, e.g. @[@"pipcount", @"training"].
// The base implementation returns an empty array (no positions).
- (NSArray<NSString *> *)requiredTags;

// Override in subclasses – a short explanatory line shown above the board
// describing the mode. The base implementation returns nil (no info line).
- (nullable NSString *)infoText;

// Identifiers stored with every workout and attempt for later filtering.
// Base: module "pipcount", empty mode. Subclasses override modeIdentifier
// ("training" / "workout").
- (NSString *)moduleIdentifier;
- (NSString *)modeIdentifier;

@end

NS_ASSUME_NONNULL_END
