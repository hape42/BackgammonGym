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

@end

NS_ASSUME_NONNULL_END
