//
//  BGGMETHintViews.h
//  BackgammonGym
//
//  Reusable hint views for the MET trainer: Neil's Numbers (the yellow
//  lookup grid) and the Janowski formula. The Training page shows these as
//  optional, toggleable hints; the Warm-up explains them in prose. Keeping
//  the grid construction here means there is a single source of truth for
//  what the hint looks like, rather than duplicating it across screens.
//
//  These views show the *method*, never the answer to the current question.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BGGMETHintViews : NSObject

// The two-row Neil's Numbers lookup (trailer's points-to-go over the
// per-point value above 50%), wrapped with a short title and a one-line
// reminder of how to read it. Self-contained for use as a standalone hint.
+ (UIView *)neilsNumbersView;

// A compact card showing the Janowski formula with a one-line legend of
// what D and T mean. No worked example – just the tool.
+ (UIView *)janowskiFormulaView;

#pragma mark - Worked examples for a concrete score

// Neil's Numbers as a worked example for one match score: the general grid
// plus the step-by-step calculation for this leaderAway/trailerAway, ending
// in the estimated equity. Shown on the Training page after the check.
+ (UIView *)neilsNumbersViewForLeaderAway:(NSInteger)leaderAway
                              trailerAway:(NSInteger)trailerAway;

// Janowski as a worked example for one match score: the formula plus the
// numbers plugged in for this score.
+ (UIView *)janowskiFormulaViewForLeaderAway:(NSInteger)leaderAway
                                 trailerAway:(NSInteger)trailerAway;

// The leader's estimated equity in percent for a score, used both for the
// worked examples and to put the result into the pill titles. Neil's per-
// point value is interpolated between the whole-number anchors.
+ (double)neilEquityForLeaderAway:(NSInteger)leaderAway
                      trailerAway:(NSInteger)trailerAway;
+ (double)janowskiEquityForLeaderAway:(NSInteger)leaderAway
                          trailerAway:(NSInteger)trailerAway;

@end

NS_ASSUME_NONNULL_END
