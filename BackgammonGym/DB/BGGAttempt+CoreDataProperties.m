//
//  BGGAttempt+CoreDataProperties.m
//  BackgammonGym
//
//  Created by Peter Schneider on 10.06.26.
//
//

#import "BGGAttempt+CoreDataProperties.h"

@implementation BGGAttempt (CoreDataProperties)

+ (NSFetchRequest<BGGAttempt *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"BGGAttempt"];
}

@dynamic correctOpponent;
@dynamic correctPlayer;
@dynamic elapsedMs;
@dynamic isCorrect;
@dynamic mode;
@dynamic module;
@dynamic positionID;
@dynamic timestamp;
@dynamic userOpponent;
@dynamic userPlayer;
@dynamic workout;

@end
