//
//  PositionDatabase.h
//  BackgammonGym
//
//  Loads positions from JSON, supports editing and export.
//
//  Storage strategy:
//    1. On first launch: copies positions.json from bundle to Documents.
//    2. Always reads from Documents after that.
//    3. All edits (add/update/delete) write back to Documents immediately.
//    4. Export shares the Documents JSON via UIActivityViewController.
//       The developer then copies it into the Xcode project for the next build.
//
//  JSON format:
//  {
//    "positions": [
//      {
//        "id":         "posID:matchID",    // required, BGBlitz format
//        "tags":       ["race","pipcount"],// up to 5 tags
//        "difficulty": 1,                  // 1–3
//        "caption":    "Starting pos",    // shown in UI
//        "text":       "Both players...", // shown in UI
//        "note":       "dev comment"      // never shown in UI
//      }
//    ]
//  }
//

#import <Foundation/Foundation.h>

@class BGGBoardState;

NS_ASSUME_NONNULL_BEGIN

// MARK: - BGGPositionEntry

@interface BGGPositionEntry : NSObject

@property (nonatomic, copy,   readonly) NSString            *positionID;
@property (nonatomic, copy,   readonly) NSArray<NSString *> *tags;
@property (nonatomic, assign, readonly) NSInteger            difficulty;
@property (nonatomic, copy,   readonly) NSString            *caption;
@property (nonatomic, copy,   readonly) NSString            *text;
@property (nonatomic, copy,   readonly) NSString            *note;

- (BOOL)hasTag:(NSString *)tag;
- (nullable BGGBoardState *)boardState;

// Serialise back to a dictionary for JSON export.
- (NSDictionary *)toDictionary;

@end


// MARK: - PositionDatabase

@interface PositionDatabase : NSObject

+ (instancetype)sharedDatabase;

@property (nonatomic, copy, readonly) NSArray<BGGPositionEntry *> *allPositions;

// MARK: Filtering
- (NSArray<BGGPositionEntry *> *)positionsForTag:(NSString *)tag;
- (NSArray<BGGPositionEntry *> *)positionsForTag:(NSString *)tag
                                      difficulty:(NSInteger)difficulty;

// Returns entries that carry ALL of the given tags (logical AND).
// Used to combine a topic tag (e.g. "pipcount") with a purpose tag
// (e.g. "training"), so a position only appears where it belongs.
- (NSArray<BGGPositionEntry *> *)positionsForTags:(NSArray<NSString *> *)tags;
- (nullable BGGPositionEntry *)randomPositionForTag:(NSString *)tag;

// Returns the entry with the given position ID, or nil if not found.
// Matches on the full combined ID (posID:matchID) as stored in the JSON.
- (nullable BGGPositionEntry *)entryForPositionID:(NSString *)positionID;

// MARK: Editing (writes to Documents immediately)

// Add a new entry. Does nothing if positionID already exists.
- (void)addEntry:(BGGPositionEntry *)entry;

// Replace an existing entry by positionID.
- (void)updateEntry:(BGGPositionEntry *)entry;

// Remove an entry by positionID.
- (void)removeEntryWithPositionID:(NSString *)positionID;

// MARK: Storage mode (Bundle-first)

// The app reads from the bundle by default. As soon as the developer edits
// a position, a Documents/positions.json override is created and used until
// it is reset. App updates ship new positions via the bundle, so the
// developer must export edited positions back into the project.

// YES if a Documents override currently exists (developer editing mode).
- (BOOL)isEditingMode;

// Reloads positions: Documents override if present, otherwise bundle.
- (void)reload;

// Deletes the Documents override, so the app reads the bundle again.
- (void)resetToBundle;

// MARK: Export

// Returns the URL of the Documents JSON file for sharing.
- (NSURL *)documentsJSONURL;

@end


// MARK: - BGGPositionEntryBuilder
// Mutable builder used by the editor VC to construct entries.

@interface BGGPositionEntryBuilder : NSObject

@property (nonatomic, copy)   NSString            *positionID;
@property (nonatomic, strong) NSMutableArray<NSString *> *tags;
@property (nonatomic, assign) NSInteger            difficulty;
@property (nonatomic, copy)   NSString            *caption;
@property (nonatomic, copy)   NSString            *text;
@property (nonatomic, copy)   NSString            *note;

// Build an immutable BGGPositionEntry.
- (BGGPositionEntry *)build;

// Populate from an existing entry for editing.
+ (instancetype)builderFromEntry:(BGGPositionEntry *)entry;

@end

NS_ASSUME_NONNULL_END
