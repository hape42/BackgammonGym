//
//  BGGBoardView.m
//  BackgammonGym
//

#import "BGGBoardView.h"
#import "BGGBoardState.h"
#import "BGGBoardGeometry.h"

@implementation BGGBoardView

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _boardDesign       = @"4";
    _showsPointNumbers = NO;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds   = YES;
}

#pragma mark - Properties

- (void)setBoardState:(nullable BGGBoardState *)boardState
{
    _boardState = boardState;
    [self setNeedsLayout];
}

- (void)setBoardDesign:(NSString *)boardDesign
{
    _boardDesign = [boardDesign copy];
    [self setNeedsLayout];
}

- (void)setShowsPointNumbers:(BOOL)showsPointNumbers
{
    _showsPointNumbers = showsPointNumbers;
    [self setNeedsLayout];
}

- (void)configureWithBoardState:(nullable BGGBoardState *)state
                          design:(NSString *)design
{
    _boardState  = state;
    _boardDesign = [design copy];
    [self setNeedsLayout];
}

#pragma mark - Scale helpers

// One scale factor keeps everything proportional, just like the zoomFactor
// I used when planning the board layout on paper.
- (CGFloat)boardScale
{
    CGFloat scaleX = self.bounds.size.width  / kBGGBoardWidth;
    CGFloat scaleY = self.bounds.size.height / kBGGBoardHeight;
    return MIN(scaleX, scaleY);
}

// Center the scaled board inside whatever space the view has.
- (CGPoint)boardOriginForScale:(CGFloat)scale
{
    CGFloat ox = (self.bounds.size.width  - kBGGBoardWidth  * scale) / 2.0;
    CGFloat oy = (self.bounds.size.height - kBGGBoardHeight * scale) / 2.0;
    return CGPointMake(ox, oy);
}

// Convert a native (unscaled) rect to view coordinates.
- (CGRect)scaleRect:(CGRect)r scale:(CGFloat)s origin:(CGPoint)o
{
    return CGRectMake(o.x + r.origin.x * s,
                      o.y + r.origin.y * s,
                      r.size.width  * s,
                      r.size.height * s);
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];

    for (UIView *sub in [self.subviews copy])
    {
        [sub removeFromSuperview];
    }

    if (self.bounds.size.width <= 0 || self.bounds.size.height <= 0)
    {
        return;
    }

    CGFloat scale  = [self boardScale];
    CGPoint origin = [self boardOriginForScale:scale];

    [self drawBackgroundWithScale:scale origin:origin];
    [self drawNumberStripsWithScale:scale origin:origin];
    [self drawOffAreaWithScale:scale origin:origin];
    [self drawBarAreaWithScale:scale origin:origin];
    [self drawCubeAreaWithScale:scale origin:origin];
    [self drawAllPointsWithScale:scale origin:origin];
    [self drawBarCheckersWithScale:scale origin:origin];
    [self drawOffCheckersWithScale:scale origin:origin];
}

#pragma mark - Background

- (void)drawBackgroundWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    UIColor *boardColor = [self colorNamed:@"ColorBoard"]
                       ?: [UIColor colorWithWhite:0.55 alpha:1.0];

    CGRect r = [self scaleRect:CGRectMake(0, 0, kBGGBoardWidth, kBGGBoardHeight)
                         scale:scale origin:origin];
    UIView *bg = [[UIView alloc] initWithFrame:r];
    bg.backgroundColor = boardColor;
    [self addSubview:bg];
}

#pragma mark - Number strips

// The number strips at the top and bottom use edgeColor, same as the off/bar/cube
// areas - that's what gives the board its consistent frame look.
- (void)drawNumberStripsWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    UIColor *edgeColor = [self colorNamed:@"ColorEdge"]
                      ?: [UIColor colorWithWhite:0.45 alpha:1.0];

    // Top strip (above the upper tongues)
    CGRect topRect = [self scaleRect:CGRectMake(0, 0, kBGGBoardWidth, kBGGNumberHeight)
                               scale:scale origin:origin];
    UIView *topStrip = [[UIView alloc] initWithFrame:topRect];
    topStrip.backgroundColor = edgeColor;
    [self addSubview:topStrip];

    // Bottom strip (below the lower tongues)
    CGFloat bottomY = kBGGBoardHeight - kBGGNumberHeight;
    CGRect bottomRect = [self scaleRect:CGRectMake(0, bottomY, kBGGBoardWidth, kBGGNumberHeight)
                                  scale:scale origin:origin];
    UIView *bottomStrip = [[UIView alloc] initWithFrame:bottomRect];
    bottomStrip.backgroundColor = edgeColor;
    [self addSubview:bottomStrip];
}

