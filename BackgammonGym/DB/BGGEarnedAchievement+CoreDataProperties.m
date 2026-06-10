//
//  BGGEarnedAchievement+CoreDataProperties.m
//  BackgammonGym
//
//  Created by Peter Schneider on 10.06.26.
//
//

#import "BGGEarnedAchievement+CoreDataProperties.h"

@implementation BGGEarnedAchievement (CoreDataProperties)

+ (NSFetchRequest<BGGEarnedAchievement *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"BGGEarnedAchievement"];
}

@dynamic earnedAt;
@dynamic identifier;
@dynamic mode;
@dynamic module;

@end
