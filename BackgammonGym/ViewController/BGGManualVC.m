//
//  BGGManualVC.m
//  BackgammonGym
//

#import "BGGManualVC.h"
#import "UIViewController+BGGHomeButton.h"
#import "BGGLocalization.h"

#pragma mark - Section view

// One accordion section: a tappable header (chevron + title) and a body label
// below it that expands/collapses. Several sections may be open at once; each
// manages its own state. Hiding the body inside a UIStackView makes the stack
// collapse the space automatically, so no manual constraint juggling.
@interface BGGManualSectionView : UIView

- (instancetype)initWithTitle:(NSString *)title
                attributedBody:(NSAttributedString *)body
                      expanded:(BOOL)expanded;

@end

@implementation BGGManualSectionView
{
    UIButton    *_headerButton;
    UIImageView *_chevron;
    UILabel     *_bodyLabel;
    BOOL         _expanded;
}

- (instancetype)initWithTitle:(NSString *)title
                attributedBody:(NSAttributedString *)body
                      expanded:(BOOL)expanded
{
    self = [super initWithFrame:CGRectZero];
    if (self == nil) { return nil; }

    _expanded = expanded;

    self.backgroundColor    = [UIColor secondarySystemBackgroundColor];
    self.layer.cornerRadius = 14.0;
    self.layer.cornerCurve  = kCACornerCurveContinuous;
    self.translatesAutoresizingMaskIntoConstraints = NO;

    // Chevron, rotated when expanded.
    _chevron = [[UIImageView alloc] initWithImage:
                [UIImage systemImageNamed:@"chevron.right"]];
    _chevron.tintColor   = [UIColor colorNamed:@"AccentColor"];
    _chevron.contentMode = UIViewContentModeScaleAspectFit;
    [_chevron.widthAnchor  constraintEqualToConstant:13.0].active = YES;
    [_chevron.heightAnchor constraintEqualToConstant:13.0].active = YES;
    [_chevron setContentHuggingPriority:UILayoutPriorityRequired
                                forAxis:UILayoutConstraintAxisHorizontal];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text          = title;
    titleLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    titleLabel.adjustsFontForContentSizeCategory = YES;
    titleLabel.numberOfLines = 0;

    UIStackView *headerStack =
        [[UIStackView alloc] initWithArrangedSubviews:@[_chevron, titleLabel]];
    headerStack.axis         = UILayoutConstraintAxisHorizontal;
    headerStack.spacing      = 10.0;
    headerStack.alignment    = UIStackViewAlignmentCenter;
    headerStack.userInteractionEnabled = NO;   // let the button take the taps
    headerStack.translatesAutoresizingMaskIntoConstraints = NO;

    // Transparent button covering the header row, for the tap target.
    _headerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _headerButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_headerButton addTarget:self
                      action:@selector(toggle)
            forControlEvents:UIControlEventTouchUpInside];
    [_headerButton addSubview:headerStack];

    [NSLayoutConstraint activateConstraints:@[
        [headerStack.topAnchor      constraintEqualToAnchor:_headerButton.topAnchor],
        [headerStack.bottomAnchor   constraintEqualToAnchor:_headerButton.bottomAnchor],
        [headerStack.leadingAnchor  constraintEqualToAnchor:_headerButton.leadingAnchor],
        [headerStack.trailingAnchor constraintEqualToAnchor:_headerButton.trailingAnchor],
    ]];

    // Body text.
    _bodyLabel = [[UILabel alloc] init];
    _bodyLabel.attributedText = body;
    _bodyLabel.numberOfLines  = 0;
    _bodyLabel.hidden         = !_expanded;

    UIStackView *outer =
        [[UIStackView alloc] initWithArrangedSubviews:@[_headerButton, _bodyLabel]];
    outer.axis    = UILayoutConstraintAxisVertical;
    outer.spacing = 12.0;
    outer.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:outer];

    [NSLayoutConstraint activateConstraints:@[
        [outer.topAnchor      constraintEqualToAnchor:self.topAnchor constant:16.0],
        [outer.leadingAnchor  constraintEqualToAnchor:self.leadingAnchor constant:18.0],
        [outer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-18.0],
        [outer.bottomAnchor   constraintEqualToAnchor:self.bottomAnchor constant:-16.0],
    ]];

    [self applyChevronRotation];
    return self;
}

- (void)toggle
{
    _expanded = !_expanded;
    [UIView animateWithDuration:0.25 animations:^{
        self->_bodyLabel.hidden = !self->_expanded;
        self->_bodyLabel.alpha  = self->_expanded ? 1.0 : 0.0;
        [self applyChevronRotation];
        // Lay out the whole stack so the collapse/expand animates smoothly.
        [self.superview layoutIfNeeded];
    }];
}

- (void)applyChevronRotation
{
    // Point down when expanded, right when collapsed.
    _chevron.transform = _expanded
        ? CGAffineTransformMakeRotation((CGFloat)(M_PI_2))
        : CGAffineTransformIdentity;
}

