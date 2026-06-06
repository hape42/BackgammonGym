//
//  PipCountClusterVC.m
//  BackgammonGym
//
//  Cluster Counting explanation screen.
//  All boards are placeholders – replace the position IDs once I have
//  exported the reference positions from BGBlitz.
//

#import "PipCountClusterVC.h"
#import "BGGBoardCard.h"
#import "BGGPosition.h"
#import "PositionDatabase.h"

// The starting position is used as a placeholder for every board
// that still needs a real position ID from BGBlitz.
static NSString * const kPlaceholderID = @"4HPwATDgc/ABMA";

@interface PipCountClusterVC ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView       *contentView;
@end

@implementation PipCountClusterVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self setupScrollView];
    [self buildContent];
}

#pragma mark - Scroll view

- (void)setupScrollView
{
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
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
    CGFloat margin  = 16.0;
    CGFloat spacing = 24.0;

    // ── Intro text ────────────────────────────────────────────────────────
    UILabel *intro = [self introLabel];
    intro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:intro];

    // ── Section header: Reference Positions ───────────────────────────────
    UILabel *refHeader = [self sectionHeader:@"Reference Positions"];
    refHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:refHeader];

    // ── The seven reference positions ─────────────────────────────────────
    // Each card now pulls its board, caption and text from positions.json
    // via the position ID. Replace each ID below with the real one from your
    // JSON. Caption and explanation come from the entry, not from code.
    BGGBoardCard *rp1 = [self cardForPositionID:@"AAAAsG0DAAAAAA:cAnkAAAAEAAE"];

    BGGBoardCard *rp2 = [self placeholderCard:@"RP 2 – Closed Board"
        explanation:@"The standard 6-point prime plus two checkers on the ace point → 42. "
                    @"Think of it as a 5-prime around point 4 (count = 40) plus 2."];

    BGGBoardCard *rp3 = [self placeholderCard:@"RP 3 – Five and Eight"
        explanation:@"Five checkers each on points 6 and 8 → 70. "
                    @"A useful pattern in your home board."];

    BGGBoardCard *rp4 = [self placeholderCard:@"RP 4 – Seven and Eight"
        explanation:@"Two checkers each on points 7 and 8 → 30. "
                    @"A compact cluster that comes up often."];

    BGGBoardCard *rp5 = [self placeholderCard:@"RP 5 – Five on Eight"
        explanation:@"Five checkers on point 8 → 40. "
                    @"Simple, but worth memorizing as a standalone cluster."];

    BGGBoardCard *rp6 = [self placeholderCard:@"RP 6 – Midpoint and Bar"
        explanation:@"Two checkers each on the midpoint (13) and the opponent's bar point (18) → 62. "
                    @"One of two reference positions whose total doesn't end in zero."];

    BGGBoardCard *rp7 = [self placeholderCard:@"RP 7 – Midpoint and Fourteen"
        explanation:@"Two checkers on the midpoint (13) and one on point 14 → 40. "
                    @"The second exception – useful for stacks near the midpoint."];

    // ── Section header: Key Points ────────────────────────────────────────
    UILabel *keyHeader = [self sectionHeader:@"Key Points"];
    keyHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:keyHeader];

    BGGBoardCard *kp1 = [self placeholderCard:@"Key Point – Your 5-Point"
        explanation:@"Eight checkers that can all be imagined on your 5-point contribute 40 pips. "
                    @"Treat scattered checkers near point 5 as if they were all sitting there, "
                    @"then adjust for the actual distance."];

    BGGBoardCard *kp2 = [self placeholderCard:@"Key Point – Opponent's 5-Point (Point 20)"
        explanation:@"The most useful key point. Checkers deep in the opponent's home board "
                    @"are all treated as sitting on point 20, then you add the extra pips. "
                    @"Five checkers on point 20 = 100; if two are actually on point 22, add 4."];

    // ── Section header: Mirrors ───────────────────────────────────────────
    UILabel *mirrorHeader = [self sectionHeader:@"Mirrors"];
    mirrorHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:mirrorHeader];

    UILabel *mirrorIntro = [self bodyLabel:
        @"Any point plus its mirror-opposite always totals 25: points 1+24, 6+19, 12+13. "
        @"Four checkers in mirror positions therefore count 50, no matter where exactly they sit."];
    mirrorIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:mirrorIntro];

    BGGBoardCard *mirror1 = [self placeholderCard:@"Mirrors – Example 1"
        explanation:@"Two checkers on point 5, two on point 20: (5+20) × 2 = 50. "
                    @"Two checkers on point 12, two on point 13: (12+13) × 2 = 50."];

    BGGBoardCard *mirror2 = [self placeholderCard:@"Mirrors – Example 2"
        explanation:@"Two checkers on point 23, two on point 2: (23+2) × 2 = 50. "
                    @"Two checkers on point 18, two on point 7: (18+7) × 2 = 50."];

    // ── Section header: Mental Shifting ───────────────────────────────────
    UILabel *shiftHeader = [self sectionHeader:@"Mental Shifting"];
    shiftHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftHeader];

    UILabel *shiftIntro = [self bodyLabel:
        @"Real positions rarely arrive pre-packaged as reference positions. "
        @"The technique is to mentally slide checkers until a recognizable cluster forms, "
        @"then compensate for the distance moved."];
    shiftIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftIntro];

    BGGBoardCard *shift1 = [self placeholderCard:@"One-Way Shift"
        explanation:@"Move checkers forward to a key point and add the distance to the cluster value. "
                    @"Three checkers on point 13, shifted to point 10: count = 30 + 9 (3 pips × 3 checkers) = 39."];

    BGGBoardCard *shift2 = [self placeholderCard:@"Two-Way Shift"
        explanation:@"Move one checker forward and another backward by the same number of pips. "
                    @"The shifts cancel out – the total is unchanged. "
                    @"Two checkers on points 6 and 8 can be shifted to the 7-point to form a 5-prime."];

    // ── Sources ───────────────────────────────────────────────────────────
    UILabel *sources = [self sourcesLabel];
    sources.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:sources];

    // ── Add all cards to content view ─────────────────────────────────────
    NSArray *cards = @[rp1, rp2, rp3, rp4, rp5, rp6, rp7,
                       kp1, kp2,
                       mirror1, mirror2,
                       shift1, shift2];
    for (BGGBoardCard *card in cards)
    {
        card.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:card];
    }

    // ── Layout ────────────────────────────────────────────────────────────
    // Build a flat vertical chain: intro → refHeader → rp1…rp7 →
    // keyHeader → kp1 → kp2 → mirrorHeader → mirrorIntro → mirror1 →
    // mirror2 → shiftHeader → shiftIntro → shift1 → shift2 → sources

    NSArray *chain = @[intro, refHeader,
                       rp1, rp2, rp3, rp4, rp5, rp6, rp7,
                       keyHeader, kp1, kp2,
                       mirrorHeader, mirrorIntro, mirror1, mirror2,
                       shiftHeader, shiftIntro, shift1, shift2,
                       sources];

    NSMutableArray *constraints = [NSMutableArray array];

    // First item pins to top.
    [constraints addObject:
     [[chain.firstObject topAnchor] constraintEqualToAnchor:self.contentView.topAnchor
                                                   constant:spacing]];

    // Every item pins leading/trailing to margins.
    for (UIView *view in chain)
    {
        [constraints addObject:
         [view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor
                                            constant:margin]];
        [constraints addObject:
         [view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor
                                             constant:-margin]];
    }

    // Chain items vertically.
    for (NSInteger i = 1; i < (NSInteger)chain.count; i++)
    {
        UIView *prev = chain[i - 1];
        UIView *curr = chain[i];
        [constraints addObject:
         [curr.topAnchor constraintEqualToAnchor:prev.bottomAnchor constant:spacing]];
    }

    // Last item pins content view bottom.
    [constraints addObject:
     [self.contentView.bottomAnchor constraintEqualToAnchor:
      [chain.lastObject bottomAnchor] constant:spacing]];

    [NSLayoutConstraint activateConstraints:constraints];
}

