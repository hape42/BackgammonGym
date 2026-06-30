//
//  PositionBrowserVC.m
//  BackgammonGym
//
//  Visual browser for positions.json.
//  Each position is shown as a BGGBoardCard (same size as Warm-up),
//  with tags and the GNU combined ID below it.
//  A tag filter bar at the top narrows the list.
//

#import "PositionBrowserVC.h"
#import "PositionDatabase.h"
#import "BGGBoardCard.h"
#import "BGGBoardIDView.h"
#import "BGGBoardState.h"
#import "BGGBoardGeometry.h"
#import "Tools.h"
#import "UIViewController+BGGHomeButton.h"
#import "BGGPositionEditorVC.h"

// MARK: - Position card view

// One card: BGGBoardCard + tag chips + ID view + optional edit/delete buttons.
@interface BGGPositionCardView : UIView

- (instancetype)initWithEntry:(BGGPositionEntry *)entry
                       design:(NSString *)design
                   editTarget:(id)target
                   editAction:(SEL)editAction
                 deleteTarget:(id)target2
                 deleteAction:(SEL)deleteAction;

@property (nonatomic, strong, readonly) BGGPositionEntry *entry;

@end

@implementation BGGPositionCardView

- (instancetype)initWithEntry:(BGGPositionEntry *)entry
                       design:(NSString *)design
                   editTarget:(id)editTarget
                   editAction:(SEL)editAction
                 deleteTarget:(id)deleteTarget
                 deleteAction:(SEL)deleteAction
{
    self = [super init];
    if (!self) { return nil; }
    _entry = entry;

    self.translatesAutoresizingMaskIntoConstraints = NO;

    // Separator line at top
    UIView *sep = [[UIView alloc] init];
    sep.backgroundColor = [UIColor separatorColor];
    sep.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:sep];

    // Board card (same component as Warm-up)
    BGGBoardCard *card = [[BGGBoardCard alloc]
                          initWithCaption:entry.caption
                          explanationText:entry.text
                               boardState:[entry boardState]];
    card.boardDesign = design;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:card];

    // Tag chips row
    UIView *tagsRow = [self buildTagsRowForEntry:entry];
    [self addSubview:tagsRow];

    // ID + copy button. Show the exact ID from the JSON so it can be pasted
    // straight back into BGBlitz – not a re-encoded version of the board.
    BGGBoardIDView *idView = [[BGGBoardIDView alloc] init];
    idView.translatesAutoresizingMaskIntoConstraints = NO;
    [idView updateWithID:entry.positionID];
    [self addSubview:idView];

    // Edit / Delete buttons
    UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [editBtn setTitle:@"Edit" forState:UIControlStateNormal];
    editBtn.tintColor = [UIColor colorNamed:@"AccentColor"] ?: [UIColor systemRedColor];
    editBtn.translatesAutoresizingMaskIntoConstraints = NO;
    editBtn.accessibilityIdentifier = entry.positionID;
    [editBtn addTarget:editTarget action:editAction
      forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:editBtn];

    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [deleteBtn setTitle:@"Delete" forState:UIControlStateNormal];
    deleteBtn.tintColor = [UIColor systemRedColor];
    deleteBtn.translatesAutoresizingMaskIntoConstraints = NO;
    deleteBtn.accessibilityIdentifier = entry.positionID;
    [deleteBtn addTarget:deleteTarget action:deleteAction
       forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:deleteBtn];

    CGFloat m = 16.0;

    [NSLayoutConstraint activateConstraints:@[
        // Separator
        [sep.topAnchor     constraintEqualToAnchor:self.topAnchor],
        [sep.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [sep.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [sep.heightAnchor  constraintEqualToConstant:0.5],

        // Board card
        [card.topAnchor     constraintEqualToAnchor:sep.bottomAnchor constant:m],
        [card.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:m],
        [card.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-m],

        // Tags
        [tagsRow.topAnchor     constraintEqualToAnchor:card.bottomAnchor constant:8.0],
        [tagsRow.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:m],
        [tagsRow.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-m],

        // ID view
        [idView.topAnchor     constraintEqualToAnchor:tagsRow.bottomAnchor constant:6.0],
        [idView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:m],
        [idView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-m],

        // Edit / Delete buttons
        [editBtn.topAnchor    constraintEqualToAnchor:idView.bottomAnchor constant:4.0],
        [editBtn.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:m],
        [editBtn.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-m],

        [deleteBtn.topAnchor    constraintEqualToAnchor:editBtn.topAnchor],
        [deleteBtn.leadingAnchor constraintEqualToAnchor:editBtn.trailingAnchor constant:16.0],
        [deleteBtn.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-m],
    ]];

    return self;
}

- (UIView *)buildTagsRowForEntry:(BGGPositionEntry *)entry
{
    UIView *row = [[UIView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;

    UIColor *accent = [UIColor colorNamed:@"AccentColor"] ?: [UIColor systemRedColor];
    CGFloat x = 0, chipH = 22.0, gap = 6.0;

    for (NSString *tag in entry.tags)
    {
        UILabel *chip = [[UILabel alloc] init];
        chip.text            = tag;
        chip.font            = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
        chip.textColor       = accent;
        chip.backgroundColor = [accent colorWithAlphaComponent:0.12];
        chip.layer.cornerRadius = 5.0;
        chip.clipsToBounds   = YES;
        chip.textAlignment   = NSTextAlignmentCenter;
        [chip sizeToFit];
        CGFloat w = chip.bounds.size.width + 12.0;
        chip.frame = CGRectMake(x, 0, w, chipH);
        [row addSubview:chip];
        x += w + gap;
    }

    [row.heightAnchor constraintEqualToConstant:chipH].active = YES;
    return row;
}

@end

// MARK: - ViewController

@interface PositionBrowserVC () <BGGPositionEditorDelegate>
@property (nonatomic, strong) UIScrollView                *tagScrollView;
@property (nonatomic, strong) UIStackView                 *tagStack;
@property (nonatomic, strong) UIScrollView                *scrollView;
@property (nonatomic, strong) UIStackView                 *cardStack;
@property (nonatomic, strong) NSArray<BGGPositionEntry *> *allPositions;
@property (nonatomic, strong) NSArray<BGGPositionEntry *> *filteredPositions;
@property (nonatomic, strong)  NSMutableSet<NSString *>      *activeTags;
// Extra filter dimensions beyond tags, combined with AND. noTextOnly keeps
// only positions whose explanation is empty; activeDifficulty (0 = any, or
// 1/2/3) keeps only that difficulty. Both are driven by special chips marked
// with a "§" prefix in their identifier so they don't collide with real tags.
@property (nonatomic, assign)  BOOL                          noTextOnly;
@property (nonatomic, assign)  NSInteger                     activeDifficulty;
// Map from positionID to entry for edit/delete button callbacks
@property (nonatomic, strong) NSMutableDictionary<NSString *, BGGPositionEntry *> *entryByPositionID;
@end

@implementation PositionBrowserVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Positions";

    self.entryByPositionID = [NSMutableDictionary dictionary];

    // Right: Add + Export
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                   target:self
                                                   action:@selector(addTapped)];
    addBtn.tintColor = [UIColor colorNamed:@"AccentColor"];
    UIBarButtonItem *exportBtn = [[UIBarButtonItem alloc]
                                  initWithImage:[UIImage systemImageNamed:@"square.and.arrow.up"]
                                          style:UIBarButtonItemStylePlain
                                         target:self
                                         action:@selector(exportTapped)];
    exportBtn.tintColor = [UIColor colorNamed:@"AccentColor"];
    self.navigationItem.rightBarButtonItems = @[addBtn, exportBtn];

    [self updateLeftBarButtons];

    self.allPositions      = [[PositionDatabase sharedDatabase] allPositions];
    self.filteredPositions = self.allPositions;
    self.activeTags        = [NSMutableSet set];
    self.noTextOnly        = NO;
    self.activeDifficulty  = 0;

    [self buildTagBar];
    [self buildScrollView];
    [self rebuildCards];
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

        [self.tagStack.topAnchor     constraintEqualToAnchor:self.tagScrollView.contentLayoutGuide.topAnchor],
        [self.tagStack.bottomAnchor  constraintEqualToAnchor:self.tagScrollView.contentLayoutGuide.bottomAnchor],
        [self.tagStack.leadingAnchor constraintEqualToAnchor:self.tagScrollView.contentLayoutGuide.leadingAnchor],
        [self.tagStack.trailingAnchor constraintEqualToAnchor:self.tagScrollView.contentLayoutGuide.trailingAnchor],
        [self.tagStack.heightAnchor  constraintEqualToAnchor:self.tagScrollView.frameLayoutGuide.heightAnchor],
    ]];

    NSMutableOrderedSet *tagSet = [NSMutableOrderedSet orderedSet];
    for (BGGPositionEntry *e in self.allPositions) { [tagSet addObjectsFromArray:e.tags]; }
    [self.tagStack addArrangedSubview:[self tagChipWithTitle:@"All" tag:nil]];
    for (NSString *tag in tagSet)
    {
        [self.tagStack addArrangedSubview:[self tagChipWithTitle:tag tag:tag]];
    }

    // Special, non-tag filters (AND-combined with the tags). Marked with a
    // "§" prefix so tagChipTapped: can tell them apart from real tags.
    [self.tagStack addArrangedSubview:[self tagChipWithTitle:@"no text" tag:@"§notext"]];
    [self.tagStack addArrangedSubview:[self tagChipWithTitle:@"D1" tag:@"§diff1"]];
    [self.tagStack addArrangedSubview:[self tagChipWithTitle:@"D2" tag:@"§diff2"]];
    [self.tagStack addArrangedSubview:[self tagChipWithTitle:@"D3" tag:@"§diff3"]];
}

