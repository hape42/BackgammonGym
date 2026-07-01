//
//  BGGPositionEditorVC.m
//  BackgammonGym
//

#import "BGGPositionEditorVC.h"
#import "BGGBoardView.h"
#import "BGGBoardGeometry.h"
#import "BGGPosition.h"
#import "BGGBoardState.h"
#import "Tools.h"

static const NSUInteger kMaxTags = 5;

// Known tags shown as chips – user can add more via text field.
static NSArray<NSString *> * defaultTags(void)
{
    return @[@"race", @"contact", @"bearoff", @"pipcount", @"cluster",
             @"holding", @"backgame", @"prime"];
}

@interface BGGPositionEditorVC () <UITextFieldDelegate, UITextViewDelegate>

// Builder
@property (nonatomic, strong) BGGPositionEntryBuilder *builder;
@property (nonatomic, assign) BOOL isNewEntry;

// Board preview
@property (nonatomic, strong) BGGBoardView  *boardView;
@property (nonatomic, strong) UILabel       *boardStatusLabel;

// Scroll view
@property (nonatomic, strong) UIScrollView  *scrollView;
@property (nonatomic, strong) UIView        *contentView;

// Form fields
@property (nonatomic, strong) UITextField   *idField;
@property (nonatomic, strong) UITextField   *captionField;
@property (nonatomic, strong) UITextView    *textView;
@property (nonatomic, strong) UITextView    *noteView;

// Difficulty buttons
@property (nonatomic, strong) NSArray<UIButton *> *diffButtons;

// Tags
@property (nonatomic, strong) NSMutableArray<NSString *> *availableTags;
@property (nonatomic, strong) UIView        *tagsWrapView;
@property (nonatomic, strong) UITextField   *aNewTagField;

@end

@implementation BGGPositionEditorVC

- (instancetype)initWithEntry:(nullable BGGPositionEntry *)entry
{
    self = [super init];
    if (self)
    {
        if (entry)
        {
            _builder = [BGGPositionEntryBuilder builderFromEntry:entry];
            _isNewEntry = NO;
        }
        else
        {
            _builder = [[BGGPositionEntryBuilder alloc] init];
            _isNewEntry = YES;
        }

        // Collect all tags already in the database plus defaults
        NSMutableOrderedSet *tagSet = [NSMutableOrderedSet orderedSetWithArray:defaultTags()];
        for (BGGPositionEntry *e in [[PositionDatabase sharedDatabase] allPositions])
        {
            [tagSet addObjectsFromArray:e.tags];
        }
        _availableTags = [[tagSet array] mutableCopy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.title = self.isNewEntry ? @"Add Position" : @"Edit Position";

    [self setupNavigationButtons];
    [self buildUI];
    [self populateFields];
    [self updateBoardPreview];
    [self updateTagChips];
}

#pragma mark - Navigation buttons

- (void)setupNavigationButtons
{
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                   target:self
                                                   action:@selector(cancelTapped)];
    cancel.tintColor = [UIColor colorNamed:@"AccentColor"];
    self.navigationItem.leftBarButtonItem = cancel;
    self.navigationItem.hidesBackButton   = YES;

    UIBarButtonItem *save = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                 target:self
                                                 action:@selector(saveTapped)];
    save.tintColor = [UIColor colorNamed:@"AccentColor"];
    self.navigationItem.rightBarButtonItem = save;
}

- (void)cancelTapped
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UI

