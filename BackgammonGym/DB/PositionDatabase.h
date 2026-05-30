//
//  PositionDatabase.h
//  BackgammonGym
//
//  Loads positions.json from the app bundle and vends BGGBoardState objects.
//  The JSON is read-only at runtime; I never write back to it.
//  User-created positions go into Core Data (CollectionPosition), not here.
//

#import <Foundation/Foundation.h>

@class BGGBoardState;

NS_ASSUME_NONNULL_BEGIN

// A single entry from positions.json.
@interface BGGPositionEntry : NSObject

@property (nonatomic, copy,   readonly) NSString      *positionID;   // GNU Position ID
@property (nonatomic, copy,   readonly) NSString      *category;     // "race" / "contact" / "bearoff"
@property (nonatomic, assign, readonly) NSInteger      difficulty;   // 1–3
@property (nonatomic, copy,   readonly) NSString      *note;         // dev comment, not shown in UI

// Decode the position into a board state on demand.
// Returns nil if the position ID is invalid.
- (nullable BGGBoardState *)boardState;

@end


@interface PositionDatabase : NSObject

// Shared instance – the JSON is loaded once and cached.
+ (instancetype)sharedDatabase;

// All positions, in the order they appear in the JSON.
@property (nonatomic, copy, readonly) NSArray<BGGPositionEntry *> *allPositions;

// Filtered subsets.
- (NSArray<BGGPositionEntry *> *)positionsForCategory:(NSString *)category;
- (NSArray<BGGPositionEntry *> *)positionsForCategory:(NSString *)category
                                           difficulty:(NSInteger)difficulty;

// Returns a random position matching the given category.
// Returns nil if no matching positions exist.
- (nullable BGGPositionEntry *)randomPositionForCategory:(NSString *)category;

@end

NS_ASSUME_NONNULL_END
