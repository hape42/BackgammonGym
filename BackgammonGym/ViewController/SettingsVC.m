//
//  SettingsVC.m
//  BackgammonGym
//
//  Created by Peter Schneider on 01.06.26.
//

#import "SettingsVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface SettingsVC () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *selectBoard;

@property (readwrite, retain, nonatomic) NSMutableArray *boardsArray;

@end

@implementation SettingsVC

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorNamed:@"ColorViewBackground"];;

    self.title = @"Settings";

    [self setupBoardArray];
    [self setupContent];
}

- (void) setupBoardArray
{
    self.boardsArray = [[NSMutableArray alloc] initWithObjects:
                   @{ @"number" : [NSNumber numberWithInt:4],
                      @"name" : @"Red / Grey HD",
                      @"design" : @"hape42",
                      @"colorLight" : @"Red",
                      @"colorDark"  : @"Grey"},
                   @{ @"number" : [NSNumber numberWithInt:5],
                      @"name" : @"Wood HD",
                      @"design" : @"darkhelmet",
                      @"colorLight" : @"Light",
                      @"colorDark"  : @"Dark"},
                   @{ @"number" : [NSNumber numberWithInt:6],
                      @"name" : @"Metal HD",
                      @"design" : @"darkhelmet",
                     @"colorLight" : @"Silver",
                      @"colorDark"  : @"Black"},
                   @{ @"number" : [NSNumber numberWithInt:7],
                      @"name" : @"Mono HD",
                      @"design" : @"darkhelmet",
                      @"colorLight" : @"Light",
                      @"colorDark"  : @"Dark"},
                   @{ @"number" : [NSNumber numberWithInt:8],
                      @"name" : @"Unicorn",
                      @"design" : @"Jutta Schneider",
                      @"colorLight" : @"Light",
                      @"colorDark"  : @"Dark"},
//                   @{ @"number" : [NSNumber numberWithInt:9],
//                      @"name" : @"Golf",
//                      @"design" : @"Jutta Schneider",
//                      @"colorLight" : @"Light",
//                      @"colorDark"  : @"Dark"},
//                   @{ @"number" : [NSNumber numberWithInt:10],
//                      @"name" : @"Snooker",
//                      @"design" : @"Jutta Schneider",
//                      @"colorLight" : @"Light",
//                      @"colorDark"  : @"Dark"},
//                   @{ @"number" : [NSNumber numberWithInt:11],
//                      @"name" : @"Billiard",
//                      @"design" : @"Jutta Schneider",
//                      @"colorLight" : @"Light",
//                      @"colorDark"  : @"Dark"},
                   @{ @"number" : [NSNumber numberWithInt:12],
                      @"name" : @"Steampunk",
                      @"design" : @"darkhelmet",
                      @"colorLight" : @"Light",
                      @"colorDark"  : @"Dark"},
                   @{ @"number" : [NSNumber numberWithInt:13],
                      @"name" : @"Sea",
                      @"design" : @"darkhelmet",
                      @"colorLight" : @"White",
                      @"colorDark"  : @"Blue"},
                   @{ @"number" : [NSNumber numberWithInt:14],
                      @"name" : @"Traditional",
                      @"design" : @"darkhelmet",
                      @"colorLight" : @"White",
                      @"colorDark"  : @"Black"},
                   @{ @"number" : [NSNumber numberWithInt:15],
                      @"name" : @"Spring",
                      @"design" : @"darkhelmet",
                      @"colorLight" : @"Yellow",
                      @"colorDark"  : @"Violet"},
              nil];
    

 }
#pragma mark - Content

