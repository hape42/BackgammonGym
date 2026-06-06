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

    // ID + copy button
    BGGBoardIDView *idView = [[BGGBoardIDView alloc] init];
    idView.translatesAutoresizingMaskIntoConstraints = NO;
    [idView updateWithBoardState:[entry boardState]];
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
@property (nonatomic, copy)   NSString                    *activeTag;
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

    [self rebuildCards];
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
    self.filteredPositions = self.activeTag
        ? [self.allPositions filteredArrayUsingPredicate:
           [NSPredicate predicateWithFormat:@"tags CONTAINS %@", self.activeTag]]
        : self.allPositions;
    [self rebuildCards];
}

@end
