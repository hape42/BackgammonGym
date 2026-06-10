//
//  BGGSessionCell.h
//  BackgammonGym
//
//  Table view cell for one training session in the Progress history.
//  Left: date and mode. Right: hit rate and average answer time.
//  Unfinished sessions (cancelled mid-way) are marked discreetly.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BGGSessionCell : UITableViewCell

- (void)configureWithDate:(nullable NSDate *)date
                     mode:(nullable NSString *)mode
             correctCount:(NSInteger)correctCount
               totalCount:(NSInteger)totalCount
            averageMillis:(NSInteger)averageMillis
               isComplete:(BOOL)isComplete;

@end

NS_ASSUME_NONNULL_END
