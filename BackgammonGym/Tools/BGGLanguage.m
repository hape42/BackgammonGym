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
    if (![[[self class] supportedLanguageCodes] containsObject:stored]) { return nil; }
    return stored;
}

- (void)setLanguage:(NSString *)language
{
    NSString *normalized = nil;
    if (language.length > 0 && [[[self class] supportedLanguageCodes] containsObject:language])
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
        if ([[[self class] supportedLanguageCodes] containsObject:code]) { return code; }
    }

    return kBGGFallbackLanguage;
}

#pragma mark - Supported languages

+ (NSArray<NSString *> *)supportedLanguageCodes
{
    // English first as the source language. Add "de" once German strings
    // exist; extend as more translations are added.
   return @[@"en", @"de"];
}

+ (NSString *)displayNameForLanguageCode:(NSString *)code
{
    if (code.length == 0) { return @"System"; }
    if ([code isEqualToString:@"en"]) { return @"EN"; }
    if ([code isEqualToString:@"de"]) { return @"DE"; }
    return [code uppercaseString];
}

@end
