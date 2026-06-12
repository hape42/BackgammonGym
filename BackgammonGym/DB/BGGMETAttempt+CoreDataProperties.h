//
//  BGGMETAttempt+CoreDataProperties.h
//  BackgammonGym
//

#import "BGGMETAttempt+CoreDataClass.h"

@class BGGWorkout;

NS_ASSUME_NONNULL_BEGIN

@interface BGGMETAttempt (CoreDataProperties)

+ (NSFetchRequest<BGGMETAttempt *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSDate *timestamp;

// The score being asked about, in away-points (both 1...11).
@property (nonatomic) int16_t playerAway;
@property (nonatomic) int16_t opponentAway;

// What the user typed (whole percent) and the correct rounded table value.
@property (nonatomic) int16_t userEquity;
@property (nonatomic) int16_t correctEquity;

// The tolerance (in percent) that applied at the time of this attempt.
// Stored per attempt because it is configurable in Settings and may change
// later – this keeps old attempts interpretable.
@property (nonatomic) int16_t toleranceUsed;

@property (nonatomic) BOOL isCorrect;
@property (nonatomic) int32_t elapsedMs;

// Duplicated from the workout for join-free filtering, mirroring how
// BGGAttempt stores mode. "training" / "workout".
@property (nullable, nonatomic, copy) NSString *mode;

@property (nullable, nonatomic, retain) BGGWorkout *workout;

@end

NS_ASSUME_NONNULL_END
