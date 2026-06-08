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
    
    BGGBoardCard *rp1 = [self cardForPositionID:@"AAAAsG0DAAAAAA:cAnkAAAAEAAE"];
    BGGBoardCard *rp2 = [self cardForPositionID:@"AAAAtm0DAAAAAA:cIkoARAAAAAE"];
    BGGBoardCard *rp3 = [self cardForPositionID:@"AAAAwOcDAAAAAA:cIkoARAAAAAE"];
    BGGBoardCard *rp4 = [self cardForPositionID:@"AAAAgA0AAAAAAA:cIkoARAAAAAE"];
    BGGBoardCard *rp5 = [self cardForPositionID:@"AAAAAB8AAAAAAA:cIkoARAAAAAE"];
    BGGBoardCard *rp6 = [self cardForPositionID:@"AAAAAGAwAAAAAA:cImoAAAAAAAE"];
    BGGBoardCard *rp7 = [self cardForPositionID:@"AAAAAGABAAAAAA:cAkgAXAAMAAE"];


    // ── Section header: Key Points ────────────────────────────────────────
    UILabel *keyHeader = [self sectionHeader:@"Key Points"];
    keyHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:keyHeader];
    
    UILabel *keypointIntro = [self bodyLabel:
                              @"The two key points most often used are the 5-point and the 20-point (opponent's 5-point). \n"
                              @"The 10-, 13- and 15-points are also quite valuable.  "];
    keypointIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:keypointIntro];

    BGGBoardCard *kp1 = [self cardForPositionID:@"eB4AALA3AAAAAA:cAkuAWAAOAAE"];
    BGGBoardCard *kp2 = [self cardForPositionID:@"AAAYCgAAMwEAAA:cAkuAWAAOAAE"];

    // ── Section header: Mirrors ───────────────────────────────────────────
    UILabel *mirrorHeader = [self sectionHeader:@"Mirrors"];
    mirrorHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:mirrorHeader];

    UILabel *mirrorIntro = [self bodyLabel:
        @"Mirrors are another important counting tool. Any point on the board plus its mirror-opposite point equals 25.\n"
        @"For example, the 5-point + 20-point, the 1-point + 24-point, and the 12-point + 13-point all total 25 pips. It follows that any cluster of 4 checkers in mirror positions total 50. "];
    mirrorIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:mirrorIntro];

    BGGBoardCard *mirror1 = [self cardForPositionID:@"eB4AALA3AAAAAA:cAkuAWAAOAAE"];
    BGGBoardCard *mirror2 = [self cardForPositionID:@"eB4AALA3AAAAAA:cAkuAWAAOAAE"];

    // ── Section header: Mental Shifting ───────────────────────────────────
    UILabel *shiftHeader = [self sectionHeader:@"Mental Shifting"];
    shiftHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftHeader];

    UILabel *shiftIntro = [self bodyLabel:
        @"It would be nice if every time you needed a pip count, the board would consist of clusters as previously described. "
        @"Unfortunately, that doesn't happen. Fortunately, these easy-to-count clusters are relatively simple to form by mentally moving the checkers where you want them. "];
    shiftIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftIntro];

    UILabel *shiftOneWayHeader = [self sectionHeader:@"One-Way Mental Shift"];
    shiftOneWayHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftOneWayHeader];

    UILabel *shiftOneWayIntro = [self bodyLabel:
        @"One-way mental shifting involves moving the checkers forward to key points or reference positions and then adding the forward movement to the value of the key points or reference positions. "];
    shiftOneWayIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftOneWayIntro];

    BGGBoardCard *shift1 = [self cardForPositionID:@"ttkYAQy43RSAIQ:cAkgATAACAAE"];
    UILabel *shiftOneWayConclusion = [self bodyLabel:
        @"Note that two of opponent's checkers were shifted to opponent's 5-point which is occupied by player's checkers. When shifting one player's checkers, the other player's checker position can be ignored. "];
    shiftOneWayConclusion.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftOneWayConclusion];

    UILabel *shiftTwoWayHeader = [self sectionHeader:@"Two-Way Mental Shift"];
    shiftTwoWayHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftTwoWayHeader];

    UILabel *shiftTwoWayIntro = [self bodyLabel:
        @"Two-way mental shifting differs from one-way mental shifting in that checkers are shifted either forward or backward to key points or reference positions and then compensating shifts are made in the opposite direction on the same side of the board, or in the same direction on opposite sides of the board. "];
    shiftTwoWayIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftTwoWayIntro];

    BGGBoardCard *shift2 = [self cardForPositionID:@"ttkYAQy43RSAIQ:cAkgATAACAAE"];

    UILabel *shiftTwoWayConclusion = [self bodyLabel:
        @"It should be noted that there are often several cluster counting choices available. \nFor instance, in player's position above, instead of forming a 5-prime, you could have shifted the two 9-point checkers to the 8-point and compensated by shifting the two 5-point checkers to the 6-point to form RP3. This cluster is also 70 pips."];
    shiftTwoWayConclusion.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftTwoWayConclusion];

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
                       keyHeader,keypointIntro, kp1, kp2,
                       mirrorHeader, mirrorIntro, mirror1, mirror2,
                       shiftHeader, shiftIntro,
                       shiftOneWayHeader, shiftOneWayIntro,
                       shift1,shiftOneWayConclusion,
                       shiftTwoWayHeader, shiftTwoWayIntro,
                       shift2,shiftTwoWayConclusion,
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
