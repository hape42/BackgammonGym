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
        _positionID = [dict[@"id"] isKindOfClass:[NSString class]] ? dict[@"id"] : @"";

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
        else { _tags = @[]; }

        _difficulty = [dict[@"difficulty"] isKindOfClass:[NSNumber class]]
                    ? [dict[@"difficulty"] integerValue] : 1;
        _caption    = [dict[@"caption"] isKindOfClass:[NSString class]] ? dict[@"caption"] : @"";
        _text       = [dict[@"text"]    isKindOfClass:[NSString class]] ? dict[@"text"]    : @"";
        _note       = [dict[@"note"]    isKindOfClass:[NSString class]] ? dict[@"note"]    : @"";
    }
    return self;
}

- (BOOL)hasTag:(NSString *)tag { return [self.tags containsObject:tag]; }

- (nullable BGGBoardState *)boardState
{
    return [BGGPosition boardStateFromCombinedID:self.positionID];
}

- (NSDictionary *)toDictionary
{
    return @{
        @"id":         self.positionID,
        @"tags":       self.tags,
        @"difficulty": @(self.difficulty),
        @"caption":    self.caption,
        @"text":       self.text,
        @"note":       self.note,
    };
}

@end

// MARK: - BGGPositionEntryBuilder

@implementation BGGPositionEntryBuilder

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _positionID = @"";
        _tags       = [NSMutableArray array];
        _difficulty = 1;
        _caption    = @"";
        _text       = @"";
        _note       = @"";
    }
    return self;
}

+ (instancetype)builderFromEntry:(BGGPositionEntry *)entry
{
    BGGPositionEntryBuilder *b = [[self alloc] init];
    b.positionID = entry.positionID;
    b.tags       = [entry.tags mutableCopy];
    b.difficulty = entry.difficulty;
    b.caption    = entry.caption;
    b.text       = entry.text;
    b.note       = entry.note;
    return b;
}

- (BGGPositionEntry *)build
{
    NSDictionary *dict = @{
        @"id":         self.positionID ?: @"",
        @"tags":       [self.tags copy],
        @"difficulty": @(self.difficulty),
        @"caption":    self.caption ?: @"",
        @"text":       self.text    ?: @"",
        @"note":       self.note    ?: @"",
    };
    return [[BGGPositionEntry alloc] initWithDictionary:dict];
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
        instance = [[PositionDatabase alloc] initAndLoad];
    });
    return instance;
}

- (instancetype)initAndLoad
{
    self = [super init];
    if (self)
    {
        [self ensureDocumentsFileExists];
        [self loadFromDocuments];
    }
    return self;
}

// MARK: - File management

- (NSURL *)documentsJSONURL
{
    NSURL *docs = [[[NSFileManager defaultManager]
                    URLsForDirectory:NSDocumentDirectory
                           inDomains:NSUserDomainMask] firstObject];
    return [docs URLByAppendingPathComponent:@"positions.json"];
}

// Copy bundle JSON to Documents on first launch.
- (void)ensureDocumentsFileExists
{
    NSURL *dest = [self documentsJSONURL];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dest.path])
    {
        NSLog(@"[PositionDatabase] using Documents/positions.json");
        return;
    }

    NSURL *bundle = [[NSBundle mainBundle] URLForResource:@"positions" withExtension:@"json"];
    if (bundle == nil)
    {
        NSLog(@"[PositionDatabase] no positions.json in bundle – starting empty");
        // Write empty JSON to Documents so we always have a writable file.
        NSDictionary *empty = @{ @"positions": @[] };
        NSData *data = [NSJSONSerialization dataWithJSONObject:empty
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
        [data writeToURL:dest atomically:YES];
        return;
    }

    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtURL:bundle toURL:dest error:&error];
    if (error)
    {
        NSLog(@"[PositionDatabase] could not copy bundle JSON: %@", error);
    }
    else
    {
        NSLog(@"[PositionDatabase] copied bundle JSON to Documents");
    }
}

