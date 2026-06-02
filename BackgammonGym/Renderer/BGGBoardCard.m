//
//  BGGBoardCard.m
//  BackgammonGym
//

#import "BGGBoardCard.h"
#import "BGGBoardView.h"
#import "BGGBoardState.h"
#import "BGGBoardGeometry.h"
#import "Tools.h"

// Below this width the card stacks vertically (iPhone layout).
static const CGFloat kBGGBoardCardWideThreshold = 600.0;

// On wide screens the board takes 40% of the width.
static const CGFloat kBGGBoardFraction = 0.40;

@interface BGGBoardCard ()
@property (nonatomic, strong) BGGBoardView *boardView;
@property (nonatomic, strong) UILabel      *captionLabel;
@property (nonatomic, strong) UILabel      *explanationLabel;

// Constraints that change between wide and narrow layouts.
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *wideConstraints;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *narrowConstraints;
@property (nonatomic, assign) BOOL isWideLayout;
@end

@implementation BGGBoardCard

#pragma mark - Init

- (instancetype)initWithCaption:(nullable NSString *)caption
                explanationText:(nullable NSString *)explanation
                     boardState:(nullable BGGBoardState *)state
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        _caption         = [caption copy];
        _explanationText = [explanation copy];
        _boardState      = state;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) { [self commonInit]; }
    return self;
}

- (void)commonInit
{
    _boardDesign       = [Tools currentBoardDesign];
    _showsPointNumbers = YES;
    _showsCube         = NO;
    _showsDice         = NO;
    _isPlaceholder     = NO;
    _isWideLayout      = NO;

    [self buildSubviews];
    [self installSharedConstraints];
}

#pragma mark - Subviews

- (void)buildSubviews
{
    // Caption label
    self.captionLabel = [[UILabel alloc] init];
    self.captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.captionLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
    self.captionLabel.numberOfLines = 0;
    self.captionLabel.text          = self.caption;
    [self addSubview:self.captionLabel];

    // Board view
    self.boardView = [[BGGBoardView alloc] init];
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardView.boardDesign       = self.boardDesign;
    self.boardView.showsPointNumbers = self.showsPointNumbers;
    self.boardView.showsCube         = self.showsCube;
    self.boardView.showsDice         = self.showsDice;
    self.boardView.boardState        = self.boardState;
    [self addSubview:self.boardView];

    // Explanation label
    self.explanationLabel = [[UILabel alloc] init];
    self.explanationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.explanationLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.explanationLabel.textColor     = [UIColor secondaryLabelColor];
    self.explanationLabel.numberOfLines = 0;
    self.explanationLabel.text          = self.explanationText;
    [self addSubview:self.explanationLabel];

    [self applyPlaceholderStyle];
}

- (void)applyPlaceholderStyle
{
    UIColor *captionColor = self.isPlaceholder
        ? [UIColor systemRedColor]
        : [UIColor labelColor];
    self.captionLabel.textColor = captionColor;

    self.boardView.layer.borderWidth = self.isPlaceholder ? 3.0 : 0.0;
    self.boardView.layer.borderColor = [UIColor systemRedColor].CGColor;
}

#pragma mark - Shared (layout-independent) constraints

- (void)installSharedConstraints
{
    // Board always keeps the correct aspect ratio.
    CGFloat ratio = kBGGBoardHeight / kBGGBoardWidth;
    [self.boardView.heightAnchor constraintEqualToAnchor:self.boardView.widthAnchor
                                              multiplier:ratio].active = YES;
}

#pragma mark - Layout switching

- (void)layoutSubviews
{
    [super layoutSubviews];

    BOOL shouldBeWide = (self.bounds.size.width >= kBGGBoardCardWideThreshold);
    if (shouldBeWide == self.isWideLayout) { return; }

    // Deactivate current layout constraints.
    [NSLayoutConstraint deactivateConstraints:self.wideConstraints ?: @[]];
    [NSLayoutConstraint deactivateConstraints:self.narrowConstraints ?: @[]];

    self.isWideLayout = shouldBeWide;
    shouldBeWide ? [self installWideConstraints] : [self installNarrowConstraints];
}

