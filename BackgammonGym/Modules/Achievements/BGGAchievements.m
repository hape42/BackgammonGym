//
//  BGGAchievements.m
//  BackgammonGym
//

#import "BGGAchievements.h"
#import "CoreDataManager.h"

#pragma mark - Definition

@interface BGGAchievementDefinition ()
@property (nonatomic, copy)   NSString *identifier;
@property (nonatomic, copy)   NSString *titleKey;
@property (nonatomic, assign) BGGAchievementCategory category;
@property (nonatomic, assign) BGGAchievementTier     tier;
@property (nonatomic, copy, nullable) NSString *module;
@property (nonatomic, assign) NSInteger threshold;
@end

@implementation BGGAchievementDefinition

+ (instancetype)withIdentifier:(NSString *)identifier
                      titleKey:(NSString *)titleKey
                      category:(BGGAchievementCategory)category
                          tier:(BGGAchievementTier)tier
                        module:(nullable NSString *)module
                     threshold:(NSInteger)threshold
{
    BGGAchievementDefinition *d = [[BGGAchievementDefinition alloc] init];
    d.identifier = identifier;
    d.titleKey   = titleKey;
    d.category   = category;
    d.tier       = tier;
    d.module     = module;
    d.threshold  = threshold;
    return d;
}

@end


#pragma mark - Achievements

@interface BGGAchievements ()
@property (nonatomic, strong) NSArray<BGGAchievementDefinition *> *definitions;
@end

@implementation BGGAchievements

+ (instancetype)sharedAchievements
{
    static BGGAchievements *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[BGGAchievements alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self buildCatalogue];
    }
    return self;
}

#pragma mark - Catalogue

// All thresholds live here, as agreed. Identifiers are stable keys: once a
// build has shipped, never rename one (it would orphan earned rows). Speed
// thresholds differ per module because tapping a MET percentage is far
// faster than counting pips.
- (void)buildCatalogue
{
    NSMutableArray<BGGAchievementDefinition *> *c = [NSMutableArray array];

    // Count (total workout exercises) – per module, 10 / 50 / 200.
    for (NSString *mod in @[@"pipcount", @"met"])
    {
        [c addObject:[BGGAchievementDefinition withIdentifier:[NSString stringWithFormat:@"%@.count.bronze", mod]
                                                     titleKey:@"ach.count.bronze"
                                                     category:BGGAchievementCategoryCount
                                                         tier:BGGAchievementTierBronze
                                                       module:mod threshold:10]];
        [c addObject:[BGGAchievementDefinition withIdentifier:[NSString stringWithFormat:@"%@.count.silver", mod]
                                                     titleKey:@"ach.count.silver"
                                                     category:BGGAchievementCategoryCount
                                                         tier:BGGAchievementTierSilver
                                                       module:mod threshold:50]];
        [c addObject:[BGGAchievementDefinition withIdentifier:[NSString stringWithFormat:@"%@.count.gold", mod]
                                                     titleKey:@"ach.count.gold"
                                                     category:BGGAchievementCategoryCount
                                                         tier:BGGAchievementTierGold
                                                       module:mod threshold:200]];
    }

    // Streak (correct in a row, within a workout session) – per module,
    // 5 / 10 / 20.
    for (NSString *mod in @[@"pipcount", @"met"])
    {
        [c addObject:[BGGAchievementDefinition withIdentifier:[NSString stringWithFormat:@"%@.streak.bronze", mod]
                                                     titleKey:@"ach.streak.bronze"
                                                     category:BGGAchievementCategoryStreak
                                                         tier:BGGAchievementTierBronze
                                                       module:mod threshold:5]];
        [c addObject:[BGGAchievementDefinition withIdentifier:[NSString stringWithFormat:@"%@.streak.silver", mod]
                                                     titleKey:@"ach.streak.silver"
                                                     category:BGGAchievementCategoryStreak
                                                         tier:BGGAchievementTierSilver
                                                       module:mod threshold:10]];
        [c addObject:[BGGAchievementDefinition withIdentifier:[NSString stringWithFormat:@"%@.streak.gold", mod]
                                                     titleKey:@"ach.streak.gold"
                                                     category:BGGAchievementCategoryStreak
                                                         tier:BGGAchievementTierGold
                                                       module:mod threshold:20]];
    }

    // Speed (fast correct workout answers, cumulative) – per module, but with
    // different second thresholds. The "threshold" here is the *count* of
    // fast answers (always 10); the per-tier seconds bar is read from
    // -speedSecondsForModule:tier:. Storing the count keeps the struct simple
    // and uniform with the other categories.
    for (NSString *mod in @[@"pipcount", @"met"])
    {
        [c addObject:[BGGAchievementDefinition withIdentifier:[NSString stringWithFormat:@"%@.speed.bronze", mod]
                                                     titleKey:@"ach.speed.bronze"
                                                     category:BGGAchievementCategorySpeed
                                                         tier:BGGAchievementTierBronze
                                                       module:mod threshold:10]];
        [c addObject:[BGGAchievementDefinition withIdentifier:[NSString stringWithFormat:@"%@.speed.silver", mod]
                                                     titleKey:@"ach.speed.silver"
                                                     category:BGGAchievementCategorySpeed
                                                         tier:BGGAchievementTierSilver
                                                       module:mod threshold:10]];
        [c addObject:[BGGAchievementDefinition withIdentifier:[NSString stringWithFormat:@"%@.speed.gold", mod]
                                                     titleKey:@"ach.speed.gold"
                                                     category:BGGAchievementCategorySpeed
                                                         tier:BGGAchievementTierGold
                                                       module:mod threshold:10]];
    }

    // Activity (consecutive active days, level >= 1) – cross-module,
    // 3 / 7 / 30. module is nil.
    [c addObject:[BGGAchievementDefinition withIdentifier:@"activity.streak.bronze"
                                                 titleKey:@"ach.activity.bronze"
                                                 category:BGGAchievementCategoryActivity
                                                     tier:BGGAchievementTierBronze
                                                   module:nil threshold:3]];
    [c addObject:[BGGAchievementDefinition withIdentifier:@"activity.streak.silver"
                                                 titleKey:@"ach.activity.silver"
                                                 category:BGGAchievementCategoryActivity
                                                     tier:BGGAchievementTierSilver
                                                   module:nil threshold:7]];
    [c addObject:[BGGAchievementDefinition withIdentifier:@"activity.streak.gold"
                                                 titleKey:@"ach.activity.gold"
                                                 category:BGGAchievementCategoryActivity
                                                     tier:BGGAchievementTierGold
                                                   module:nil threshold:30]];

    self.definitions = [c copy];
}