#pragma mark - Off area (left side)

- (void)drawOffAreaWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    UIColor *edgeColor  = [self colorNamed:@"ColorEdge"]
                       ?: [UIColor colorWithWhite:0.45 alpha:1.0];
    UIColor *boardColor = [self colorNamed:@"ColorBoard"]
                       ?: [UIColor colorWithWhite:0.55 alpha:1.0];

    // The off area starts below the number strip.
    CGRect offNative = CGRectMake(0,
                                  kBGGNumberHeight,
                                  kBGGOffWidth,
                                  kBGGBoardHeight - kBGGNumberHeight);
    UIView *offView = [[UIView alloc] initWithFrame:[self scaleRect:offNative
                                                              scale:scale origin:origin]];
    offView.backgroundColor = edgeColor;
    [self addSubview:offView];

    [self addTrayInsideView:offView
              nativeParentH:kBGGBoardHeight - kBGGNumberHeight
                      scale:scale
                 boardColor:boardColor
                   isBottom:NO];

    [self addTrayInsideView:offView
              nativeParentH:kBGGBoardHeight - kBGGNumberHeight
                      scale:scale
                 boardColor:boardColor
                   isBottom:YES];
}

#pragma mark - Cube area (right side)

- (void)drawCubeAreaWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    UIColor *edgeColor  = [self colorNamed:@"ColorEdge"]
                       ?: [UIColor colorWithWhite:0.45 alpha:1.0];
    UIColor *boardColor = [self colorNamed:@"ColorBoard"]
                       ?: [UIColor colorWithWhite:0.55 alpha:1.0];

    CGRect cubeNative = CGRectMake(kBGGCubeAreaX,
                                   kBGGNumberHeight,
                                   kBGGCubeWidth,
                                   kBGGBoardHeight - kBGGNumberHeight);
    UIView *cubeView = [[UIView alloc] initWithFrame:[self scaleRect:cubeNative
                                                              scale:scale origin:origin]];
    cubeView.backgroundColor = edgeColor;
    [self addSubview:cubeView];

    [self addTrayInsideView:cubeView
              nativeParentH:kBGGBoardHeight - kBGGNumberHeight
                      scale:scale
                 boardColor:boardColor
                   isBottom:NO];

    [self addTrayInsideView:cubeView
              nativeParentH:kBGGBoardHeight - kBGGNumberHeight
                      scale:scale
                 boardColor:boardColor
                   isBottom:YES];
}

// Both the off area and the cube area have two inner fields (top and bottom),
// each showing the tray_light image. The space between them is where the
// bear-off checkers stack up, and on the cube side it's where the doubling
// cube sits.
- (void)addTrayInsideView:(UIView *)parentView
            nativeParentH:(CGFloat)nativeParentH
                    scale:(CGFloat)scale
               boardColor:(UIColor *)boardColor
                 isBottom:(BOOL)isBottom
{
    // Centered horizontally within the off/cube width.
    CGFloat nativeX = (kBGGOffWidth - kBGGCheckerWidth) / 2.0;   // 15
    CGFloat nativeW = kBGGCheckerWidth;
    CGFloat nativeH = kBGGPointsHeight;

    CGFloat nativeY = isBottom
        ? kBGGPointsHeight + kBGGIndicatorHeight + kBGGCheckerWidth + kBGGIndicatorHeight
        : 0.0;

    CGRect insideFrame = CGRectMake(nativeX * scale,
                                    nativeY * scale,
                                    nativeW * scale,
                                    nativeH * scale);

    UIView *insideView = [[UIView alloc] initWithFrame:insideFrame];
    insideView.backgroundColor = boardColor;
    insideView.layer.borderWidth = 0.5;
    insideView.layer.borderColor = [UIColor grayColor].CGColor;
    [parentView addSubview:insideView];

    UIImage *tray = [self imageNamed:[self namespacedName:@"tray_light"]];
    if (tray != nil)
    {
        UIImageView *trayIV = [[UIImageView alloc] initWithFrame:insideView.bounds];
        trayIV.image = tray;
        trayIV.contentMode = UIViewContentModeScaleToFill;
        [insideView addSubview:trayIV];
    }
}

