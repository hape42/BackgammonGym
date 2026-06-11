//
//  BGGMatchEquityTable.m
//  BackgammonGym
//

#import "BGGMatchEquityTable.h"

@implementation BGGMatchEquityTable
{
    // [row][col], 0-based: index 0 == 1-away. Full precision from the
    // Rockwell-Kazaross MET (bkgm.com/articles/Kazaross).
    double _met[11][11];
}

+ (instancetype)sharedTable
{
    static BGGMatchEquityTable *shared = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _maxAway = 11;
        [self fillTable];
    }
    return self;
}

- (void)fillTable
{
    // Rows 1..11 (player away), columns 1..11 (opponent away).
    // The diagonal is 50.0; (a,b) + (b,a) == 100.
    static const double rows[11][11] = {
        { 50.0, 67.7, 75.1, 81.4, 84.2, 88.7, 90.7, 93.2, 94.4, 95.9, 96.6 },
        { 32.3, 50.0, 59.9, 66.9, 74.3, 79.9, 84.2, 87.5, 90.2, 92.3, 93.9 },
        { 24.9, 40.1, 50.0, 57.1, 64.8, 71.2, 76.3, 80.5, 84.0, 87.1, 89.4 },
        { 18.6, 33.1, 42.9, 50.0, 57.7, 64.3, 70.0, 74.6, 78.8, 82.4, 85.4 },
        { 15.8, 25.7, 35.2, 42.3, 50.0, 56.7, 62.7, 67.8, 72.6, 76.7, 80.3 },
        { 11.3, 20.1, 28.8, 35.7, 43.3, 50.0, 56.3, 61.7, 66.8, 71.3, 75.3 },
        {  9.3, 15.8, 23.7, 30.0, 37.3, 43.7, 50.0, 55.5, 60.9, 65.6, 70.0 },
        {  6.8, 12.5, 19.5, 25.4, 32.2, 38.3, 44.5, 50.0, 55.4, 60.4, 65.0 },
        {  5.6,  9.8, 16.0, 21.2, 27.4, 33.2, 39.1, 44.6, 50.0, 55.0, 59.8 },
        {  4.1,  7.7, 12.9, 17.6, 23.3, 28.7, 34.4, 39.6, 45.0, 50.0, 54.9 },
        {  3.4,  6.1, 10.6, 14.6, 19.7, 24.7, 30.0, 35.0, 40.2, 45.1, 50.0 },
    };

    for (NSInteger r = 0; r < 11; r++)
    {
        for (NSInteger c = 0; c < 11; c++)
        {
            _met[r][c] = rows[r][c];
        }
    }
}

- (double)equityForPlayerAway:(NSInteger)playerAway
                 opponentAway:(NSInteger)opponentAway
{
    if (playerAway   < 1 || playerAway   > self.maxAway ||
        opponentAway < 1 || opponentAway > self.maxAway)
    {
        return 0.0;   // out of range
    }
    return _met[playerAway - 1][opponentAway - 1];
}

- (NSInteger)roundedEquityForPlayerAway:(NSInteger)playerAway
                           opponentAway:(NSInteger)opponentAway
{
    double v = [self equityForPlayerAway:playerAway opponentAway:opponentAway];
    return (NSInteger)floor(v + 0.5);
}

@end
