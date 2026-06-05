//
//  BGGBoardElements.h
//  BackgammonGym
//
//  Provides all visual board elements for a given schema.
//
//  Schema <= 4: loads pre-rendered PNGs from the asset catalog.
//  Schema >= 5: draws elements at runtime using point_light/point_dark,
//               checker_dk/checker_lt and off_dark/off_light assets,
//               then renders them into a UIImage.
//
//  BGGBoardView only talks to this class - it never needs to know
//  which schema it is dealing with.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Checker colors, matching the naming convention in the asset catalog.
typedef NS_ENUM(NSInteger, BGGCheckerColor)
{
    BGGCheckerColorDark  = 0,   // "b" in pt_ names, checker_dk
    BGGCheckerColorLight = 1,   // "y" in pt_ names, checker_lt
};

// Point (tongue) direction.
typedef NS_ENUM(NSInteger, BGGPointDirection)
{
    BGGPointDirectionDown = 0,
    BGGPointDirectionUp   = 1,
};

// Point (tongue) shade.
typedef NS_ENUM(NSInteger, BGGPointShade)
{
    BGGPointShadeDark  = 0,
    BGGPointShadeLight = 1,
};

@interface BGGBoardElements : NSObject

// Designated initializer. schema is the board design number (4, 5, 6, ...).
- (instancetype)initWithSchema:(NSInteger)schema NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) NSInteger schema;

// Returns the board background image for this schema, or nil if none exists
// (the caller then uses ColorBoard as a plain background).
- (nullable UIImage *)boardBackgroundImage;

// Returns the named color asset for this schema.
// Handles the namespace prefix automatically: "4/ColorBoard" etc.
- (nullable UIColor *)colorNamed:(NSString *)name;

// Returns a fully composited tongue image including checkers, drawn at runtime.
- (nullable UIImage *)pointImageForShade:(BGGPointShade)shade
                               direction:(BGGPointDirection)direction
                            checkerColor:(BGGCheckerColor)color
                            checkerCount:(NSInteger)count
                              pointIndex:(NSInteger)pointIndex;

// Returns a bar checker stack image.
- (nullable UIImage *)barImageForCheckerColor:(BGGCheckerColor)color
                                 checkerCount:(NSInteger)count;

// Returns a single lying-down off checker. The caller stacks as many as needed.
- (nullable UIImage *)offCheckerImageForColor:(BGGCheckerColor)color;

@end

NS_ASSUME_NONNULL_END
