//
//  BGGBoardElements.m
//  BackgammonGym
//

#import "BGGBoardElements.h"

// These match the constants I used in DailyGammon.
// Schema 4 was rebuilt to work like schema 5+, so all schemas now draw at
// runtime and there is no longer a pre-rendered-PNG special case.
static const CGFloat   kNativeCheckerSize   = 50.0; // checker PNG is 50x50 in native coords

@implementation BGGBoardElements

#pragma mark - Init

- (instancetype)initWithSchema:(NSInteger)schema
{
    self = [super init];
    if (self)
    {
        _schema = schema;
    }
    return self;
}

#pragma mark - Colors

- (nullable UIColor *)colorNamed:(NSString *)name
{
    NSString *fullName = [NSString stringWithFormat:@"%ld/%@", (long)_schema, name];
    return [UIColor colorNamed:fullName];
}

#pragma mark - Background

// All schemas ship a background image that covers the playing field.
- (nullable UIImage *)boardBackgroundImage
{
    NSString *name = [NSString stringWithFormat:@"%ld/background", (long)_schema];
    return [UIImage imageNamed:name];
}

#pragma mark - Point image

- (nullable UIImage *)pointImageForShade:(BGGPointShade)shade
                               direction:(BGGPointDirection)direction
                            checkerColor:(BGGCheckerColor)color
                            checkerCount:(NSInteger)count
                              pointIndex:(NSInteger)pointIndex
{
    // All schemas draw tongue and checkers separately at runtime.
    return [self drawPointForShade:shade
                         direction:direction
                      checkerColor:color
                      checkerCount:count
                        pointIndex:pointIndex];
}

// Draws a point (tongue + checkers) at runtime.
// Mirrors the logic from drawPointForSchema:... in DailyGammon.
- (nullable UIImage *)drawPointForShade:(BGGPointShade)shade
                              direction:(BGGPointDirection)direction
                           checkerColor:(BGGCheckerColor)color
                           checkerCount:(NSInteger)count
                             pointIndex:(NSInteger)pointIndex
{
    CGFloat w = kNativeCheckerSize;
    CGFloat h = kNativeCheckerSize * 5.0;   // tongue height = 5 checkers tall
    UIView *pointView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];

    // Tongue background.
    NSString *tongueName = (shade == BGGPointShadeLight)
        ? [NSString stringWithFormat:@"%ld/point_light", (long)_schema]
        : [NSString stringWithFormat:@"%ld/point_dark",  (long)_schema];
    UIImage *tongueImage = [UIImage imageNamed:tongueName];

    if (direction == BGGPointDirectionUp)
    {
        tongueImage = [self rotateImage:tongueImage byDegrees:180.0];
    }

    UIImageView *tongueIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    tongueIV.image = tongueImage;
    [pointView addSubview:tongueIV];

    // Checker images - schema >= 5 may have several variants (_1, _2, ...).
    // I collect them into an array and pick using a stable random per point,
    // exactly as in DailyGammon, so checkers look natural without changing
    // on every redraw.
    NSString *checkerBase = (color == BGGCheckerColorDark)
        ? [NSString stringWithFormat:@"%ld/checker_dk", (long)_schema]
        : [NSString stringWithFormat:@"%ld/checker_lt", (long)_schema];

    NSMutableArray<UIImage *> *variants = [NSMutableArray array];
    UIImage *base = [UIImage imageNamed:checkerBase];
    if (base != nil) { [variants addObject:base]; }
    for (NSInteger i = 1; ; i++)
    {
        NSString *varName = [NSString stringWithFormat:@"%@_%ld", checkerBase, (long)i];
        UIImage *var = [UIImage imageNamed:varName];
        if (var == nil) { break; }
        [variants addObject:var];
    }

    // Stable per-point random seed (same formula as DailyGammon).
    NSUInteger seed = (NSUInteger)(pointIndex * 7);

    NSInteger visible = MIN(count, 5);
    for (NSInteger i = 0; i < visible; i++)
    {
        UIImage *checker = (variants.count > 0)
            ? variants[(seed + (NSUInteger)i) % variants.count]
            : nil;

        UIImageView *civ = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, w, w)];
        civ.image = checker;

        CGRect f = civ.frame;
        f.origin.y = (direction == BGGPointDirectionDown)
            ? (CGFloat)i * w
            : (4.0 - (CGFloat)i) * w;
        civ.frame = f;
        [pointView addSubview:civ];
    }

    // Number label when more than 5 checkers on one point.
    if (count > 5)
    {
        CGFloat labelY = (direction == BGGPointDirectionDown) ? (4.0 * w) : 0.0;

        // Shadow label (black, offset by 1pt for legibility).
        UILabel *shadow = [[UILabel alloc] initWithFrame:CGRectMake(1, labelY + 1, w, w)];
        shadow.text = [NSString stringWithFormat:@"%ld", (long)count];
        shadow.textAlignment = NSTextAlignmentCenter;
        shadow.textColor = [UIColor blackColor];
        shadow.font = [shadow.font fontWithSize:25.0];
        shadow.adjustsFontSizeToFitWidth = YES;
        [pointView addSubview:shadow];

        // Main label (white).
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, labelY, w, w)];
        lbl.text = shadow.text;
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.textColor = [UIColor whiteColor];
        lbl.font = shadow.font;
        lbl.adjustsFontSizeToFitWidth = YES;
        [pointView addSubview:lbl];
    }

    return [self imageFromView:pointView];
}

