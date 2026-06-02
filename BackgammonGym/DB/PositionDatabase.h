//
//  PositionDatabase.h
//  BackgammonGym
//
//  Loads positions.json from the app bundle and vends BGGBoardState objects.
//  The JSON is read-only at runtime; I never write back to it.
//  User-created positions go into Core Data (CollectionPosition), not here.
//
//  JSON format:
//  {
//    "positions": [
//      {
//        "id": "4HPwATDgc/ABMA",
//        "tags": ["race", "pipcount", "cluster"],   // up to 5 tags
//        "difficulty": 1,
//        "note": "dev comment, not shown in UI"
//      }
//    ]
//  }
//

#import <Foundation/Foundation.h>

@class BGGBoardState;

NS_ASSUME_NONNULL_BEGIN

// A single entry from positions.json.
@interface BGGPositionEntry : NSObject

@property (nonatomic, copy,   readonly) NSString            *positionID;  // GNU Position ID
@property (nonatomic, copy,   readonly) NSArray<NSString *> *tags;        // up to 5 tags
@property (nonatomic, assign, readonly) NSInteger            difficulty;  // 1–3
@property (nonatomic, copy,   readonly) NSString            *note;        // dev comment, not shown in UI

// Convenience: YES if the entry has the given tag.
- (BOOL)hasTag:(NSString *)tag;

// Decode the position into a board state on demand.
// The board can always be drawn from the ID alone – it does not depend
// on the entry still being in the JSON.
- (nullable BGGBoardState *)boardState;

@end


@interface PositionDatabase : NSObject

// Shared instance – the JSON is loaded once and cached.
+ (instancetype)sharedDatabase;

// All positions, in the order they appear in the JSON.
@property (nonatomic, copy, readonly) NSArray<BGGPositionEntry *> *allPositions;

// Returns all positions that have the given tag.
- (NSArray<BGGPositionEntry *> *)positionsForTag:(NSString *)tag;

// Returns all positions that have the given tag and difficulty.
- (NSArray<BGGPositionEntry *> *)positionsForTag:(NSString *)tag
                                      difficulty:(NSInteger)difficulty;

// Returns a random position that has the given tag.
// Returns nil if no matching positions exist.
- (nullable BGGPositionEntry *)randomPositionForTag:(NSString *)tag;

@end

NS_ASSUME_NONNULL_END
