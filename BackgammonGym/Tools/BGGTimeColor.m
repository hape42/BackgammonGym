//
//  BGGTimeColor.m
//  BackgammonGym
//

#import "BGGTimeColor.h"

NSString * const kBGGTimeGreenMaxKey  = @"PipTimeGreenMax";
NSString * const kBGGTimeOrangeMaxKey = @"PipTimeOrangeMax";

const NSInteger kBGGTimeGreenMaxDefault  = 20;
const NSInteger kBGGTimeOrangeMaxDefault = 60;

// Smallest gap kept between the two thresholds so the ranges never cross.
static const NSInteger kMinGap = 1;

@implementation BGGTimeColor

+ (void)registerDefaults
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        kBGGTimeGreenMaxKey:  @(kBGGTimeGreenMaxDefault),
        kBGGTimeOrangeMaxKey: @(kBGGTimeOrangeMaxDefault),
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

+ (UIColor *)faintColorForSeconds:(NSInteger)seconds
{
    // A low-alpha tint of the strong colour, so the live timer hints at the
    // current band without the loud feel of a solid badge.
    return [[self colorForSeconds:seconds] colorWithAlphaComponent:0.20];
}

@end
