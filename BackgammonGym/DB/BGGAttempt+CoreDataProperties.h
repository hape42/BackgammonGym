//
//  BGGAttempt+CoreDataProperties.h
//  BackgammonGym
//
//  Created by Peter Schneider on 10.06.26.
//
//

#import "BGGAttempt+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface BGGAttempt (CoreDataProperties)

+ (NSFetchRequest<BGGAttempt *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nonatomic) int32_t correctOpponent;
@property (nonatomic) int32_t correctPlayer;
@property (nonatomic) int32_t elapsedMs;
@property (nonatomic) BOOL isCorrect;
@property (nullable, nonatomic, copy) NSString *mode;
@property (nullable, nonatomic, copy) NSString *module;
@property (nullable, nonatomic, copy) NSString *positionID;
@property (nullable, nonatomic, copy) NSDate *timestamp;
@property (nonatomic) int32_t userOpponent;
@property (nonatomic) int32_t userPlayer;
@property (nullable, nonatomic, retain) BGGWorkout *workout;

@end

NS_ASSUME_NONNULL_END
