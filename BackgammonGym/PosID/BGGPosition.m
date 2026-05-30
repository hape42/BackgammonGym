//
//  BGGPosition.m
//  BackgammonGym
//

#import "BGGPosition.h"
#import "BGGBoardState.h"

// GNU uses standard Base64 with this alphabet.
static const char kBase64Chars[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

// Position ID is 80 bits = 10 bytes = 14 Base64 chars (padding omitted).
static const NSInteger kPositionIDBits  = 80;
static const NSInteger kPositionIDBytes = 10;
static const NSInteger kPositionIDChars = 14;

// Match ID is 66 bits, stored in 9 bytes, encoded as 12 Base64 chars.
static const NSInteger kMatchIDBytes = 9;
static const NSInteger kMatchIDChars = 12;

@implementation BGGPosition

// MARK: - Base64 helpers

// Decode a single Base64 character to its 6-bit value, or -1 if invalid.
static int base64Value(char c)
{
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}

// Decode a Base64 string into raw bytes using the standard Base64 algorithm.
// Each character contributes 6 bits, packed MSB-first into the output bytes.
// The GNU position/match IDs omit the trailing '==' padding.
static BOOL decodeBase64(NSString *string, uint8_t *outBytes,
                          NSInteger expectedBytes, NSInteger expectedChars)
{
    if ((NSInteger)string.length < expectedChars) { return NO; }
    memset(outBytes, 0, (size_t)expectedBytes);

    // Standard Base64: 4 chars → 3 bytes. Here we work bit by bit for clarity.
    // Each Base64 char = 6 bits, written MSB-first into the byte stream.
    NSInteger outBitPos = 0;
    for (NSInteger i = 0; i < expectedChars; i++)
    {
        char c = (char)[string characterAtIndex:(NSUInteger)i];
        int val = base64Value(c);
        if (val < 0) { return NO; }

        // Write 6 bits MSB-first.
        for (NSInteger bit = 5; bit >= 0; bit--)
        {
            if (outBitPos >= expectedBytes * 8) { break; }
            if ((val >> bit) & 1)
            {
                outBytes[outBitPos / 8] |= (uint8_t)(0x80 >> (outBitPos % 8));
            }
            outBitPos++;
        }
    }
    return YES;
}

// Encode raw bytes into a Base64 string, MSB-first, without padding.
static NSString *encodeBase64(const uint8_t *bytes, NSInteger byteCount,
                               NSInteger charCount)
{
    NSMutableString *result = [NSMutableString stringWithCapacity:charCount];
    NSInteger inBitPos = 0;

    for (NSInteger i = 0; i < charCount; i++)
    {
        int val = 0;
        // Read 6 bits MSB-first.
        for (NSInteger bit = 5; bit >= 0; bit--)
        {
            if (inBitPos < byteCount * 8)
            {
                if (bytes[inBitPos / 8] & (0x80 >> (inBitPos % 8)))
                {
                    val |= (1 << bit);
                }
                inBitPos++;
            }
        }
        [result appendFormat:@"%c", kBase64Chars[val]];
    }
    return [result copy];
}

// Read a single bit from a byte array.
// The GNU spec stores the bit string LSB-first within each byte:
// bit 0 of the string → LSB (bit 0) of byte 0,
// bit 7 of the string → MSB (bit 7) of byte 0,
// bit 8 of the string → LSB (bit 0) of byte 1, etc.
static BOOL readBit(const uint8_t *bytes, NSInteger bitPos)
{
    return (bytes[bitPos / 8] >> (bitPos % 8)) & 1;
}

// Write a single bit into a byte array (LSB-first within each byte).
static void writeBit(uint8_t *bytes, NSInteger bitPos, BOOL value)
{
    if (value)
        bytes[bitPos / 8] |= (uint8_t)(1 << (bitPos % 8));
    else
        bytes[bitPos / 8] &= (uint8_t)~(1 << (bitPos % 8));
}

// Read an n-bit unsigned integer from a byte array at bitPos (LSB-first).
static NSUInteger readBits(const uint8_t *bytes, NSInteger bitPos, NSInteger count)
{
    NSUInteger val = 0;
    for (NSInteger i = 0; i < count; i++)
    {
        if (readBit(bytes, bitPos + i))
            val |= (NSUInteger)(1 << i);
    }
    return val;
}

// Write an n-bit unsigned integer into a byte array at bitPos (LSB-first).
static void writeBits(uint8_t *bytes, NSInteger bitPos, NSUInteger val, NSInteger count)
{
    for (NSInteger i = 0; i < count; i++)
    {
        writeBit(bytes, bitPos + i, (val >> i) & 1);
    }
}

// MARK: - Position ID decode

+ (nullable BGGBoardState *)boardStateFromPositionID:(NSString *)positionID
{
    if (positionID.length < kPositionIDChars) { return nil; }

    uint8_t bytes[kPositionIDBytes];
    if (!decodeBase64(positionID, bytes, kPositionIDBytes, kPositionIDChars))
    {
        return nil;
    }

    BGGBoardState *board = [BGGBoardState emptyBoard];

    // The bit string encodes checkers for the player on roll first (points 1–24
    // from their perspective, then bar), then the opponent (same order).
    // Each point: N ones followed by a zero. The zero is the separator.
    //
    // We map the on-roll player to Blue (positive) and the opponent to Yellow
    // (negative), using our internal 1-based point numbering.
    //
    // The on-roll player's point 1 = our point 1 (bottom right in our geometry).
    // The opponent's point 1 = our point 24 (mirrored).

    NSInteger bitPos = 0;

    // Player on roll (Blue): points 1–24, then bar.
    for (NSInteger point = 1; point <= 24; point++)
    {
        NSInteger count = 0;
        while (bitPos < kPositionIDBits && readBit(bytes, bitPos))
        {
            count++;
            bitPos++;
        }
        bitPos++;   // skip the separator 0

        if (count > 0)
        {
            [board setCheckers:count onPoint:point];
        }
    }
    // Bar for on-roll player (Blue).
    NSInteger blueBar = 0;
    while (bitPos < kPositionIDBits && readBit(bytes, bitPos))
    {
        blueBar++;
        bitPos++;
    }
    bitPos++;
    board.barBlue = blueBar;

    // Opponent (Yellow): their point 1 = our point 24, mirrored.
    for (NSInteger i = 1; i <= 24; i++)
    {
        NSInteger ourPoint = 25 - i;   // mirror: opponent's 1 → our 24
        NSInteger count = 0;
        while (bitPos < kPositionIDBits && readBit(bytes, bitPos))
        {
            count++;
            bitPos++;
        }
        bitPos++;

        if (count > 0)
        {
            // Yellow is stored as negative in BGGBoardState.
            [board setCheckers:-count onPoint:ourPoint];
        }
    }
    // Bar for opponent (Yellow).
    NSInteger yellowBar = 0;
    while (bitPos < kPositionIDBits && readBit(bytes, bitPos))
    {
        yellowBar++;
        bitPos++;
    }
    board.barYellow = yellowBar;

    return board;
}

// MARK: - Match ID decode

+ (BOOL)applyMatchID:(NSString *)matchID toBoardState:(BGGBoardState *)boardState
{
    if (matchID.length < kMatchIDChars) { return NO; }

    uint8_t bytes[kMatchIDBytes];
    if (!decodeBase64(matchID, bytes, kMatchIDBytes, kMatchIDChars))
    {
        return NO;
    }

    // Bit layout (all little-endian, LSB first):
    // Bits  1– 4: log2(cube value)
    // Bits  5– 6: cube owner (00=player0, 01=player1, 11=centered)
    // Bit   7:    player on roll (0=player0, 1=player1)
    // Bit   8:    Crawford flag
    // Bits  9–11: game state
    // Bit  12:    turn (whose decision)
    // Bit  13:    double being offered
    // Bits 14–15: resignation
    // Bits 16–18: die 1
    // Bits 19–21: die 2
    // Bits 22–36: match length (15 bits)
    // Bits 37–51: score player 0 (15 bits)
    // Bits 52–66: score player 1 (15 bits)

    NSUInteger cubeLog    = readBits(bytes, 0, 4);
    boardState.cubeValue  = (NSInteger)(1 << cubeLog);

    NSUInteger cubeOwner  = readBits(bytes, 4, 2);
    if (cubeOwner == 0)       boardState.cubeOwner = BGGPlayerBlue;
    else if (cubeOwner == 1)  boardState.cubeOwner = BGGPlayerYellow;
    else                      boardState.cubeOwner = BGGPlayerNone;

    NSUInteger onRoll     = readBits(bytes, 6, 1);
    boardState.onRoll     = (onRoll == 0) ? BGGPlayerBlue : BGGPlayerYellow;

    boardState.isCrawford = readBit(bytes, 7);

    NSUInteger die1       = readBits(bytes, 15, 3);
    NSUInteger die2       = readBits(bytes, 18, 3);
    BGGDice dice          = { (NSInteger)die1, (NSInteger)die2 };
    boardState.dice       = dice;

    boardState.matchLength = (NSInteger)readBits(bytes, 21, 15);
    boardState.scoreBlue   = (NSInteger)readBits(bytes, 36, 15);
    boardState.scoreYellow = (NSInteger)readBits(bytes, 51, 15);

    return YES;
}

// MARK: - Combined decode

+ (nullable BGGBoardState *)boardStateFromCombinedID:(NSString *)combinedID
{
    // Accept "posID matchID" (space) or "posID/matchID" (slash between them,
    // but note the Position ID itself contains a slash — so we split on the
    // first space, or take the first 14 chars as posID and last 12 as matchID).
    NSString *stripped = [combinedID stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSString *posID   = nil;
    NSString *matchID = nil;

    // Format: "4HPwATDgc/ABMA" – 14 chars, no separator between them
    // (the slash is part of the Position ID Base64 alphabet).
    if (stripped.length >= kPositionIDChars + kMatchIDChars)
    {
        posID   = [stripped substringToIndex:kPositionIDChars];
        matchID = [stripped substringFromIndex:kPositionIDChars];
        // Strip any leading space or separator between the two IDs.
        matchID = [matchID stringByTrimmingCharactersInSet:
                   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([matchID hasPrefix:@"/"] || [matchID hasPrefix:@" "])
            matchID = [matchID substringFromIndex:1];
    }
    else if (stripped.length >= kPositionIDChars)
    {
        posID = [stripped substringToIndex:kPositionIDChars];
    }

    if (posID == nil) { return nil; }

    BGGBoardState *board = [self boardStateFromPositionID:posID];
    if (board == nil)  { return nil; }

    if (matchID.length >= kMatchIDChars)
    {
        [self applyMatchID:matchID toBoardState:board];
    }

    return board;
}

// MARK: - Position ID encode

+ (nullable NSString *)positionIDFromBoardState:(BGGBoardState *)boardState
{
    uint8_t bytes[kPositionIDBytes];
    memset(bytes, 0, sizeof(bytes));

    NSInteger bitPos = 0;

    // Blue (on-roll player): points 1–24, then bar.
    for (NSInteger point = 1; point <= 24; point++)
    {
        NSInteger count = [boardState checkersOnPoint:point];
        if (count < 0) { count = 0; }   // Yellow checkers on this point
        for (NSInteger i = 0; i < count; i++)
        {
            writeBit(bytes, bitPos++, YES);
        }
        writeBit(bytes, bitPos++, NO);   // separator
    }
    for (NSInteger i = 0; i < boardState.barBlue; i++)
    {
        writeBit(bytes, bitPos++, YES);
    }
    writeBit(bytes, bitPos++, NO);

    // Yellow (opponent): their point 1 = our point 24 (mirrored).
    for (NSInteger i = 1; i <= 24; i++)
    {
        NSInteger ourPoint = 25 - i;
        NSInteger count = [boardState checkersOnPoint:ourPoint];
        if (count > 0) { count = 0; }   // Blue checkers on this point
        count = -count;                  // make positive

        for (NSInteger j = 0; j < count; j++)
        {
            writeBit(bytes, bitPos++, YES);
        }
        writeBit(bytes, bitPos++, NO);
    }
    for (NSInteger i = 0; i < boardState.barYellow; i++)
    {
        writeBit(bytes, bitPos++, YES);
    }
    // Final separator (spec says pad to 80 bits with zeros, already done by memset).

    return encodeBase64(bytes, kPositionIDBytes, kPositionIDChars);
}

// MARK: - Match ID encode

+ (nullable NSString *)matchIDFromBoardState:(BGGBoardState *)boardState
{
    uint8_t bytes[kMatchIDBytes];
    memset(bytes, 0, sizeof(bytes));

    // log2 of cube value (bits 0–3).
    NSInteger cubeLog = 0;
    NSInteger cube = boardState.cubeValue;
    while (cube > 1) { cube >>= 1; cubeLog++; }
    writeBits(bytes, 0, (NSUInteger)cubeLog, 4);

    // Cube owner (bits 4–5).
    NSUInteger cubeOwner = 3;   // centered
    if (boardState.cubeOwner == BGGPlayerBlue)   cubeOwner = 0;
    if (boardState.cubeOwner == BGGPlayerYellow) cubeOwner = 1;
    writeBits(bytes, 4, cubeOwner, 2);

    // Player on roll (bit 6).
    writeBit(bytes, 6, boardState.onRoll == BGGPlayerYellow);

    // Crawford (bit 7).
    writeBit(bytes, 7, boardState.isCrawford);

    // Game state: 001 = playing (bits 8–10).
    writeBits(bytes, 8, 1, 3);

    // Dice (bits 15–20).
    writeBits(bytes, 15, (NSUInteger)boardState.dice.die1, 3);
    writeBits(bytes, 18, (NSUInteger)boardState.dice.die2, 3);

    // Match length (bits 21–35).
    writeBits(bytes, 21, (NSUInteger)boardState.matchLength, 15);

    // Scores (bits 36–50 and 51–65).
    writeBits(bytes, 36, (NSUInteger)boardState.scoreBlue,   15);
    writeBits(bytes, 51, (NSUInteger)boardState.scoreYellow, 15);

    return encodeBase64(bytes, kMatchIDBytes, kMatchIDChars);
}

// MARK: - Combined encode

+ (nullable NSString *)combinedIDFromBoardState:(BGGBoardState *)boardState
{
    NSString *posID   = [self positionIDFromBoardState:boardState];
    NSString *matchID = [self matchIDFromBoardState:boardState];
    if (posID == nil || matchID == nil) { return nil; }
    return [NSString stringWithFormat:@"%@ %@", posID, matchID];
}

@end
