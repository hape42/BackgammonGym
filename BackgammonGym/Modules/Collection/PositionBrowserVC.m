//
//  PositionBrowserVC.m
//  BackgammonGym
//

#import "PositionBrowserVC.h"
#import "PositionDatabase.h"
#import "BGGBoardView.h"
#import "BGGBoardIDView.h"
#import "BGGBoardState.h"
#import "BGGBoardGeometry.h"
#import "Tools.h"
#import "UIViewController+BGGHomeButton.h"
#import "BGGPositionEditorVC.h"

static NSString * const kCellID     = @"PositionCell";
static const CGFloat    kBoardWidth = 240.0;
static const CGFloat    kRowHeight  = 200.0;

// MARK: - Wrapping tag view

// A simple view that lays out tag chips left-to-right and wraps to a new
// line when the available width is exceeded. Used in each table cell.
@interface BGGTagWrapView : UIView
- (void)setTags:(NSArray<NSString *> *)tags;
@end

@implementation BGGTagWrapView

- (void)setTags:(NSArray<NSString *> *)tags
{
    for (UIView *v in self.subviews) { [v removeFromSuperview]; }

    UIColor *accent = [UIColor colorNamed:@"AccentColor"] ?: [UIColor systemRedColor];
    CGFloat x = 0, y = 0;
    CGFloat chipH = 18.0, gap = 4.0;

    for (NSString *tag in tags)
    {
        UILabel *chip = [[UILabel alloc] init];
        chip.text            = tag;
        chip.font            = [UIFont systemFontOfSize:10.0 weight:UIFontWeightSemibold];
        chip.textColor       = accent;
        chip.backgroundColor = [accent colorWithAlphaComponent:0.12];
        chip.layer.cornerRadius = 4.0;
        chip.clipsToBounds   = YES;
        chip.textAlignment   = NSTextAlignmentCenter;
        [chip sizeToFit];
        CGFloat w = chip.bounds.size.width + 10.0;

        // Wrap to next line if needed
        CGFloat maxX = self.bounds.size.width > 0 ? self.bounds.size.width : 200.0;
        if (x + w > maxX && x > 0)
        {
            x = 0;
            y += chipH + gap;
        }
        chip.frame = CGRectMake(x, y, w, chipH);
        [self addSubview:chip];
        x += w + gap;
    }
}

// Tell Auto Layout how tall this view needs to be after chips are laid out.
- (CGSize)intrinsicContentSize
{
    CGFloat maxY = 0;
    for (UIView *v in self.subviews)
    {
        maxY = MAX(maxY, CGRectGetMaxY(v.frame));
    }
    return CGSizeMake(UIViewNoIntrinsicMetric, maxY > 0 ? maxY : 18.0);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    // Re-layout chips whenever our width changes (rotation, etc.)
    NSArray<NSString *> *tags = [self.subviews valueForKey:@"text"];
    if (tags.count > 0) { [self setTags:tags]; }
    [self invalidateIntrinsicContentSize];
}

@end

// MARK: - Cell

@interface PositionBrowserCell : UITableViewCell
@property (nonatomic, strong) BGGBoardView    *boardView;
@property (nonatomic, strong) BGGBoardIDView  *boardIDView;
@property (nonatomic, strong) UILabel         *captionLabel;
@property (nonatomic, strong) UILabel         *posTextLabel;
@property (nonatomic, strong) BGGTagWrapView  *tagsView;
@property (nonatomic, strong) UILabel         *idLabel;
@property (nonatomic, strong) UILabel         *difficultyLabel;
@end

@implementation PositionBrowserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(nullable NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) { [self buildSubviews]; }
    return self;
}

