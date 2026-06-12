//
//  CoreDataManager.m
//  BackgammonGym
//

#import "CoreDataManager.h"

@implementation CoreDataManager

+ (instancetype)sharedManager
{
    static CoreDataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _persistentContainer = [[NSPersistentCloudKitContainer alloc]
                                initWithName:@"BackgammonGym"];

        // Single private store, synced across the user's own devices.
        NSURL *storeURL = [[self applicationDocumentsDirectory]
                           URLByAppendingPathComponent:@"BackgammonGym.sqlite"];
        NSPersistentStoreDescription *desc =
            [[NSPersistentStoreDescription alloc] initWithURL:storeURL];

        desc.cloudKitContainerOptions =
            [[NSPersistentCloudKitContainerOptions alloc]
             initWithContainerIdentifier:@"iCloud.de.hape42.BackgammonGym"];
        desc.cloudKitContainerOptions.databaseScope = CKDatabaseScopePrivate;

        // History tracking so remote-change notifications are posted.
        [desc setOption:@YES forKey:NSPersistentHistoryTrackingKey];
        [desc setOption:@YES forKey:NSPersistentStoreRemoteChangeNotificationPostOptionKey];

        _persistentContainer.persistentStoreDescriptions = @[desc];

        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(handleRemoteChange:)
                   name:NSPersistentStoreRemoteChangeNotification
                 object:_persistentContainer.persistentStoreCoordinator];

        [_persistentContainer loadPersistentStoresWithCompletionHandler:
         ^(NSPersistentStoreDescription *description, NSError *error)
        {
            if (error == nil)
            {
                self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = YES;
                self.persistentContainer.viewContext.mergePolicy =
                    NSMergeByPropertyObjectTrumpMergePolicy;

                // The store is ready now, so it's safe to record that the app
                // was opened today (activity level 1). Doing it here rather than
                // in the AppDelegate guarantees the context is loaded first.
                [self bumpTodayActivityToLevel:1];
            }
            else
            {
                NSLog(@"[CoreData] load error: %@", error.localizedDescription);
            }
        }];

        NSURL *loadedURL = [[self.persistentContainer.persistentStoreDescriptions firstObject] URL];
        NSLog(@"[CoreData] store path: %@", loadedURL.path);
    }
    return self;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

// Another of the user's devices changed the store. Tell the UI to refresh.
- (void)handleRemoteChange:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshAllViews"
                                                            object:nil];
    });
}

#pragma mark - Save / cancel

- (void)saveContext
{
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    if ([context hasChanges])
    {
        NSError *error = nil;
        if (![context save:&error])
        {
            NSLog(@"[CoreData] save error: %@", error);
        }
    }
}

- (void)cancelContext
{
    [self.persistentContainer.viewContext rollback];
}

#pragma mark - Workouts

- (BGGWorkout *)createWorkoutWithModule:(NSString *)module
                                   mode:(NSString *)mode
                             totalCount:(NSInteger)totalCount
{
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    BGGWorkout *workout = [NSEntityDescription insertNewObjectForEntityForName:@"BGGWorkout"
                                                       inManagedObjectContext:context];
    workout.startedAt  = [NSDate date];
    workout.module     = module;
    workout.mode       = mode;
    workout.totalCount = (int32_t)totalCount;
    return workout;
}

- (NSArray<BGGWorkout *> *)getAllWorkouts
{
    return [self getWorkoutsForModule:nil mode:nil];
}

- (NSArray<BGGWorkout *> *)getWorkoutsForModule:(nullable NSString *)module
                                           mode:(nullable NSString *)mode
{
    NSFetchRequest *request = [BGGWorkout fetchRequest];
    request.predicate       = [self predicateForModule:module mode:mode];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startedAt"
                                                              ascending:NO]];
    NSError *error = nil;
    NSArray *results = [self.persistentContainer.viewContext executeFetchRequest:request
                                                                          error:&error];
    return error ? @[] : results;
}

- (void)deleteWorkout:(BGGWorkout *)workout
{
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    [context deleteObject:workout];
    NSError *error = nil;
    if (![context save:&error])
    {
        NSLog(@"[CoreData] delete workout error: %@", error.localizedDescription);
    }
}

#pragma mark - Attempts

