//
//  BGGSessionCell.m
//  BackgammonGym
//

#import "BGGSessionCell.h"
#import "BGGTimeColor.h"

static const CGFloat kPadding = 12.0;

@interface BGGSessionCell ()
@property (nonatomic, strong) UILabel *dateLabel;     // top-left: date & time
@property (nonatomic, strong) UILabel *modeLabel;     // bottom-left: mode
@property (nonatomic, strong) UILabel *scoreLabel;    // top-right: hit rate
@property (nonatomic, strong) UILabel *timeBadge;     // bottom-right: avg time
@end

@implementation BGGSessionCell

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
    // Date & time (top-left)
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [self.contentView addSubview:self.dateLabel];

    // Mode (bottom-left)
    self.modeLabel = [[UILabel alloc] init];
    self.modeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.modeLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.modeLabel.textColor = [UIColor secondaryLabelColor];
    [self.contentView addSubview:self.modeLabel];

    // Hit rate (top-right)
    self.scoreLabel = [[UILabel alloc] init];
    self.scoreLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.scoreLabel.font = [UIFont monospacedDigitSystemFontOfSize:17.0
                                                            weight:UIFontWeightSemibold];
    self.scoreLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:self.scoreLabel];

    // Average time badge (bottom-right)
    self.timeBadge = [[UILabel alloc] init];
    self.timeBadge.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeBadge.font = [UIFont monospacedDigitSystemFontOfSize:14.0
                                                           weight:UIFontWeightSemibold];
    self.timeBadge.textColor     = [UIColor whiteColor];
    self.timeBadge.textAlignment = NSTextAlignmentCenter;
    self.timeBadge.layer.cornerRadius  = 10.0;
    self.timeBadge.layer.masksToBounds = YES;
    [self.contentView addSubview:self.timeBadge];

    [NSLayoutConstraint activateConstraints:@[
        [self.dateLabel.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor],
        [self.dateLabel.topAnchor     constraintEqualToAnchor:self.contentView.topAnchor constant:kPadding],

        [self.modeLabel.leadingAnchor constraintEqualToAnchor:self.dateLabel.leadingAnchor],
        [self.modeLabel.topAnchor     constraintEqualToAnchor:self.dateLabel.bottomAnchor constant:2.0],
        [self.modeLabel.bottomAnchor  constraintEqualToAnchor:self.contentView.bottomAnchor constant:-kPadding],

        [self.scoreLabel.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
        [self.scoreLabel.centerYAnchor  constraintEqualToAnchor:self.dateLabel.centerYAnchor],
        [self.scoreLabel.leadingAnchor  constraintGreaterThanOrEqualToAnchor:self.dateLabel.trailingAnchor
                                                                    constant:kPadding],

        [self.timeBadge.trailingAnchor constraintEqualToAnchor:self.scoreLabel.trailingAnchor],
        [self.timeBadge.topAnchor      constraintEqualToAnchor:self.scoreLabel.bottomAnchor
                                                      constant:8.0],
        [self.timeBadge.heightAnchor   constraintEqualToConstant:24.0],
    ]];
}

#pragma mark - Configuration

- (void)configureWithDate:(nullable NSDate *)date
                     mode:(nullable NSString *)mode
             correctCount:(NSInteger)correctCount
               totalCount:(NSInteger)totalCount
            averageMillis:(NSInteger)averageMillis
               isComplete:(BOOL)isComplete
{
    // Date & time, e.g. "10 Jun 2026, 09:30"
    if (date != nil)
    {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"d MMM yyyy, HH:mm";
        self.dateLabel.text = [df stringFromDate:date];
    }
    else
    {
        self.dateLabel.text = @"—";
    }

    // Mode, capitalised; mark incomplete sessions discreetly.
    NSString *modeText = (mode.length > 0) ? [mode capitalizedString] : @"Session";
    if (!isComplete)
    {
        modeText = [modeText stringByAppendingString:@" · incomplete"];
        self.modeLabel.textColor = [UIColor tertiaryLabelColor];
    }
    else
    {
        self.modeLabel.textColor = [UIColor secondaryLabelColor];
    }
    self.modeLabel.text = modeText;

    // Hit rate "8 / 10 · 80%"
    NSInteger percent = (totalCount > 0)
        ? (NSInteger)round((double)correctCount / totalCount * 100.0)
        : 0;
    self.scoreLabel.text = [NSString stringWithFormat:@"%ld / %ld · %ld%%",
                            (long)correctCount, (long)totalCount, (long)percent];

    // Average time badge, coloured by the same thresholds as the exercise.
    NSInteger avgSeconds = (NSInteger)round((double)averageMillis / 1000.0);
    self.timeBadge.text = [NSString stringWithFormat:@"  ⌀ %@  ",
                           [self formattedSeconds:avgSeconds]];
    self.timeBadge.backgroundColor = [BGGTimeColor colorForSeconds:avgSeconds];

    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

// "17 seconds" below a minute, "1 min 25 sec" from a minute up.
- (NSString *)formattedSeconds:(NSInteger)seconds
{
    if (seconds < 60)
    {
        return [NSString stringWithFormat:@"%ld seconds", (long)seconds];
    }
    NSInteger min = seconds / 60;
    NSInteger sec = seconds % 60;
    return [NSString stringWithFormat:@"%ld min %ld sec", (long)min, (long)sec];
}

@end
