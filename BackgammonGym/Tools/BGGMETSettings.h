//
//  BGGMETSettings.h
//  BackgammonGym
//
//  Module-scoped settings for the Match Equity Table trainer, kept in
//  NSUserDefaults. I keep this separate from BGGTimeColor (which owns the
//  colour thresholds) so each module's settings live in their own small
//  class instead of one growing grab-bag. More MET settings can be added
//  here later without touching anything else.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BGGMETSettings : NSObject

// Registers the default values. Call once early (e.g. in SettingsVC or the
// MET view controllers) before reading any value.
+ (void)registerDefaults;

// Answer tolerance in whole percent. 0 means the answer must match the
// rounded table value exactly; 1...3 allow that much deviation in either
// direction. Clamped to 0...3.
+ (NSInteger)tolerancePercent;
+ (void)setTolerancePercent:(NSInteger)percent;

@end

NS_ASSUME_NONNULL_END