- (BGGAttempt *)addAttemptToWorkout:(BGGWorkout *)workout
                         positionID:(NSString *)positionID
                          isCorrect:(BOOL)isCorrect
                          elapsedMs:(NSInteger)elapsedMs
                         userPlayer:(NSInteger)userPlayer
                       userOpponent:(NSInteger)userOpponent
                      correctPlayer:(NSInteger)correctPlayer
                    correctOpponent:(NSInteger)correctOpponent
{
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    BGGAttempt *attempt = [NSEntityDescription insertNewObjectForEntityForName:@"BGGAttempt"
                                                       inManagedObjectContext:context];
    attempt.timestamp       = [NSDate date];
    attempt.positionID      = positionID;
    attempt.isCorrect       = isCorrect;
    attempt.elapsedMs       = (int32_t)elapsedMs;
    attempt.userPlayer      = (int32_t)userPlayer;
    attempt.userOpponent    = (int32_t)userOpponent;
    attempt.correctPlayer   = (int32_t)correctPlayer;
    attempt.correctOpponent = (int32_t)correctOpponent;

    // Duplicate module/mode from the workout so attempts can be filtered
    // without a join.
    attempt.module = workout.module;
    attempt.mode   = workout.mode;
    attempt.workout = workout;

    return attempt;
}

- (NSArray<BGGAttempt *> *)getAttemptsForModule:(nullable NSString *)module
                                           mode:(nullable NSString *)mode
{
    NSFetchRequest *request = [BGGAttempt fetchRequest];
    request.predicate       = [self predicateForModule:module mode:mode];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp"
                                                              ascending:NO]];
    NSError *error = nil;
    NSArray *results = [self.persistentContainer.viewContext executeFetchRequest:request
                                                                          error:&error];
    return error ? @[] : results;
}

#pragma mark - Achievements

- (nullable BGGEarnedAchievement *)earnedAchievementWithIdentifier:(NSString *)identifier
{
    NSFetchRequest *request = [BGGEarnedAchievement fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *results = [self.persistentContainer.viewContext executeFetchRequest:request
                                                                          error:&error];
    return error ? nil : results.firstObject;
}

- (BGGEarnedAchievement *)earnAchievementWithIdentifier:(NSString *)identifier
                                                 module:(nullable NSString *)module
                                                   mode:(nullable NSString *)mode
{
    BGGEarnedAchievement *existing = [self earnedAchievementWithIdentifier:identifier];
    if (existing != nil) { return existing; }

    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    BGGEarnedAchievement *earned =
        [NSEntityDescription insertNewObjectForEntityForName:@"BGGEarnedAchievement"
                                      inManagedObjectContext:context];
    earned.identifier = identifier;
    earned.earnedAt   = [NSDate date];
    earned.module     = module;
    earned.mode       = mode;
    return earned;
}

- (NSArray<BGGEarnedAchievement *> *)getAllEarnedAchievements
{
    NSFetchRequest *request = [BGGEarnedAchievement fetchRequest];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"earnedAt"
                                                              ascending:NO]];
    NSError *error = nil;
    NSArray *results = [self.persistentContainer.viewContext executeFetchRequest:request
                                                                          error:&error];
    return error ? @[] : results;
}

#pragma mark - Activity grid

// A fixed formatter for day keys: POSIX locale and a stable pattern so the
// string never drifts with the user's locale or 12/24h settings.
- (NSDateFormatter *)dayKeyFormatter
{
    static NSDateFormatter *df = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        df = [[NSDateFormatter alloc] init];
        df.locale     = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        df.dateFormat = @"yyyy-MM-dd";
    });
    return df;
}

- (void)bumpTodayActivityToLevel:(NSInteger)level
{
    if (level <= 0) { return; }

    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSString *today = [[self dayKeyFormatter] stringFromDate:[NSDate date]];

    // Find today's row(s). CloudKit may have created more than one, so fetch
    // all matches and keep the one with the highest level; raise that.
    NSFetchRequest *request = [BGGDayActivity fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"day == %@", today];

    NSError *error = nil;
    NSArray<BGGDayActivity *> *rows = [context executeFetchRequest:request error:&error];
    if (error) { rows = @[]; }

    BGGDayActivity *row = nil;
    int16_t best = 0;
    for (BGGDayActivity *candidate in rows)
    {
        if (row == nil || candidate.level > best)
        {
            row  = candidate;
            best = candidate.level;
        }
    }

    if (row == nil)
    {
        row = [NSEntityDescription insertNewObjectForEntityForName:@"BGGDayActivity"
                                           inManagedObjectContext:context];
        row.day   = today;
        row.level = (int16_t)level;
    }
    else if ((int16_t)level > row.level)
    {
        row.level = (int16_t)level;
    }
    else
    {
        return;   // nothing to raise, avoid a needless save
    }

    if (![context save:&error])
    {
        NSLog(@"[CoreData] bump activity error: %@", error.localizedDescription);
    }
}