#pragma mark - Factory helpers

// Builds a card from a real position in the database, identified by its
// position ID. Caption and explanation text come from the JSON entry.
// Falls back to a red placeholder card if the ID is not found, so a missing
// entry is obvious during development.
- (BGGBoardCard *)cardForPositionID:(NSString *)positionID
{
    BGGPositionEntry *entry = [[PositionDatabase sharedDatabase]
                               entryForPositionID:positionID];

    if (entry == nil)
    {
        BGGBoardCard *missing = [[BGGBoardCard alloc]
            initWithCaption:@"⚠ Position not found"
            explanationText:positionID
                 boardState:[BGGPosition boardStateFromPositionID:kPlaceholderID]];
        missing.isPlaceholder     = YES;
        missing.showsPointNumbers = YES;
        missing.showsCube         = NO;
        missing.showsDice         = NO;
        return missing;
    }

    BGGBoardCard *card = [[BGGBoardCard alloc]
                          initWithCaption:entry.caption
                          explanationText:entry.text
                               boardState:[entry boardState]];
    card.isPlaceholder     = NO;
    card.showsPointNumbers = YES;
    card.showsCube         = NO;
    card.showsDice         = NO;
    return card;
}

- (BGGBoardCard *)placeholderCard:(NSString *)caption
                      explanation:(NSString *)explanation
{
    BGGBoardCard *card = [[BGGBoardCard alloc]
                          initWithCaption:caption
                          explanationText:explanation
                           boardState:[BGGPosition boardStateFromPositionID:kPlaceholderID]];
    card.isPlaceholder     = YES;
    card.showsPointNumbers = YES;
    card.showsCube         = NO;
    card.showsDice         = NO;
    return card;
}

