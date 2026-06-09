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

@interface PipCountExerciseVC : UIViewController

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

@end

NS_ASSUME_NONNULL_END
