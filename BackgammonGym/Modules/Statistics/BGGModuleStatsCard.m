//
//  BGGModuleStatsCard.m
//  BackgammonGym
//

#import "BGGModuleStatsCard.h"
#import "CoreDataManager.h"
#import "BGGTimeColor.h"
#import "BGGLocalization.h"

@interface BGGModuleStatsCard ()

@property (nonatomic, copy)   NSString    *moduleID;
@property (nonatomic, strong) UILabel     *titleLabel;
@property (nonatomic, strong) UIStackView *outerStack;   // title + the two mode blocks

@end

@implementation BGGModuleStatsCard

- (instancetype)initWithTitle:(NSString *)title
                       module:(NSString *)module
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        _moduleID = [module copy];
        [self buildCardWithTitle:title];
        [self reload];
    }
    return self;
}

#pragma mark - Build

- (void)buildCardWithTitle:(NSString *)title
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor      = [UIColor secondarySystemBackgroundColor];
    self.layer.cornerRadius   = 14.0;
    self.layer.cornerCurve    = kCACornerCurveContinuous;

    self.titleLabel               = [[UILabel alloc] init];
    self.titleLabel.text          = title;   // brand language, not localized
    self.titleLabel.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    self.titleLabel.adjustsFontForContentSizeCategory = YES;
    self.titleLabel.numberOfLines = 0;

    self.outerStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.titleLabel]];
    self.outerStack.axis    = UILayoutConstraintAxisVertical;
    self.outerStack.spacing = 16.0;
    self.outerStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.outerStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.outerStack.topAnchor      constraintEqualToAnchor:self.topAnchor constant:16.0],
        [self.outerStack.leadingAnchor  constraintEqualToAnchor:self.leadingAnchor constant:16.0],
        [self.outerStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16.0],
        [self.outerStack.bottomAnchor   constraintEqualToAnchor:self.bottomAnchor constant:-16.0],
    ]];
}

#pragma mark - Reload

- (void)reload
{
    // Drop the existing mode blocks (keep the title at index 0).
    while (self.outerStack.arrangedSubviews.count > 1)
    {
        UIView *v = self.outerStack.arrangedSubviews.lastObject;
        [self.outerStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    CoreDataManager *db = [CoreDataManager sharedManager];
    NSDictionary *training = [db statsForModule:self.moduleID mode:@"training"];
    NSDictionary *workout  = [db statsForModule:self.moduleID mode:@"workout"];

    NSInteger total = [training[@"exercises"] integerValue] +
                      [workout[@"exercises"] integerValue];

    if (total == 0)
    {
        // Nothing recorded yet for this module.
        UILabel *empty = [[UILabel alloc] init];
        empty.text          = BGGLocalizedString(@"No sessions yet.");
        empty.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        empty.textColor     = [UIColor secondaryLabelColor];
        empty.numberOfLines = 0;
        [self.outerStack addArrangedSubview:empty];
        return;
    }

    // "Training" / "Workout" are brand language and stay unlocalized.
    [self.outerStack addArrangedSubview:[self blockForMode:@"Training" stats:training]];
    [self.outerStack addArrangedSubview:[self blockForMode:@"Workout"  stats:workout]];
}

#pragma mark - One mode block

// A mode block is: a small all-caps mode header, then two info lines. The
// hit rate and the average time are tinted with the BGGTimeColor thresholds,
// matching the colours used in Progress and the live workout timer.
- (UIView *)blockForMode:(NSString *)modeTitle
                   stats:(NSDictionary *)stats
{
    NSInteger sessions   = [stats[@"sessions"]   integerValue];
    NSInteger exercises  = [stats[@"exercises"]  integerValue];
    NSInteger percent    = [stats[@"percent"]    integerValue];
    NSInteger avgMs       = [stats[@"avgMs"]      integerValue];
    NSInteger bestStreak = [stats[@"bestStreak"] integerValue];

    UILabel *header = [[UILabel alloc] init];
    header.text      = modeTitle;
    header.font      = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    header.textColor = [UIColor secondaryLabelColor];

    UIStackView *block = [[UIStackView alloc] initWithArrangedSubviews:@[header]];
    block.axis    = UILayoutConstraintAxisVertical;
    block.spacing = 4.0;

    if (exercises == 0)
    {
        // This mode unused, but the other one has data – show a quiet dash.
        UILabel *none = [self lineLabel];
        none.attributedText = nil;
        none.text           = @"—";
        none.textColor      = [UIColor tertiaryLabelColor];
        [block addArrangedSubview:none];
        return block;
    }

    // Line 1: "6 sessions · 84 exercises · 91%"  (the % coloured)
    NSString *sessionsWord  = sessions  == 1 ? BGGLocalizedString(@"session")
                                             : BGGLocalizedString(@"sessions");
    NSString *exercisesWord = exercises == 1 ? BGGLocalizedString(@"exercise")
                                             : BGGLocalizedString(@"exercises");

    NSMutableAttributedString *line1 = [[NSMutableAttributedString alloc] init];
    [line1 appendAttributedString:[self plain:[NSString stringWithFormat:@"%ld %@ · %ld %@ · ",
                                               (long)sessions, sessionsWord,
                                               (long)exercises, exercisesWord]]];
    [line1 appendAttributedString:[self coloured:[NSString stringWithFormat:@"%ld%%", (long)percent]
                                            color:[BGGTimeColor colorForRate:percent]]];

    UILabel *l1 = [self lineLabel];
    l1.attributedText = line1;

    // Line 2: "⌀ 18s · best streak 12"  (the time coloured)
    NSInteger avgSeconds = (NSInteger)round((double)avgMs / 1000.0);

    NSMutableAttributedString *line2 = [[NSMutableAttributedString alloc] init];
    [line2 appendAttributedString:[self plain:@"⌀ "]];
    [line2 appendAttributedString:[self coloured:[self timeStringForSeconds:avgSeconds]
                                            color:[BGGTimeColor colorForSeconds:avgSeconds]]];
    [line2 appendAttributedString:[self plain:[NSString stringWithFormat:@" · %@ %ld",
                                               BGGLocalizedString(@"best streak"),
                                               (long)bestStreak]]];

    UILabel *l2 = [self lineLabel];
    l2.attributedText = line2;

    [block addArrangedSubview:l1];
    [block addArrangedSubview:l2];
    return block;
}

#pragma mark - Small helpers

- (UILabel *)lineLabel
{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.font          = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    lbl.adjustsFontForContentSizeCategory = YES;
    lbl.numberOfLines = 0;
    return lbl;
}

- (NSAttributedString *)plain:(NSString *)text
{
    return [[NSAttributedString alloc] initWithString:text
                                           attributes:@{
        NSForegroundColorAttributeName: [UIColor labelColor]
    }];
}

- (NSAttributedString *)coloured:(NSString *)text
                           color:(UIColor *)color
{
    return [[NSAttributedString alloc] initWithString:text
                                           attributes:@{
        NSForegroundColorAttributeName: color
    }];
}

// Same wording as BGGSessionCell: "17 seconds" under a minute,
// "1 min 25 sec" from a minute on.
- (NSString *)timeStringForSeconds:(NSInteger)seconds
{
    if (seconds < 60)
    {
        return [NSString stringWithFormat:@"%ld %@", (long)seconds,
                BGGLocalizedString(@"seconds")];
    }
    NSInteger min = seconds / 60;
    NSInteger sec = seconds % 60;
    return [NSString stringWithFormat:@"%ld %@ %ld %@",
            (long)min, BGGLocalizedString(@"min"),
            (long)sec, BGGLocalizedString(@"sec")];
}

@end