@end


#pragma mark - Manual view controller

@interface BGGManualVC ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView       *contentView;

@end

@implementation BGGManualVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = BGGLocalizedString(@"Manual");

    [self installHomeButton];
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

#pragma mark - Data

// The manual content. Each section is @{ @"title", @"body" }, both speaking
// catalog keys. Body text may contain SF-symbol placeholders like [house],
// which are replaced with the inline symbol when rendered (see
// attributedBodyFromString:). To add a section, extend this array.
- (NSArray<NSDictionary *> *)sections
{
    return @[
        @{ @"title": BGGLocalizedString(@"manual.idea.title"),
           @"body":  BGGLocalizedString(@"manual.idea.body") },
        @{ @"title": BGGLocalizedString(@"manual.warmup.title"),
           @"body":  BGGLocalizedString(@"manual.warmup.body") },
        @{ @"title": BGGLocalizedString(@"manual.training.title"),
           @"body":  BGGLocalizedString(@"manual.training.body") },
        @{ @"title": BGGLocalizedString(@"manual.workout.title"),
           @"body":  BGGLocalizedString(@"manual.workout.body") },
        @{ @"title": BGGLocalizedString(@"manual.progress.title"),
           @"body":  BGGLocalizedString(@"manual.progress.body") },
        @{ @"title": BGGLocalizedString(@"manual.stats.title"),
           @"body":  BGGLocalizedString(@"manual.stats.body") },
        @{ @"title": BGGLocalizedString(@"manual.navigation.title"),
           @"body":  BGGLocalizedString(@"manual.navigation.body") },
    ];
}

#pragma mark - Content

- (void)buildContent
{
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis    = UILayoutConstraintAxisVertical;
    stack.spacing = 12.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:stack];

    NSArray<NSDictionary *> *sections = [self sections];
    for (NSUInteger i = 0; i < sections.count; i++)
    {
        NSDictionary *section = sections[i];
        // First section starts expanded so the screen never opens empty and
        // the expand/collapse affordance is immediately obvious.
        BOOL expanded = (i == 0);
        BGGManualSectionView *view =
            [[BGGManualSectionView alloc]
                initWithTitle:section[@"title"]
               attributedBody:[self attributedBodyFromString:section[@"body"]]
                     expanded:expanded];
        [stack addArrangedSubview:view];
    }

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor constant:20.0],
        [stack.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:20.0],
        [stack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20.0],
        [stack.bottomAnchor   constraintEqualToAnchor:self.contentView.bottomAnchor constant:-28.0],
    ]];
}

#pragma mark - Symbol placeholders

// Builds a body attributed string from plain text that may contain SF-symbol
// placeholders written as [symbol.name], e.g. "tap [house] to go home". Each
// placeholder is replaced with the inline symbol image; everything else is
// body-styled text. Unknown symbol names are left as literal text so a typo is
// visible rather than silently dropped.
- (NSAttributedString *)attributedBodyFromString:(NSString *)text
{
    UIFont  *font  = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIColor *color = [UIColor labelColor];
    NSDictionary *attrs = @{ NSFontAttributeName: font,
                             NSForegroundColorAttributeName: color };

    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];

    NSScanner *scanner = [NSScanner scannerWithString:text];
    scanner.charactersToBeSkipped = nil;

    while (!scanner.atEnd)
    {
        NSString *plain = nil;
        if ([scanner scanUpToString:@"[" intoString:&plain] && plain.length > 0)
        {
            [result appendAttributedString:
                [[NSAttributedString alloc] initWithString:plain attributes:attrs]];
        }

        if (scanner.atEnd) { break; }

        // At a "[" – try to read "[name]".
        NSUInteger bracketStart = scanner.scanLocation;
        [scanner setScanLocation:bracketStart + 1];   // skip "["

        NSString *name = nil;
        BOOL gotName  = [scanner scanUpToString:@"]" intoString:&name];
        BOOL gotClose = (!scanner.atEnd);

        UIImage *symbol = gotName ? [UIImage systemImageNamed:name
                            withConfiguration:[UIImageSymbolConfiguration
                                configurationWithFont:font]] : nil;

        if (gotName && gotClose && symbol != nil)
        {
            [scanner setScanLocation:scanner.scanLocation + 1];   // skip "]"
            symbol = [symbol imageWithTintColor:[UIColor colorNamed:@"AccentColor"]
                                  renderingMode:UIImageRenderingModeAlwaysOriginal];
            NSTextAttachment *att = [[NSTextAttachment alloc] init];
            att.image = symbol;
            [result appendAttributedString:
                [NSAttributedString attributedStringWithAttachment:att]];
        }
        else
        {
            // Not a valid placeholder: emit the "[" literally and continue
            // scanning after it, so the rest of the text is unaffected.
            [result appendAttributedString:
                [[NSAttributedString alloc] initWithString:@"[" attributes:attrs]];
            [scanner setScanLocation:bracketStart + 1];
        }
    }

    return result;
}

@end