- (NSDictionary<NSString *, NSNumber *> *)activityLevelsForLastDays:(NSInteger)days
{
    if (days <= 0) { return @{}; }

    // Lower bound: midnight `days-1` days ago, so today is included.
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *startOfToday = [cal startOfDayForDate:[NSDate date]];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    comps.day = -(days - 1);
    NSDate *cutoff = [cal dateByAddingComponents:comps toDate:startOfToday options:0];
    NSString *cutoffKey = [[self dayKeyFormatter] stringFromDate:cutoff];

    NSFetchRequest *request = [BGGDayActivity fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"day >= %@", cutoffKey];

    NSError *error = nil;
    NSArray<BGGDayActivity *> *rows = [self.persistentContainer.viewContext
                                       executeFetchRequest:request error:&error];
    if (error || rows.count == 0) { return @{}; }

    // Deduplicate per day, keeping the highest level.
    NSMutableDictionary<NSString *, NSNumber *> *map = [NSMutableDictionary dictionary];
    for (BGGDayActivity *r in rows)
    {
        if (r.day == nil) { continue; }
        NSNumber *existing = map[r.day];
        if (existing == nil || r.level > existing.intValue)
        {
            map[r.day] = @(r.level);
        }
    }
    return map;
}

#pragma mark - Aggregation for charts

- (NSArray<NSDictionary *> *)sessionChartDataForMode:(nullable NSString *)mode
{
    // Oldest first so the chart reads left-to-right over time.
    NSFetchRequest *request = [BGGWorkout fetchRequest];
    request.predicate       = [self predicateForModule:nil mode:mode];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startedAt"
                                                              ascending:YES]];
    NSError *error = nil;
    NSArray<BGGWorkout *> *workouts =
        [self.persistentContainer.viewContext executeFetchRequest:request error:&error];
    if (error || workouts.count == 0) { return @[]; }

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"d MMM";

    NSMutableArray<NSDictionary *> *out = [NSMutableArray array];
    for (BGGWorkout *w in workouts)
    {
        NSArray *attempts = w.attempts.allObjects;
        NSInteger count   = (NSInteger)attempts.count;
        if (count == 0) { continue; }   // skip empty sessions

        NSInteger correct = 0;
        NSInteger totalMs = 0;
        for (BGGAttempt *a in attempts)
        {
            if (a.isCorrect) { correct++; }
            totalMs += a.elapsedMs;
        }

        NSInteger percent    = (NSInteger)round((double)correct / count * 100.0);
        NSInteger avgSeconds = (NSInteger)round((double)(totalMs / count) / 1000.0);
        NSString *label      = w.startedAt ? [df stringFromDate:w.startedAt] : @"—";

        [out addObject:@{
            @"label":      label,
            @"percent":    @(percent),
            @"avgSeconds": @(avgSeconds),
            @"mode":       w.mode ?: @"",
            @"count":      @(count),
        }];
    }
    return out;
}

#pragma mark - Helpers

// Builds a predicate combining optional module and mode filters.
- (nullable NSPredicate *)predicateForModule:(nullable NSString *)module
                                        mode:(nullable NSString *)mode
{
    NSMutableArray<NSPredicate *> *subs = [NSMutableArray array];
    if (module != nil)
    {
        [subs addObject:[NSPredicate predicateWithFormat:@"module == %@", module]];
    }
    if (mode != nil)
    {
        [subs addObject:[NSPredicate predicateWithFormat:@"mode == %@", mode]];
    }
    if (subs.count == 0) { return nil; }
    return [NSCompoundPredicate andPredicateWithSubpredicates:subs];
}

@end
