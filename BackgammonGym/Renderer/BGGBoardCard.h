//
//  BGGBoardCard.h
//  BackgammonGym
//
//  A reusable view that shows a board alongside a text description.
//
//  On iPad (width >= 600pt): board left (40%), text right (60%), side by side.
//  On iPhone (width < 600pt): text on top, board below.
//
//  I use this everywhere in the app where I need to explain a position.
//

#import <UIKit/UIKit.h>

@class BGGBoardState;

NS_ASSUME_NONNULL_BEGIN

@interface BGGBoardCard : UIView

// The position to display.
@property (nonatomic, strong, nullable) BGGBoardState *boardState;

// Board design / schema (default: @"4").
@property (nonatomic, copy) NSString *boardDesign;

// Caption shown above the board (or above both on iPhone).
@property (nonatomic, copy, nullable) NSString *caption;

// Explanation text shown next to the board on iPad, below on iPhone.
@property (nonatomic, copy, nullable) NSString *explanationText;

// Highlight the caption in red – use this for placeholder boards.
@property (nonatomic, assign) BOOL isPlaceholder;

// Board display options forwarded to BGGBoardView.
@property (nonatomic, assign) BOOL showsPointNumbers;  // default YES
@property (nonatomic, assign) BOOL showsCube;           // default NO
@property (nonatomic, assign) BOOL showsDice;           // default NO

// Convenience initializer.
- (instancetype)initWithCaption:(nullable NSString *)caption
                explanationText:(nullable NSString *)explanation
                    boardState:(nullable BGGBoardState *)state;

@end

NS_ASSUME_NONNULL_END