// Per-module seconds bar for the speed achievements. Pip count is genuine
// counting; MET is just tapping a percentage, so its bars are tighter.
- (NSInteger)speedSecondsForModule:(NSString *)module
                              tier:(BGGAchievementTier)tier
{
    BOOL isMET = [module isEqualToString:@"met"];
    switch (tier)
    {
        case BGGAchievementTierBronze: return isMET ? 12 : 30;
        case BGGAchievementTierSilver: return isMET ?  8 : 20;
        case BGGAchievementTierGold:   return isMET ?  5 : 12;
    }
    return 0;
}

#pragma mark - Lookup

- (NSArray<BGGAchievementDefinition *> *)allDefinitions
{
    return self.definitions;
}

- (nullable BGGAchievementDefinition *)definitionForIdentifier:(NSString *)identifier
{
    for (BGGAchievementDefinition *d in self.definitions)
    {
        if ([d.identifier isEqualToString:identifier]) { return d; }
    }
    return nil;
}

- (BOOL)isEarned:(BGGAchievementDefinition *)definition
{
    return [[CoreDataManager sharedManager]
            earnedAchievementWithIdentifier:definition.identifier] != nil;
}

#pragma mark - Progress

// The cumulative current value of a definition, given the precomputed
// figures for its module (or the activity streak for activity achievements).
// This is the single source both the check and the progress display use, so
// they can never disagree.
- (NSInteger)valueForDefinition:(BGGAchievementDefinition *)def
                        figures:(nullable NSDictionary *)figs
                 activityStreak:(NSInteger)activityStreak
{
    switch (def.category)
    {
        case BGGAchievementCategoryCount:
            return [figs[@"exercises"] integerValue];
        case BGGAchievementCategoryStreak:
            return [figs[@"bestStreak"] integerValue];
        case BGGAchievementCategorySpeed:
        {
            NSInteger seconds = [self speedSecondsForModule:def.module tier:def.tier];
            return [figs[[self fastKeyForSeconds:seconds]] integerValue];
        }
        case BGGAchievementCategoryActivity:
            return activityStreak;
    }
    return 0;
}

