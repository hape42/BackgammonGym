//
//  BGGBoardView.h
//  BackgammonGym
//
//  Data-driven board view: takes a BGGBoardState and a schema number,
//  and renders the position using BGGBoardElements.
//
//  No DailyGammon HTML, no move logic, no dice required.
//  Display only.
//

#import <UIKit/UIKit.h>

@class BGGBoardState;

NS_ASSUME_NONNULL_BEGIN

@interface BGGBoardView : UIView

// The position to display. Setting this triggers a redraw.
@property (nonatomic, strong, nullable) BGGBoardState *boardState;

// Board design / schema number as a string (e.g. @"4").
// Schema <= 4 loads pre-rendered PNGs; schema >= 5 draws at runtime.
// Default: @"4".
@property (nonatomic, copy) NSString *boardDesign;

// Show point numbers 1–24 along the edge strips.
// In a real game the board has no numbers - this is a training aid.
// Default: NO.
@property (nonatomic, assign) BOOL showsPointNumbers;

// Convenience: set position and schema in one call.
- (void)configureWithBoardState:(nullable BGGBoardState *)state
                          design:(NSString *)design;

@end

NS_ASSUME_NONNULL_END
