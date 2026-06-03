//
//  BGGBoardIDView.m
//  BackgammonGym
//

#import "BGGBoardIDView.h"
#import "BGGBoardState.h"
#import "BGGPosition.h"

@interface BGGBoardIDView ()
@property (nonatomic, strong) UILabel  *idLabel;
@property (nonatomic, strong) UIButton *clipboardButton;
@property (nonatomic, copy)   NSString *currentID;
@end

@implementation BGGBoardIDView

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self buildSubviews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews
{
    // ID label
    self.idLabel = [[UILabel alloc] init];
    self.idLabel.font          = [UIFont monospacedSystemFontOfSize:11.0
                                                             weight:UIFontWeightRegular];
    self.idLabel.textColor     = [UIColor secondaryLabelColor];
    self.idLabel.numberOfLines = 1;
    self.idLabel.adjustsFontSizeToFitWidth = YES;
    self.idLabel.minimumScaleFactor = 0.7;
    self.idLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.idLabel];

    // Copy button
    self.clipboardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *icon = [UIImage systemImageNamed:@"doc.on.doc"];
    [self.clipboardButton setImage:icon forState:UIControlStateNormal];
    self.clipboardButton.tintColor  = [UIColor colorNamed:@"AccentColor"] ?: [UIColor systemRedColor];
    self.clipboardButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.clipboardButton addTarget:self
                        action:@selector(copyTapped)
              forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.clipboardButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.clipboardButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.clipboardButton.centerYAnchor  constraintEqualToAnchor:self.centerYAnchor],
        [self.clipboardButton.widthAnchor    constraintEqualToConstant:32.0],
        [self.clipboardButton.heightAnchor   constraintEqualToConstant:32.0],

        [self.idLabel.leadingAnchor     constraintEqualToAnchor:self.leadingAnchor],
        [self.idLabel.trailingAnchor    constraintEqualToAnchor:self.clipboardButton.leadingAnchor
                                                        constant:-4.0],
        [self.idLabel.centerYAnchor     constraintEqualToAnchor:self.centerYAnchor],

        [self.heightAnchor constraintEqualToConstant:32.0],
    ]];
}

#pragma mark - Public

- (void)updateWithBoardState:(nullable BGGBoardState *)boardState
{
    if (boardState == nil)
    {
        self.idLabel.text = @"–";
        self.currentID    = nil;
        return;
    }

    NSString *combined = [BGGPosition combinedIDFromBoardState:boardState];
    self.currentID    = combined;
    self.idLabel.text = combined ?: @"–";
}

#pragma mark - Copy

- (void)copyTapped
{
    if (self.currentID.length == 0) { return; }

    [UIPasteboard generalPasteboard].string = self.currentID;

    // Haptic feedback
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc]
                                       initWithStyle:UIImpactFeedbackStyleLight];
    [gen impactOccurred];

    // Brief visual confirmation: icon changes to checkmark then back
    UIImage *check = [UIImage systemImageNamed:@"checkmark"];
    UIImage *copy  = [UIImage systemImageNamed:@"doc.on.doc"];
    [self.clipboardButton setImage:check forState:UIControlStateNormal];
    self.clipboardButton.tintColor = [UIColor systemGreenColor];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.clipboardButton setImage:copy forState:UIControlStateNormal];
        self.clipboardButton.tintColor = [UIColor colorNamed:@"AccentColor"]
                                 ?: [UIColor systemRedColor];
    });
}

@end
