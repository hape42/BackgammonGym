//
//  BGGStartTileCell.h
//  BackgammonGym
//
//  Created by Peter Schneider on 29.05.26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BGGStartTileCell : UICollectionViewCell

- (void)configureWithIcon:(UIImage *)icon
                iconColor:(UIColor *)iconColor
                    title:(NSString *)title
                 subtitle:(nullable NSString *)subtitle;

@end

NS_ASSUME_NONNULL_END