- (void)buildUI
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

    CGFloat m = 16.0, s = 12.0;

    // ── Board preview ──────────────────────────────────────────────────
    self.boardView = [[BGGBoardView alloc] init];
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardView.boardDesign       = [Tools currentBoardDesign];
    self.boardView.showsPointNumbers = YES;
    self.boardView.showsCube         = YES;
    self.boardView.showsDice         = YES;
    [self.contentView addSubview:self.boardView];

    CGFloat boardW = MIN(400.0, UIScreen.mainScreen.bounds.size.width - 2 * m);
    CGFloat boardH = boardW * (kBGGBoardHeight / kBGGBoardWidth);

    [NSLayoutConstraint activateConstraints:@[
        [self.boardView.topAnchor     constraintEqualToAnchor:self.contentView.topAnchor
                                                     constant:m],
        [self.boardView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.boardView.widthAnchor   constraintEqualToConstant:boardW],
        [self.boardView.heightAnchor  constraintEqualToConstant:boardH],
    ]];

    // Board status (shows "Invalid ID" etc.)
    self.boardStatusLabel = [self smallLabel:@"Enter a GNU Position ID above to preview the board"];
    [self.contentView addSubview:self.boardStatusLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.boardStatusLabel.topAnchor     constraintEqualToAnchor:self.boardView.bottomAnchor
                                                            constant:4.0],
        [self.boardStatusLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor
                                                            constant:m],
        [self.boardStatusLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor
                                                             constant:-m],
    ]];

    // ── Position ID ────────────────────────────────────────────────────
    UILabel *idHeader = [self sectionHeader:@"Position ID (GNU format, posID:matchID)"];
    [self.contentView addSubview:idHeader];
    [self pinView:idHeader below:self.boardStatusLabel offset:m leading:m trailing:-m inView:self.contentView];

    self.idField = [self textFieldWithPlaceholder:@"e.g. 4HPwATDgc/ABMA:QYkqAS..."];
    self.idField.font          = [UIFont monospacedSystemFontOfSize:13.0 weight:UIFontWeightRegular];
    self.idField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.idField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.idField.delegate      = self;
    [self.contentView addSubview:self.idField];
    [self pinView:self.idField below:idHeader offset:s leading:m trailing:-m inView:self.contentView];
    [self.idField.heightAnchor constraintEqualToConstant:44.0].active = YES;

    // ── Caption ────────────────────────────────────────────────────────
    UILabel *captionHeader = [self sectionHeader:@"Caption (shown in app)"];
    [self.contentView addSubview:captionHeader];
    [self pinView:captionHeader below:self.idField offset:m leading:m trailing:-m inView:self.contentView];

    self.captionField = [self textFieldWithPlaceholder:@"e.g. Starting position"];
    self.captionField.delegate = self;
    [self.contentView addSubview:self.captionField];
    [self pinView:self.captionField below:captionHeader offset:s leading:m trailing:-m inView:self.contentView];
    [self.captionField.heightAnchor constraintEqualToConstant:44.0].active = YES;

    // ── Text ───────────────────────────────────────────────────────────
    UILabel *textHeader = [self sectionHeader:@"Explanation text (shown in app)"];
    [self.contentView addSubview:textHeader];
    [self pinView:textHeader below:self.captionField offset:m leading:m trailing:-m inView:self.contentView];

    self.textView = [self textViewWithPlaceholder:@"Explanation shown next to the board…"];
    [self.contentView addSubview:self.textView];
    [self pinView:self.textView below:textHeader offset:s leading:m trailing:-m inView:self.contentView];
    // The didactic explanations run long (a dozen lines or more). 80pt only
    // showed three or four lines, so editing them meant peering through a
    // slot. Give the field room to show most of a typical text at once; the
    // rest scrolls inside the text view. Press Return for real line breaks –
    // NSJSONSerialization stores them as \n in positions.json automatically.
    [self.textView.heightAnchor constraintEqualToConstant:240.0].active = YES;

    // ── Difficulty ─────────────────────────────────────────────────────
    UILabel *diffHeader = [self sectionHeader:@"Difficulty"];
    [self.contentView addSubview:diffHeader];
    [self pinView:diffHeader below:self.textView offset:m leading:m trailing:-m inView:self.contentView];

    UIStackView *diffStack = [[UIStackView alloc] init];
    diffStack.axis         = UILayoutConstraintAxisHorizontal;
    diffStack.spacing      = 8.0;
    diffStack.distribution = UIStackViewDistributionFillEqually;
    diffStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:diffStack];
    [self pinView:diffStack below:diffHeader offset:s leading:m trailing:-m inView:self.contentView];
    [diffStack.heightAnchor constraintEqualToConstant:44.0].active = YES;

    NSArray *diffTitles = @[@"1 – Easy", @"2 – Medium", @"3 – Hard"];
    NSMutableArray *diffBtns = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; i++)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:diffTitles[i] forState:UIControlStateNormal];
        btn.layer.cornerRadius = 8.0;
        btn.layer.borderWidth  = 1.0;
        btn.tag = i + 1;
        [btn addTarget:self action:@selector(diffTapped:)
      forControlEvents:UIControlEventTouchUpInside];
        [diffStack addArrangedSubview:btn];
        [diffBtns addObject:btn];
    }
    self.diffButtons = [diffBtns copy];

    // ── Tags ───────────────────────────────────────────────────────────
    UILabel *tagsHeader = [self sectionHeader:@"Tags (max 5)"];
    [self.contentView addSubview:tagsHeader];
    [self pinView:tagsHeader below:diffStack offset:m leading:m trailing:-m inView:self.contentView];

    self.tagsWrapView = [[UIView alloc] init];
    self.tagsWrapView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.tagsWrapView];
    [self pinView:self.tagsWrapView below:tagsHeader offset:s leading:m trailing:-m inView:self.contentView];
    [self.tagsWrapView.heightAnchor constraintGreaterThanOrEqualToConstant:32.0].active = YES;

    // New tag field
    UILabel *newTagHeader = [self sectionHeader:@"Add new tag"];
    [self.contentView addSubview:newTagHeader];
    [self pinView:newTagHeader below:self.tagsWrapView offset:m leading:m trailing:-m inView:self.contentView];

    self.aNewTagField = [self textFieldWithPlaceholder:@"Type tag name and press Return…"];
    self.aNewTagField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.aNewTagField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.aNewTagField.returnKeyType = UIReturnKeyDone;
    self.aNewTagField.delegate = self;
    [self.contentView addSubview:self.aNewTagField];
    [self pinView:self.aNewTagField below:newTagHeader offset:s leading:m trailing:-m inView:self.contentView];
    [self.aNewTagField.heightAnchor constraintEqualToConstant:44.0].active = YES;

    // ── Note ───────────────────────────────────────────────────────────
    UILabel *noteHeader = [self sectionHeader:@"Note (dev only, not shown in app)"];
    [self.contentView addSubview:noteHeader];
    [self pinView:noteHeader below:self.aNewTagField offset:m leading:m trailing:-m inView:self.contentView];

    self.noteView = [self textViewWithPlaceholder:@"Optional dev comment…"];
    [self.contentView addSubview:self.noteView];
    [self pinView:self.noteView below:noteHeader offset:s leading:m trailing:-m inView:self.contentView];
    [self.noteView.heightAnchor constraintEqualToConstant:60.0].active = YES;

    // Bottom padding
    [self.noteView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor
                                               constant:-32.0].active = YES;
}

