//
//  BGGBoardIDView.h
//  BackgammonGym
//
//  A small view that displays a GNU combined ID (posID:matchID)
//  with a one-tap copy button.
//
//  Usage: place below any BGGBoardView.
//  - updateWithID: shows an exact ID string (e.g. straight from the JSON).
//  - updateWithBoardState: derives the ID from a board state (re-encoded).
//

#import <UIKit/UIKit.h>
@class BGGBoardState;

NS_ASSUME_NONNULL_BEGIN

@interface BGGBoardIDView : UIView

// Shows an exact ID string verbatim (preferred when the original ID is known,
// e.g. from positions.json – avoids any re-encoding differences).
- (void)updateWithID:(nullable NSString *)combinedID;

// Derives and shows the ID from a board state by re-encoding it.
- (void)updateWithBoardState:(nullable BGGBoardState *)boardState;

@end

NS_ASSUME_NONNULL_END