#pragma mark - Bar area (center divider)

- (void)drawBarAreaWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    UIColor *edgeColor  = [self colorNamed:@"ColorEdge"]
                       ?: [UIColor colorWithWhite:0.45 alpha:1.0];
    UIColor *stripColor = [self colorNamed:@"ColorBarCentralStripe"]
                       ?: [UIColor colorWithWhite:0.35 alpha:1.0];

    // The bar represents the central hinge of an opened backgammon case.
    CGRect barNative = CGRectMake(kBGGOffWidth + 6.0 * kBGGCheckerWidth,
                                  0,
                                  kBGGBarWidth,
                                  kBGGBoardHeight);
    UIView *barView = [[UIView alloc] initWithFrame:[self scaleRect:barNative
                                                             scale:scale origin:origin]];
    barView.backgroundColor = edgeColor;
    [self addSubview:barView];

    // The thin stripe down the middle reinforces the "case hinge" look.
    CGFloat stripW = 2.0;
    CGRect stripFrame = CGRectMake((kBGGBarWidth * scale - stripW) / 2.0,
                                   0,
                                   stripW,
                                   kBGGBoardHeight * scale);
    UIView *strip = [[UIView alloc] initWithFrame:stripFrame];
    strip.backgroundColor = stripColor;
    [barView addSubview:strip];
}

#pragma mark - Points (tongues 1–24)

- (void)drawAllPointsWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    for (NSInteger point = 1; point <= 24; point++)
    {
        [self drawPoint:point scale:scale origin:origin];
    }
}

- (void)drawPoint:(NSInteger)point scale:(CGFloat)scale origin:(CGPoint)origin
{
    NSInteger slot;
    BOOL isTopRow;
    [self slotForPoint:point outSlot:&slot outIsTopRow:&isTopRow];

    NSInteger checkers = (self.boardState != nil) ? [self.boardState checkersOnPoint:point] : 0;
    BOOL isBlue = (checkers > 0);
    NSInteger cnt = ABS(checkers);

    // Alternate light/dark tongues across the board like a chess pattern.
    BOOL isLight   = (slot % 2 == 0);
    BOOL pointsDown = isTopRow;

    NSString *imgName = [self pointImageNameForLightTongue:isLight
                                                pointsDown:pointsDown
                                                    isBlue:isBlue
                                                     count:cnt];
    UIImage *img = [self imageNamed:imgName];

    CGFloat nativeX = BGGTongueLeftX(slot);
    CGFloat nativeY = isTopRow ? kBGGTopTongueY : kBGGBottomTongueY;

    CGRect frame = [self scaleRect:CGRectMake(nativeX, nativeY,
                                               kBGGCheckerWidth, kBGGPointsHeight)
                             scale:scale origin:origin];
    UIImageView *iv = [[UIImageView alloc] initWithFrame:frame];
    iv.image = img;
    iv.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:iv];

    if (self.showsPointNumbers)
    {
        [self addPointNumberLabel:point atRect:frame isTopRow:isTopRow];
    }
}

// Map point number (1–24) to horizontal slot (0–11) and row.
//
// My board geometry, planned on paper:
//   Point 1  = bottom right  -> slot 11, lower row
//   Point 12 = bottom left   -> slot 0,  lower row
//   Point 13 = top left      -> slot 0,  upper row
//   Point 24 = top right     -> slot 11, upper row
- (void)slotForPoint:(NSInteger)point
             outSlot:(NSInteger *)outSlot
         outIsTopRow:(BOOL *)outIsTopRow
{
    if (point >= 13)
    {
        if (outIsTopRow) { *outIsTopRow = YES; }
        if (outSlot)     { *outSlot = point - 13; }
    }
    else
    {
        if (outIsTopRow) { *outIsTopRow = NO; }
        if (outSlot)     { *outSlot = 12 - point; }
    }
}

// Build the asset name deterministically from the position data,
// e.g. "4/pt_lt_down_b7" for a light tongue pointing down with 7 blue checkers.
// This was previously scattered across drawBoard - now it's all in one place.
- (NSString *)pointImageNameForLightTongue:(BOOL)isLight
                                pointsDown:(BOOL)pointsDown
                                    isBlue:(BOOL)isBlue
                                     count:(NSInteger)count
{
    NSString *shade = isLight ? @"lt" : @"dk";
    NSString *dir   = pointsDown ? @"down" : @"up";

    if (count == 0)
    {
        return [self namespacedName:[NSString stringWithFormat:@"pt_%@_%@0", shade, dir]];
    }

    NSString *color = isBlue ? @"b" : @"y";
    return [self namespacedName:[NSString stringWithFormat:@"pt_%@_%@_%@%ld",
                                 shade, dir, color, (long)count]];
}