// MARK: - Populate

- (void)populateFields
{
    self.idField.text      = self.builder.positionID;
    self.captionField.text = self.builder.caption;
    self.textView.text     = self.builder.text;
    self.noteView.text     = self.builder.note;
    [self updateDiffButtons];
}

- (void)updateDiffButtons
{
    UIColor *accent = [UIColor colorNamed:@"AccentColor"] ?: [UIColor systemRedColor];
    for (UIButton *btn in self.diffButtons)
    {
        BOOL active = (btn.tag == self.builder.difficulty);
        btn.backgroundColor = active ? accent : [UIColor secondarySystemGroupedBackgroundColor];
        [btn setTitleColor:active ? [UIColor whiteColor] : [UIColor labelColor]
                  forState:UIControlStateNormal];
        btn.layer.borderColor = active ? accent.CGColor
                                       : [UIColor separatorColor].CGColor;
    }
}

- (void)updateTagChips
{
    for (UIView *v in self.tagsWrapView.subviews) { [v removeFromSuperview]; }

    UIColor *accent = [UIColor colorNamed:@"AccentColor"] ?: [UIColor systemRedColor];
    CGFloat x = 0, y = 0, chipH = 30.0, gap = 6.0;
    CGFloat maxW = self.view.bounds.size.width - 32.0;

    for (NSString *tag in self.availableTags)
    {
        BOOL selected = [self.builder.tags containsObject:tag];

        UIButton *chip = [UIButton buttonWithType:UIButtonTypeSystem];
        [chip setTitle:tag forState:UIControlStateNormal];
        chip.titleLabel.font   = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
        chip.layer.cornerRadius = 14.0;
        chip.layer.borderWidth  = 1.0;

        if (selected)
        {
            chip.backgroundColor = accent;
            [chip setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            chip.layer.borderColor = accent.CGColor;
        }
        else
        {
            chip.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
            [chip setTitleColor:accent forState:UIControlStateNormal];
            chip.layer.borderColor = [accent colorWithAlphaComponent:0.4].CGColor;
        }

        // Size chip to fit text
        [chip sizeToFit];
        CGFloat w = chip.bounds.size.width + 20.0;

        if (x + w > maxW && x > 0)
        {
            x = 0;
            y += chipH + gap;
        }
        chip.frame = CGRectMake(x, y, w, chipH);
        [chip addTarget:self action:@selector(tagChipTapped:)
       forControlEvents:UIControlEventTouchUpInside];
        chip.accessibilityLabel = tag;
        [self.tagsWrapView addSubview:chip];
        x += w + gap;
    }

    // Update wrap view height constraint
    CGFloat totalH = y + chipH;
    for (NSLayoutConstraint *c in self.tagsWrapView.constraints)
    {
        if (c.firstAttribute == NSLayoutAttributeHeight) { [c setActive:NO]; }
    }
    [self.tagsWrapView.heightAnchor constraintEqualToConstant:totalH].active = YES;
}

// MARK: - Board preview

- (void)updateBoardPreview
{
    NSString *idText = [self.idField.text stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceCharacterSet]];
    if (idText.length == 0)
    {
        self.boardView.boardState  = [BGGPosition boardStateFromPositionID:@"4HPwATDgc/ABMA"];
        self.boardStatusLabel.text = @"Enter a GNU Position ID to preview";
        self.boardStatusLabel.textColor = [UIColor secondaryLabelColor];
        return;
    }

    BGGBoardState *state = [BGGPosition boardStateFromCombinedID:idText];
    if (state)
    {
        self.boardView.boardState  = state;
        // Show both pip counts next to the valid-ID confirmation, so the
        // explanation text can be checked against the real totals while
        // writing it. Player = blue (bottom, the user), Opponent = yellow.
        NSInteger playerPips   = [state pipCountForPlayer:BGGPlayerBlue];
        NSInteger opponentPips = [state pipCountForPlayer:BGGPlayerYellow];
        self.boardStatusLabel.text =
            [NSString stringWithFormat:@"✓ Valid position ID   ·   Player %ld   ·   Opponent %ld",
             (long)playerPips, (long)opponentPips];
        self.boardStatusLabel.textColor = [UIColor systemGreenColor];
    }
    else
    {
        self.boardStatusLabel.text  = @"⚠ Invalid position ID";
        self.boardStatusLabel.textColor = [UIColor systemOrangeColor];
    }
}

