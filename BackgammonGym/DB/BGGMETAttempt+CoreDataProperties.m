//
//  BGGMETAttempt+CoreDataProperties.m
//  BackgammonGym
//

#import "BGGMETAttempt+CoreDataProperties.h"

@implementation BGGMETAttempt (CoreDataProperties)

+ (NSFetchRequest<BGGMETAttempt *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"BGGMETAttempt"];
}

@dynamic timestamp;
@dynamic playerAway;
@dynamic opponentAway;
@dynamic userEquity;
@dynamic correctEquity;
@dynamic toleranceUsed;
@dynamic isCorrect;
@dynamic elapsedMs;
@dynamic mode;
@dynamic workout;

@end
