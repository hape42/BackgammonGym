//
//  BGGActivityGridView.h
//  BackgammonGym
//
//  A GitHub-style contribution grid for the Statistics tile. Shows the last
//  ~12 months as a grid of day cells (today at the right edge), coloured by
//  the highest activity of each day:
//    0 not used (grey), 1 opened, 2 training, 3 workout — in red tones.
//  The data comes from CoreDataManager's activityLevelsForLastDays:.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BGGActivityGridView : UIView

// The visible range, in months: 12 (default), 6, or 3. Fewer months means
// fewer week-columns across the same width, so each day cell is larger and
// easier to read on a narrow (iPhone) screen. Other values are clamped to
// these three.
@property (nonatomic, assign) NSInteger monthsToShow;

// Reloads the activity data from Core Data and redraws. Safe to call from
// viewWillAppear and on the RefreshAllViews notification.
- (void)reload;

@end

NS_ASSUME_NONNULL_END
