//
//  BGGTimeColor.h
//  BackgammonGym
//
//  Central place for the answer-time colour thresholds and the colour
//  lookup. The thresholds are user-configurable in Settings and shared
//  by Training and Workout.
//
//    elapsed <= greenMax   -> green   (fast)
//    elapsed <= orangeMax  -> orange  (ok)
//    else                  -> red     (slow)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// NSUserDefaults keys for the two thresholds (in seconds).
extern NSString * const kBGGTimeGreenMaxKey;
extern NSString * const kBGGTimeOrangeMaxKey;

// Default threshold values, used until the user changes them.
extern const NSInteger kBGGTimeGreenMaxDefault;   // 20
extern const NSInteger kBGGTimeOrangeMaxDefault;  // 60

@interface BGGTimeColor : NSObject

// Registers the default thresholds. Safe to call more than once;
// call early (e.g. from the app delegate or first use).
+ (void)registerDefaults;

// The current thresholds, read from NSUserDefaults (falling back to the
// defaults above if nothing is stored yet).
+ (NSInteger)greenMax;
+ (NSInteger)orangeMax;

// Store a threshold. greenMax is clamped to stay below orangeMax and
// orangeMax is clamped to stay above greenMax, so the ranges never cross.
+ (void)setGreenMax:(NSInteger)seconds;
+ (void)setOrangeMax:(NSInteger)seconds;

// The strong colour for a given elapsed time – used for badges and results.
+ (UIColor *)colorForSeconds:(NSInteger)seconds;

// A faint, desaturated version of the same colour – used for the live
// timer tint during a workout, so it hints without shouting.
+ (UIColor *)faintColorForSeconds:(NSInteger)seconds;

@end

NS_ASSUME_NONNULL_END
