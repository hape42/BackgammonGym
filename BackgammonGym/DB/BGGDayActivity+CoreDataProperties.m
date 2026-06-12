//
//  BGGDayActivity+CoreDataProperties.m
//  BackgammonGym
//
//  Created by Peter Schneider on 11.06.26.
//
//

#import "BGGDayActivity+CoreDataProperties.h"

@implementation BGGDayActivity (CoreDataProperties)

+ (NSFetchRequest<BGGDayActivity *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"BGGDayActivity"];
}

@dynamic day;
@dynamic level;

@end
