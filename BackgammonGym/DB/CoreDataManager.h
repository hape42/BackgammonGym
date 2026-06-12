//
//  CoreDataManager.h
//  BackgammonGym
//
//  Core Data stack as a singleton, backed by CloudKit so a user's own
//  devices (iPhone / iPad) stay in sync. This is a personal training app:
//  there is no sharing between different people, so a single private store
//  is enough – no shared store, no ownership anchors, no merge handling.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CloudKit/CloudKit.h>

#import "BGGWorkout+CoreDataClass.h"
#import "BGGAttempt+CoreDataClass.h"
#import "BGGMETAttempt+CoreDataClass.h"
#import "BGGEarnedAchievement+CoreDataClass.h"
#import "BGGDayActivity+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataManager : NSObject

@property (readonly, strong, nonatomic) NSPersistentCloudKitContainer *persistentContainer;

+ (instancetype)sharedManager;

// Central save / rollback.
- (void)saveContext;
- (void)cancelContext;

// MARK: Workouts

// Creates a new workout (a training session) and returns it. Not yet saved.
- (BGGWorkout *)createWorkoutWithModule:(NSString *)module
                                   mode:(NSString *)mode
                             totalCount:(NSInteger)totalCount;

// All workouts, newest first.
- (NSArray<BGGWorkout *> *)getAllWorkouts;

// Workouts for a given module and/or mode (pass nil to ignore that filter),
// newest first.
- (NSArray<BGGWorkout *> *)getWorkoutsForModule:(nullable NSString *)module
                                           mode:(nullable NSString *)mode;

- (void)deleteWorkout:(BGGWorkout *)workout;

// MARK: Attempts (pip count)

// Records one pip-count attempt inside a workout. Returns the new attempt
// (not saved; call saveContext after the workout finishes, or save per
// attempt).
- (BGGAttempt *)addAttemptToWorkout:(BGGWorkout *)workout
                         positionID:(NSString *)positionID
                          isCorrect:(BOOL)isCorrect
                          elapsedMs:(NSInteger)elapsedMs
                         userPlayer:(NSInteger)userPlayer
                       userOpponent:(NSInteger)userOpponent
                      correctPlayer:(NSInteger)correctPlayer
                    correctOpponent:(NSInteger)correctOpponent;

// All pip-count attempts, newest first (optionally filtered by module/mode).
- (NSArray<BGGAttempt *> *)getAttemptsForModule:(nullable NSString *)module
                                           mode:(nullable NSString *)mode;

// MARK: MET attempts

// Records one MET attempt inside a workout. The user answered with a single
// percentage for the score playerAway vs opponentAway; correctEquity is the
// rounded table value and toleranceUsed is the tolerance (percent) that was
// in effect. Returns the new attempt (not saved).
- (BGGMETAttempt *)addMETAttemptToWorkout:(BGGWorkout *)workout
                               playerAway:(NSInteger)playerAway
                             opponentAway:(NSInteger)opponentAway
                               userEquity:(NSInteger)userEquity
                            correctEquity:(NSInteger)correctEquity
                            toleranceUsed:(NSInteger)toleranceUsed
                                isCorrect:(BOOL)isCorrect
                                elapsedMs:(NSInteger)elapsedMs;

// All MET attempts, newest first (optionally filtered by mode).
- (NSArray<BGGMETAttempt *> *)getMETAttemptsForMode:(nullable NSString *)mode;

// MARK: Achievements

// Returns the earned achievement for an identifier, or nil if not yet earned.
- (nullable BGGEarnedAchievement *)earnedAchievementWithIdentifier:(NSString *)identifier;

// Marks an achievement as earned (idempotent: does nothing if already earned).
// Returns the achievement (existing or newly created).
- (BGGEarnedAchievement *)earnAchievementWithIdentifier:(NSString *)identifier
                                                 module:(nullable NSString *)module
                                                   mode:(nullable NSString *)mode;

- (NSArray<BGGEarnedAchievement *> *)getAllEarnedAchievements;

// MARK: Activity grid

// Raises today's activity level if the new level is higher than what is
// already stored (open = 1, training = 2, workout = 3). Never lowers it,
// so the day always reflects its highest activity. Saves immediately.
- (void)bumpTodayActivityToLevel:(NSInteger)level;

// Returns a map "YYYY-MM-DD" -> highest level (NSNumber) for the last
// `days` days (including today). Days with no activity are simply absent
// from the dictionary; the caller treats a missing day as level 0. If the
// CloudKit sync produced more than one row for the same day, the highest
// level wins.
- (NSDictionary<NSString *, NSNumber *> *)activityLevelsForLastDays:(NSInteger)days;

// MARK: Aggregation for charts

// Builds a chart-friendly array: one dictionary per workout, oldest first
// (left to right on the time axis). Keys:
//   @"label"      NSString  – short date, e.g. "10 Jun"
//   @"percent"    NSNumber  – hit rate 0–100
//   @"avgSeconds" NSNumber  – average answer time in seconds
//   @"mode"       NSString  – "training" / "workout"
//   @"count"      NSNumber  – number of attempts in the session
// Optionally filtered by mode (pass nil for all).
- (NSArray<NSDictionary *> *)sessionChartDataForMode:(nullable NSString *)mode;

// Same as sessionChartDataForMode: but aggregates the MET attempts
// (metAttempts) of MET workouts instead of the pip-count attempts. Keeps the
// same dictionary shape so the trend chart can render either module.
- (NSArray<NSDictionary *> *)metSessionChartDataForMode:(nullable NSString *)mode;

@end

NS_ASSUME_NONNULL_END
