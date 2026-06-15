//
//  BGGStartTileCell.m
//  BackgammonGym
//
//  Created by Peter Schneider on 29.05.26.
//

#import "BGGStartTileCell.h"

@interface BGGStartTileCell ()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation BGGStartTileCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.layer.cornerRadius = 14.0;
    self.layer.masksToBounds = YES;
    self.backgroundColor = [UIColor colorNamed:@"ColorCV"];

    _iconView = [[UIImageView alloc] init];
    _iconView.translatesAutoresizingMaskIntoConstraints = NO;
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_iconView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont boldSystemFontOfSize:22];
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.minimumScaleFactor = 0.6;
    _titleLabel.numberOfLines = 1;
    [self.contentView addSubview:_titleLabel];

    UILayoutGuide *g = self.contentView.layoutMarginsGuide;

    [NSLayoutConstraint activateConstraints:@[
        // Icon: top-left.
        [_iconView.topAnchor      constraintEqualToAnchor:g.topAnchor],
        [_iconView.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
        [_iconView.widthAnchor    constraintEqualToConstant:34],
        [_iconView.heightAnchor   constraintEqualToConstant:34],

        // Title: bottom-left, below the icon.
        [_titleLabel.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
        [_titleLabel.bottomAnchor   constraintEqualToAnchor:g.bottomAnchor],
    ]];
}

- (void)configureWithIcon:(UIImage *)icon
                iconColor:(UIColor *)iconColor
                    title:(NSString *)title
                 subtitle:(NSString *)subtitle
{
    self.iconView.image     = icon;
    self.iconView.tintColor = iconColor;
    self.titleLabel.text    = title;
    // subtitle is intentionally ignored now – tiles show icon + title only.
}

@end
