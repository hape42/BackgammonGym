//
//  BGGAchievements.h
//  BackgammonGym
//
//  The one place that defines every achievement and decides when it is
//  earned. Definitions live in code (not in settings): an achievement is a
//  fixed performance bar, and its whole value depends on it meaning the same
//  thing for everyone. The user can never lower it.
//
//  Scope decisions (see project doc):
//   - Only WORKOUT data counts towards achievements. Training has crutches
//     (numbers on the board, MET hints), so it is not a real performance.
//   - Count / streak / speed achievements are per module (pipcount, met).
//   - Activity-streak achievements are cross-module, read from the activity
//     grid (a day counts as soon as the app was opened, level >= 1).
//   - Checking is always retroactive: it re-derives progress from the whole
//     history, so awarding works even for sessions played before this code
//     existed. Awarding is idempotent; a check returns only what was newly
//     earned in that run, so the same trophy is never celebrated twice.
//
//  This class is pure logic over CoreDataManager; it holds no Core Data
//  itself. It mirrors BGGTimeColor / BGGMETSettings in living under Tools/.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// The tier of an achievement. Used for sorting and for picking the medal
// colour in the UI later.
typedef NS_ENUM(NSInteger, BGGAchievementTier)
{
    BGGAchievementTierBronze = 0,
    BGGAchievementTierSilver = 1,
    BGGAchievementTierGold   = 2,
};

// The category an achievement belongs to. Groups the catalogue for display.
typedef NS_ENUM(NSInteger, BGGAchievementCategory)
{
    BGGAchievementCategoryCount    = 0,   // total workout exercises solved
    BGGAchievementCategoryStreak   = 1,   // correct in a row within a session
    BGGAchievementCategorySpeed    = 2,   // fast correct answers (cumulative)
    BGGAchievementCategoryActivity = 3,   // consecutive active days (grid)
};

// One immutable achievement definition. `identifier` is the stable key stored
// in Core Data (BGGEarnedAchievement.identifier); never change a shipped one.
@interface BGGAchievementDefinition : NSObject

@property (nonatomic, readonly, copy)   NSString *identifier;
@property (nonatomic, readonly, copy)   NSString *titleKey;   // BGGLocalizedString key
@property (nonatomic, readonly)         BGGAchievementCategory category;
@property (nonatomic, readonly)         BGGAchievementTier     tier;
// module is "pipcount" / "met" for per-module achievements, or nil for the
// cross-module activity achievements.
@property (nonatomic, readonly, copy, nullable) NSString *module;
// The numeric bar (exercises, streak length, fast-answer count, or days).
@property (nonatomic, readonly)         NSInteger threshold;

@end


@interface BGGAchievements : NSObject

+ (instancetype)sharedAchievements;

// The full catalogue, in display order (category, then module, then tier).
- (NSArray<BGGAchievementDefinition *> *)allDefinitions;

// Look up a single definition by its identifier (nil if unknown).
- (nullable BGGAchievementDefinition *)definitionForIdentifier:(NSString *)identifier;

// Re-derives progress from the whole history and awards everything that is
// now satisfied (idempotent). Returns the definitions that were *newly*
// earned in this run, so the caller can celebrate only those. Saves the
// context once at the end if anything changed.
//
// Pass the module that just finished a workout ("pipcount" / "met") to also
// re-check that module's per-module achievements; the cross-module activity
// achievements are always re-checked. Pass nil to re-check everything (used
// for a full sweep, e.g. on first launch after the update).
- (NSArray<BGGAchievementDefinition *> *)checkAndAwardForModule:(nullable NSString *)module;

// Convenience: is a given definition already earned?
- (BOOL)isEarned:(BGGAchievementDefinition *)definition;

// Current progress towards a definition's threshold, as a cumulative value
// (e.g. 6 means "6 of threshold"). For an earned achievement this is simply
// >= threshold. Recomputed from the whole history. For rendering a whole
// list, prefer -progressForAllDefinitions which touches the database only
// once.
- (NSInteger)currentValueForDefinition:(BGGAchievementDefinition *)definition;

// Current value for every definition, keyed by identifier (NSNumber). Reads
// the database once and reuses the figures across all definitions, so a list
// view can render every row from one call.
- (NSDictionary<NSString *, NSNumber *> *)progressForAllDefinitions;

@end

NS_ASSUME_NONNULL_END
