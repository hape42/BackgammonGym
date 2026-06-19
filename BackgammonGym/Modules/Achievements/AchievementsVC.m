//
//  AchievementsVC.m
//  BackgammonGym
//

#import <UIKit/UIKit.h>
#import "AchievementsVC.h"
#import "BGGAchievements.h"
#import "CoreDataManager.h"
#import "UIViewController+BGGHomeButton.h"
#import "BGGLocalization.h"

@interface AchievementsVC ()

// Three sections, by module. Each holds the definitions for that group in
// catalogue order (bronze -> silver -> gold within a category).
@property (nonatomic, strong) NSArray<NSArray<BGGAchievementDefinition *> *> *sections;
@property (nonatomic, strong) NSArray<NSString *> *sectionTitles;

// Progress snapshot for this reload: identifier -> current value.
@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *progress;

@end

@implementation AchievementsVC

- (instancetype)init
{
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Achievements";   // brand language, stays English
    [self installHomeButton];

    self.tableView.allowsSelection = NO;

    [self buildSections];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:@"RefreshAllViews"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reload];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Data

// Split the flat catalogue into the three module groups. "Pip Count" and
// "MET" are brand language; the across-modules header is localized.
- (void)buildSections
{
    NSArray<BGGAchievementDefinition *> *all =
        [[BGGAchievements sharedAchievements] allDefinitions];

    NSMutableArray<BGGAchievementDefinition *> *pip = [NSMutableArray array];
    NSMutableArray<BGGAchievementDefinition *> *met = [NSMutableArray array];
    NSMutableArray<BGGAchievementDefinition *> *across = [NSMutableArray array];

    for (BGGAchievementDefinition *d in all)
    {
        if ([d.module isEqualToString:@"pipcount"])   { [pip addObject:d]; }
        else if ([d.module isEqualToString:@"met"])   { [met addObject:d]; }
        else                                          { [across addObject:d]; }
    }

    self.sections      = @[pip, met, across];
    self.sectionTitles = @[@"Pip Count", @"MET", BGGLocalizedString(@"Across modules")];
}

- (void)reload
{
    // Award anything now due before reading state. Activity-streak
    // achievements can become due just by opening the app on consecutive
    // days, with no workout to trigger a check – so re-check here (idempotent)
    // or they would show their progress as full (e.g. 3/3) yet stay grey.
    [[BGGAchievements sharedAchievements] checkAndAwardForModule:nil];

    self.progress = [[BGGAchievements sharedAchievements] progressForAllDefinitions];
    [self.tableView reloadData];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.sections[section].count;
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section
{
    return self.sectionTitles[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AchCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"AchCell"];
    }

    BGGAchievementDefinition *def = self.sections[indexPath.section][indexPath.row];
    BOOL earned = [[CoreDataManager sharedManager]
                   earnedAchievementWithIdentifier:def.identifier] != nil;

    UIListContentConfiguration *content = [cell defaultContentConfiguration];
    content.text = BGGLocalizedString(def.titleKey);

    // Medal icon, tinted by tier; greyed out while locked.
    NSString *symbol = earned ? @"medal.fill" : @"medal";
    content.image = [UIImage systemImageNamed:symbol];
    content.imageProperties.tintColor = earned
        ? [self colorForTier:def.tier]
        : [UIColor tertiaryLabelColor];

    cell.contentConfiguration = content;

    // Accessory text: a checkmark-ish "done" for earned, else "value / bar".
    UILabel *trailing = [[UILabel alloc] init];
    trailing.font = [UIFont monospacedDigitSystemFontOfSize:15.0
                                                     weight:UIFontWeightRegular];
    if (earned)
    {
        trailing.text      = BGGLocalizedString(@"Earned");
        trailing.textColor = [UIColor labelColor];
        trailing.font      = [UIFont monospacedDigitSystemFontOfSize:15.0
                                                              weight:UIFontWeightBold];
    }
    else
    {
        NSInteger value = [self.progress[def.identifier] integerValue];
        // Clamp the shown value to the bar so a locked row never reads past
        // its threshold (can happen mid-save before the award lands).
        if (value > def.threshold) { value = def.threshold; }
        trailing.text      = [NSString stringWithFormat:@"%ld / %ld",
                              (long)value, (long)def.threshold];
        trailing.textColor = [UIColor secondaryLabelColor];
    }
    [trailing sizeToFit];
    cell.accessoryView = trailing;

    return cell;
}

#pragma mark - Helpers

- (UIColor *)colorForTier:(BGGAchievementTier)tier
{
    switch (tier)
    {
        case BGGAchievementTierBronze:
            return [UIColor colorWithRed:0.80 green:0.50 blue:0.20 alpha:1.0];
        case BGGAchievementTierSilver:
            return [UIColor colorWithRed:0.60 green:0.60 blue:0.62 alpha:1.0];
        case BGGAchievementTierGold:
            return [UIColor colorWithRed:0.83 green:0.69 blue:0.22 alpha:1.0];
    }
    return [UIColor labelColor];
}

@end
