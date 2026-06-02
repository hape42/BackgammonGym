//
//  BGGBoardState.m
//  BackgammonGym
//

#import "BGGBoardState.h"

@implementation BGGBoardState
{
    // Internes Speicher-Array. Index 0 bleibt ungenutzt, damit wir 1...24
    // direkt und ohne Umrechnung ansprechen können (weniger Off-by-one-Fehler).
    NSInteger _points[25];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Cube startet immer bei 1 (neutral). Alle anderen Felder sind 0/None,
        // was den gewünschten neutralen Defaults entspricht.
        _cubeValue = 1;
    }
    return self;
}

#pragma mark - Punkte

- (NSInteger)checkersOnPoint:(NSInteger)point
{
    NSParameterAssert(point >= 1 && point <= 24);
    if (point < 1 || point > 24)
    {
        return 0;
    }
    return _points[point];
}

- (void)setCheckers:(NSInteger)count onPoint:(NSInteger)point
{
    NSParameterAssert(point >= 1 && point <= 24);
    if (point < 1 || point > 24)
    {
        return;
    }
    _points[point] = count;
}

#pragma mark - Hilfen

- (NSInteger)totalCheckersForPlayer:(BGGPlayer)player
{
    NSInteger total = 0;

    for (NSInteger p = 1; p <= 24; p++)
    {
        NSInteger c = _points[p];

        if (player == BGGPlayerBlue && c > 0)
        {
            total += c;
        }
        else if (player == BGGPlayerYellow && c < 0)
        {
            total += -c;
        }
    }

    if (player == BGGPlayerBlue)
    {
        total += self.barBlue + self.offBlue;
    }
    else if (player == BGGPlayerYellow)
    {
        total += self.barYellow + self.offYellow;
    }

    return total;
}

- (BOOL)isValidCheckerCount
{
    return ([self totalCheckersForPlayer:BGGPlayerBlue]   == 15 &&
            [self totalCheckersForPlayer:BGGPlayerYellow] == 15);
}

- (NSInteger)pipCountForPlayer:(BGGPlayer)player
{
    NSInteger total = 0;

    if (player == BGGPlayerBlue)
    {
        for (NSInteger point = 1; point <= 24; point++)
        {
            NSInteger checkers = [self checkersOnPoint:point];
            if (checkers > 0)
            {
                total += point * checkers;
            }
        }
        // Bar checkers still have 25 points to travel.
        total += 25 * self.barBlue;
    }
    else if (player == BGGPlayerYellow)
    {
        for (NSInteger point = 1; point <= 24; point++)
        {
            NSInteger checkers = [self checkersOnPoint:point];
            if (checkers < 0)
            {
                // Yellow moves from high to low, so distance = 25 - point.
                total += (25 - point) * (-checkers);
            }
        }
        total += 25 * self.barYellow;
    }

    return total;
}

#pragma mark - Factory

+ (instancetype)emptyBoard
{
    return [[self alloc] init];
}

+ (instancetype)startingPosition
{
    BGGBoardState *board = [[self alloc] init];

    // Standard-Startstellung aus Sicht von Blau (positiv).
    // Blau: 2 auf 24, 5 auf 13, 3 auf 8, 5 auf 6.
    [board setCheckers:+2  onPoint:24];
    [board setCheckers:+5  onPoint:13];
    [board setCheckers:+3  onPoint:8];
    [board setCheckers:+5  onPoint:6];

    // Gelb (negativ) spiegelbildlich: 2 auf 1, 5 auf 12, 3 auf 17, 5 auf 19.
    [board setCheckers:-2  onPoint:1];
    [board setCheckers:-5  onPoint:12];
    [board setCheckers:-3  onPoint:17];
    [board setCheckers:-5  onPoint:19];

    return board;
}

@end