// MARK: - Loading

- (void)loadFromDocuments
{
    NSURL *url = [self documentsJSONURL];
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (data == nil)
    {
        NSLog(@"[PositionDatabase] could not read: %@", error);
        _allPositions = @[];
        return;
    }

    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (json == nil)
    {
        NSLog(@"[PositionDatabase] JSON parse error: %@", error);
        _allPositions = @[];
        return;
    }

    NSArray *raw = json[@"positions"];
    if (![raw isKindOfClass:[NSArray class]])
    {
        NSLog(@"[PositionDatabase] unexpected JSON structure");
        _allPositions = @[];
        return;
    }

    NSMutableArray<BGGPositionEntry *> *entries = [NSMutableArray arrayWithCapacity:raw.count];
    for (NSDictionary *dict in raw)
    {
        if (![dict isKindOfClass:[NSDictionary class]]) { continue; }
        BGGPositionEntry *entry = [[BGGPositionEntry alloc] initWithDictionary:dict];
        if (entry.positionID.length > 0) { [entries addObject:entry]; }
    }

    _allPositions = [entries copy];
    NSLog(@"[PositionDatabase] loaded %lu positions", (unsigned long)_allPositions.count);
}

// MARK: - Saving

- (void)saveToDocuments
{
    NSMutableArray *dicts = [NSMutableArray arrayWithCapacity:self.allPositions.count];
    for (BGGPositionEntry *entry in self.allPositions)
    {
        [dicts addObject:[entry toDictionary]];
    }

    NSDictionary *json = @{ @"positions": dicts };
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:json
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    if (data == nil)
    {
        NSLog(@"[PositionDatabase] serialisation error: %@", error);
        return;
    }

    BOOL ok = [data writeToURL:[self documentsJSONURL] atomically:YES];
    NSLog(@"[PositionDatabase] saved %lu positions (%@)",
          (unsigned long)self.allPositions.count, ok ? @"OK" : @"FAILED");
}

// MARK: - Filtering

- (NSArray<BGGPositionEntry *> *)positionsForTag:(NSString *)tag
{
    return [self.allPositions filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"tags CONTAINS %@", tag]];
}

- (NSArray<BGGPositionEntry *> *)positionsForTag:(NSString *)tag
                                      difficulty:(NSInteger)difficulty
{
    return [self.allPositions filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"tags CONTAINS %@ AND difficulty == %ld",
             tag, (long)difficulty]];
}

- (nullable BGGPositionEntry *)randomPositionForTag:(NSString *)tag
{
    NSArray<BGGPositionEntry *> *filtered = [self positionsForTag:tag];
    if (filtered.count == 0) { return nil; }
    return filtered[arc4random_uniform((uint32_t)filtered.count)];
}

// MARK: - Editing

- (void)addEntry:(BGGPositionEntry *)entry
{
    // Ignore duplicates
    for (BGGPositionEntry *e in self.allPositions)
    {
        if ([e.positionID isEqualToString:entry.positionID]) { return; }
    }
    NSMutableArray *updated = [self.allPositions mutableCopy];
    [updated addObject:entry];
    self.allPositions = [updated copy];
    [self saveToDocuments];
}

- (void)updateEntry:(BGGPositionEntry *)entry
{
    NSMutableArray *updated = [self.allPositions mutableCopy];
    for (NSUInteger i = 0; i < updated.count; i++)
    {
        if ([((BGGPositionEntry *)updated[i]).positionID isEqualToString:entry.positionID])
        {
            updated[i] = entry;
            break;
        }
    }
    self.allPositions = [updated copy];
    [self saveToDocuments];
}

- (void)removeEntryWithPositionID:(NSString *)positionID
{
    NSMutableArray *updated = [self.allPositions mutableCopy];
    [updated filterUsingPredicate:
     [NSPredicate predicateWithFormat:@"positionID != %@", positionID]];
    self.allPositions = [updated copy];
    [self saveToDocuments];
}

@end
