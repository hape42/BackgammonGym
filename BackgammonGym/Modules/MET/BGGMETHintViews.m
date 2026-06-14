//
//  BGGMETHintViews.m
//  BackgammonGym
//

#import "BGGMETHintViews.h"
#import "BGGLocalization.h"

@implementation BGGMETHintViews

#pragma mark - Neil's Numbers

+ (UIView *)neilsNumbersView
{
    UILabel *title = [self titleLabel:@"Neil's Numbers"];
    UILabel *hint  = [self captionLabel:
        BGGLocalizedString(@"Top: trailer's points-to-go. Bottom: value per point of lead, "
        @"above 50%. Interpolate between anchors.")];

    UIView *grid = [self buildNeilGrid];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, hint, grid]];
    stack.axis    = UILayoutConstraintAxisVertical;
    stack.spacing = 6.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [stack setCustomSpacing:8.0 afterView:hint];
    return [self cardWrapping:stack];
}

// The two-row Neil's Numbers lookup, identical to the Warm-up's grid:
// top row is the trailer's points-to-go (3..15), bottom row is the
// per-point value above 50%. Values exist only at the whole-number anchors
// (3,4,5,6,8,11,15); the cells in between are intentionally blank.
+ (UIView *)buildNeilGrid
{
    NSArray<NSNumber *> *togo = @[ @3, @4, @5, @6, @7, @8, @9, @10, @11, @12, @13, @14, @15 ];

    NSDictionary<NSNumber *, NSNumber *> *values = @{
        @3: @10, @4: @9, @5: @8, @6: @7, @8: @6, @11: @5, @15: @4
    };

    UIColor *bandColor = [UIColor colorWithRed:1.00 green:0.99 blue:0.80 alpha:1.0];

    UIStackView *rows = [[UIStackView alloc] init];
    rows.axis         = UILayoutConstraintAxisVertical;
    rows.spacing      = 2.0;
    rows.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *topRow = [self gridRow];
    for (NSNumber *t in togo)
    {
        [topRow addArrangedSubview:[self neilCell:[NSString stringWithFormat:@"%@", t]
                                       background:bandColor
                                             bold:NO]];
    }
    [rows addArrangedSubview:topRow];

    UIStackView *bottomRow = [self gridRow];
    for (NSNumber *t in togo)
    {
        NSNumber *v   = values[t];
        NSString *txt = v ? [NSString stringWithFormat:@"%@", v] : @"";
        [bottomRow addArrangedSubview:[self neilCell:txt
                                          background:bandColor
                                                bold:YES]];
    }
    [rows addArrangedSubview:bottomRow];

    return rows;
}

#pragma mark - Janowski formula

+ (UIView *)janowskiFormulaView
{
    UILabel *title = [self titleLabel:@"Janowski's formula"];

    UILabel *formula = [[UILabel alloc] init];
    formula.text          = @"E = 50 + (D \u00d7 85) \u00f7 (T + 6)";
    formula.font          = [UIFont monospacedDigitSystemFontOfSize:18.0
                                                             weight:UIFontWeightSemibold];
    formula.textColor     = [UIColor labelColor];
    formula.textAlignment = NSTextAlignmentCenter;
    formula.numberOfLines = 0;
    formula.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *legend = [self captionLabel:
        BGGLocalizedString(@"E = leader's equity (%).  D = score difference (points-to-go).  "
        @"T = trailer's away-score.")];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, formula, legend]];
    stack.axis    = UILayoutConstraintAxisVertical;
    stack.spacing = 8.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    return [self cardWrapping:stack];
}

#pragma mark - Card wrapper

// Wraps a content view in a rounded, lightly tinted card so each hint reads
// as one block on the exercise page.
+ (UIView *)cardWrapping:(UIView *)content
{
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor    = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 10.0;
    [card addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor      constraintEqualToAnchor:card.topAnchor constant:12.0],
        [content.leadingAnchor  constraintEqualToAnchor:card.leadingAnchor constant:12.0],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12.0],
        [content.bottomAnchor   constraintEqualToAnchor:card.bottomAnchor constant:-12.0],
    ]];
    return card;
}

#pragma mark - Grid cell helpers

+ (UIStackView *)gridRow
{
    UIStackView *row = [[UIStackView alloc] init];
    row.axis         = UILayoutConstraintAxisHorizontal;
    row.spacing      = 2.0;
    row.distribution = UIStackViewDistributionFillEqually;
    return row;
}

+ (UILabel *)gridCellBase
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.font          = [UIFont monospacedDigitSystemFontOfSize:13.0
                                                         weight:UIFontWeightRegular];
    lbl.adjustsFontSizeToFitWidth = YES;
    lbl.minimumScaleFactor        = 0.6;
    [lbl.heightAnchor constraintEqualToConstant:30.0].active = YES;
    lbl.layer.cornerRadius  = 4.0;
    lbl.layer.masksToBounds = YES;
    return lbl;
}

+ (UILabel *)neilCell:(NSString *)text background:(UIColor *)background bold:(BOOL)bold
{
    UILabel *lbl = [self gridCellBase];
    lbl.text            = text;
    lbl.backgroundColor = background;
    lbl.textColor       = [UIColor blackColor];   // band is a fixed light yellow
    lbl.font            = [UIFont monospacedDigitSystemFontOfSize:13.0
                                                          weight:(bold ? UIFontWeightSemibold
                                                                       : UIFontWeightRegular)];
    return lbl;
}

#pragma mark - Label helpers

+ (UILabel *)titleLabel:(NSString *)text
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text          = text;
    lbl.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    lbl.numberOfLines = 0;
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    return lbl;
}

+ (UILabel *)captionLabel:(NSString *)text
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text          = text;
    lbl.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    lbl.textColor     = [UIColor secondaryLabelColor];
    lbl.numberOfLines = 0;
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    return lbl;
}

@end
