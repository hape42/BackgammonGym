//
//  METWarmupVC.m
//  BackgammonGym
//

#import "METWarmupVC.h"
#import "BGGMatchEquityTable.h"

@interface METWarmupVC ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView       *contentView;

// Grid builders and cell helpers (defined below in arbitrary order).
- (UIView *)buildEquityGrid;
- (UIView *)buildNeilGrid;
- (UIStackView *)gridRow;
- (UILabel *)gridCellBase;
- (UILabel *)valueCell:(NSInteger)value diagonal:(BOOL)diagonal;
- (UILabel *)headerCell:(NSString *)text;
- (UILabel *)cornerCell:(NSString *)text;
- (UILabel *)neilCell:(NSString *)text background:(UIColor *)background bold:(BOOL)bold;

// Label helpers.
- (UILabel *)headlineLabel:(NSString *)text;
- (UILabel *)bodyLabel:(NSString *)text;
- (UILabel *)captionLabel:(NSString *)text;

@end

@implementation METWarmupVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self setupScrollView];
    [self buildContent];
}

#pragma mark - Scaffolding

- (void)setupScrollView
{
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor      constraintEqualToAnchor:safe.topAnchor],
        [self.scrollView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.scrollView.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],

        [self.contentView.topAnchor      constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor  constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor   constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor    constraintEqualToAnchor:self.scrollView.widthAnchor],
    ]];
}

#pragma mark - Content

