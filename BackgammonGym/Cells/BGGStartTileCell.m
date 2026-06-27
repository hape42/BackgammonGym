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
    _titleLabel.font = [UIFont boldSystemFontOfSize:20];
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.minimumScaleFactor = 0.6;
    _titleLabel.numberOfLines = 1;
    [self.contentView addSubview:_titleLabel];

    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _subtitleLabel.font = [UIFont systemFontOfSize:13];
    _subtitleLabel.textColor = [UIColor secondaryLabelColor];
    _subtitleLabel.textAlignment = NSTextAlignmentLeft;
    _subtitleLabel.adjustsFontSizeToFitWidth = YES;
    _subtitleLabel.minimumScaleFactor = 0.7;
    _subtitleLabel.numberOfLines = 1;
    [self.contentView addSubview:_subtitleLabel];

    UILayoutGuide *g = self.contentView.layoutMarginsGuide;

    [NSLayoutConstraint activateConstraints:@[
        // Icon: top-left.
        [_iconView.topAnchor      constraintEqualToAnchor:g.topAnchor],
        [_iconView.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
        [_iconView.widthAnchor    constraintEqualToConstant:32],
        [_iconView.heightAnchor   constraintEqualToConstant:32],

        // Subtitle: pinned to the bottom, full width.
        [_subtitleLabel.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
        [_subtitleLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
        [_subtitleLabel.bottomAnchor   constraintEqualToAnchor:g.bottomAnchor],

        // Title: sits directly above the subtitle.
        [_titleLabel.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
        [_titleLabel.bottomAnchor   constraintEqualToAnchor:_subtitleLabel.topAnchor
                                                  constant:-2.0],
    ]];
}

- (void)configureWithIcon:(UIImage *)icon
                iconColor:(UIColor *)iconColor
                    title:(NSString *)title
                 subtitle:(NSString *)subtitle
{
    [self configureWithIcon:icon
                  iconColor:iconColor
                      title:title
                   subtitle:subtitle
                  prominent:NO];
}

- (void)configureWithIcon:(UIImage *)icon
                iconColor:(UIColor *)iconColor
                    title:(NSString *)title
                 subtitle:(NSString *)subtitle
                prominent:(BOOL)prominent
{
    self.iconView.image     = icon;
    self.titleLabel.text    = title;
    self.subtitleLabel.text = subtitle;

    // The cell is reused, so every style property is set in BOTH branches –
    // otherwise a recycled prominent cell would keep its red background when
    // it later represents a plain tile, and vice versa.
    if (prominent)
    {
        // Training tile: AccentColor fill, light text, grey icon.
        self.backgroundColor      = [UIColor colorNamed:@"AccentColor"];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.subtitleLabel.textColor =
            [[UIColor whiteColor] colorWithAlphaComponent:0.85];
        self.iconView.tintColor   = [UIColor systemGray5Color];
    }
    else
    {
        // Plain tile: grey fill, normal label colours, icon colour as given.
        self.backgroundColor         = [UIColor colorNamed:@"ColorCV"];
        self.titleLabel.textColor    = [UIColor labelColor];
        self.subtitleLabel.textColor = [UIColor secondaryLabelColor];
        self.iconView.tintColor      = iconColor;
    }

    // When there is no subtitle, hide its label so the title can sit lower
    // and stay vertically centred-ish instead of leaving an empty gap.
    self.subtitleLabel.hidden = (subtitle.length == 0);
}

@end
