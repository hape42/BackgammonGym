//
//  PipCountWarmupVC.m
//  BackgammonGym
//
//  Warm-up screen for Pip Count.
//  Shows the intro text followed by example boards using BGGBoardCard,
//  which automatically switches between side-by-side (iPad) and
//  stacked (iPhone) layout.
//

#import "PipCountWarmupVC.h"
#import "BGGBoardCard.h"
#import "BGGPosition.h"
#import "PositionDatabase.h"

@interface PipCountWarmupVC ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView       *contentView;
@end

@implementation PipCountWarmupVC

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

    UILabel *sources = [self sourcesLabel];
    sources.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:sources];

    // ── Board 1: starting position ────────────────────────────────────────
    BGGBoardCard *card1 = [[BGGBoardCard alloc]
                           initWithCaption:@"Starting position – pip count 167 : 167"
                           explanationText:@"Count every checker: multiply its point number by the number of checkers on it, then add everything up. \nFor example: The two checkers on point 24 contribute 48 pips; the five on point 13 contribute 65. \nBoth players start at exactly 167."
                            boardState:[BGGPosition boardStateFromPositionID:@"4HPwATDgc/ABMA"]];
    card1.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:card1];

    // ── Board 2:  ──────────────────────────────────────────────
    BGGBoardCard *card2 = [[BGGBoardCard alloc]
                           initWithCaption:@"A typical bear off position"
                           explanationText:@"Pipcount Player 1: 51 pips - Player 2 : 60 pips"
                            boardState:[BGGPosition boardStateFromPositionID:@"u7sNAADbtg8AAA:MIEqAWAAEAAE"]];
    card2.isPlaceholder = NO;
    card2.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:card2];

    // ── Board 3:  ──────────────────────────────────────────────
    BGGPositionEntry *entry = [[PositionDatabase sharedDatabase]
                               entryForPositionID:@"22aICAbG3j0AAA:MAEAAAAAAAAA"];

    BGGBoardCard *card3 = [[BGGBoardCard alloc]
                           initWithCaption:entry.caption
                           explanationText:entry.text
                                boardState:[entry boardState]];
    card3.isPlaceholder = NO;
    card3.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:card3];

    // ── Layout ────────────────────────────────────────────────────────────
    [NSLayoutConstraint activateConstraints:@[
        [intro.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor   constant:spacing],
        [intro.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:margin],
        [intro.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-margin],

        [sources.topAnchor      constraintEqualToAnchor:intro.bottomAnchor         constant:8.0],
        [sources.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:margin],
        [sources.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-margin],

        [card1.topAnchor      constraintEqualToAnchor:sources.bottomAnchor         constant:spacing],
        [card1.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:margin],
        [card1.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-margin],

        [card2.topAnchor      constraintEqualToAnchor:card1.bottomAnchor           constant:spacing],
        [card2.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:margin],
        [card2.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-margin],

        [card3.topAnchor      constraintEqualToAnchor:card2.bottomAnchor           constant:spacing],
        [card3.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:margin],
        [card3.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-margin],

        [self.contentView.bottomAnchor constraintEqualToAnchor:card3.bottomAnchor  constant:spacing],
    ]];
}

#pragma mark - Labels

- (UILabel *)introLabel
{
    UILabel *label      = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.textColor     = [UIColor labelColor];

    NSString *boldPart = @"What is a Pip Count?\n\n";
    NSString *bodyPart =
        @"Backgammon is essentially a race. To know who's winning that race, "
        @"you need the pip count – the total number of points all your checkers "
        @"still have to travel before they're off the board.\n\n"
        @"Every checker sits on a numbered point, and contributes that number to "
        @"your total. Two checkers on point 24 add 48 pips; five on point 6 add 30. "
        @"Add it all up and you have your pip count. At the start of the game, both "
        @"players stand at exactly 167.\n\n"
        @"The lower your count, the closer you are to winning. A pip count advantage "
        @"drives most of the big decisions in a game: do you race or play a holding "
        @"game? Is this the right moment to double? Can you take that double? As a "
        @"rough guide, being 10 pips ahead in a long race is enough to consider "
        @"doubling.\n\n"
        @"When you play on Heroes, Backgammon Galaxy, DailyGammon or any other online "
        @"platform, the pip count is always right there on the screen – you never have "
        @"to think about it. Sit down at a real board, and it's gone. That gap is "
        @"exactly why training this skill matters."
        @"\n\nThis app is designed to help you learn how to quickly and accurately calculate the PipCount for the positions below in just a few seconds. ";

    NSMutableAttributedString *attr =
        [[NSMutableAttributedString alloc]
         initWithString:[boldPart stringByAppendingString:bodyPart]];

    UIFont *bodyFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIFont *boldFont = [UIFont boldSystemFontOfSize:bodyFont.pointSize + 1.0];
    [attr addAttribute:NSFontAttributeName value:bodyFont
                 range:NSMakeRange(0, attr.length)];
    [attr addAttribute:NSFontAttributeName value:boldFont
                 range:NSMakeRange(0, boldPart.length)];
    label.attributedText = attr;
    return label;
}

- (UILabel *)sourcesLabel
{
    UILabel *label      = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    label.textColor     = [UIColor tertiaryLabelColor];
    label.text          = @"Sources: Mark Driver, \"Beginner's Guide to Counting Pips\", "
                          @"bkgm.com (2000) · 247backgammon.org, \"What is PIP Count in Backgammon\"";
    return label;
}

@end
