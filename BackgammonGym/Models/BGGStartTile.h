//
//  BGGStartTile.h
//  BackgammonGym
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Welche Art von Kachel auf dem Startbildschirm.
/// Wenn ein neues Modul dazukommt, hier einen neuen Fall ergänzen.
typedef NS_ENUM(NSInteger, BGGStartTileKind)
{
    BGGStartTileKindPipCount     = 1,
    BGGStartTileKindMETQuiz      = 2,
    BGGStartTileKindCollection   = 30,
    BGGStartTileKindStatistics   = 40,
    BGGStartTileKindAchievements = 41,
    BGGStartTileKindFeedback     = 50,
    BGGStartTileKindMoreModules  = 51,
    BGGStartTileKindCredits      = 60,
};

/// Datenmodell für eine einzelne Kachel auf dem Startbildschirm.
@interface BGGStartTile : NSObject

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly, nullable) NSString *subtitle;
@property (nonatomic, strong, readonly) UIImage *icon;
@property (nonatomic, strong, readonly) UIColor *iconColor;
@property (nonatomic, assign, readonly) BGGStartTileKind kind;

/// Kräftige Darstellung: AccentColor-Hintergrund, helle Schrift, graues Icon.
/// NO (Default) = dezent: grauer Hintergrund, normale Schrift, iconColor wie übergeben.
@property (nonatomic, assign, readonly) BOOL prominent;

/// Convenience-Konstruktor: erzeugt eine dezente Kachel (prominent = NO).
+ (instancetype)tileWithKind:(BGGStartTileKind)kind
                       title:(NSString *)title
                    subtitle:(nullable NSString *)subtitle
                    iconName:(NSString *)iconName
                   iconColor:(UIColor *)iconColor;

/// Wie oben, aber mit explizitem prominent-Schalter.
+ (instancetype)tileWithKind:(BGGStartTileKind)kind
                       title:(NSString *)title
                    subtitle:(nullable NSString *)subtitle
                    iconName:(NSString *)iconName
                   iconColor:(UIColor *)iconColor
                   prominent:(BOOL)prominent;

@end

NS_ASSUME_NONNULL_END
