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
        [self reload];
    }
    return self;
}

// Loads positions following the Bundle-first strategy:
//   - If a Documents/positions.json exists (developer editing mode), use it.
//   - Otherwise read the read-only bundle copy.
// This way app updates always ship new positions via the bundle, and the
// Documents file is only a temporary developer override.
- (void)reload
{
    NSURL *docsURL = [self documentsJSONURL];
    BOOL hasDocs = [[NSFileManager defaultManager] fileExistsAtPath:docsURL.path];

    if (hasDocs)
    {
        NSLog(@"[PositionDatabase] editing mode: reading Documents/positions.json");
        [self loadFromURL:docsURL];
    }
    else
    {
        NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"positions"
                                                   withExtension:@"json"];
        NSLog(@"[PositionDatabase] reading bundle positions.json");
        [self loadFromURL:bundleURL];
    }
}

// YES if a Documents override file currently exists.
- (BOOL)isEditingMode
{
    return [[NSFileManager defaultManager]
            fileExistsAtPath:[self documentsJSONURL].path];
}

// Deletes the Documents override so the app reads the bundle again.
- (void)resetToBundle
{
    NSURL *docsURL = [self documentsJSONURL];
    if ([[NSFileManager defaultManager] fileExistsAtPath:docsURL.path])
    {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:docsURL error:&error];
        if (error) { NSLog(@"[PositionDatabase] reset failed: %@", error); }
        else       { NSLog(@"[PositionDatabase] reset to bundle"); }
    }
    [self reload];
}

// MARK: - File management

- (NSURL *)documentsJSONURL
{
    NSURL *docs = [[[NSFileManager defaultManager]
                    URLsForDirectory:NSDocumentDirectory
                           inDomains:NSUserDomainMask] firstObject];
    return [docs URLByAppendingPathComponent:@"positions.json"];
}

// MARK: - Loading

- (void)loadFromURL:(NSURL *)url
{
    if (url == nil)
    {
        NSLog(@"[PositionDatabase] no URL to load from");
        _allPositions = @[];
        return;
    }

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

- (nullable BGGPositionEntry *)entryForPositionID:(NSString *)positionID
{
    for (BGGPositionEntry *e in self.allPositions)
    {
        if ([e.positionID isEqualToString:positionID]) { return e; }
    }
    return nil;
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
