//
//  BGGNumberPad.h
//  BackgammonGym
//
//  A self-contained on-screen number pad (1–9, 0, delete, OK), built to be
//  reused across modules instead of the system number keyboard. It owns no
//  value itself – it just reports taps through its delegate, so the host
//  decides what the typed digits mean. This keeps the host's match score (or
//  whatever sits above) visible, since the pad is laid out inline rather than
//  sliding up over the screen.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BGGNumberPad;

@protocol BGGNumberPadDelegate <NSObject>
// A digit key 0–9 was tapped.
- (void)numberPad:(BGGNumberPad *)pad didTapDigit:(NSInteger)digit;
// The delete key was tapped (remove the last digit).
- (void)numberPadDidTapDelete:(BGGNumberPad *)pad;
// The OK key was tapped (submit the current value).
- (void)numberPadDidTapOK:(BGGNumberPad *)pad;
@end

@interface BGGNumberPad : UIView

@property (nonatomic, weak) id<BGGNumberPadDelegate> delegate;

// The OK key uses this colour for its background (defaults to AccentColor).
@property (nonatomic, strong) UIColor *okColor;

// Enables / disables the whole pad (e.g. after an answer is checked).
@property (nonatomic, assign) BOOL enabled;

@end

NS_ASSUME_NONNULL_END