- (void)setupContent
{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneButtonTapped)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    float edge = 10.0;
    float gap  = 10.0;
        
    self.selectBoard = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.selectBoard];
    self.selectBoard.text = @"Select Board Style";
    
    [self.selectBoard setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.selectBoard.topAnchor     constraintEqualToAnchor:safe.topAnchor               constant:edge].active = YES;
    [self.selectBoard.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor constant:0].active = YES;
    [self.selectBoard.heightAnchor  constraintEqualToConstant:35].active = YES;


    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];

    self.tableView.delegate   = self;
    self.tableView.dataSource = self;

    [self.view addSubview:self.tableView];

    [self.tableView.topAnchor     constraintEqualToAnchor:self.selectBoard.bottomAnchor                constant:gap].active = YES;
    [self.tableView.bottomAnchor     constraintEqualToAnchor:safe.bottomAnchor                constant:-gap].active = YES;
//    [self.tableView.leftAnchor constraintEqualToAnchor:safe.leftAnchor constant:edge].active = YES;
//    [self.tableView.rightAnchor  constraintEqualToAnchor:safe.rightAnchor constant:-edge].active = YES;
    [self.tableView.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor constant:0].active = YES;
    [self.tableView.widthAnchor  constraintEqualToConstant:400].active = YES;

    self.tableView.layer.borderWidth = 1;
    self.tableView.layer.cornerRadius = 14.0f;
    self.tableView.layer.borderColor = [[UIColor colorNamed:@"ColorImages"] CGColor];

}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
    return self.boardsArray.count;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }

    for (UIView *subview in [cell.contentView subviews])
    {
        if ([subview isKindOfClass:[UILabel class]])
        {
            [subview removeFromSuperview];
        }
       if ([subview isKindOfClass:[UIImageView class]])
        {
            [subview removeFromSuperview];
        }
    }
    cell.backgroundColor = [UIColor colorNamed:@"ColorTableViewCell"];;

    cell.accessoryType = UITableViewCellAccessoryNone;

    NSDictionary *dict = self.boardsArray[indexPath.row];

    int boardSchema = [[[NSUserDefaults standardUserDefaults] valueForKey:@"BoardSchema"]intValue];
    if(boardSchema < 1)
        boardSchema = 4;

    int x = 0;
    int labelHeight = cell.contentView.frame.size.height;
    labelHeight = 100;
    
    UILabel *checkLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0 ,50,labelHeight)];
    checkLabel.textAlignment = NSTextAlignmentCenter;
    if([[dict objectForKey:@"number"]intValue] == boardSchema)
        checkLabel.text = @"✅";
    [cell.contentView addSubview:checkLabel];

    x += 50;
    NSString *imageName = [NSString stringWithFormat:@"%d/board", [[dict objectForKey:@"number"]intValue ]];

    UIImage *image = [UIImage imageNamed:imageName];
    if(!image)
        image = [UIImage imageNamed:@"DeadShot"];
    float factor = image.size.width / image.size.height;
    UIImageView *board =  [[UIImageView alloc] initWithFrame:CGRectMake(x, 5 ,labelHeight * factor,labelHeight-10)];
    board.image = image;
    [cell.contentView addSubview:board];

    x += board.frame.size.width + 5;
    int labelWidth = cell.contentView.frame.size.width - x;

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0 ,labelWidth,labelHeight/2)];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.text = [NSString stringWithFormat:@"%@", [dict objectForKey:@"name"]];
    [cell.contentView addSubview:nameLabel];
    
    nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, labelHeight/2 ,labelWidth,labelHeight/4)];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.text = [NSString stringWithFormat:@"Designed by"];
    [cell.contentView addSubview:nameLabel];
    
    nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, labelHeight/4*3 ,labelWidth,labelHeight/4)];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.text = [NSString stringWithFormat:@"%@",  [dict objectForKey:@"design"] ];
    [cell.contentView addSubview:nameLabel];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = self.boardsArray[indexPath.row];

    [[NSUserDefaults standardUserDefaults] setInteger:[[dict objectForKey:@"number"]intValue] forKey:@"BoardSchema"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.tableView reloadData];
}

#pragma mark - Aktionen

- (void)doneButtonTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end

NS_ASSUME_NONNULL_END
