//
//  BGGMETAttempt+CoreDataClass.h
//  BackgammonGym
//
//  One attempt inside a Match Equity Table workout. The user is asked for
//  the match-winning chance at a given score (playerAway vs opponentAway)
//  and types a single percentage. I keep this separate from BGGAttempt
//  (the pip-count attempt) on purpose: every module gets its own attempt
//  type with fields that actually fit it, rather than overloading one
//  generic row. BGGWorkout is the shared, module-neutral session container.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BGGWorkout;

NS_ASSUME_NONNULL_BEGIN

@interface BGGMETAttempt : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "BGGMETAttempt+CoreDataProperties.h"
