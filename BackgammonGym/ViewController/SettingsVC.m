//
//  SettingsVC.m
//  BackgammonGym
//

#import "SettingsVC.h"
#import "BGGBoardStyleCell.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kCellID = @"BGGBoardStyleCell";

@interface SettingsVC () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView   *tableView;
@property (nonatomic, strong) UILabel       *versionLabel;
@property (nonatomic, strong) UILabel       *selectBoard;
@property (nonatomic, strong) NSArray<NSDictionary *> *boardsArray;

@end

@implementation SettingsVC

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorNamed:@"ColorViewBackground"];
    self.title = @"Settings";
    [self setupBoardArray];
    [self setupContent];
}

#pragma mark - Version

// "Backgammon Gym Version 1.0 build 356"
- (NSString *)versionString
{
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    NSString *version  = info[@"CFBundleShortVersionString"] ?: @"?";
    NSString *build    = info[@"CFBundleVersion"]            ?: @"?";
    return [NSString stringWithFormat:@"Backgammon Gym Version %@ build %@",
            version, build];
}

#pragma mark - Board data

- (void)setupBoardArray
{
    self.boardsArray = @[
        @{ @"number": @4,  @"name": @"Red / Grey HD",  @"design": @"hape42" },
        @{ @"number": @5,  @"name": @"Wood HD",         @"design": @"darkhelmet" },
        @{ @"number": @6,  @"name": @"Metal HD",        @"design": @"darkhelmet" },
        @{ @"number": @7,  @"name": @"Mono HD",         @"design": @"darkhelmet" },
        @{ @"number": @8,  @"name": @"Unicorn",         @"design": @"Jutta Schneider" },
        @{ @"number": @12, @"name": @"Steampunk",       @"design": @"darkhelmet" },
        @{ @"number": @13, @"name": @"Sea",             @"design": @"darkhelmet" },
        @{ @"number": @14, @"name": @"Traditional",     @"design": @"darkhelmet" },
        @{ @"number": @15, @"name": @"Spring",          @"design": @"darkhelmet" },
    ];
}

- (NSInteger)currentBoardSchema
{
    NSInteger schema = [[NSUserDefaults standardUserDefaults] integerForKey:@"BoardSchema"];
    return (schema < 4) ? 4 : schema;
}

#pragma mark - UI setup

- (void)setupContent
{
    // Done button
    UIBarButtonItem *done = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                 target:self
                                                 action:@selector(doneButtonTapped)];
    done.tintColor = [UIColor colorNamed:@"AccentColor"];
    self.navigationItem.rightBarButtonItem = done;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // Version / build label
    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.text          = [self versionString];
    self.versionLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.versionLabel.textColor     = [UIColor secondaryLabelColor];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.versionLabel];

    // Header label
    self.selectBoard = [[UILabel alloc] init];
    self.selectBoard.text = @"Select Board Style";
    self.selectBoard.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.selectBoard];

    // Table view
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate   = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight  = 100.0;
    self.tableView.layer.borderWidth  = 1.0;
    self.tableView.layer.cornerRadius = 14.0;
    self.tableView.layer.borderColor  = [UIColor colorNamed:@"ColorImages"].CGColor;
    [self.tableView registerClass:[BGGBoardStyleCell class]
           forCellReuseIdentifier:kCellID];
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.selectBoard.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:10.0],
        [self.selectBoard.centerXAnchor  constraintEqualToAnchor:safe.centerXAnchor],
        [self.selectBoard.heightAnchor   constraintEqualToConstant:35.0],

        [self.versionLabel.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor constant:-8.0],
        [self.versionLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:16.0],
        [self.versionLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16.0],

        [self.tableView.topAnchor        constraintEqualToAnchor:self.selectBoard.bottomAnchor constant:10.0],
        [self.tableView.bottomAnchor     constraintEqualToAnchor:self.versionLabel.topAnchor constant:-10.0],
        [self.tableView.centerXAnchor    constraintEqualToAnchor:safe.centerXAnchor],
        [self.tableView.widthAnchor      constraintEqualToConstant:400.0],
    ]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)self.boardsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BGGBoardStyleCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID
                                                              forIndexPath:indexPath];
    NSDictionary *dict   = self.boardsArray[(NSUInteger)indexPath.row];
    NSInteger schema     = [dict[@"number"] integerValue];
    BOOL isSelected      = (schema == [self currentBoardSchema]);

    [cell configureWithSchema:schema
                         name:dict[@"name"]
                     designer:dict[@"design"]
                   isSelected:isSelected];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *dict = self.boardsArray[(NSUInteger)indexPath.row];
    [[NSUserDefaults standardUserDefaults] setInteger:[dict[@"number"] integerValue]
                                               forKey:@"BoardSchema"];
    [tableView reloadData];
}

#pragma mark - Actions

- (void)doneButtonTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

NS_ASSUME_NONNULL_END
