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
@property (nonatomic, strong) UILabel *subtitleLabel;

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
    _titleLabel.font = [UIFont boldSystemFontOfSize:28];
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.minimumScaleFactor = 0.6;
    [self.contentView addSubview:_titleLabel];

    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _subtitleLabel.font = [UIFont systemFontOfSize:16];
    _subtitleLabel.textColor = [UIColor secondaryLabelColor];
    _subtitleLabel.textAlignment = NSTextAlignmentLeft;
    [self.contentView addSubview:_subtitleLabel];

    UILayoutGuide *g = self.contentView.layoutMarginsGuide;

    [NSLayoutConstraint activateConstraints:@[
        [_iconView.topAnchor      constraintEqualToAnchor:g.topAnchor constant:8],
        [_iconView.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
        [_iconView.widthAnchor    constraintEqualToConstant:36],
        [_iconView.heightAnchor   constraintEqualToConstant:36],

        [_titleLabel.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
        [_titleLabel.bottomAnchor   constraintEqualToAnchor:_subtitleLabel.topAnchor constant:-2],

        [_subtitleLabel.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
        [_subtitleLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
        [_subtitleLabel.bottomAnchor   constraintEqualToAnchor:g.bottomAnchor constant:-4],
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
    self.subtitleLabel.text = subtitle ?: @"";
    self.subtitleLabel.hidden = (subtitle.length == 0);
}

@end
