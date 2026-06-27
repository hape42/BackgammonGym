//
//  BGGStartTileCell.h
//  BackgammonGym
//
//  Created by Peter Schneider on 29.05.26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BGGStartTileCell : UICollectionViewCell

/// Dezente Kachel (grauer Hintergrund, iconColor wie übergeben, normale Schrift).
- (void)configureWithIcon:(UIImage *)icon
                iconColor:(UIColor *)iconColor
                    title:(NSString *)title
                 subtitle:(nullable NSString *)subtitle;

/// Wie oben, plus Schalter: prominent = AccentColor-Hintergrund, helle Schrift,
/// graues Icon. iconColor wird dann ignoriert (das Icon wird grau gesetzt).
- (void)configureWithIcon:(UIImage *)icon
                iconColor:(UIColor *)iconColor
                    title:(NSString *)title
                 subtitle:(nullable NSString *)subtitle
                prominent:(BOOL)prominent;

@end

NS_ASSUME_NONNULL_END