// MARK: - Actions

- (void)diffTapped:(UIButton *)sender
{
    self.builder.difficulty = sender.tag;
    [self updateDiffButtons];
}

- (void)tagChipTapped:(UIButton *)sender
{
    NSString *tag = sender.accessibilityLabel;
    if ([self.builder.tags containsObject:tag])
    {
        [self.builder.tags removeObject:tag];
    }
    else
    {
        if (self.builder.tags.count >= kMaxTags)
        {
            // Show brief warning
            self.boardStatusLabel.text = @"⚠ Maximum 5 tags per position";
            self.boardStatusLabel.textColor = [UIColor systemOrangeColor];
            return;
        }
        [self.builder.tags addObject:tag];
    }
    [self updateTagChips];
}

- (void)saveTapped
{
    // Collect current field values into builder
    self.builder.positionID = [self.idField.text
                               stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceCharacterSet]];
    self.builder.caption    = self.captionField.text ?: @"";
    self.builder.text       = self.textView.text     ?: @"";
    self.builder.note       = self.noteView.text     ?: @"";

    if (self.builder.positionID.length == 0)
    {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"Position ID required"
                                                     message:@"Please enter a GNU Position ID."
                                              preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    BGGPositionEntry *entry = [self.builder build];

    if (self.isNewEntry)
    {
        [[PositionDatabase sharedDatabase] addEntry:entry];
    }
    else
    {
        [[PositionDatabase sharedDatabase] updateEntry:entry];
    }

    [self.delegate editorDidSaveEntry:entry isNewEntry:self.isNewEntry];
    [self.navigationController popViewControllerAnimated:YES];
}

