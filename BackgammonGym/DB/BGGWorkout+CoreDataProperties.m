//
//  BGGWorkout+CoreDataProperties.m
//  BackgammonGym
//
//  Created by Peter Schneider on 10.06.26.
//
//

#import "BGGWorkout+CoreDataProperties.h"

@implementation BGGWorkout (CoreDataProperties)

+ (NSFetchRequest<BGGWorkout *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"BGGWorkout"];
}

@dynamic finishedAt;
@dynamic mode;
@dynamic module;
@dynamic startedAt;
@dynamic totalCount;
@dynamic attempts;

@end