- (UIButton *)tagChipWithTitle:(NSString *)title tag:(nullable NSString *)tag
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font    = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    btn.layer.cornerRadius = 14.0;
    btn.layer.borderWidth  = 1.0;
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

    if (tag.length == 0)
    {
        // The "All" chip clears everything: tags and the special filters.
        [self.activeTags removeAllObjects];
        self.noTextOnly       = NO;
        self.activeDifficulty = 0;
    }
    else if ([tag isEqualToString:@"§notext"])
    {
        self.noTextOnly = !self.noTextOnly;   // toggle
    }
    else if ([tag hasPrefix:@"§diff"])
    {
        NSInteger d = [[tag substringFromIndex:5] integerValue];   // 1/2/3
        // Tapping the active difficulty turns it off; another replaces it.
        self.activeDifficulty = (self.activeDifficulty == d) ? 0 : d;
    }
    else if ([self.activeTags containsObject:tag])
    {
        [self.activeTags removeObject:tag];   // tapping an active tag turns it off
    }
    else
    {
        [self.activeTags addObject:tag];
    }

    [self refreshChipStyles];
    [self applyFilter];
    [self rebuildCards];
}

// Highlights every chip whose filter is active; the "All" chip is highlighted
// only when nothing at all is selected (no tags, no text filter, no difficulty).
- (void)refreshChipStyles
{
    BOOL nothingActive = (self.activeTags.count == 0
                          && !self.noTextOnly
                          && self.activeDifficulty == 0);

    for (UIView *v in self.tagStack.arrangedSubviews)
    {
        if (![v isKindOfClass:[UIButton class]]) { continue; }
        UIButton *chip = (UIButton *)v;
        NSString *chipTag = chip.accessibilityIdentifier;

        BOOL isActive;
        if (chipTag.length == 0)
        {
            isActive = nothingActive;                      // "All"
        }
        else if ([chipTag isEqualToString:@"§notext"])
        {
            isActive = self.noTextOnly;
        }
        else if ([chipTag hasPrefix:@"§diff"])
        {
            isActive = (self.activeDifficulty == [[chipTag substringFromIndex:5] integerValue]);
        }
        else
        {
            isActive = [self.activeTags containsObject:chipTag];
        }
        [self applyChipStyle:chip active:isActive];
    }
}

