//
//  BGGTimeColor.m
//  BackgammonGym
//

#import "BGGTimeColor.h"

NSString * const kBGGTimeGreenMaxKey  = @"PipTimeGreenMax";
NSString * const kBGGTimeOrangeMaxKey = @"PipTimeOrangeMax";

const NSInteger kBGGTimeGreenMaxDefault  = 20;
const NSInteger kBGGTimeOrangeMaxDefault = 60;

NSString * const kBGGRateGreenMinKey  = @"PipRateGreenMin";
NSString * const kBGGRateOrangeMinKey = @"PipRateOrangeMin";

const NSInteger kBGGRateGreenMinDefault  = 80;
const NSInteger kBGGRateOrangeMinDefault = 50;

// Smallest gap kept between the two thresholds so the ranges never cross.
static const NSInteger kMinGap = 1;

@implementation BGGTimeColor

+ (void)registerDefaults
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        kBGGTimeGreenMaxKey:  @(kBGGTimeGreenMaxDefault),
        kBGGTimeOrangeMaxKey: @(kBGGTimeOrangeMaxDefault),
        kBGGRateGreenMinKey:  @(kBGGRateGreenMinDefault),
        kBGGRateOrangeMinKey: @(kBGGRateOrangeMinDefault),
    }];
}

+ (NSInteger)greenMax
{
    NSInteger v = [[NSUserDefaults standardUserDefaults] integerForKey:kBGGTimeGreenMaxKey];
    return (v > 0) ? v : kBGGTimeGreenMaxDefault;
}

+ (NSInteger)orangeMax
{
    NSInteger v = [[NSUserDefaults standardUserDefaults] integerForKey:kBGGTimeOrangeMaxKey];
    return (v > 0) ? v : kBGGTimeOrangeMaxDefault;
}

+ (void)setGreenMax:(NSInteger)seconds
{
    if (seconds < 1) { seconds = 1; }

    // Keep green below orange.
    NSInteger orange = [self orangeMax];
    if (seconds >= orange) { seconds = orange - kMinGap; }
    if (seconds < 1)       { seconds = 1; }

    [[NSUserDefaults standardUserDefaults] setInteger:seconds forKey:kBGGTimeGreenMaxKey];
}

+ (void)setOrangeMax:(NSInteger)seconds
{
    // Keep orange above green.
    NSInteger green = [self greenMax];
    if (seconds <= green) { seconds = green + kMinGap; }

    [[NSUserDefaults standardUserDefaults] setInteger:seconds forKey:kBGGTimeOrangeMaxKey];
}

+ (UIColor *)colorForSeconds:(NSInteger)seconds
{
    if (seconds <= [self greenMax])  { return [UIColor systemGreenColor];  }
    if (seconds <= [self orangeMax]) { return [UIColor systemOrangeColor]; }
    return [UIColor systemRedColor];
}

// MARK: Hit-rate thresholds (higher is better)

+ (NSInteger)rateGreenMin
{
    NSInteger v = [[NSUserDefaults standardUserDefaults] integerForKey:kBGGRateGreenMinKey];
    return (v > 0) ? v : kBGGRateGreenMinDefault;
}

+ (NSInteger)rateOrangeMin
{
    NSInteger v = [[NSUserDefaults standardUserDefaults] integerForKey:kBGGRateOrangeMinKey];
    return (v > 0) ? v : kBGGRateOrangeMinDefault;
}

+ (void)setRateGreenMin:(NSInteger)percent
{
    if (percent > 100) { percent = 100; }
    // Green threshold must stay above the orange one.
    NSInteger orange = [self rateOrangeMin];
    if (percent <= orange) { percent = orange + kMinGap; }
    if (percent > 100)     { percent = 100; }
    [[NSUserDefaults standardUserDefaults] setInteger:percent forKey:kBGGRateGreenMinKey];
}

+ (void)setRateOrangeMin:(NSInteger)percent
{
    if (percent < 1) { percent = 1; }
    // Orange threshold must stay below the green one.
    NSInteger green = [self rateGreenMin];
    if (percent >= green) { percent = green - kMinGap; }
    if (percent < 1)      { percent = 1; }
    [[NSUserDefaults standardUserDefaults] setInteger:percent forKey:kBGGRateOrangeMinKey];
}

+ (UIColor *)colorForRate:(NSInteger)percent
{
    if (percent >= [self rateGreenMin])  { return [UIColor systemGreenColor];  }
    if (percent >= [self rateOrangeMin]) { return [UIColor systemOrangeColor]; }
    return [UIColor systemRedColor];
}

+ (UIColor *)faintColorForSeconds:(NSInteger)seconds
{
    // A low-alpha tint of the strong colour, so the live timer hints at the
    // current band without the loud feel of a solid badge.
    return [[self colorForSeconds:seconds] colorWithAlphaComponent:0.20];
}

@end
