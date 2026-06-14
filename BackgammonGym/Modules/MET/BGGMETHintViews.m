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

#pragma mark - Equity calculations

// Neil's per-point value for a given trailer away-score, interpolated
// linearly between the whole-number anchors (3→10, 4→9, 5→8, 6→7, 8→6,
// 11→5, 15→4). Below 3 we clamp to the 3-anchor; above 15 to the 15-anchor.
+ (double)neilValueForTrailerAway:(NSInteger)trailerAway
{
    // Anchor points as (away, value) pairs, ascending by away.
    NSArray<NSArray<NSNumber *> *> *anchors = @[
        @[@3, @10.0], @[@4, @9.0], @[@5, @8.0], @[@6, @7.0],
        @[@8, @6.0],  @[@11, @5.0], @[@15, @4.0]
    ];

    double t = (double)trailerAway;

    // Clamp outside the anchor range.
    if (t <= 3.0)  { return 10.0; }
    if (t >= 15.0) { return 4.0;  }

    // Find the two anchors t sits between and interpolate.
    for (NSUInteger i = 0; i + 1 < anchors.count; i++)
    {
        double a0 = anchors[i][0].doubleValue;
        double a1 = anchors[i + 1][0].doubleValue;
        if (t >= a0 && t <= a1)
        {
            double v0 = anchors[i][1].doubleValue;
            double v1 = anchors[i + 1][1].doubleValue;
            double f  = (t - a0) / (a1 - a0);
            return v0 + f * (v1 - v0);
        }
    }
    return 4.0;   // unreachable, keeps the compiler happy
}

+ (double)neilEquityForLeaderAway:(NSInteger)leaderAway
                      trailerAway:(NSInteger)trailerAway
{
    // Leader is closer, so the score difference is trailerAway - leaderAway.
    double diff  = (double)(trailerAway - leaderAway);
    double value = [self neilValueForTrailerAway:trailerAway];
    return 50.0 + diff * value;
}

+ (double)janowskiEquityForLeaderAway:(NSInteger)leaderAway
                          trailerAway:(NSInteger)trailerAway
{
    double D = (double)(trailerAway - leaderAway);
    double T = (double)trailerAway;
    return 50.0 + (D * 85.0) / (T + 6.0);
}

// Whether Neil's Numbers is unreliable for this score: it drifts when either
// player is only 1 or 2 points away.
+ (BOOL)neilUnreliableForLeaderAway:(NSInteger)leaderAway
                        trailerAway:(NSInteger)trailerAway
{
    return (leaderAway <= 2 || trailerAway <= 2);
}

#pragma mark - Worked examples

+ (UIView *)neilsNumbersViewForLeaderAway:(NSInteger)leaderAway
                              trailerAway:(NSInteger)trailerAway
{
    UILabel *title = [self titleLabel:@"Neil's Numbers"];
    UILabel *hint  = [self captionLabel:
        BGGLocalizedString(@"Top: trailer's points-to-go. Bottom: value per point of lead, "
        @"above 50%. Interpolate between anchors.")];

    UIView *grid = [self buildNeilGrid];

    // Worked calculation for this score, line by line.
    double value  = [self neilValueForTrailerAway:trailerAway];
    double product = (double)(trailerAway - leaderAway) * value;
    double equity = [self neilEquityForLeaderAway:leaderAway trailerAway:trailerAway];
    NSInteger diff = trailerAway - leaderAway;

    NSString *eqLabel = BGGLocalizedString(@"Leader's equity E");
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    // Trailer needs T = 7 points
    [lines addObject:[NSString stringWithFormat:@"%@ T = %ld",
                      BGGLocalizedString(@"Trailer needs"), (long)trailerAway]];
    // Value per point = 6,5
    [lines addObject:[NSString stringWithFormat:@"%@ = %@",
                      BGGLocalizedString(@"Value per point"), [self trimmedNumber:value]]];
    // Lead = 7 − 3 = 4 points
    [lines addObject:[NSString stringWithFormat:@"%@ = %ld − %ld = %ld",
                      BGGLocalizedString(@"Lead"),
                      (long)trailerAway, (long)leaderAway, (long)diff]];
    // E = 50 + lead × value   — symbolic
    [lines addObject:[NSString stringWithFormat:@"%@ E = 50 + %@ × %@",
                      eqLabel, BGGLocalizedString(@"Lead"), BGGLocalizedString(@"Value per point")]];
    // E = 50 + 4 × 6,5        — numbers in
    [lines addObject:[NSString stringWithFormat:@"E = 50 + %ld × %@",
                      (long)diff, [self trimmedNumber:value]]];
    // E = 50 + 26,0 = 76,0%   — result
    [lines addObject:[NSString stringWithFormat:@"E = 50 + %@ = %@%%",
                      [self oneDecimal:product], [self oneDecimal:equity]]];

    UILabel *workLabel = [self bodyLabel:[lines componentsJoinedByString:@"\n"]];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, hint, grid]];
    stack.axis    = UILayoutConstraintAxisVertical;
    stack.spacing = 6.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [stack setCustomSpacing:8.0 afterView:hint];
    [stack setCustomSpacing:10.0 afterView:grid];

    // Reliability warning goes above the worked calculation when either
    // player is 1 or 2 away.
    if ([self neilUnreliableForLeaderAway:leaderAway trailerAway:trailerAway])
    {
        UILabel *warn = [self captionLabel:
            BGGLocalizedString(@"Note: Neil's Numbers drift when either player is only "
                               @"1 or 2 points away — trust memorized values there.")];
        warn.textColor = [UIColor systemOrangeColor];
        [stack addArrangedSubview:warn];
        [stack setCustomSpacing:10.0 afterView:warn];
    }

    [stack addArrangedSubview:workLabel];

    return [self cardWrapping:stack];
}

