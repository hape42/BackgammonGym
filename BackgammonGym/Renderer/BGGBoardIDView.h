//
//  BGGBoardIDView.h
//  BackgammonGym
//
//  A small view that displays the GNU combined ID (posID:matchID)
//  for a given board state, with a one-tap copy button.
//
//  Usage: place below any BGGBoardView.
//  Call -updateWithBoardState: whenever the board changes.
//

#import <UIKit/UIKit.h>
@class BGGBoardState;

NS_ASSUME_NONNULL_BEGIN

@interface BGGBoardIDView : UIView

- (void)updateWithBoardState:(nullable BGGBoardState *)boardState;

@end

NS_ASSUME_NONNULL_END
