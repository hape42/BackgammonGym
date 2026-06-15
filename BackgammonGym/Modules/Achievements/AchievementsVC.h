//
//  AchievementsVC.h
//  BackgammonGym
//
//  The Achievements screen, opened from the start tile. Lists every
//  achievement grouped by module (Pip Count, MET, and the cross-module
//  activity ones), showing earned state and, for locked ones, the current
//  progress towards the bar (e.g. 6 / 10). All definitions, earned state and
//  progress come from BGGAchievements; this screen is pure presentation.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AchievementsVC : UITableViewController

@end

NS_ASSUME_NONNULL_END
