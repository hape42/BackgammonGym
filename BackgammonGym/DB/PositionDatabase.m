//
//  PositionDatabase.m
//  BackgammonGym
//

#import "PositionDatabase.h"
#import "BGGPosition.h"
#import "BGGBoardState.h"

static const NSUInteger kMaxTags = 5;

// MARK: - BGGPositionEntry

@implementation BGGPositionEntry

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        _positionID = [dict[@"id"] isKindOfClass:[NSString class]]
                    ? dict[@"id"] : @"";

        // Tags: array of strings, capped at kMaxTags.
        NSArray *rawTags = dict[@"tags"];
        if ([rawTags isKindOfClass:[NSArray class]])
        {
            NSMutableArray<NSString *> *tags = [NSMutableArray array];
            for (id tag in rawTags)
            {
                if ([tag isKindOfClass:[NSString class]] && tags.count < kMaxTags)
                {
                    [tags addObject:tag];
                }
            }
            _tags = [tags copy];
        }
        else
        {
            _tags = @[];
        }

        _difficulty = [dict[@"difficulty"] isKindOfClass:[NSNumber class]]
                    ? [dict[@"difficulty"] integerValue] : 1;

        _caption = [dict[@"caption"] isKindOfClass:[NSString class]]
                 ? dict[@"caption"] : @"";

        _text = [dict[@"text"] isKindOfClass:[NSString class]]
              ? dict[@"text"] : @"";

        _note = [dict[@"note"] isKindOfClass:[NSString class]]
              ? dict[@"note"] : @"";
    }
    return self;
}

- (BOOL)hasTag:(NSString *)tag
{
    return [self.tags containsObject:tag];
}

- (nullable BGGBoardState *)boardState
{
    // The board is always drawable from the ID alone – it does not depend
    // on the entry still being in the JSON.
//    return [BGGPosition boardStateFromPositionID:self.positionID];
    return [BGGPosition boardStateFromCombinedID:self.positionID];

}

@end

// MARK: - PositionDatabase

@interface PositionDatabase ()
@property (nonatomic, copy, readwrite) NSArray<BGGPositionEntry *> *allPositions;
@end

@implementation PositionDatabase

+ (instancetype)sharedDatabase
{
    static PositionDatabase *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PositionDatabase alloc] initFromBundle];
    });
    return instance;
}

- (instancetype)initFromBundle
{
    self = [super init];
    if (self)
    {
        [self loadPositions];
    }
    return self;
}

- (void)loadPositions
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"positions" withExtension:@"json"];
    if (url == nil)
    {
        NSLog(@"[PositionDatabase] positions.json not found in bundle");
        _allPositions = @[];
        return;
    }

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (data == nil)
    {
        NSLog(@"[PositionDatabase] could not read positions.json: %@", error);
        _allPositions = @[];
        return;
    }

    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:0
                                                           error:&error];
    if (json == nil)
    {
        NSLog(@"[PositionDatabase] JSON parse error: %@", error);
        _allPositions = @[];
        return;
    }

    NSArray *raw = json[@"positions"];
    if (![raw isKindOfClass:[NSArray class]])
    {
        NSLog(@"[PositionDatabase] unexpected JSON structure – expected 'positions' array");
        _allPositions = @[];
        return;
    }

    NSMutableArray<BGGPositionEntry *> *entries = [NSMutableArray arrayWithCapacity:raw.count];
    for (NSDictionary *dict in raw)
    {
        if (![dict isKindOfClass:[NSDictionary class]]) { continue; }
        BGGPositionEntry *entry = [[BGGPositionEntry alloc] initWithDictionary:dict];
        if (entry.positionID.length > 0)
        {
            [entries addObject:entry];
        }
    }

    _allPositions = [entries copy];
    NSLog(@"[PositionDatabase] loaded %lu positions", (unsigned long)_allPositions.count);
}

// MARK: - Filtering

- (NSArray<BGGPositionEntry *> *)positionsForTag:(NSString *)tag
{
    NSMutableArray *result = [NSMutableArray array];
    for (BGGPositionEntry *entry in self.allPositions)
    {
        if ([entry hasTag:tag])
        {
            [result addObject:entry];
        }
    }
    return [result copy];
}

- (NSArray<BGGPositionEntry *> *)positionsForTag:(NSString *)tag
                                      difficulty:(NSInteger)difficulty
{
    NSMutableArray *result = [NSMutableArray array];
    for (BGGPositionEntry *entry in self.allPositions)
    {
        if ([entry hasTag:tag] && entry.difficulty == difficulty)
        {
            [result addObject:entry];
        }
    }
    return [result copy];
}

- (nullable BGGPositionEntry *)randomPositionForTag:(NSString *)tag
{
    NSArray<BGGPositionEntry *> *filtered = [self positionsForTag:tag];
    if (filtered.count == 0) { return nil; }
    NSUInteger index = arc4random_uniform((uint32_t)filtered.count);
    return filtered[index];
}

@end
