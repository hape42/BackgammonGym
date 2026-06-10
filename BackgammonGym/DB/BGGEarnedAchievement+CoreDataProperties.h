//
//  BGGEarnedAchievement+CoreDataProperties.h
//  BackgammonGym
//
//  Created by Peter Schneider on 10.06.26.
//
//

#import "BGGEarnedAchievement+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface BGGEarnedAchievement (CoreDataProperties)

+ (NSFetchRequest<BGGEarnedAchievement *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSDate *earnedAt;
@property (nullable, nonatomic, copy) NSString *identifier;
@property (nullable, nonatomic, copy) NSString *mode;
@property (nullable, nonatomic, copy) NSString *module;

@end

NS_ASSUME_NONNULL_END
