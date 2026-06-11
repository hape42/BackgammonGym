//
//  BGGMatchEquityTable.h
//  BackgammonGym
//
//  The Rockwell-Kazaross match equity table (1-away through 11-away),
//  stored at full precision. Values are the match-winning chance (in
//  percent) for the player whose away-score is the row, against an
//  opponent whose away-score is the column.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BGGMatchEquityTable : NSObject

// The largest away-score the table covers (11).
@property (nonatomic, assign, readonly) NSInteger maxAway;

+ (instancetype)sharedTable;

// Match-winning chance (percent, full precision e.g. 32.31) for the player
// who is `playerAway` points from victory, against an opponent who is
// `opponentAway` points away. Both must be 1...maxAway.
- (double)equityForPlayerAway:(NSInteger)playerAway
                 opponentAway:(NSInteger)opponentAway;

// Same value rounded to a whole percent, for display and 1%-tolerance modes.
- (NSInteger)roundedEquityForPlayerAway:(NSInteger)playerAway
                           opponentAway:(NSInteger)opponentAway;

@end

NS_ASSUME_NONNULL_END
