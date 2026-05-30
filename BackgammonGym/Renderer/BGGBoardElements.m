//
//  BGGBoardElements.m
//  BackgammonGym
//

#import "BGGBoardElements.h"

// These match the constants I used in DailyGammon.
static const NSInteger kSchemaDrawThreshold = 5;   // schema >= 5 draws at runtime
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

// Schema >= 5 may ship a background image that covers the playing field.
// Schema <= 4 use a plain backgroundColor, so this returns nil for them.
- (nullable UIImage *)boardBackgroundImage
{
    if (_schema < kSchemaDrawThreshold) { return nil; }
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
    if (_schema < kSchemaDrawThreshold)
    {
        // Schema <= 4: one pre-rendered PNG covers tongue + checkers.
        return [UIImage imageNamed:[self pointAssetNameForShade:shade
                                                     direction:direction
                                                  checkerColor:color
                                                  checkerCount:count]];
    }
    else
    {
        // Schema >= 5: draw tongue and checkers separately at runtime.
        return [self drawPointForShade:shade
                             direction:direction
                          checkerColor:color
                          checkerCount:count
                            pointIndex:pointIndex];
    }
}

// Builds the asset name for schema <= 4, e.g. "4/pt_lt_down_b7".
- (NSString *)pointAssetNameForShade:(BGGPointShade)shade
                           direction:(BGGPointDirection)direction
                        checkerColor:(BGGCheckerColor)color
                        checkerCount:(NSInteger)count
{
    NSString *shadeStr = (shade == BGGPointShadeLight) ? @"lt" : @"dk";
    NSString *dirStr   = (direction == BGGPointDirectionDown) ? @"down" : @"up";

    NSString *base;
    if (count == 0)
    {
        base = [NSString stringWithFormat:@"pt_%@_%@0", shadeStr, dirStr];
    }
    else
    {
        NSString *colorStr = (color == BGGCheckerColorDark) ? @"b" : @"y";
        base = [NSString stringWithFormat:@"pt_%@_%@_%@%ld",
                shadeStr, dirStr, colorStr, (long)count];
    }
    return [NSString stringWithFormat:@"%ld/%@", (long)_schema, base];
}

// Draws a point (tongue + checkers) at runtime for schema >= 5.
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
    if (_schema < kSchemaDrawThreshold)
    {
        // Schema <= 4: pre-rendered asset.
        NSString *colorStr = (color == BGGCheckerColorDark) ? @"b" : @"y";
        NSString *name = [NSString stringWithFormat:@"%ld/bar_%@%ld",
                          (long)_schema, colorStr, (long)count];
        return [UIImage imageNamed:name];
    }
    else
    {
        return [self drawBarForCheckerColor:color checkerCount:count];
    }
}

// Draws a bar checker stack at runtime for schema >= 5.
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

- (nullable UIImage *)offImageForCheckerColor:(BGGCheckerColor)color
                                    direction:(BGGOffDirection)direction
                                 checkerCount:(NSInteger)count
{
    if (_schema < kSchemaDrawThreshold)
    {
        // Schema <= 4: pre-rendered asset, e.g. "4/off_b2_top".
        NSString *colorStr = (color == BGGCheckerColorDark) ? @"b" : @"y";
        NSString *dirStr;
        switch (direction)
        {
            case BGGOffDirectionTop:    dirStr = @"top"; break;
            case BGGOffDirectionBottom: dirStr = @"bot"; break;
            default:                    dirStr = nil;    break;
        }

        NSString *name;
        if (dirStr != nil)
        {
            name = [NSString stringWithFormat:@"%ld/off_%@%ld_%@",
                    (long)_schema, colorStr, (long)count, dirStr];
        }
        else
        {
            // off_b5 / off_y5 – combined image for >= 5.
            name = [NSString stringWithFormat:@"%ld/off_%@5", (long)_schema, colorStr];
        }
        return [UIImage imageNamed:name];
    }
    else
    {
        return [self drawOffForCheckerColor:color direction:direction checkerCount:count];
    }
}

// Draws off-checkers at runtime for schema >= 5.
- (nullable UIImage *)drawOffForCheckerColor:(BGGCheckerColor)color
                                   direction:(BGGOffDirection)direction
                                checkerCount:(NSInteger)count
{
    CGFloat w = kNativeCheckerSize;
    UIView *offView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 230.0, 350.0)];

    NSString *checkerName = (color == BGGCheckerColorDark)
        ? [NSString stringWithFormat:@"%ld/off_dark",  (long)_schema]
        : [NSString stringWithFormat:@"%ld/off_light", (long)_schema];

    for (NSInteger i = 0; i < count; i++)
    {
        UIImageView *iv = [[UIImageView alloc]
                           initWithImage:[UIImage imageNamed:checkerName]];
        CGRect f = iv.frame;
        f.origin.x = 15.0;
        switch (direction)
        {
            case BGGOffDirectionBottom:
                f.origin.y = offView.frame.size.height - 100.0 - (CGFloat)i * w;
                break;
            case BGGOffDirectionTop:
                f.origin.y = w + (CGFloat)i * w;
                break;
            case BGGOffDirectionAll:
            default:
                f.origin.y = w + (CGFloat)i * w;
                break;
        }
        iv.frame = f;
        [offView addSubview:iv];
    }

    return [self imageFromView:offView];
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
