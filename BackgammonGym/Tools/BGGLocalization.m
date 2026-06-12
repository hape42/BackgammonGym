//
//  BGGLocalization.m
//  BackgammonGym
//

#import "BGGLocalization.h"
#import "BGGLanguage.h"

static NSBundle *gCurrentBundle   = nil;
static NSString *gCurrentLanguage = nil;

NSString *BGGLocalizedString(NSString *key)
{
    if (key.length == 0) { return @""; }

    NSString *currentCode = [[BGGLanguage sharedLanguage] effectiveLanguageCode];

    // Re-resolve the bundle whenever the effective language changed.
    if (gCurrentBundle == nil || ![currentCode isEqualToString:gCurrentLanguage])
    {
        [BGGLocalization reloadCurrentBundle];
    }

    // localizedStringForKey: returns the key itself when not found, which is
    // exactly the English fallback we want (keys are English source text).
    return [gCurrentBundle localizedStringForKey:key value:nil table:nil];
}

@implementation BGGLocalization

+ (void)load
{
    // Reload the bundle whenever the chosen language changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageDidChange:)
                                                 name:BGGLanguageDidChangeNotification
                                               object:nil];
}

+ (void)languageDidChange:(NSNotification *)notification
{
    [self reloadCurrentBundle];
}

+ (void)reloadCurrentBundle
{
    NSString *code = [[BGGLanguage sharedLanguage] effectiveLanguageCode];
    gCurrentLanguage = [code copy];

    // Look for <code>.lproj in the main bundle.
    NSString *path = [[NSBundle mainBundle] pathForResource:code ofType:@"lproj"];
    if (path != nil)
    {
        gCurrentBundle = [NSBundle bundleWithPath:path];
        return;
    }

    // Fallback: the English bundle, if present.
    NSString *enPath = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
    if (enPath != nil)
    {
        gCurrentBundle = [NSBundle bundleWithPath:enPath];
        return;
    }

    // Last resort: the main bundle (keys will show through as-is, i.e.
    // English source text).
    gCurrentBundle = [NSBundle mainBundle];
}

@end
