//
//  UIViewController+BGGHomeButton.h
//  BackgammonGym
//
//  Adds a house icon to the left side of the navigation bar.
//  Tapping it always navigates back to the root (StartVC),
//  regardless of how deep in the stack the user is.
//
//  Usage: call [self installHomeButton] in viewDidLoad.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (BGGHomeButton)

// Installs a home button as the left bar button item.
// Replaces the default back button.
- (void)installHomeButton;

@end

NS_ASSUME_NONNULL_END
