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
#import "BGGEarnedAchievement+CoreDataClass.h"

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

// MARK: Attempts

// Records one attempt inside a workout. Returns the new attempt (not saved;
// call saveContext after the workout finishes, or save per attempt).
- (BGGAttempt *)addAttemptToWorkout:(BGGWorkout *)workout
                         positionID:(NSString *)positionID
                          isCorrect:(BOOL)isCorrect
                          elapsedMs:(NSInteger)elapsedMs
                         userPlayer:(NSInteger)userPlayer
                       userOpponent:(NSInteger)userOpponent
                      correctPlayer:(NSInteger)correctPlayer
                    correctOpponent:(NSInteger)correctOpponent;

// All attempts, newest first (optionally filtered by module/mode).
- (NSArray<BGGAttempt *> *)getAttemptsForModule:(nullable NSString *)module
                                           mode:(nullable NSString *)mode;

// MARK: Achievements

// Returns the earned achievement for an identifier, or nil if not yet earned.
- (nullable BGGEarnedAchievement *)earnedAchievementWithIdentifier:(NSString *)identifier;

// Marks an achievement as earned (idempotent: does nothing if already earned).
// Returns the achievement (existing or newly created).
- (BGGEarnedAchievement *)earnAchievementWithIdentifier:(NSString *)identifier
                                                 module:(nullable NSString *)module
                                                   mode:(nullable NSString *)mode;

- (NSArray<BGGEarnedAchievement *> *)getAllEarnedAchievements;

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

@end

NS_ASSUME_NONNULL_END