- (void)buildContent
{
    UILabel *title = [self headlineLabel:@"What is a Match Equity Table?"];

    UILabel *intro = [self bodyLabel:
        @"A match equity table (MET) tells you your chance of winning the "
        @"whole match from any given score, assuming both players are "
        @"equally strong. Each value is a match-winning percentage. The "
        @"table is symmetric around its diagonal: when both players need "
        @"the same number of points, each has exactly 50%."];

    UILabel *whyTitle = [self headlineLabel:@"Why memorize it?"];

    UILabel *why = [self bodyLabel:
        @"The clearest payoff is in cube decisions. Imagine you trail 3–5 "
        @"in an 11-point match and your opponent doubles to 8. If you pass, "
        @"the score becomes 3–7, where your match-winning chances are about "
        @"36%. So taking only makes sense if you expect to win this game "
        @"more than 36% of the time — far above the 25% you'd need in a "
        @"money game. Without the table, you're guessing; with it, you have "
        @"a concrete threshold to compare against.\n\n"
        @"The same numbers feed into subtler checker and cube choices that "
        @"depend on the score. Knowing your equity turns vague intuition "
        @"into a number you can actually reason with — a big part of moving "
        @"from intermediate to advanced match play."];

    UILabel *startTitle = [self headlineLabel:@"Where to start"];

    UILabel *start = [self bodyLabel:
        @"You don't need all of it at once. The values that come up most "
        @"and matter most are the Crawford scores (one player needs just "
        @"one point) and any score where a player is 2-away. Memorize those "
        @"exactly first, then widen out to 5-point, 7-point, and 9-point "
        @"match scores as you go."];

    UILabel *tableTitle = [self headlineLabel:@"The full table (1-away to 11-away)"];

    UILabel *tableHint = [self captionLabel:
        @"Your away-score down the left, your opponent's across the top. "
        @"Each cell is your match-winning chance in percent."];

    UIView *table = [self buildEquityGrid];

    // Two shortcuts for when you can't recall the exact cell. Both will be
    // selectable as optional hints on the Training page.
    UILabel *shortcutsTitle = [self headlineLabel:@"Two shortcuts when you forget a cell"];

    UILabel *shortcutsIntro = [self bodyLabel:
        @"Almost nobody memorizes the whole table perfectly. Two well-known "
        @"approximations get you very close in your head, and you'll be able "
        @"to switch each one on as a hint while you train."];

    // --- Neil's Numbers (Neil Kazaross) ---
    UILabel *neilTitle = [self headlineLabel:@"Neil's Numbers"];

    UILabel *neil = [self bodyLabel:
        @"Neil Kazaross's method estimates the leader's equity with a single "
        @"multiplication. Look at how many points the trailer still needs, "
        @"read off a per-point value, then multiply it by the size of the "
        @"lead and add to 50%."];

    UILabel *neilGridHint = [self captionLabel:
        @"Top row: the trailer's points-to-go. Bottom row: what each point of "
        @"lead is worth above 50%."];

    UIView *neilGrid = [self buildNeilGrid];

    UILabel *neil2 = [self bodyLabel:
        @"For an in-between number, interpolate (7-away sits halfway between "
        @"6 and 8, so it's worth 6\u00bd). Beyond the trivial 3/4/5/6 start, the "
        @"only thing to remember is \u201c8 is 6, 11 is 5, 15 is 4.\u201d\n\n"
        @"Example: you lead 3\u20130 in a 7-point match. The trailer needs 7, "
        @"worth 6\u00bd per point. Your lead is 3 points, so 3 \u00d7 6\u00bd = 19\u00bd over "
        @"50% \u2192 about 69\u00bd%. The table says 70% \u2014 close enough to act on.\n\n"
        @"Neil's Numbers are remarkably accurate as long as the leader still "
        @"needs 3 or more points. They drift when the leader is only 1 or 2 "
        @"points away, so it's worth learning those few scores exactly."];

    // --- Janowski formula (Rick Janowski) ---
    UILabel *janTitle = [self headlineLabel:@"Janowski's formula"];

    UILabel *jan = [self bodyLabel:
        @"Rick Janowski's formula gives the leader's match equity directly:\n\n"
        @"  E = 50 + (D \u00d7 85) \u00f7 (T + 6)\n\n"
        @"where E is the leader's equity in percent, D is the difference in "
        @"scores (points-to-go), and T is the trailer's away-score \u2014 the "
        @"points the player who is behind still needs.\n\n"
        @"Example: an 11-point match standing 5-away vs 9-away. The difference "
        @"is D = 9 \u2212 5 = 4 and T = 9, so E = 50 + (4 \u00d7 85) \u00f7 (9 + 6) = "
        @"50 + 340 \u00f7 15 \u2248 72.7%. Woolsey's table gives 73% here.\n\n"
        @"It's usually within about 1%. The exception is when the leader needs "
        @"only one or two points \u2014 there it can produce outliers, so trust the "
        @"memorized values at those scores instead."];

    // Stack everything vertically.
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        title, intro, whyTitle, why, startTitle, start, tableTitle, tableHint, table,
        shortcutsTitle, shortcutsIntro,
        neilTitle, neil, neilGridHint, neilGrid, neil2,
        janTitle, jan
    ]];
    stack.axis    = UILayoutConstraintAxisVertical;
    stack.spacing = 12.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [stack setCustomSpacing:20.0 afterView:intro];
    [stack setCustomSpacing:20.0 afterView:why];
    [stack setCustomSpacing:20.0 afterView:start];
    [stack setCustomSpacing:6.0  afterView:tableTitle];
    [stack setCustomSpacing:10.0 afterView:tableHint];
    [stack setCustomSpacing:24.0 afterView:table];
    [stack setCustomSpacing:20.0 afterView:shortcutsIntro];
    [stack setCustomSpacing:6.0  afterView:neil];
    [stack setCustomSpacing:8.0  afterView:neilGridHint];
    [stack setCustomSpacing:12.0 afterView:neilGrid];
    [stack setCustomSpacing:20.0 afterView:neil2];
    [self.contentView addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor constant:20.0],
        [stack.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:20.0],
        [stack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20.0],
        [stack.bottomAnchor   constraintEqualToAnchor:self.contentView.bottomAnchor constant:-28.0],
    ]];
}

#pragma mark - Equity grid

// Builds a 12x12 grid: a header row/column with away-scores 1..11 plus the
// 11x11 equity values, rounded to whole percent. The diagonal (always 50)
// and the header band are tinted to make the layout readable.
- (UIView *)buildEquityGrid
{
    BGGMatchEquityTable *met = [BGGMatchEquityTable sharedTable];
    NSInteger n = met.maxAway;

    UIStackView *rows = [[UIStackView alloc] init];
    rows.axis         = UILayoutConstraintAxisVertical;
    rows.spacing      = 2.0;
    rows.translatesAutoresizingMaskIntoConstraints = NO;

    // Header row: empty corner + 1..n
    UIStackView *headerRow = [self gridRow];
    [headerRow addArrangedSubview:[self cornerCell:@"↓ me / opp →"]];
    for (NSInteger c = 1; c <= n; c++)
    {
        [headerRow addArrangedSubview:[self headerCell:[NSString stringWithFormat:@"%ld", (long)c]]];
    }
    [rows addArrangedSubview:headerRow];

    // Value rows
    for (NSInteger r = 1; r <= n; r++)
    {
        UIStackView *row = [self gridRow];
        [row addArrangedSubview:[self headerCell:[NSString stringWithFormat:@"%ld", (long)r]]];

        for (NSInteger c = 1; c <= n; c++)
        {
            NSInteger value = [met roundedEquityForPlayerAway:r opponentAway:c];
            BOOL isDiagonal = (r == c);
            [row addArrangedSubview:[self valueCell:value diagonal:isDiagonal]];
        }
        [rows addArrangedSubview:row];
    }

    return rows;
}