- (void)buildSubviews
{
    CGFloat pad = 8.0;

    self.boardView = [[BGGBoardView alloc] init];
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardView.showsPointNumbers = NO;
    self.boardView.showsCube         = YES;
    self.boardView.showsDice         = YES;
    self.boardView.clipsToBounds     = YES;
    self.boardView.layer.cornerRadius = 6.0;
    [self.contentView addSubview:self.boardView];

    // ID + copy button below the board
    self.boardIDView = [[BGGBoardIDView alloc] init];
    self.boardIDView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.boardIDView];

    self.captionLabel = [[UILabel alloc] init];
    self.captionLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
    self.captionLabel.numberOfLines = 2;
    self.captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.captionLabel];

    self.posTextLabel = [[UILabel alloc] init];
    self.posTextLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.posTextLabel.textColor     = [UIColor secondaryLabelColor];
    self.posTextLabel.numberOfLines = 3;
    self.posTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.posTextLabel];

    self.tagsView = [[BGGTagWrapView alloc] init];
    self.tagsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.tagsView];

    self.idLabel = [[UILabel alloc] init];
    self.idLabel.font      = [UIFont monospacedSystemFontOfSize:10.0 weight:UIFontWeightRegular];
    self.idLabel.textColor = [UIColor tertiaryLabelColor];
    self.idLabel.numberOfLines = 1;
    self.idLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.idLabel];

    self.difficultyLabel = [[UILabel alloc] init];
    self.difficultyLabel.font      = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    self.difficultyLabel.textColor = [UIColor secondaryLabelColor];
    self.difficultyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.difficultyLabel];

    [NSLayoutConstraint activateConstraints:@[
        // Board: top left, fixed size
        [self.boardView.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor
                                                      constant:pad],
        [self.boardView.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor
                                                      constant:pad],
        [self.boardView.widthAnchor    constraintEqualToConstant:kBoardWidth],
        [self.boardView.heightAnchor   constraintEqualToConstant:kBoardWidth * (kBGGBoardHeight / kBGGBoardWidth)],

        // Caption: top right
        [self.captionLabel.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor
                                                         constant:pad],
        [self.captionLabel.leadingAnchor  constraintEqualToAnchor:self.boardView.trailingAnchor
                                                         constant:pad],
        [self.captionLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor
                                                         constant:-pad],

        // Text below caption
        [self.posTextLabel.topAnchor      constraintEqualToAnchor:self.captionLabel.bottomAnchor
                                                         constant:3.0],
        [self.posTextLabel.leadingAnchor  constraintEqualToAnchor:self.captionLabel.leadingAnchor],
        [self.posTextLabel.trailingAnchor constraintEqualToAnchor:self.captionLabel.trailingAnchor],

        // Tags below text
        [self.tagsView.topAnchor      constraintEqualToAnchor:self.posTextLabel.bottomAnchor
                                                     constant:6.0],
        [self.tagsView.leadingAnchor  constraintEqualToAnchor:self.captionLabel.leadingAnchor],
        [self.tagsView.trailingAnchor constraintEqualToAnchor:self.captionLabel.trailingAnchor],

        // Difficulty dots: bottom left of right column
        [self.difficultyLabel.bottomAnchor  constraintEqualToAnchor:self.contentView.bottomAnchor
                                                           constant:-pad],
        [self.difficultyLabel.leadingAnchor constraintEqualToAnchor:self.captionLabel.leadingAnchor],

        // ID + copy button: bottom right
        [self.boardIDView.bottomAnchor   constraintEqualToAnchor:self.contentView.bottomAnchor
                                                        constant:-pad],
        [self.boardIDView.leadingAnchor  constraintEqualToAnchor:self.difficultyLabel.trailingAnchor
                                                        constant:8.0],
        [self.boardIDView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor
                                                        constant:-pad],
    ]];
}

- (void)configureWithEntry:(BGGPositionEntry *)entry design:(NSString *)design
{
    self.boardView.boardDesign = design;
    self.boardView.boardState  = [entry boardState];
    [self.boardIDView updateWithBoardState:[entry boardState]];
    self.captionLabel.text     = entry.caption.length > 0 ? entry.caption : @"";
    self.posTextLabel.text     = entry.text.length > 0 ? entry.text : @"";
    self.idLabel.text          = entry.positionID;

    NSMutableString *dots = [NSMutableString string];
    for (NSInteger i = 0; i < entry.difficulty; i++)  { [dots appendString:@"●"]; }
    for (NSInteger i = entry.difficulty; i < 3; i++)   { [dots appendString:@"○"]; }
    self.difficultyLabel.text = dots;

    [self.tagsView setTags:entry.tags];
}

@end

// MARK: - ViewController

@interface PositionBrowserVC () <UITableViewDataSource, UITableViewDelegate,
                                  BGGPositionEditorDelegate>