+ (UIView *)janowskiFormulaViewForLeaderAway:(NSInteger)leaderAway
                                 trailerAway:(NSInteger)trailerAway
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

    // Worked calculation for this score, as separate lines so each step is
    // visible — people need the detail, especially when their own answer was
    // wrong.
    NSInteger D = trailerAway - leaderAway;
    NSInteger T = trailerAway;
    double quotient = (D * 85.0) / (T + 6.0);
    double equity   = 50.0 + quotient;

    NSString *eqLabel = BGGLocalizedString(@"Leader's equity E");
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    // D = trailer − leader = diff
    [lines addObject:[NSString stringWithFormat:@"%@ D = %ld − %ld = %ld",
                      BGGLocalizedString(@"Score difference"),
                      (long)trailerAway, (long)leaderAway, (long)D]];
    // T = trailerAway
    [lines addObject:[NSString stringWithFormat:@"%@ T = %ld",
                      BGGLocalizedString(@"Trailer's away-score"), (long)T]];
    // E = 50 + (D × 85) ÷ (T + 6)   — symbolic
    [lines addObject:[NSString stringWithFormat:@"%@ E = 50 + (D × 85) ÷ (T + 6)", eqLabel]];
    // E = 50 + (4 × 85) ÷ (5 + 6)   — numbers in
    [lines addObject:[NSString stringWithFormat:@"E = 50 + (%ld × 85) ÷ (%ld + 6)",
                      (long)D, (long)T]];
    // E = 50 + 340 ÷ 11             — partial fraction
    [lines addObject:[NSString stringWithFormat:@"E = 50 + %ld ÷ %ld",
                      (long)(D * 85), (long)(T + 6)]];
    // E = 50 + 30,9 = 80,9%         — result
    [lines addObject:[NSString stringWithFormat:@"E = 50 + %@ = %@%%",
                      [self oneDecimal:quotient], [self oneDecimal:equity]]];

    UILabel *workLabel = [self bodyLabel:[lines componentsJoinedByString:@"\n"]];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, formula, legend, workLabel]];
    stack.axis    = UILayoutConstraintAxisVertical;
    stack.spacing = 8.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    return [self cardWrapping:stack];
}

#pragma mark - Number formatting

// One decimal place, localized decimal separator (comma in German). Uses the
// app's chosen language locale so the worked example matches the UI language
// rather than the device region.
+ (NSString *)oneDecimal:(double)value
{
    return [[self decimalFormatter] stringFromNumber:@(value)];
}

// Like oneDecimal:, but drops a trailing ".0" so whole numbers read cleanly
// (6 instead of 6.0, 6.5 stays 6,5). Used for the per-point value.
+ (NSString *)trimmedNumber:(double)value
{
    double rounded = round(value * 10.0) / 10.0;
    if (fabs(rounded - round(rounded)) < 0.05)
    {
        return [NSString stringWithFormat:@"%ld", (long)round(rounded)];
    }
    return [[self decimalFormatter] stringFromNumber:@(rounded)];
}

// A shared formatter: exactly one fraction digit, localized separator.
+ (NSNumberFormatter *)decimalFormatter
{
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    nf.minimumFractionDigits = 1;
    nf.maximumFractionDigits = 1;
    nf.usesGroupingSeparator = NO;
    return nf;
}

// A body-sized label for the worked calculation lines. Uses a monospaced
// digit font so the numbers line up across the stacked steps.
+ (UILabel *)bodyLabel:(NSString *)text
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text          = text;
    lbl.font          = [UIFont monospacedDigitSystemFontOfSize:15.0
                                                         weight:UIFontWeightRegular];
    lbl.textColor     = [UIColor labelColor];
    lbl.numberOfLines = 0;
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    return lbl;
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