#pragma mark - Bar checkers

- (void)drawBarCheckersWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    if (self.boardState == nil) { return; }

    NSInteger blueOnBar   = self.boardState.barBlue;
    NSInteger yellowOnBar = self.boardState.barYellow;

    if (blueOnBar > 0)
    {
        [self drawBarStack:blueOnBar isBlue:YES inUpperHalf:YES scale:scale origin:origin];
    }
    if (yellowOnBar > 0)
    {
        [self drawBarStack:yellowOnBar isBlue:NO inUpperHalf:NO scale:scale origin:origin];
    }
}

// Stack individual checker images on the bar, same approach as drawBarForSchema:
// in DailyGammon. Blue goes in the upper half, yellow in the lower half.
- (void)drawBarStack:(NSInteger)count
              isBlue:(BOOL)isBlue
         inUpperHalf:(BOOL)upper
               scale:(CGFloat)scale
              origin:(CGPoint)origin
{
    NSString *checkerName = [self namespacedName:(isBlue ? @"checker_lt" : @"checker_dk")];
    UIImage  *checker     = [self imageNamed:checkerName];

    NSInteger visible = MIN(count, 5);

    // Center the checker stack within the bar width.
    CGFloat nativeBarX    = kBGGOffWidth + 6.0 * kBGGCheckerWidth;
    CGFloat checkerNativeX = nativeBarX + (kBGGBarWidth - kBGGCheckerWidth) / 2.0;

    for (NSInteger i = 0; i < visible; i++)
    {
        CGFloat nativeY;
        if (upper)
        {
            nativeY = kBGGTopTongueY + (CGFloat)i * kBGGCheckerWidth;
        }
        else
        {
            CGFloat stackBottom = kBGGBoardHeight - kBGGNumberHeight;
            nativeY = stackBottom - (CGFloat)(i + 1) * kBGGCheckerWidth;
        }

        CGRect frame = [self scaleRect:CGRectMake(checkerNativeX, nativeY,
                                                   kBGGCheckerWidth, kBGGCheckerWidth)
                                 scale:scale origin:origin];
        UIImageView *iv = [[UIImageView alloc] initWithFrame:frame];
        iv.image = checker;
        iv.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:iv];
    }

    // Show the count as a number label when more than 5 checkers are on the bar.
    if (count > 5)
    {
        CGFloat nativeY = upper
            ? kBGGTopTongueY + 2.0 * kBGGCheckerWidth
            : kBGGBoardHeight - kBGGNumberHeight - 3.0 * kBGGCheckerWidth;

        CGRect frame = [self scaleRect:CGRectMake(checkerNativeX, nativeY,
                                                   kBGGCheckerWidth, kBGGCheckerWidth)
                                 scale:scale origin:origin];
        UILabel *lbl = [[UILabel alloc] initWithFrame:frame];
        lbl.text = [NSString stringWithFormat:@"%ld", (long)count];
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont monospacedDigitSystemFontOfSize:frame.size.height * 0.5
                                                    weight:UIFontWeightBold];
        lbl.adjustsFontSizeToFitWidth = YES;
        [self addSubview:lbl];
    }
}

#pragma mark - Off checkers

- (void)drawOffCheckersWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    if (self.boardState == nil) { return; }

    NSInteger blueOff   = self.boardState.offBlue;
    NSInteger yellowOff = self.boardState.offYellow;

    if (blueOff > 0)
    {
        [self drawOffStack:blueOff isBlue:YES inUpperHalf:NO scale:scale origin:origin];
    }
    if (yellowOff > 0)
    {
        [self drawOffStack:yellowOff isBlue:NO inUpperHalf:YES scale:scale origin:origin];
    }
}