// iPad: caption spans full width on top, then board (40%) left + text (60%) right.
- (void)installWideConstraints
{
    CGFloat gap = 16.0;

    self.wideConstraints = @[
        // Caption – full width at top
        [self.captionLabel.topAnchor      constraintEqualToAnchor:self.topAnchor],
        [self.captionLabel.leadingAnchor  constraintEqualToAnchor:self.leadingAnchor],
        [self.captionLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],

        // Board – left 40%, below caption
        [self.boardView.topAnchor         constraintEqualToAnchor:self.captionLabel.bottomAnchor constant:8.0],
        [self.boardView.leadingAnchor     constraintEqualToAnchor:self.leadingAnchor],
        [self.boardView.widthAnchor       constraintEqualToAnchor:self.widthAnchor
                                                       multiplier:kBGGBoardFraction],

        // Explanation – right 60%, vertically centered next to board
        [self.explanationLabel.leadingAnchor  constraintEqualToAnchor:self.boardView.trailingAnchor
                                                              constant:gap],
        [self.explanationLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.explanationLabel.centerYAnchor  constraintEqualToAnchor:self.boardView.centerYAnchor],

        // Card bottom follows whichever is taller.
        [self.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.boardView.bottomAnchor],
        [self.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.explanationLabel.bottomAnchor],
    ];
    [NSLayoutConstraint activateConstraints:self.wideConstraints];
}

// iPhone: caption, then board full width, then explanation below.
- (void)installNarrowConstraints
{
    self.narrowConstraints = @[
        // Caption
        [self.captionLabel.topAnchor      constraintEqualToAnchor:self.topAnchor],
        [self.captionLabel.leadingAnchor  constraintEqualToAnchor:self.leadingAnchor],
        [self.captionLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],

        // Board – full width
        [self.boardView.topAnchor      constraintEqualToAnchor:self.captionLabel.bottomAnchor constant:8.0],
        [self.boardView.leadingAnchor  constraintEqualToAnchor:self.leadingAnchor],
        [self.boardView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],

        // Explanation below board
        [self.explanationLabel.topAnchor      constraintEqualToAnchor:self.boardView.bottomAnchor constant:8.0],
        [self.explanationLabel.leadingAnchor  constraintEqualToAnchor:self.leadingAnchor],
        [self.explanationLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],

        // Card bottom
        [self.bottomAnchor constraintEqualToAnchor:self.explanationLabel.bottomAnchor],
    ];
    [NSLayoutConstraint activateConstraints:self.narrowConstraints];
}

#pragma mark - Property setters (update subviews)

- (void)setBoardState:(nullable BGGBoardState *)boardState
{
    _boardState = boardState;
    self.boardView.boardState = boardState;
}

- (void)setBoardDesign:(NSString *)boardDesign
{
    _boardDesign = [boardDesign copy];
    self.boardView.boardDesign = boardDesign;
}

- (void)setCaption:(nullable NSString *)caption
{
    _caption = [caption copy];
    self.captionLabel.text = caption;
    [self applyPlaceholderStyle];
}

- (void)setExplanationText:(nullable NSString *)explanationText
{
    _explanationText = [explanationText copy];
    self.explanationLabel.text = explanationText;
}

- (void)setIsPlaceholder:(BOOL)isPlaceholder
{
    _isPlaceholder = isPlaceholder;
    [self applyPlaceholderStyle];
}

- (void)setShowsPointNumbers:(BOOL)showsPointNumbers
{
    _showsPointNumbers = showsPointNumbers;
    self.boardView.showsPointNumbers = showsPointNumbers;
}

- (void)setShowsCube:(BOOL)showsCube
{
    _showsCube = showsCube;
    self.boardView.showsCube = showsCube;
}

- (void)setShowsDice:(BOOL)showsDice
{
    _showsDice = showsDice;
    self.boardView.showsDice = showsDice;
}

@end