#pragma mark - Neil's Numbers grid

// Builds the two-row Neil's Numbers lookup: the top row is the trailer's
// points-to-go (3..15), the bottom row is the per-point value above 50%.
// Values exist only at whole-number anchors (3,4,5,6,8,11,15); the cells in
// between are intentionally left blank, exactly as the method is taught.
- (UIView *)buildNeilGrid
{
    NSArray<NSNumber *> *togo = @[ @3, @4, @5, @6, @7, @8, @9, @10, @11, @12, @13, @14, @15 ];

    // Per-point value keyed by points-to-go; missing keys render as blank.
    NSDictionary<NSNumber *, NSNumber *> *values = @{
        @3: @10, @4: @9, @5: @8, @6: @7, @8: @6, @11: @5, @15: @4
    };

    UIColor *bandColor = [UIColor colorWithRed:1.00 green:0.99 blue:0.80 alpha:1.0];

    UIStackView *rows = [[UIStackView alloc] init];
    rows.axis         = UILayoutConstraintAxisVertical;
    rows.spacing      = 2.0;
    rows.translatesAutoresizingMaskIntoConstraints = NO;

    // Top row: points-to-go.
    UIStackView *topRow = [self gridRow];
    for (NSNumber *t in togo)
    {
        [topRow addArrangedSubview:[self neilCell:[NSString stringWithFormat:@"%@", t]
                                       background:bandColor
                                             bold:NO]];
    }
    [rows addArrangedSubview:topRow];

    // Bottom row: per-point value, blank where there is no whole number.
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

- (UILabel *)neilCell:(NSString *)text background:(UIColor *)background bold:(BOOL)bold
{
    UILabel *lbl = [self gridCellBase];
    lbl.text            = text;
    lbl.backgroundColor = background;
    lbl.textColor       = [UIColor labelColor];
    lbl.font            = [UIFont monospacedDigitSystemFontOfSize:13.0
                                                          weight:(bold ? UIFontWeightSemibold
                                                                       : UIFontWeightRegular)];
    return lbl;
}

- (UIStackView *)gridRow
{
    UIStackView *row = [[UIStackView alloc] init];
    row.axis         = UILayoutConstraintAxisHorizontal;
    row.spacing      = 2.0;
    row.distribution = UIStackViewDistributionFillEqually;
    return row;
}

- (UILabel *)gridCellBase
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

- (UILabel *)valueCell:(NSInteger)value diagonal:(BOOL)diagonal
{
    UILabel *lbl = [self gridCellBase];
    lbl.text = [NSString stringWithFormat:@"%ld", (long)value];
    if (diagonal)
    {
        lbl.backgroundColor = [UIColor colorNamed:@"AccentColor"];
        lbl.textColor       = [UIColor whiteColor];
        lbl.font            = [UIFont monospacedDigitSystemFontOfSize:13.0
                                                              weight:UIFontWeightBold];
    }
    else
    {
        lbl.backgroundColor = [UIColor secondarySystemBackgroundColor];
        lbl.textColor       = [UIColor labelColor];
    }
    return lbl;
}

- (UILabel *)headerCell:(NSString *)text
{
    UILabel *lbl = [self gridCellBase];
    lbl.text            = text;
    lbl.font            = [UIFont monospacedDigitSystemFontOfSize:13.0
                                                          weight:UIFontWeightSemibold];
    lbl.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    lbl.textColor       = [UIColor secondaryLabelColor];
    return lbl;
}

- (UILabel *)cornerCell:(NSString *)text
{
    UILabel *lbl = [self gridCellBase];
    lbl.text            = text;
    lbl.font            = [UIFont systemFontOfSize:8.0 weight:UIFontWeightMedium];
    lbl.textColor       = [UIColor tertiaryLabelColor];
    lbl.backgroundColor = [UIColor clearColor];
    return lbl;
}

#pragma mark - Label helpers

- (UILabel *)headlineLabel:(NSString *)text
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text          = text;
    lbl.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    lbl.numberOfLines = 0;
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    return lbl;
}

- (UILabel *)bodyLabel:(NSString *)text
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text          = text;
    lbl.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    lbl.textColor     = [UIColor labelColor];
    lbl.numberOfLines = 0;
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    return lbl;
}

- (UILabel *)captionLabel:(NSString *)text
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