// Bear-off checkers use the off_* images which show checkers lying on their side,
// stacked from the outside in. This makes it easy to count how many are already off.
- (void)drawOffStack:(NSInteger)count
              isBlue:(BOOL)isBlue
         inUpperHalf:(BOOL)upper
               scale:(CGFloat)scale
              origin:(CGPoint)origin
{
    NSString *colorStr = isBlue ? @"b" : @"y";
    NSString *halfStr  = upper  ? @"top" : @"bot";

    NSInteger visible = MIN(count, 4);
    CGFloat slotH     = kBGGPointsHeight / 5.0;   // each off image occupies 1/5 of point height
    CGFloat nativeX   = kBGGCubeAreaX + (kBGGCubeWidth - kBGGCheckerWidth) / 2.0;

    for (NSInteger i = 1; i <= visible; i++)
    {
        NSString *name = [self namespacedName:
                          [NSString stringWithFormat:@"off_%@%ld_%@",
                           colorStr, (long)i, halfStr]];
        UIImage *img = [self imageNamed:name];

        CGFloat nativeY = upper
            ? kBGGTopTongueY + (CGFloat)(i - 1) * slotH
            : kBGGBoardHeight - kBGGNumberHeight - (CGFloat)i * slotH;

        CGRect frame = [self scaleRect:CGRectMake(nativeX, nativeY,
                                                   kBGGCheckerWidth, slotH)
                                 scale:scale origin:origin];
        UIImageView *iv = [[UIImageView alloc] initWithFrame:frame];
        iv.image = img;
        iv.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:iv];
    }

    // off_b5 / off_y5 is a special combined image for 5 or more checkers.
    if (count >= 5)
    {
        NSString *name = [self namespacedName:
                          [NSString stringWithFormat:@"off_%@5", colorStr]];
        UIImage *img = [self imageNamed:name];

        CGFloat nativeY = upper
            ? kBGGTopTongueY
            : kBGGBoardHeight - kBGGNumberHeight - slotH;

        CGRect frame = [self scaleRect:CGRectMake(nativeX, nativeY,
                                                   kBGGCheckerWidth, slotH)
                                 scale:scale origin:origin];
        UIImageView *iv = [[UIImageView alloc] initWithFrame:frame];
        iv.image = img;
        iv.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:iv];
    }
}

#pragma mark - Point number labels

// Point numbers are a training aid - in a real game the board has no numbers.
// Toggle showsPointNumbers to switch them on or off.
- (void)addPointNumberLabel:(NSInteger)point
                     atRect:(CGRect)tongueRect
                   isTopRow:(BOOL)isTopRow
{
    UIColor *numColor = [self colorNamed:@"ColorNumber"]
                     ?: [UIColor secondaryLabelColor];

    UILabel *lbl = [[UILabel alloc] init];
    lbl.text = [NSString stringWithFormat:@"%ld", (long)point];
    lbl.font = [UIFont monospacedDigitSystemFontOfSize:10.0 weight:UIFontWeightMedium];
    lbl.textColor = numColor;
    lbl.textAlignment = NSTextAlignmentCenter;
    [lbl sizeToFit];

    CGFloat w = MAX(lbl.bounds.size.width, 16.0);
    CGFloat h = lbl.bounds.size.height;
    CGFloat x = CGRectGetMidX(tongueRect) - w / 2.0;

    // Center the label vertically within the number strip (kBGGNumberHeight),
    // not glued to the tongue edge.
    CGFloat stripH = kBGGNumberHeight * [self boardScale];
    CGFloat y = isTopRow
        ? CGRectGetMinY(tongueRect) - stripH + (stripH - h) / 2.0
        : CGRectGetMaxY(tongueRect) + (stripH - h) / 2.0;

    lbl.frame = CGRectMake(x, y, w, h);
    [self addSubview:lbl];
}

#pragma mark - Image helpers

// Prepend the board design namespace so the same image names work
// across all board styles (4, 5, 6, ...).
- (NSString *)namespacedName:(NSString *)base
{
    if (self.boardDesign.length == 0) { return base; }
    return [NSString stringWithFormat:@"%@/%@", self.boardDesign, base];
}

// Log missing images during development so typos in asset names are
// caught immediately rather than silently showing a blank space.
- (nullable UIImage *)imageNamed:(NSString *)name
{
    UIImage *img = [UIImage imageNamed:name];
    if (img == nil)
    {
        NSLog(@"[BGGBoardView] image not found: %@", name);
    }
    return img;
}

// Color assets live in the same numbered subfolders as the image assets,
// so the namespace prefix works exactly the same way: "4/ColorNumber" etc.
- (nullable UIColor *)colorNamed:(NSString *)name
{
    return [UIColor colorNamed:[self namespacedName:name]];
}

@end