// Filters to positions matching ALL active criteria (AND): every selected
// tag, plus the no-text filter and the difficulty filter when set. With
// nothing selected, shows everything.
- (void)applyFilter
{
    NSMutableArray<NSPredicate *> *subs = [NSMutableArray array];

    for (NSString *tag in self.activeTags)
    {
        [subs addObject:[NSPredicate predicateWithFormat:@"tags CONTAINS %@", tag]];
    }

    if (self.activeDifficulty != 0)
    {
        [subs addObject:[NSPredicate predicateWithFormat:@"difficulty == %ld",
                         (long)self.activeDifficulty]];
    }

    if (subs.count == 0 && !self.noTextOnly)
    {
        self.filteredPositions = self.allPositions;   // nothing selected
        return;
    }

    NSArray<BGGPositionEntry *> *result = self.allPositions;
    if (subs.count > 0)
    {
        NSPredicate *all = [NSCompoundPredicate andPredicateWithSubpredicates:subs];
        result = [result filteredArrayUsingPredicate:all];
    }

    // "no text" isn't a key-path predicate (it needs trimming), so filter it
    // in code on top of the predicate result.
    if (self.noTextOnly)
    {
        NSMutableArray<BGGPositionEntry *> *withoutText = [NSMutableArray array];
        for (BGGPositionEntry *e in result)
        {
            NSString *t = [e.text stringByTrimmingCharactersInSet:
                           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (t.length == 0) { [withoutText addObject:e]; }
        }
        result = withoutText;
    }

    self.filteredPositions = result;
}

#pragma mark - Scroll view + cards

- (void)buildScrollView
{
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];

    self.cardStack = [[UIStackView alloc] init];
    self.cardStack.axis    = UILayoutConstraintAxisVertical;
    self.cardStack.spacing = 0;
    self.cardStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.cardStack];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor      constraintEqualToAnchor:self.tagScrollView.bottomAnchor
                                                       constant:8.0],
        [self.scrollView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.scrollView.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],

        [self.cardStack.topAnchor      constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [self.cardStack.leadingAnchor  constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [self.cardStack.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [self.cardStack.bottomAnchor   constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [self.cardStack.widthAnchor    constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor],
    ]];
}

- (void)rebuildCards
{
    // Keep the title in step with what is actually shown: "Positions (N)",
    // where N is the count after the current tag filter. When some of those
    // positions have no explanation text yet, append "· M without text" as a
    // progress hint. Both counts are over the filtered set, so filtering by a
    // tag shows how many gaps remain within that group. (Note: cluster
    // positions keep their text in the catalog by convention, so an empty JSON
    // text there is expected, not a real gap.)
    NSUInteger missing = 0;
    for (BGGPositionEntry *e in self.filteredPositions)
    {
        NSString *t = [e.text stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (t.length == 0) { missing++; }
    }

    if (missing > 0)
    {
        self.title = [NSString stringWithFormat:@"Positions (%lu · %lu without text)",
                      (unsigned long)self.filteredPositions.count,
                      (unsigned long)missing];
    }
    else
    {
        self.title = [NSString stringWithFormat:@"Positions (%lu)",
                      (unsigned long)self.filteredPositions.count];
    }

    // Remove old cards. Copy the array first – removing while iterating over
    // arrangedSubviews skips elements and leaves stale cards behind.
    NSArray *oldCards = [self.cardStack.arrangedSubviews copy];
    for (UIView *v in oldCards)
    {
        [self.cardStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [self.entryByPositionID removeAllObjects];

    NSString *design = [Tools currentBoardDesign];

    for (BGGPositionEntry *entry in self.filteredPositions)
    {
        self.entryByPositionID[entry.positionID] = entry;

        BGGPositionCardView *card = [[BGGPositionCardView alloc]
                                     initWithEntry:entry
                                            design:design
                                        editTarget:self
                                        editAction:@selector(editButtonTapped:)
                                      deleteTarget:self
                                      deleteAction:@selector(deleteButtonTapped:)];
        [self.cardStack addArrangedSubview:card];
    }
}

#pragma mark - Edit / Delete button callbacks

- (void)editButtonTapped:(UIButton *)sender
{
    BGGPositionEntry *entry = self.entryByPositionID[sender.accessibilityIdentifier];
    if (entry) { [self openEditorForEntry:entry]; }
}

- (void)deleteButtonTapped:(UIButton *)sender
{
    BGGPositionEntry *entry = self.entryByPositionID[sender.accessibilityIdentifier];
    if (!entry) { return; }

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Delete position?"
                         message:entry.caption.length > 0 ? entry.caption : entry.positionID
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *a) {
        [[PositionDatabase sharedDatabase] removeEntryWithPositionID:entry.positionID];
        [self reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Add / Export / Reset

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

- (void)resetTapped
{
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Reset to bundle?"
                         message:@"This deletes your local edits and reloads the "
                                  "positions shipped with the app. Export first if "
                                  "you want to keep your changes."
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *a) {
        [[PositionDatabase sharedDatabase] resetToBundle];
        [self reloadData];
        [self updateLeftBarButtons];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
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
    [self updateLeftBarButtons];
}

#pragma mark - Left bar buttons

- (void)updateLeftBarButtons
{
    [self installHomeButton];
    if ([[PositionDatabase sharedDatabase] isEditingMode])
    {
        UIBarButtonItem *homeItem = self.navigationItem.leftBarButtonItem;
        UIBarButtonItem *resetBtn = [[UIBarButtonItem alloc]
                                     initWithImage:[UIImage systemImageNamed:@"arrow.counterclockwise"]
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(resetTapped)];
        resetBtn.tintColor = [UIColor colorNamed:@"AccentColor"];
        self.navigationItem.leftBarButtonItems = @[homeItem, resetBtn];
    }
}

#pragma mark - Reload

- (void)reloadData
{
    self.allPositions = [[PositionDatabase sharedDatabase] allPositions];
    // A tag may have disappeared if its last position was deleted; drop any
    // active tags that no longer exist so the filter stays valid.
    NSMutableSet<NSString *> *stillPresent = [NSMutableSet set];
    for (BGGPositionEntry *e in self.allPositions) { [stillPresent addObjectsFromArray:e.tags]; }
    [self.activeTags intersectSet:stillPresent];

    [self applyFilter];
    [self refreshChipStyles];
    [self rebuildCards];
}

@end
