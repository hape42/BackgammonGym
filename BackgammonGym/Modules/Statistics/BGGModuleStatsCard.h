//
//  BGGModuleStatsCard.h
//  BackgammonGym
//
//  A rounded card for the cross-module Statistics screen showing the
//  cumulative numbers of one module (e.g. Pip Count, MET), split into a
//  Training and a Workout block. The card pulls its own figures from the
//  CoreDataManager via statsForModule:mode:, so the hosting view controller
//  only has to hand it a module identifier and a display title.
//
//  New modules drop in by adding another card with their module string; the
//  layout and number formatting stay the same.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BGGModuleStatsCard : UIView

// title    – shown at the top of the card (brand language, e.g. "Pip Count").
// module   – Core Data module identifier ("pipcount" / "met").
- (instancetype)initWithTitle:(NSString *)title
                       module:(NSString *)module;

// Re-reads the numbers from Core Data and rebuilds the two blocks. Safe to
// call from viewWillAppear / on a RefreshAllViews notification.
- (void)reload;

@end

NS_ASSUME_NONNULL_END
