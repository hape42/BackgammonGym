//
//  BGGLanguage.h
//  BackgammonGym
//
//  Slim language management for the in-app language picker. Holds the
//  manually chosen language (or none, meaning "follow the device") and
//  resolves the effective language code. Deliberately separate from the
//  per-module settings classes (BGGTimeColor, BGGMETSettings) so language
//  has its own small home rather than being wedged into one of them.
//
//  Pattern adapted from the SketchPrompt app's working localization setup,
//  trimmed down to just the language logic.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Posted when the chosen language changes. BGGLocalization listens for this
// to reload its bundle; views can listen too if they want to re-localize
// live.
extern NSString * const BGGLanguageDidChangeNotification;

@interface BGGLanguage : NSObject

+ (instancetype)sharedLanguage;

// The manually chosen language code (e.g. "de"), or nil to follow the
// device. Only codes in supportedLanguageCodes are accepted; anything else
// is treated as nil.
@property (nonatomic, copy, nullable) NSString *language;

// The language actually used right now: the chosen one if set, otherwise
// the first device-preferred language that we support, otherwise English.
- (NSString *)effectiveLanguageCode;

// The languages the app ships translations for. English is the source
// language (keys are English text), so it is always available as a fallback.
+ (NSArray<NSString *> *)supportedLanguageCodes;

// A short display name for a language code ("DE", "EN", …). Pass nil for the
// "follow the device" option.
+ (NSString *)displayNameForLanguageCode:(nullable NSString *)code;

@end

NS_ASSUME_NONNULL_END