@property (nonatomic, strong) UIScrollView                *tagScrollView;
@property (nonatomic, strong) UIStackView                 *tagStack;
@property (nonatomic, strong) UITableView                 *tableView;
@property (nonatomic, strong) NSArray<BGGPositionEntry *> *allPositions;
@property (nonatomic, strong) NSArray<BGGPositionEntry *> *filteredPositions;
@property (nonatomic, copy)   NSString                    *activeTag;
@end

@implementation PositionBrowserVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Positions";
    [self installHomeButton];

    // Add button (right)
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                   target:self
                                                   action:@selector(addTapped)];
    addBtn.tintColor = [UIColor colorNamed:@"AccentColor"];

    // Export button (right, next to Add)
    UIBarButtonItem *exportBtn = [[UIBarButtonItem alloc]
                                  initWithImage:[UIImage systemImageNamed:@"square.and.arrow.up"]
                                          style:UIBarButtonItemStylePlain
                                         target:self
                                         action:@selector(exportTapped)];
    exportBtn.tintColor = [UIColor colorNamed:@"AccentColor"];

    self.navigationItem.rightBarButtonItems = @[addBtn, exportBtn];

    self.allPositions      = [[PositionDatabase sharedDatabase] allPositions];
    self.filteredPositions = self.allPositions;

    [self buildTagBar];
    [self buildTableView];
}

#pragma mark - Tag bar

- (void)buildTagBar
{
    self.tagScrollView = [[UIScrollView alloc] init];
    self.tagScrollView.showsHorizontalScrollIndicator = NO;
    self.tagScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tagScrollView];

    self.tagStack = [[UIStackView alloc] init];
    self.tagStack.axis    = UILayoutConstraintAxisHorizontal;
    self.tagStack.spacing = 8.0;
    self.tagStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tagScrollView addSubview:self.tagStack];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.tagScrollView.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:8.0],
        [self.tagScrollView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:12.0],
        [self.tagScrollView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12.0],
        [self.tagScrollView.heightAnchor   constraintEqualToConstant:36.0],

        // Stack pins to the scroll view's content layout guide on all sides.
        // This defines the scrollable content width so it can scroll horizontally.
        [self.tagStack.topAnchor      constraintEqualToAnchor:self.tagScrollView.contentLayoutGuide.topAnchor],
        [self.tagStack.bottomAnchor   constraintEqualToAnchor:self.tagScrollView.contentLayoutGuide.bottomAnchor],
        [self.tagStack.leadingAnchor  constraintEqualToAnchor:self.tagScrollView.contentLayoutGuide.leadingAnchor],
        [self.tagStack.trailingAnchor constraintEqualToAnchor:self.tagScrollView.contentLayoutGuide.trailingAnchor],
        [self.tagStack.heightAnchor   constraintEqualToAnchor:self.tagScrollView.frameLayoutGuide.heightAnchor],
    ]];

    NSMutableOrderedSet *tagSet = [NSMutableOrderedSet orderedSet];
    for (BGGPositionEntry *e in self.allPositions) { [tagSet addObjectsFromArray:e.tags]; }
    [self.tagStack addArrangedSubview:[self tagChipWithTitle:@"All" tag:nil]];
    for (NSString *tag in tagSet)
    {
        [self.tagStack addArrangedSubview:[self tagChipWithTitle:tag tag:tag]];
    }
}

- (UIButton *)tagChipWithTitle:(NSString *)title tag:(nullable NSString *)tag
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font    = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    btn.layer.cornerRadius = 14.0;
    btn.layer.borderWidth  = 1.0;
    // contentEdgeInsets is deprecated in iOS 15 but the configuration API
    // would override the manual background/border styling in applyChipStyle:.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    btn.contentEdgeInsets  = UIEdgeInsetsMake(4, 12, 4, 12);
#pragma clang diagnostic pop
    btn.accessibilityIdentifier = tag ?: @"";
    [btn addTarget:self action:@selector(tagChipTapped:)
  forControlEvents:UIControlEventTouchUpInside];
    [self applyChipStyle:btn active:(tag == nil)];
    return btn;
}

