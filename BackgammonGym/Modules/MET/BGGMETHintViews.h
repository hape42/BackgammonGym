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

@end

NS_ASSUME_NONNULL_END
