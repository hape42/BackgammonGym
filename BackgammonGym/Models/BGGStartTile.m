//
//  BGGStartTile.m
//  BackgammonGym
//

#import "BGGStartTile.h"

@interface BGGStartTile ()

// Die Properties sind im Header als readonly deklariert,
// hier in der Class Extension machen wir sie privat readwrite,
// damit der Initializer sie setzen kann.
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite, nullable) NSString *subtitle;
@property (nonatomic, strong, readwrite) UIImage *icon;
@property (nonatomic, strong, readwrite) UIColor *iconColor;
@property (nonatomic, assign, readwrite) BGGStartTileKind kind;

@end

@implementation BGGStartTile

+ (instancetype)tileWithKind:(BGGStartTileKind)kind
                       title:(NSString *)title
                    subtitle:(NSString *)subtitle
                    iconName:(NSString *)iconName
                   iconColor:(UIColor *)iconColor
{
    BGGStartTile *tile = [[BGGStartTile alloc] init];
    tile.kind      = kind;
    tile.title     = title;
    tile.subtitle  = subtitle;
    tile.icon      = [UIImage systemImageNamed:iconName];
    tile.iconColor = iconColor;
    return tile;
}

@end
