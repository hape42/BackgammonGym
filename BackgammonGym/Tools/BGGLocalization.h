//
//  BGGLocalization.h
//  BackgammonGym
//
//  Localization helper that does NOT follow the system language, but the one
//  chosen in BGGLanguage. It reads from the matching .lproj bundle inside the
//  app bundle. Keys are English source text, so a missing translation falls
//  back to the key itself (i.e. English).
//
//  Pattern adapted from the SketchPrompt app's working setup.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Returns the localized string for `key` in the currently effective language.
// Fallback: the key itself if no translation is found.
FOUNDATION_EXPORT NSString *BGGLocalizedString(NSString *key);

@interface BGGLocalization : NSObject

// Re-resolves the internal bundle after a language change. Called
// automatically via BGGLanguageDidChangeNotification, but can be triggered
// manually too.
+ (void)reloadCurrentBundle;

@end

NS_ASSUME_NONNULL_END
