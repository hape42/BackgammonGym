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
#import "BGGLocalization.h"

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
    UILabel *refHeader = [self sectionHeader:BGGLocalizedString(@"cluster.header.referencePositions")];
    refHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:refHeader];

    // ── The seven reference positions ─────────────────────────────────────
    
    BGGBoardCard *rp1 = [self cardForPositionID:@"AAAAsG0DAAAAAA:cAnkAAAAEAAE"
                                     captionKey:@"cluster.rp1.caption"
                                 explanationKey:@"cluster.rp1.explanation"];
    BGGBoardCard *rp2 = [self cardForPositionID:@"AAAAtm0DAAAAAA:cIkoARAAAAAE"
                                     captionKey:@"cluster.rp2.caption"
                                 explanationKey:@"cluster.rp2.explanation"];
    BGGBoardCard *rp3 = [self cardForPositionID:@"AAAAwOcDAAAAAA:cIkoARAAAAAE"
                                     captionKey:@"cluster.rp3.caption"
                                 explanationKey:@"cluster.rp3.explanation"];
    BGGBoardCard *rp4 = [self cardForPositionID:@"AAAAgA0AAAAAAA:cIkoARAAAAAE"
                                     captionKey:@"cluster.rp4.caption"
                                 explanationKey:@"cluster.rp4.explanation"];
    BGGBoardCard *rp5 = [self cardForPositionID:@"AAAAAB8AAAAAAA:cIkoARAAAAAE"
                                     captionKey:@"cluster.rp5.caption"
                                 explanationKey:@"cluster.rp5.explanation"];
    BGGBoardCard *rp6 = [self cardForPositionID:@"AAAAAGAwAAAAAA:cImoAAAAAAAE"
                                     captionKey:@"cluster.rp6.caption"
                                 explanationKey:@"cluster.rp6.explanation"];
    BGGBoardCard *rp7 = [self cardForPositionID:@"AAAAAGABAAAAAA:cAkgAXAAMAAE"
                                     captionKey:@"cluster.rp7.caption"
                                 explanationKey:@"cluster.rp7.explanation"];


    // ── Section header: Key Points ────────────────────────────────────────
    UILabel *keyHeader = [self sectionHeader:BGGLocalizedString(@"cluster.header.keyPoints")];
    keyHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:keyHeader];
    
    UILabel *keypointIntro = [self bodyLabel:
                              BGGLocalizedString(@"cluster.keyPoints.intro")];
    keypointIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:keypointIntro];

    BGGBoardCard *kp1 = [self cardForPositionID:@"eB4AALA3AAAAAA:cAkuAWAAOAAE"
                                     captionKey:@"cluster.kp1.caption"
                                 explanationKey:@"cluster.kp1.explanation"];
    BGGBoardCard *kp2 = [self cardForPositionID:@"AAAYCgAAMwEAAA:cAkuAWAAOAAE"
                                     captionKey:@"cluster.kp2.caption"
                                 explanationKey:@"cluster.kp2.explanation"];

    // ── Section header: Mirrors ───────────────────────────────────────────
    UILabel *mirrorHeader = [self sectionHeader:BGGLocalizedString(@"cluster.header.mirrors")];
    mirrorHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:mirrorHeader];

    UILabel *mirrorIntro = [self bodyLabel:
        BGGLocalizedString(@"cluster.mirrors.intro")];
    mirrorIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:mirrorIntro];

    // NOTE: these two still load the same position as kp1 (the 5-Point key
    // point board) — a pre-existing bug to fix later by pointing them at the
    // "Mirror - Example 1/2" positions. The keys/texts below match what is
    // currently shown, not the intended mirror examples.
    BGGBoardCard *mirror1 = [self cardForPositionID:@"eB4AALA3AAAAAA:cAkuAWAAOAAE"
                                         captionKey:@"cluster.mirror1.caption"
                                     explanationKey:@"cluster.mirror1.explanation"];
    BGGBoardCard *mirror2 = [self cardForPositionID:@"eB4AALA3AAAAAA:cAkuAWAAOAAE"
                                         captionKey:@"cluster.mirror2.caption"
                                     explanationKey:@"cluster.mirror2.explanation"];

    // ── Section header: Mental Shifting ───────────────────────────────────
    UILabel *shiftHeader = [self sectionHeader:BGGLocalizedString(@"cluster.header.mentalShifting")];
    shiftHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftHeader];

    UILabel *shiftIntro = [self bodyLabel:
        BGGLocalizedString(@"cluster.mentalShifting.intro")];
    shiftIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftIntro];

    UILabel *shiftOneWayHeader = [self sectionHeader:BGGLocalizedString(@"cluster.header.oneWayShift")];
    shiftOneWayHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftOneWayHeader];

    UILabel *shiftOneWayIntro = [self bodyLabel:
        BGGLocalizedString(@"cluster.oneWayShift.intro")];
    shiftOneWayIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftOneWayIntro];

    BGGBoardCard *shift1 = [self cardForPositionID:@"ttkYAQy43RSAIQ:cAkgATAACAAE"
                                        captionKey:@"cluster.shift1.caption"
                                    explanationKey:@"cluster.shift1.explanation"];
    UILabel *shiftOneWayConclusion = [self bodyLabel:
        BGGLocalizedString(@"cluster.oneWayShift.conclusion")];
    shiftOneWayConclusion.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftOneWayConclusion];

    UILabel *shiftTwoWayHeader = [self sectionHeader:BGGLocalizedString(@"cluster.header.twoWayShift")];
    shiftTwoWayHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftTwoWayHeader];

    UILabel *shiftTwoWayIntro = [self bodyLabel:
        BGGLocalizedString(@"cluster.twoWayShift.intro")];
    shiftTwoWayIntro.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:shiftTwoWayIntro];

    BGGBoardCard *shift2 = [self cardForPositionID:@"2NbBAQawc8MHAA:cInlADAAEAAE"
                                        captionKey:@"cluster.shift2.caption"
                                    explanationKey:@"cluster.shift2.explanation"];

    UILabel *shiftTwoWayConclusion = [self bodyLabel:
        BGGLocalizedString(@"cluster.twoWayShift.conclusion")];
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

// Like cardForPositionID:, but the caption and explanation come from the
// string catalog (localized) instead of the JSON entry. The board position
// still comes from positions.json via the ID. Used for the curated cluster
// teaching boards, following the rule that didactic views show no JSON text.
- (BGGBoardCard *)cardForPositionID:(NSString *)positionID
                         captionKey:(NSString *)captionKey
                     explanationKey:(NSString *)explanationKey
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
                          initWithCaption:BGGLocalizedString(captionKey)
                          explanationText:BGGLocalizedString(explanationKey)
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

    NSString *titlePart = BGGLocalizedString(@"cluster.intro.title");
    NSString *bodyPart  = BGGLocalizedString(@"cluster.intro.body");
    NSString *boldPart  = [titlePart stringByAppendingString:@"\n\n"];

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
