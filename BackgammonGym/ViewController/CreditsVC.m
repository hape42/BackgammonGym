//
//  CreditsVC.m
//  BackgammonGym
//

#import "CreditsVC.h"
#import "UIViewController+BGGHomeButton.h"
#import "BGGLocalization.h"

@interface CreditsVC ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView       *contentView;

// Maps a tappable name label to the URL it should open. A map table with weak
// keys lets the labels be released normally; we only need the link while they
// are on screen.
@property (nonatomic, strong) NSMapTable<UILabel *, NSURL *> *linkURLs;

@end

@implementation CreditsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Credits";   // brand language, stays English
    self.linkURLs = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory
                                          valueOptions:NSPointerFunctionsStrongMemory];
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

// The credits content. Each section is
//   @{ @"title": ..., @"icon": SF-symbol, @"intro": (optional),
//      @"entries": @[ @{ @"label": left text, @"name": right (accented) text,
//                        @"url": (optional) https-link on the name }, ... ] }.
// To add a credit, extend this array – the layout renders whatever it finds.
// A name with an empty label spans naturally; a label with an empty name shows
// only the description. Add @"url" to make the name a tappable, underlined link.
//
// TODO(hape42): fill in the real names/sources where marked «…», and add
// @"url" entries where a name should link out.
- (NSArray<NSDictionary *> *)sections
{
    return @[
        @{
            @"title": BGGLocalizedString(@"Backgammon knowledge & sources"),
            @"icon":  @"book",
            @"intro": BGGLocalizedString(@"So much excellent material is freely "
                      @"available. This app stands on the shoulders of the "
                      @"community."),
            @"entries": @[
                @{ @"label": BGGLocalizedString(@"Match Equity"), @"name": @"Rockwell–Kazaross", @"url":   @"https://bkgm.com/articles/Kazaross/RockwellKazarossMET/index.html" },
                @{ @"label": BGGLocalizedString(@"General"),      @"name": @"bkgm.com", @"url":   @"https://www.bkgm.com" },
                @{ @"label": BGGLocalizedString(@"Pip count"),    @"name": @"bkgm.com", @"url":   @"https://www.bkgm.com" },
                @{ @"label": BGGLocalizedString(@"Cluster counting"), @"name": @"Jack Kissane", @"url":   @"https://bkgm.com/articles/McCool/cluster.html" },
            ],
        },
        @{
            @"title": BGGLocalizedString(@"Board designs"),
            @"icon":  @"paintpalette",
            @"entries": @[
                @{ @"label": @"Red / Grey HD", @"name": @"hape42", @"url":   @"https://hape42.de/" },
                @{ @"label": @"Wood, Metal, Mono, Steampunk, Sea, Traditional, Spring",
                   @"name":  @"darkhelmet" },
                @{ @"label": @"Unicorn", @"name": @"Jutta Schneider", @"url":   @"https://juhesch.art" },
            ],
        },
        @{
            @"title": BGGLocalizedString(@"Graphics & app icon"),
            @"icon":  @"app.badge",
            @"entries": @[
                @{ @"label": @"", @"name": @"Jutta Schneider", @"url":   @"https://juhesch.art" },
            ],
        },
        @{
            @"title": BGGLocalizedString(@"Testers"),
            @"icon":  @"checkmark.seal",
            @"entries": @[
                @{ @"label": @"", @"name": @"Karlheinz Agsteiner" },
            ],
        },
        @{
            @"title": BGGLocalizedString(@"Tools & libraries"),
            @"icon":  @"wrench.and.screwdriver",
            @"entries": @[
                @{ @"label": @"", @"name": @"GNU Backgammon" },
                @{ @"label": @"", @"name": @"Bgblitz" },

            ],
        },
    ];
}

#pragma mark - Content

- (void)buildContent
{
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis    = UILayoutConstraintAxisVertical;
    stack.spacing = 14.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:stack];

    // Warm opening line (serif), then a card per section, then a closing line.
    UILabel *opening = [self bracketLabel:
        BGGLocalizedString(@"creditscredits.opening")];
    [stack addArrangedSubview:opening];
    [stack setCustomSpacing:22.0 afterView:opening];

    UIView *lastCard = nil;
    for (NSDictionary *section in [self sections])
    {
        UIView *card = [self cardForSection:section];
        [stack addArrangedSubview:card];
        lastCard = card;
    }

    UILabel *closing = [self bracketLabel:
        BGGLocalizedString(@"creditscredits.closing")];
    [stack addArrangedSubview:closing];
    if (lastCard != nil) { [stack setCustomSpacing:22.0 afterView:lastCard]; }

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor constant:24.0],
        [stack.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:20.0],
        [stack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20.0],
        [stack.bottomAnchor   constraintEqualToAnchor:self.contentView.bottomAnchor constant:-32.0],
    ]];
}

#pragma mark - Section card

