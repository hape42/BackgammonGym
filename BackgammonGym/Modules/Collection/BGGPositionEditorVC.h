//
//  BGGPositionEditorVC.h
//  BackgammonGym
//
//  Editor for a single position entry.
//  Shows a live board preview while the user types the position ID.
//  Used for both Add and Edit.
//
//  The caller sets the delegate and optionally passes an existing entry
//  for editing. On save, the delegate receives the finished entry.
//

#import <UIKit/UIKit.h>
#import "PositionDatabase.h"

NS_ASSUME_NONNULL_BEGIN

@class BGGPositionEditorVC;

@protocol BGGPositionEditorDelegate <NSObject>
- (void)editorDidSaveEntry:(BGGPositionEntry *)entry
                 isNewEntry:(BOOL)isNew;
@end

@interface BGGPositionEditorVC : UIViewController

// Pass nil for Add, existing entry for Edit.
- (instancetype)initWithEntry:(nullable BGGPositionEntry *)entry;

@property (nonatomic, weak) id<BGGPositionEditorDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