#pragma mark - Bar image

- (nullable UIImage *)barImageForCheckerColor:(BGGCheckerColor)color
                                 checkerCount:(NSInteger)count
{
    // All schemas draw the bar checker stack at runtime.
    return [self drawBarForCheckerColor:color checkerCount:count];
}

// Draws a bar checker stack at runtime.
- (nullable UIImage *)drawBarForCheckerColor:(BGGCheckerColor)color
                                checkerCount:(NSInteger)count
{
    CGFloat w = kNativeCheckerSize;
    NSInteger visible = MIN(count, 5);
    UIView *barView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, w * (CGFloat)visible)];

    NSString *checkerName = (color == BGGCheckerColorDark)
        ? [NSString stringWithFormat:@"%ld/checker_dk", (long)_schema]
        : [NSString stringWithFormat:@"%ld/checker_lt", (long)_schema];
    UIImage *checker = [UIImage imageNamed:checkerName];

    for (NSInteger i = 0; i < visible; i++)
    {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, (CGFloat)i * w, w, w)];
        iv.image = checker;
        [barView addSubview:iv];
    }

    if (count > 5)
    {
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 2.0 * w, w, w)];
        lbl.text = [NSString stringWithFormat:@"%ld", (long)count];
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [lbl.font fontWithSize:25.0];
        lbl.adjustsFontSizeToFitWidth = YES;
        [barView addSubview:lbl];
    }

    return [self imageFromView:barView];
}

#pragma mark - Off image

// Returns a single lying-down off checker (the off_dark / off_light asset).
// The caller (BGGBoardView) stacks as many as needed, one per slot.
- (nullable UIImage *)offCheckerImageForColor:(BGGCheckerColor)color
{
    NSString *name = (color == BGGCheckerColorDark)
        ? [NSString stringWithFormat:@"%ld/off_dark",  (long)_schema]
        : [NSString stringWithFormat:@"%ld/off_light", (long)_schema];
    return [UIImage imageNamed:name];
}

#pragma mark - Utilities

// Renders a UIView hierarchy into a UIImage.
// I use this instead of UIGraphicsImageRenderer because it matches
// the exact approach from DailyGammon, keeping the two codebases consistent.
- (UIImage *)imageFromView:(UIView *)view
{
    CGSize size = view.bounds.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// Rotates an image by the given angle in degrees.
- (UIImage *)rotateImage:(UIImage *)image byDegrees:(CGFloat)degrees
{
    CGFloat radians = degrees * M_PI / 180.0;
    CGSize size = image.size;

    UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, size.width / 2.0, size.height / 2.0);
    CGContextRotateCTM(ctx, radians);
    [image drawInRect:CGRectMake(-size.width / 2.0, -size.height / 2.0,
                                  size.width, size.height)];
    UIImage *rotated = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rotated;
}

@end
