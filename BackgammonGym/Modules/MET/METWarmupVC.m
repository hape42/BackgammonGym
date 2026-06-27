//
//  METWarmupVC.m
//  BackgammonGym
//

#import "METWarmupVC.h"
#import "BGGLocalization.h"
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
    UILabel *title = [self headlineLabel:BGGLocalizedString(@"met.warmup.what.title")];

    UILabel *intro = [self bodyLabel:
        BGGLocalizedString(@"met.warmup.what.body")];

    UILabel *whyTitle = [self headlineLabel:BGGLocalizedString(@"met.warmup.why.title")];

    UILabel *why = [self bodyLabel:
        BGGLocalizedString(@"met.warmup.why.body")];

    UILabel *startTitle = [self headlineLabel:BGGLocalizedString(@"met.warmup.start.title")];

    UILabel *start = [self bodyLabel:
        BGGLocalizedString(@"met.warmup.start.body")];

    UILabel *tableTitle = [self headlineLabel:BGGLocalizedString(@"met.warmup.table.title")];

    UILabel *tableHint = [self captionLabel:
        BGGLocalizedString(@"met.warmup.table.body")];

    UIView *table = [self buildEquityGrid];

    // Two shortcuts for when you can't recall the exact cell. Both will be
    // selectable as optional hints on the Training page.
    UILabel *shortcutsTitle = [self headlineLabel:BGGLocalizedString(@"met.warmup.shortcuts.title")];

    UILabel *shortcutsIntro = [self bodyLabel:
        BGGLocalizedString(@"met.warmup.shortcuts.body")];

    // --- Neil's Numbers (Neil Kazaross) ---
    UILabel *neilTitle = [self headlineLabel:@"Neil's Numbers"];

    UILabel *neil = [self bodyLabel:
        BGGLocalizedString(@"met.warmup.neil.body")];

    UILabel *neilGridHint = [self captionLabel:
        BGGLocalizedString(@"met.warmup.neil.gridhint")];

    UIView *neilGrid = [self buildNeilGrid];

    UILabel *neil2 = [self bodyLabel:
        BGGLocalizedString(@"met.warmup.neil.example")];

    // --- Janowski formula (Rick Janowski) ---
    UILabel *janTitle = [self headlineLabel:@"Janowski's formula"];

    UILabel *jan = [self bodyLabel:
        BGGLocalizedString(@"met.warmup.janowski.body")];

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
    [headerRow addArrangedSubview:[self cornerCell:BGGLocalizedString(@"↓ me / opp →")]];
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
    // The band is a fixed light yellow that does not adapt to dark mode, so
    // the text colour must be fixed too. labelColor turns near-white in dark
    // mode, which left the whole grid invisible on that fixed band. Use a
    // fixed dark colour instead so it reads in both appearances.
    lbl.textColor       = [UIColor blackColor];
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