#pragma mark - Labels

- (UILabel *)introLabel
{
    UILabel *label      = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.textColor     = [UIColor labelColor];

    NSString *boldPart = @"What is Cluster Counting?\n\n";
    NSString *bodyPart =
        @"Cluster Counting is a technique developed by Jack Kissane that lets you estimate "
        @"pip counts much faster than the traditional point-by-point method. Instead of "
        @"multiplying every checker individually, you mentally rearrange the checkers into "
        @"recognizable patterns – clusters – whose pip totals are easy to calculate. "
        @"With practice, you can count most positions in a few seconds.\n\n"
        @"The key insight is simple: any two points that mirror each other across the board "
        @"add up to 25. Point 1 and point 24, point 6 and point 19, point 12 and point 13 – "
        @"always 25. Four checkers in mirror positions therefore count 50, regardless of "
        @"exactly where they sit.\n\n"
        @"Rather than memorizing endless combinations, Kissane identified seven reference "
        @"positions whose pip totals end in zero – making mental arithmetic easy. "
        @"Combined with a few key points and mirror patterns, these cover the vast majority "
        @"of positions you will encounter.";

    NSMutableAttributedString *attr =
        [[NSMutableAttributedString alloc]
         initWithString:[boldPart stringByAppendingString:bodyPart]];
    UIFont *bodyFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIFont *boldFont = [UIFont boldSystemFontOfSize:bodyFont.pointSize + 1.0];
    [attr addAttribute:NSFontAttributeName value:bodyFont range:NSMakeRange(0, attr.length)];
    [attr addAttribute:NSFontAttributeName value:boldFont range:NSMakeRange(0, boldPart.length)];
    label.attributedText = attr;
    return label;
}

- (UILabel *)sectionHeader:(NSString *)title
{
    UILabel *label  = [[UILabel alloc] init];
    label.text      = title;
    label.font      = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    label.textColor = [UIColor labelColor];
    return label;
}

- (UILabel *)bodyLabel:(NSString *)text
{
    UILabel *label      = [[UILabel alloc] init];
    label.text          = text;
    label.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.textColor     = [UIColor secondaryLabelColor];
    label.numberOfLines = 0;
    return label;
}

- (UILabel *)sourcesLabel
{
    UILabel *label      = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    label.textColor     = [UIColor tertiaryLabelColor];
    label.text          = @"Sources: Jack Kissane, \"Cluster Counting\", Chicago Point No. 52 (1992), "
                          @"reprinted at bkgm.com · German translation and commentary by "
                          @"Hardy Hübener, hardyhuebener.de";
    return label;
}

@end
