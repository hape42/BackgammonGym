//
//  BGGWorkout+CoreDataProperties.h
//  BackgammonGym
//
//  Created by Peter Schneider on 10.06.26.
//
//

#import "BGGWorkout+CoreDataClass.h"

@class BGGAttempt;
@class BGGMETAttempt;

NS_ASSUME_NONNULL_BEGIN

@interface BGGWorkout (CoreDataProperties)

+ (NSFetchRequest<BGGWorkout *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSDate *finishedAt;
@property (nullable, nonatomic, copy) NSString *mode;
@property (nullable, nonatomic, copy) NSString *module;
@property (nullable, nonatomic, copy) NSDate *startedAt;
@property (nonatomic) int32_t totalCount;

// Pip-count attempts (module "pipcount").
@property (nullable, nonatomic, retain) NSSet<BGGAttempt *> *attempts;

// MET attempts (module "met"). A workout holds exactly one module's worth
// of attempts; which set is populated depends on workout.module.
@property (nullable, nonatomic, retain) NSSet<BGGMETAttempt *> *metAttempts;

@end

@interface BGGWorkout (CoreDataGeneratedAccessors)

- (void)addAttemptsObject:(BGGAttempt *)value;
- (void)removeAttemptsObject:(BGGAttempt *)value;
- (void)addAttempts:(NSSet<BGGAttempt *> *)values;
- (void)removeAttempts:(NSSet<BGGAttempt *> *)values;

- (void)addMetAttemptsObject:(BGGMETAttempt *)value;
- (void)removeMetAttemptsObject:(BGGMETAttempt *)value;
- (void)addMetAttempts:(NSSet<BGGMETAttempt *> *)values;
- (void)removeMetAttempts:(NSSet<BGGMETAttempt *> *)values;

@end

NS_ASSUME_NONNULL_END
