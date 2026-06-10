//
//  BGGWorkout+CoreDataProperties.h
//  BackgammonGym
//
//  Created by Peter Schneider on 10.06.26.
//
//

#import "BGGWorkout+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface BGGWorkout (CoreDataProperties)

+ (NSFetchRequest<BGGWorkout *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSDate *finishedAt;
@property (nullable, nonatomic, copy) NSString *mode;
@property (nullable, nonatomic, copy) NSString *module;
@property (nullable, nonatomic, copy) NSDate *startedAt;
@property (nonatomic) int32_t totalCount;
@property (nullable, nonatomic, retain) NSSet<BGGAttempt *> *attempts;

@end

@interface BGGWorkout (CoreDataGeneratedAccessors)

- (void)addAttemptsObject:(BGGAttempt *)value;
- (void)removeAttemptsObject:(BGGAttempt *)value;
- (void)addAttempts:(NSSet<BGGAttempt *> *)values;
- (void)removeAttempts:(NSSet<BGGAttempt *> *)values;

@end

NS_ASSUME_NONNULL_END
