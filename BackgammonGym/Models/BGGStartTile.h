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
};

/// Datenmodell für eine einzelne Kachel auf dem Startbildschirm.
@interface BGGStartTile : NSObject

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly, nullable) NSString *subtitle;
@property (nonatomic, strong, readonly) UIImage *icon;
@property (nonatomic, strong, readonly) UIColor *iconColor;
@property (nonatomic, assign, readonly) BGGStartTileKind kind;

/// Convenience-Konstruktor: erzeugt eine fertige Kachel in einer Zeile.
+ (instancetype)tileWithKind:(BGGStartTileKind)kind
                       title:(NSString *)title
                    subtitle:(nullable NSString *)subtitle
                    iconName:(NSString *)iconName
                   iconColor:(UIColor *)iconColor;

@end

NS_ASSUME_NONNULL_END
