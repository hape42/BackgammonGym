//
//  BGGBoardStyleCell.m
//  BackgammonGym
//

#import "BGGBoardStyleCell.h"

static const CGFloat kCellHeight    = 100.0;
static const CGFloat kPreviewHeight = 90.0;   // board preview image height
static const CGFloat kPadding       = 8.0;

@interface BGGBoardStyleCell ()
@property (nonatomic, strong) UIImageView *previewView;
@property (nonatomic, strong) UILabel     *nameLabel;
@property (nonatomic, strong) UILabel     *designedByLabel;
@property (nonatomic, strong) UILabel     *designerLabel;
@end

@implementation BGGBoardStyleCell

#pragma mark - Init

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(nullable NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews
{
    // Board preview image
    self.previewView = [[UIImageView alloc] init];
    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
    self.previewView.contentMode = UIViewContentModeScaleAspectFit;
    self.previewView.clipsToBounds = YES;
    self.previewView.layer.cornerRadius = 6.0;
    [self.contentView addSubview:self.previewView];

    // Style name (large)
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.adjustsFontForContentSizeCategory = YES;
    [self.contentView addSubview:self.nameLabel];

    // "Designed by" caption
    self.designedByLabel = [[UILabel alloc] init];
    self.designedByLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.designedByLabel.text = @"Designed by";
    self.designedByLabel.textAlignment = NSTextAlignmentCenter;
    self.designedByLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.designedByLabel.textColor = [UIColor secondaryLabelColor];
    [self.contentView addSubview:self.designedByLabel];

    // Designer name
    self.designerLabel = [[UILabel alloc] init];
    self.designerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.designerLabel.textAlignment = NSTextAlignmentCenter;
    self.designerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.designerLabel.textColor = [UIColor secondaryLabelColor];
    [self.contentView addSubview:self.designerLabel];

    // The preview image has a fixed aspect ratio based on the board image.
    // I use a placeholder width constraint that gets updated in configure:.
    // For now I use a 16:9-ish ratio as default; the actual ratio comes
    // from the image once it is loaded.
    [NSLayoutConstraint activateConstraints:@[
        // Preview: fixed width left area, vertically centered
        [self.previewView.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor
                                                        constant:kPadding],
        [self.previewView.centerYAnchor  constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.previewView.heightAnchor   constraintEqualToConstant:kPreviewHeight],
        [self.previewView.widthAnchor    constraintEqualToConstant:120.0],

        // Name: right of preview, centered vertically in upper third
        [self.nameLabel.leadingAnchor    constraintEqualToAnchor:self.previewView.trailingAnchor
                                                        constant:kPadding],
        [self.nameLabel.trailingAnchor   constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
        [self.nameLabel.topAnchor        constraintEqualToAnchor:self.contentView.topAnchor
                                                        constant:kPadding * 2],

        // "Designed by" below name
        [self.designedByLabel.leadingAnchor  constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.designedByLabel.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
        [self.designedByLabel.topAnchor      constraintEqualToAnchor:self.nameLabel.bottomAnchor
                                                            constant:4.0],

        // Designer name below "Designed by"
        [self.designerLabel.leadingAnchor  constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.designerLabel.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
        [self.designerLabel.topAnchor      constraintEqualToAnchor:self.designedByLabel.bottomAnchor
                                                          constant:2.0],
    ]];
}

#pragma mark - Configuration

- (void)configureWithSchema:(NSInteger)schema
                       name:(NSString *)name
                   designer:(NSString *)designer
                 isSelected:(BOOL)isSelected
{
    self.nameLabel.text    = name;
    self.designerLabel.text = designer;

    NSString *imageName = [NSString stringWithFormat:@"%ld/board", (long)schema];
    UIImage *image = [UIImage imageNamed:imageName]
                  ?: [UIImage imageNamed:@"DeadShot"];
    self.previewView.image = image;

    // Native iOS checkmark accessory in AccentColor – no emoji needed.
    self.accessoryType = isSelected
        ? UITableViewCellAccessoryCheckmark
        : UITableViewCellAccessoryNone;
    self.tintColor = [UIColor colorNamed:@"AccentColor"];
}

@end
