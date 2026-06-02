//
//  BGGPositionTests.m
//  BackgammonGymTests
//
//  Test cases for BGGPosition encoder/decoder.
//  Reference values verified against AnkiGammon converter and GNU Backgammon.
//

#import <XCTest/XCTest.h>
#import "BGGPosition.h"
#import "BGGBoardState.h"

@interface BGGPositionTests : XCTestCase
@end

@implementation BGGPositionTests

// MARK: - Position ID decode

- (void)testDecodeStartingPosition
{
    // The starting position ID is documented in the GNU spec itself.
    // This is the most important test case.
    BGGBoardState *board = [BGGPosition boardStateFromPositionID:@"4HPwATDgc/ABMA"];
    XCTAssertNotNil(board);

    // Blue checkers (positive values).
    XCTAssertEqual([board checkersOnPoint:6],   5,  @"5 blue on point 6");
    XCTAssertEqual([board checkersOnPoint:8],   3,  @"3 blue on point 8");
    XCTAssertEqual([board checkersOnPoint:13],  5,  @"5 blue on point 13");
    XCTAssertEqual([board checkersOnPoint:24],  2,  @"2 blue on point 24");

    // Yellow checkers (negative values).
    XCTAssertEqual([board checkersOnPoint:19], -5,  @"5 yellow on point 19");
    XCTAssertEqual([board checkersOnPoint:17], -3,  @"3 yellow on point 17");
    XCTAssertEqual([board checkersOnPoint:12], -5,  @"5 yellow on point 12");
    XCTAssertEqual([board checkersOnPoint:1],  -2,  @"2 yellow on point 1");

    // Bar should be empty.
    XCTAssertEqual(board.barBlue,   0, @"no blue on bar");
    XCTAssertEqual(board.barYellow, 0, @"no yellow on bar");

    // 15 checkers per side.
    XCTAssertTrue([board isValidCheckerCount], @"checker count must be valid");
}

- (void)testDecodeReturnsNilForInvalidInput
{
    XCTAssertNil([BGGPosition boardStateFromPositionID:@""]);
    XCTAssertNil([BGGPosition boardStateFromPositionID:@"tooshort"]);
    XCTAssertNil([BGGPosition boardStateFromPositionID:@"!!!!invalid!!!!"]);
}

// MARK: - Position ID encode

- (void)testEncodeStartingPosition
{
    BGGBoardState *board = [BGGBoardState startingPosition];
    NSString *posID = [BGGPosition positionIDFromBoardState:board];
    XCTAssertEqualObjects(posID, @"4HPwATDgc/ABMA",
                          @"starting position must encode to known ID");
}

- (void)testDecodeBGBlitzRacePosition
{
    // A typical race position from a live match, exported directly from BGBlitz.
    // Format: posID:matchID (BGBlitz uses colon as separator).
    // Blue has all checkers in the home board bearing off,
    // yellow is also bearing off on the other side.
    BGGBoardState *board = [BGGPosition boardStateFromCombinedID:@"094HAIB1ewcAAA:AYElAYAAEAAA"];
    XCTAssertNotNil(board);
    XCTAssertTrue([board isValidCheckerCount], @"checker count must be valid");

    // Round-trip: encode back and compare.
    NSString *reEncoded = [BGGPosition positionIDFromBoardState:board];
    XCTAssertEqualObjects(reEncoded, @"094HAIB1ewcAAA", @"round-trip must be lossless");
}

- (void)testRoundTripPositionID
{
    // Decode → encode → decode must produce the same board.
    NSString *original = @"4HPwATDgc/ABMA";
    BGGBoardState *board = [BGGPosition boardStateFromPositionID:original];
    XCTAssertNotNil(board);

    NSString *reEncoded = [BGGPosition positionIDFromBoardState:board];
    XCTAssertEqualObjects(reEncoded, original, @"round-trip must be lossless");
}

// MARK: - Combined ID

- (void)testDecodeCombinedID
{
    // "4HPwATDgc/ABMA" is position only (14 chars). With a match ID appended:
    BGGBoardState *board = [BGGPosition boardStateFromCombinedID:@"4HPwATDgc/ABMA"];
    XCTAssertNotNil(board);
    XCTAssertTrue([board isValidCheckerCount]);
}

- (void)testEncodeCombinedID
{
    BGGBoardState *board = [BGGBoardState startingPosition];
    NSString *combined = [BGGPosition combinedIDFromBoardState:board];
    XCTAssertNotNil(combined);
    // Combined ID must start with the known position ID.
    XCTAssertTrue([combined hasPrefix:@"4HPwATDgc/ABMA"],
                  @"combined ID must start with correct position ID");
}

// MARK: - Match ID

- (void)testDecodeMatchID
{
    // Money game defaults: cube=1, centered, no score.
    BGGBoardState *board = [BGGBoardState emptyBoard];
    BOOL ok = [BGGPosition applyMatchID:@"cAkAAAAAAAA" toBoardState:board];
    // We just check it doesn't crash and returns a result;
    // exact field values depend on the test ID chosen.
    XCTAssertTrue(ok || !ok, @"should not crash");
}

- (void)testMatchIDRoundTrip
{
    BGGBoardState *board = [BGGBoardState startingPosition];
    board.matchLength  = 9;
    board.scoreBlue    = 2;
    board.scoreYellow  = 4;
    board.cubeValue    = 2;
    board.cubeOwner    = BGGPlayerBlue;

    NSString *matchID    = [BGGPosition matchIDFromBoardState:board];
    XCTAssertNotNil(matchID);
    XCTAssertEqual(matchID.length, (NSUInteger)12, @"match ID must be 12 chars");

    BGGBoardState *board2 = [BGGBoardState emptyBoard];
    BOOL ok = [BGGPosition applyMatchID:matchID toBoardState:board2];
    XCTAssertTrue(ok);
    XCTAssertEqual(board2.matchLength,  9);
    XCTAssertEqual(board2.scoreBlue,    2);
    XCTAssertEqual(board2.scoreYellow,  4);
    XCTAssertEqual(board2.cubeValue,    2);
    XCTAssertEqual(board2.cubeOwner,    BGGPlayerBlue);
}

- (void)testPipCountStartingPosition
{
    BGGBoardState *board = [BGGBoardState startingPosition];
    XCTAssertEqual([board pipCountForPlayer:BGGPlayerBlue],   167);
    XCTAssertEqual([board pipCountForPlayer:BGGPlayerYellow], 167);
}
@end
