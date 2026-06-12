//
//  BGGDayActivity+CoreDataProperties.h
//  BackgammonGym
//
//  Created by Peter Schneider on 11.06.26.
//
//

#import "BGGDayActivity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface BGGDayActivity (CoreDataProperties)

+ (NSFetchRequest<BGGDayActivity *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSString *day;
@property (nonatomic) int16_t level;

@end

NS_ASSUME_NONNULL_END