- (NSInteger)currentValueForDefinition:(BGGAchievementDefinition *)definition
{
    CoreDataManager *db = [CoreDataManager sharedManager];
    NSMutableDictionary *cache = [NSMutableDictionary dictionary];

    NSDictionary *figs = nil;
    NSInteger activityStreak = 0;

    if (definition.category == BGGAchievementCategoryActivity)
    {
        activityStreak = [self currentActivityDayStreakFromDB:db];
    }
    else
    {
        figs = [self workoutFiguresForModule:definition.module cache:cache db:db];
    }
    return [self valueForDefinition:definition figures:figs activityStreak:activityStreak];
}

- (NSDictionary<NSString *, NSNumber *> *)progressForAllDefinitions
{
    CoreDataManager *db = [CoreDataManager sharedManager];
    NSMutableDictionary *cache = [NSMutableDictionary dictionary];
    NSInteger activityStreak = -1;   // computed lazily, at most once

    NSMutableDictionary<NSString *, NSNumber *> *out = [NSMutableDictionary dictionary];
    for (BGGAchievementDefinition *def in self.definitions)
    {
        NSDictionary *figs = nil;
        if (def.category == BGGAchievementCategoryActivity)
        {
            if (activityStreak < 0)
            {
                activityStreak = [self currentActivityDayStreakFromDB:db];
            }
        }
        else
        {
            figs = [self workoutFiguresForModule:def.module cache:cache db:db];
        }
        NSInteger v = [self valueForDefinition:def
                                       figures:figs
                                activityStreak:(activityStreak < 0 ? 0 : activityStreak)];
        out[def.identifier] = @(v);
    }
    return [out copy];
}

#pragma mark - Checking & awarding

- (NSArray<BGGAchievementDefinition *> *)checkAndAwardForModule:(nullable NSString *)module
{
    CoreDataManager *db = [CoreDataManager sharedManager];
    NSMutableArray<BGGAchievementDefinition *> *newlyEarned = [NSMutableArray array];

    // Cache the per-module workout figures we need, so we compute each once.
    // Keyed by module. Each entry: exercises (count), bestStreak, and the
    // fast-answer counts per tier.
    NSMutableDictionary<NSString *, NSDictionary *> *cache = [NSMutableDictionary dictionary];

    // The activity-day streak (cross-module) is computed at most once.
    NSInteger activityStreak = -1;

    for (BGGAchievementDefinition *def in self.definitions)
    {
        // Skip the work if it is already earned (idempotent + cheap).
        if ([self isEarned:def]) { continue; }

        // For per-module achievements, only re-check the module that just
        // finished (or everything when module == nil).
        if (def.category != BGGAchievementCategoryActivity &&
            module != nil &&
            ![def.module isEqualToString:module])
        {
            continue;
        }

        // Compute the current value through the same path the progress
        // display uses, then compare against the bar.
        NSDictionary *figs = nil;
        if (def.category == BGGAchievementCategoryActivity)
        {
            if (activityStreak < 0)
            {
                activityStreak = [self currentActivityDayStreakFromDB:db];
            }
        }
        else
        {
            figs = [self workoutFiguresForModule:def.module cache:cache db:db];
        }
        NSInteger value = [self valueForDefinition:def
                                           figures:figs
                                    activityStreak:(activityStreak < 0 ? 0 : activityStreak)];

        if (value >= def.threshold)
        {
            [db earnAchievementWithIdentifier:def.identifier
                                       module:def.module
                                         mode:(def.category == BGGAchievementCategoryActivity
                                               ? nil : @"workout")];
            [newlyEarned addObject:def];
        }
    }

    if (newlyEarned.count > 0)
    {
        [db saveContext];
    }
    return [newlyEarned copy];
}

#pragma mark - Figure derivation