- (void)applyChipStyle:(UIButton *)btn active:(BOOL)active
{
    UIColor *accent = [UIColor colorNamed:@"AccentColor"] ?: [UIColor systemRedColor];
    if (active)
    {
        btn.backgroundColor = accent;
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.layer.borderColor = accent.CGColor;
    }
    else
    {
        btn.backgroundColor = [UIColor clearColor];
        [btn setTitleColor:accent forState:UIControlStateNormal];
        btn.layer.borderColor = [accent colorWithAlphaComponent:0.4].CGColor;
    }
}

- (void)tagChipTapped:(UIButton *)sender
{
    NSString *tag = sender.accessibilityIdentifier;
    self.activeTag = (tag.length > 0) ? tag : nil;

    for (UIView *v in self.tagStack.arrangedSubviews)
    {
        if (![v isKindOfClass:[UIButton class]]) { continue; }
        UIButton *chip = (UIButton *)v;
        NSString *chipTag = chip.accessibilityIdentifier;
        BOOL isActive = (self.activeTag == nil && chipTag.length == 0)
                      || [chipTag isEqualToString:self.activeTag ?: @""];
        [self applyChipStyle:chip active:isActive];
    }

    self.filteredPositions = self.activeTag == nil
        ? self.allPositions
        : [self.allPositions filteredArrayUsingPredicate:
           [NSPredicate predicateWithFormat:@"tags CONTAINS %@", self.activeTag]];
    [self.tableView reloadData];
}

#pragma mark - Table view

- (void)buildTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                  style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource         = self;
    self.tableView.delegate           = self;
    self.tableView.rowHeight          = kRowHeight;
    self.tableView.estimatedRowHeight = kRowHeight;
    self.tableView.separatorInset     = UIEdgeInsetsMake(0, kBoardWidth + 16.0, 0, 0);
    [self.tableView registerClass:[PositionBrowserCell class]
           forCellReuseIdentifier:kCellID];
    [self.view addSubview:self.tableView];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor      constraintEqualToAnchor:self.tagScrollView.bottomAnchor
                                                      constant:8.0],
        [self.tableView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.tableView.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],
    ]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)self.filteredPositions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PositionBrowserCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID
                                                                forIndexPath:indexPath];
    BGGPositionEntry *entry = self.filteredPositions[(NSUInteger)indexPath.row];
    [cell configureWithEntry:entry design:[Tools currentBoardDesign]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

// Tap → Edit
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    BGGPositionEntry *entry = self.filteredPositions[(NSUInteger)indexPath.row];
    [self openEditorForEntry:entry];
}

// Swipe to delete
- (BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath { return YES; }

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete) { return; }

    BGGPositionEntry *entry = self.filteredPositions[(NSUInteger)indexPath.row];
    [[PositionDatabase sharedDatabase] removeEntryWithPositionID:entry.positionID];
    [self reloadData];
}

#pragma mark - Add / Export

- (void)addTapped
{
    [self openEditorForEntry:nil];
}

- (void)exportTapped
{
    NSURL *url = [[PositionDatabase sharedDatabase] documentsJSONURL];
    UIActivityViewController *share = [[UIActivityViewController alloc]
                                       initWithActivityItems:@[url]
                                       applicationActivities:nil];
    share.popoverPresentationController.barButtonItem =
        self.navigationItem.rightBarButtonItems.firstObject;
    [self presentViewController:share animated:YES completion:nil];
}

- (void)openEditorForEntry:(nullable BGGPositionEntry *)entry
{
    BGGPositionEditorVC *editor = [[BGGPositionEditorVC alloc] initWithEntry:entry];
    editor.delegate = self;
    [self.navigationController pushViewController:editor animated:YES];
}

#pragma mark - BGGPositionEditorDelegate

- (void)editorDidSaveEntry:(BGGPositionEntry *)entry isNewEntry:(BOOL)isNew
{
    [self reloadData];
}

#pragma mark - Reload

- (void)reloadData
{
    self.allPositions = [[PositionDatabase sharedDatabase] allPositions];
    if (self.activeTag)
    {
        self.filteredPositions = [self.allPositions filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"tags CONTAINS %@", self.activeTag]];
    }
    else
    {
        self.filteredPositions = self.allPositions;
    }
    [self.tableView reloadData];
}

@end
