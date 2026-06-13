//
//  BGGLanguage.m
//  BackgammonGym
//

#import "BGGLanguage.h"

NSString * const BGGLanguageDidChangeNotification = @"BGGLanguageDidChangeNotification";

static NSString * const kBGGLanguageKey = @"bgg.settings.language";
static NSString * const kBGGFallbackLanguage = @"en";

@implementation BGGLanguage

+ (instancetype)sharedLanguage
{
    static BGGLanguage *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[BGGLanguage alloc] init]; });
    return instance;
}

#pragma mark - Chosen language

- (NSString *)language
{
    NSString *stored = [[NSUserDefaults standardUserDefaults] stringForKey:kBGGLanguageKey];
    if (stored.length == 0) { return nil; }
    if (![[[self class] availableLanguageCodes] containsObject:stored]) { return nil; }
    return stored;
}

- (void)setLanguage:(NSString *)language
{
    NSString *normalized = nil;
    if (language.length > 0 && [[[self class] availableLanguageCodes] containsObject:language])
    {
        normalized = language;
    }

    NSString *current = self.language;
    if ((normalized == nil && current == nil)
        || (normalized != nil && [normalized isEqualToString:current]))
    {
        return;   // no change
    }

    if (normalized == nil)
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kBGGLanguageKey];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:normalized forKey:kBGGLanguageKey];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:BGGLanguageDidChangeNotification
                                                        object:self];
}

#pragma mark - Effective language

- (NSString *)effectiveLanguageCode
{
    NSString *chosen = self.language;
    if (chosen.length > 0) { return chosen; }

    // No manual choice: walk the device's preferred languages and take the
    // first one we actually support.
    NSArray<NSString *> *preferred = [NSLocale preferredLanguages];
    for (NSString *raw in preferred)
    {
        NSString *code = [[raw componentsSeparatedByString:@"-"] firstObject];
        if (code.length == 0) { continue; }
        if ([[[self class] availableLanguageCodes] containsObject:code]) { return code; }
    }

    return kBGGFallbackLanguage;
}

#pragma mark - Supported languages

+ (NSArray<NSString *> *)availableLanguageCodes
{
    // English first as the source language. Add codes here once a language
    // is fully translated and ready to be selected.
    return @[@"en", @"de"];
}

+ (NSArray<NSString *> *)plannedLanguageCodes
{
    // Shown in the picker to invite translators, but not yet selectable.
    // Strong backgammon countries first targets. Order here is by display
    // name; the picker sorts them anyway.
    return @[@"fr", @"es", @"it", @"no", @"sv", @"fi", @"da"];
}

+ (NSString *)displayNameForLanguageCode:(NSString *)code
{
    if (code.length == 0) { return @"System"; }

    // Each language's name in its own language, so a reader recognises it.
    NSDictionary<NSString *, NSString *> *names = @{
        @"en": @"English",
        @"de": @"Deutsch",
        @"fr": @"Français",
        @"es": @"Español",
        @"it": @"Italiano",
        @"no": @"Norsk",
        @"sv": @"Svenska",
        @"fi": @"Suomi",
        @"da": @"Dansk",
    };
    NSString *name = names[code];
    if (name != nil) { return name; }

    // Fallback: ask the system for the autonym, else just the code.
    NSLocale *loc = [NSLocale localeWithLocaleIdentifier:code];
    NSString *autox = [loc localizedStringForLanguageCode:code];
    return autox.length > 0 ? [autox capitalizedStringWithLocale:loc] : [code uppercaseString];
}

+ (NSString *)comingSoonMessageForLanguageCode:(NSString *)code
{
    // The same invitation in the tapped language where known, English
    // otherwise. Kept here (not in the string catalog) because it must read
    // in the tapped language, independent of the active UI language. More
    // translations can be filled in as volunteers provide them.
    NSDictionary<NSString *, NSString *> *messages = @{
        @"en": @"This language isn't translated yet. I'm looking for "
               @"volunteers — if you'd like to help, reach out by email or "
               @"on GitHub Discussions.",
        @"de": @"Diese Sprache ist noch nicht übersetzt. Ich suche helfende "
               @"Hände — wenn du mitmachen möchtest, melde dich per E-Mail "
               @"oder auf GitHub Discussions.",
        @"fr": @"Cette langue n'est pas encore traduite. Je cherche des "
               @"volontaires — si vous souhaitez aider, contactez-moi par "
               @"e-mail ou sur GitHub Discussions.",
    };
    NSString *msg = messages[code];
    return msg != nil ? msg : messages[@"en"];
}

@end