// MARK: - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.idField)
    {
        self.builder.positionID = textField.text ?: @"";
        [self updateBoardPreview];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.aNewTagField)
    {
        NSString *tag = [textField.text stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]].lowercaseString;
        if (tag.length > 0 && ![self.availableTags containsObject:tag])
        {
            [self.availableTags addObject:tag];
        }
        if (tag.length > 0 && ![self.builder.tags containsObject:tag]
            && self.builder.tags.count < kMaxTags)
        {
            [self.builder.tags addObject:tag];
        }
        textField.text = @"";
        [self updateTagChips];
        return NO;
    }
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidChangeSelection:(UITextField *)textField
{
    if (textField == self.idField)
    {
        [self updateBoardPreview];
    }
}

// MARK: - Helpers

- (void)pinView:(UIView *)view below:(UIView *)above offset:(CGFloat)offset
        leading:(CGFloat)leading trailing:(CGFloat)trailing inView:(UIView *)parent
{
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [view.topAnchor     constraintEqualToAnchor:above.bottomAnchor constant:offset],
        [view.leadingAnchor constraintEqualToAnchor:parent.leadingAnchor constant:leading],
        [view.trailingAnchor constraintEqualToAnchor:parent.trailingAnchor constant:trailing],
    ]];
}

- (UILabel *)sectionHeader:(NSString *)text
{
    UILabel *lbl    = [[UILabel alloc] init];
    lbl.text        = text;
    lbl.font        = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    lbl.textColor   = [UIColor secondaryLabelColor];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    return lbl;
}

- (UILabel *)smallLabel:(NSString *)text
{
    UILabel *lbl    = [[UILabel alloc] init];
    lbl.text        = text;
    lbl.font        = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    lbl.textColor   = [UIColor secondaryLabelColor];
    lbl.numberOfLines = 0;
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    return lbl;
}

- (UITextField *)textFieldWithPlaceholder:(NSString *)placeholder
{
    UITextField *f  = [[UITextField alloc] init];
    f.placeholder   = placeholder;
    f.borderStyle   = UITextBorderStyleRoundedRect;
    f.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    f.translatesAutoresizingMaskIntoConstraints = NO;
    return f;
}

- (UITextView *)textViewWithPlaceholder:(NSString *)placeholder
{
    UITextView *tv     = [[UITextView alloc] init];
    tv.font            = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    tv.layer.borderColor  = [UIColor separatorColor].CGColor;
    tv.layer.borderWidth  = 0.5;
    tv.layer.cornerRadius = 8.0;
    tv.text            = @"";
    tv.delegate        = self;
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    // Placeholder via accessibilityHint (real placeholder needs more code)
    tv.accessibilityHint = placeholder;
    return tv;
}

@end