// Returns (and caches) the workout figures for a module:
//   @"exercises"   total workout attempts
//   @"bestStreak"  longest correct run in a session
//   @"fast<N>"     count of correct workout answers under N seconds, for each
//                  distinct seconds bar this module uses
- (NSDictionary *)workoutFiguresForModule:(NSString *)module
                                    cache:(NSMutableDictionary *)cache
                                       db:(CoreDataManager *)db
{
    NSDictionary *cached = cache[module];
    if (cached != nil) { return cached; }

    // Count + streak come straight from the statistics aggregator.
    NSDictionary *stats = [db statsForModule:module mode:@"workout"];

    // Speed needs the individual elapsed times. Gather correct workout
    // attempts and count how many fall under each tier's seconds bar.
    NSArray<NSNumber *> *correctMs = [self correctWorkoutElapsedMsForModule:module db:db];

    NSMutableDictionary *figs = [NSMutableDictionary dictionary];
    figs[@"exercises"]  = stats[@"exercises"]  ?: @0;
    figs[@"bestStreak"] = stats[@"bestStreak"] ?: @0;

    for (BGGAchievementTier tier = BGGAchievementTierBronze; tier <= BGGAchievementTierGold; tier++)
    {
        NSInteger seconds = [self speedSecondsForModule:module tier:tier];
        NSInteger limitMs = seconds * 1000;
        NSInteger fast = 0;
        for (NSNumber *ms in correctMs)
        {
            if (ms.integerValue < limitMs) { fast++; }
        }
        figs[[self fastKeyForSeconds:seconds]] = @(fast);
    }

    cache[module] = figs;
    return figs;
}

- (NSString *)fastKeyForSeconds:(NSInteger)seconds
{
    return [NSString stringWithFormat:@"fast%ld", (long)seconds];
}

// Elapsed times (ms) of all CORRECT workout attempts for a module. Only
// correct ones count, so fast wrong guessing never earns a speed badge.
- (NSArray<NSNumber *> *)correctWorkoutElapsedMsForModule:(NSString *)module
                                                       db:(CoreDataManager *)db
{
    NSMutableArray<NSNumber *> *out = [NSMutableArray array];
    if ([module isEqualToString:@"met"])
    {
        for (BGGMETAttempt *a in [db getMETAttemptsForMode:@"workout"])
        {
            if (a.isCorrect) { [out addObject:@(a.elapsedMs)]; }
        }
    }
    else
    {
        for (BGGAttempt *a in [db getAttemptsForModule:module mode:@"workout"])
        {
            if (a.isCorrect) { [out addObject:@(a.elapsedMs)]; }
        }
    }
    return out;
}

// Longest run of consecutive days (ending today or yesterday) on which the
// app was at least opened (grid level >= 1). "Ending yesterday" is allowed so
// the streak does not look broken before today's first activity is recorded.
- (NSInteger)currentActivityDayStreakFromDB:(CoreDataManager *)db
{
    // 400 days is plenty: it exceeds the gold bar (30) with room to spare and
    // matches the grid's ~12-month window.
    NSDictionary<NSString *, NSNumber *> *levels = [db activityLevelsForLastDays:400];
    if (levels.count == 0) { return 0; }

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale     = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    df.dateFormat = @"yyyy-MM-dd";
    df.timeZone   = [NSTimeZone localTimeZone];

    // Walk back day by day from today, counting while the day is active.
    // Allow the very first step (today) to be inactive, so a streak that ran
    // up to yesterday still counts before today's first session.
    NSInteger streak = 0;
    NSDate *day = [NSDate date];
    BOOL first = YES;

    while (YES)
    {
        NSString *key = [df stringFromDate:day];
        BOOL active = [levels[key] integerValue] >= 1;

        if (active)
        {
            streak++;
        }
        else if (!first)
        {
            break;   // a gap (other than possibly today) ends the streak
        }

        first = NO;
        NSDateComponents *minusOne = [[NSDateComponents alloc] init];
        minusOne.day = -1;
        day = [cal dateByAddingComponents:minusOne toDate:day options:0];

        // Safety bound: never look past what we fetched.
        if (streak > 400) { break; }
    }

    return streak;
}

@end
