//
//  BGGMETSettings.m
//  BackgammonGym
//

#import "BGGMETSettings.h"

static NSString * const kMETTolerancePercent = @"METTolerancePercent";

static const NSInteger kMinTolerance = 0;
static const NSInteger kMaxTolerance = 3;
static const NSInteger kDefaultTolerance = 0;

@implementation BGGMETSettings

+ (void)registerDefaults
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        kMETTolerancePercent: @(kDefaultTolerance),
    }];
}

+ (NSInteger)tolerancePercent
{
    NSInteger value = [[NSUserDefaults standardUserDefaults]
                       integerForKey:kMETTolerancePercent];
    return [self clamp:value];
}

+ (void)setTolerancePercent:(NSInteger)percent
{
    [[NSUserDefaults standardUserDefaults] setInteger:[self clamp:percent]
                                               forKey:kMETTolerancePercent];
}

+ (NSInteger)clamp:(NSInteger)value
{
    if (value < kMinTolerance) { return kMinTolerance; }
    if (value > kMaxTolerance) { return kMaxTolerance; }
    return value;
}

@end
