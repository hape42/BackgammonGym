//
//  PositionDatabase.m
//  BackgammonGym
//

#import "PositionDatabase.h"
#import "BGGPosition.h"
#import "BGGBoardState.h"

// MARK: - BGGPositionEntry

@implementation BGGPositionEntry

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        _positionID = [dict[@"id"]         isKindOfClass:[NSString class]] ? dict[@"id"]         : @"";
        _category   = [dict[@"category"]   isKindOfClass:[NSString class]] ? dict[@"category"]   : @"";
        _note       = [dict[@"note"]       isKindOfClass:[NSString class]] ? dict[@"note"]       : @"";
        _difficulty = [dict[@"difficulty"] isKindOfClass:[NSNumber class]] ? [dict[@"difficulty"] integerValue] : 1;
    }
    return self;
}

- (nullable BGGBoardState *)boardState
{
    return [BGGPosition boardStateFromPositionID:self.positionID];
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

- (NSArray<BGGPositionEntry *> *)positionsForCategory:(NSString *)category
{
    return [self.allPositions filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"category == %@", category]];
}

- (NSArray<BGGPositionEntry *> *)positionsForCategory:(NSString *)category
                                           difficulty:(NSInteger)difficulty
{
    return [self.allPositions filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"category == %@ AND difficulty == %ld",
             category, (long)difficulty]];
}

- (nullable BGGPositionEntry *)randomPositionForCategory:(NSString *)category
{
    NSArray<BGGPositionEntry *> *filtered = [self positionsForCategory:category];
    if (filtered.count == 0) { return nil; }
    NSUInteger index = arc4random_uniform((uint32_t)filtered.count);
    return filtered[index];
}

@end