- (UIView *)cardForSection:(NSDictionary *)section
{
    UIView *card = [[UIView alloc] init];
    card.backgroundColor    = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 14.0;
    card.layer.cornerCurve  = kCACornerCurveContinuous;
    card.translatesAutoresizingMaskIntoConstraints = NO;

    // Header: icon + title.
    UIImageView *icon = [[UIImageView alloc] init];
    icon.image       = [UIImage systemImageNamed:section[@"icon"]];
    icon.tintColor   = [UIColor colorNamed:@"AccentColor"];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [icon setContentHuggingPriority:UILayoutPriorityRequired
                            forAxis:UILayoutConstraintAxisHorizontal];

    UILabel *title = [[UILabel alloc] init];
    title.text          = section[@"title"];
    title.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    title.adjustsFontForContentSizeCategory = YES;
    title.numberOfLines = 0;

    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[icon, title]];
    header.axis      = UILayoutConstraintAxisHorizontal;
    header.spacing   = 10.0;
    header.alignment = UIStackViewAlignmentCenter;
    [icon.widthAnchor  constraintEqualToConstant:22.0].active = YES;
    [icon.heightAnchor constraintEqualToConstant:22.0].active = YES;

    UIStackView *inner = [[UIStackView alloc] initWithArrangedSubviews:@[header]];
    inner.axis    = UILayoutConstraintAxisVertical;
    inner.spacing = 10.0;
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    [inner setCustomSpacing:12.0 afterView:header];

    // Optional intro line.
    NSString *intro = section[@"intro"];
    if (intro.length > 0)
    {
        UILabel *introLabel = [[UILabel alloc] init];
        introLabel.text          = intro;
        introLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        introLabel.textColor     = [UIColor tertiaryLabelColor];
        introLabel.numberOfLines = 0;
        [inner addArrangedSubview:introLabel];
        [inner setCustomSpacing:12.0 afterView:introLabel];
    }

    // Entry rows: description (secondary) left, name (accent) right, divided.
    NSArray<NSDictionary *> *entries = section[@"entries"];
    for (NSDictionary *entry in entries)
    {
        UIView *divider = [[UIView alloc] init];
        divider.backgroundColor = [UIColor separatorColor];
        [divider.heightAnchor constraintEqualToConstant:0.5].active = YES;
        [inner addArrangedSubview:divider];
        [inner setCustomSpacing:8.0 afterView:divider];

        UIView *row = [self rowForLabel:entry[@"label"]
                                   name:entry[@"name"]
                                    url:entry[@"url"]];
        [inner addArrangedSubview:row];
        [inner setCustomSpacing:8.0 afterView:row];
    }

    [card addSubview:inner];
    [NSLayoutConstraint activateConstraints:@[
        [inner.topAnchor      constraintEqualToAnchor:card.topAnchor constant:16.0],
        [inner.leadingAnchor  constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [inner.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [inner.bottomAnchor   constraintEqualToAnchor:card.bottomAnchor constant:-16.0],
    ]];
    return card;
}

// One two-column row. The name (right) is accented and never truncates; the
// label (left) takes the remaining width and wraps if long. If urlString is
// non-empty, the name becomes a tappable, underlined link.
- (UIView *)rowForLabel:(NSString *)label name:(NSString *)name url:(nullable NSString *)urlString
{
    UILabel *left = [[UILabel alloc] init];
    left.text          = label ?: @"";
    left.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    left.textColor     = [UIColor secondaryLabelColor];
    left.numberOfLines = 0;
    [left setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                          forAxis:UILayoutConstraintAxisHorizontal];

    UILabel *right = [[UILabel alloc] init];
    right.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    right.textColor     = [UIColor colorNamed:@"AccentColor"];
    right.textAlignment = NSTextAlignmentRight;
    right.numberOfLines = 0;
    [right setContentHuggingPriority:UILayoutPriorityRequired
                             forAxis:UILayoutConstraintAxisHorizontal];
    [right setContentCompressionResistancePriority:UILayoutPriorityRequired
                                           forAxis:UILayoutConstraintAxisHorizontal];

    NSURL *url = (urlString.length > 0) ? [NSURL URLWithString:urlString] : nil;
    if (url != nil)
    {
        // Underline to signal it is a link, and wire up a tap.
        NSDictionary *attrs = @{
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
            NSForegroundColorAttributeName: [UIColor colorNamed:@"AccentColor"],
        };
        right.attributedText = [[NSAttributedString alloc] initWithString:(name ?: @"")
                                                              attributes:attrs];
        right.userInteractionEnabled = YES;
        [self.linkURLs setObject:url forKey:right];

        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(linkTapped:)];
        [right addGestureRecognizer:tap];
    }
    else
    {
        right.text = name ?: @"";
    }

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[left, right]];
    row.axis         = UILayoutConstraintAxisHorizontal;
    row.spacing      = 16.0;
    row.alignment    = UIStackViewAlignmentFirstBaseline;
    row.distribution = UIStackViewDistributionFill;
    return row;
}

// Opens the URL associated with the tapped name label.
- (void)linkTapped:(UITapGestureRecognizer *)gesture
{
    UILabel *label = (UILabel *)gesture.view;
    NSURL *url = [self.linkURLs objectForKey:label];
    if (url != nil)
    {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

#pragma mark - Label builders

// Serif bracket line (opening / closing), centered, muted.
- (UILabel *)bracketLabel:(NSString *)text
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text          = text;
    lbl.font          = [UIFont fontWithName:@"Georgia" size:17.0]
                        ?: [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    lbl.textColor     = [UIColor secondaryLabelColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.numberOfLines = 0;
    return lbl;
}

@end
