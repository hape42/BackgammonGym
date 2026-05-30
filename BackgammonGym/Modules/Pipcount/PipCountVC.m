//
//  PipCountVC.m
//  BackgammonGym
//

#import "PipCountVC.h"
#import "BGGBoardView.h"
#import "BGGBoardState.h"
#import "BGGBoardGeometry.h"

@interface PipCountVC ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView       *contentView;
@property (nonatomic, strong) BGGBoardView *boardView;
@property (nonatomic, strong) BGGBoardView *boardView2;

@end

@implementation PipCountVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Pip Count";

    // The scroll view fills the whole safe area.
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];

    // All board views go into a plain content view inside the scroll view.
    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    // First board – full width.
    self.boardView = [[BGGBoardView alloc] init];
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardView.boardDesign     = @"4";
    self.boardView.showsPointNumbers = YES;
    self.boardView.boardState      = [BGGBoardState startingPosition];
    [self.contentView addSubview:self.boardView];

    // Second board – half width, same position for now.
    self.boardView2 = [[BGGBoardView alloc] init];
    self.boardView2.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardView2.boardDesign      = @"5";
    self.boardView2.showsPointNumbers = YES;
    self.boardView2.boardState       = [BGGBoardState startingPosition];
    [self.contentView addSubview:self.boardView2];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // Board aspect ratio: height = width * (514/660)
    CGFloat ratio = kBGGBoardHeight / kBGGBoardWidth;

    [NSLayoutConstraint activateConstraints:@[

        // Scroll view pins to safe area.
        [self.scrollView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.scrollView.topAnchor      constraintEqualToAnchor:safe.topAnchor],
        [self.scrollView.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],

        // Content view determines scroll height; width is pinned to scroll view.
        [self.contentView.leadingAnchor  constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.topAnchor      constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.bottomAnchor   constraintEqualToAnchor:self.scrollView.bottomAnchor],
        // This is the key: content width = scroll view width, so only
        // vertical scrolling is enabled.
        [self.contentView.widthAnchor    constraintEqualToAnchor:self.scrollView.widthAnchor],

        // First board: full width, height follows aspect ratio.
        [self.boardView.leadingAnchor    constraintEqualToAnchor:self.contentView.leadingAnchor  constant:12.0],
        [self.boardView.trailingAnchor   constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12.0],
        [self.boardView.topAnchor        constraintEqualToAnchor:self.contentView.topAnchor      constant:12.0],
        [self.boardView.heightAnchor     constraintEqualToAnchor:self.boardView.widthAnchor      multiplier:ratio],

        // Second board: half width, centered, below first board.
        [self.boardView2.centerXAnchor   constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.boardView2.widthAnchor     constraintEqualToAnchor:self.boardView.widthAnchor      multiplier:0.5],
        [self.boardView2.topAnchor       constraintEqualToAnchor:self.boardView.bottomAnchor     constant:16.0],
        [self.boardView2.heightAnchor    constraintEqualToAnchor:self.boardView2.widthAnchor     multiplier:ratio],

        // Content view bottom follows last board, so the scroll view knows
        // how tall the content is.
        [self.contentView.bottomAnchor   constraintEqualToAnchor:self.boardView2.bottomAnchor    constant:12.0],
    ]];
}

@end
