//
//  BGGPosition.h
//  BackgammonGym
//
//  Encodes and decodes GNU Position IDs and Match IDs.
//
//  The GNU formats are the single source of truth for positions in this app.
//  XGID is an import-only format; it gets converted to GNU on the way in
//  and is never stored internally.
//
//  Spec references:
//  - Position ID: https://www.gnu.org/software/gnubg/manual/html_node/A-technical-description-of-the-Position-ID.html
//  - Match ID:    https://www.gnu.org/software/gnubg/manual/html_node/A-technical-description-of-the-Match-ID.html
//

#import <Foundation/Foundation.h>

@class BGGBoardState;

NS_ASSUME_NONNULL_BEGIN

@interface BGGPosition : NSObject

// MARK: - Decode

// Decode a GNU Position ID (14 Base64 chars) into a BGGBoardState.
// The resulting board state has checkers placed from the perspective
// of the player on roll: their point 1 maps to our point 1.
// Returns nil if the string is not a valid Position ID.
+ (nullable BGGBoardState *)boardStateFromPositionID:(NSString *)positionID;

// Decode a GNU Match ID (12 Base64 chars) into the match context fields
// of an existing BGGBoardState. Call this after boardStateFromPositionID:
// to fill in cube value, score, match length, etc.
// Returns NO if the string is not a valid Match ID.
+ (BOOL)applyMatchID:(NSString *)matchID toBoardState:(BGGBoardState *)boardState;

// Convenience: decode a combined "posID matchID" or "posID/matchID" string.
+ (nullable BGGBoardState *)boardStateFromCombinedID:(NSString *)combinedID;

// MARK: - Encode

// Encode a BGGBoardState into a 14-character GNU Position ID.
+ (nullable NSString *)positionIDFromBoardState:(BGGBoardState *)boardState;

// Encode the match context of a BGGBoardState into a 12-character GNU Match ID.
+ (nullable NSString *)matchIDFromBoardState:(BGGBoardState *)boardState;

// Convenience: returns "positionID matchID" as a single string.
+ (nullable NSString *)combinedIDFromBoardState:(BGGBoardState *)boardState;

@end

NS_ASSUME_NONNULL_END
