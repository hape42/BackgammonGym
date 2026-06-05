//
//  BGGBoardView.m
//  BackgammonGym
//

#import "BGGBoardView.h"
#import "BGGBoardState.h"
#import "BGGBoardGeometry.h"
#import "BGGBoardElements.h"

@interface BGGBoardView ()
@property (nonatomic, strong) BGGBoardElements *elements;
@end

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
    _showsCube         = YES;
    _showsDice         = YES;
    _elements          = [[BGGBoardElements alloc] initWithSchema:4];
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
    _elements    = [[BGGBoardElements alloc] initWithSchema:[boardDesign integerValue]];
    [self setNeedsLayout];
}

- (void)setShowsPointNumbers:(BOOL)showsPointNumbers
{
    _showsPointNumbers = showsPointNumbers;
    [self setNeedsLayout];
}

- (void)setShowsCube:(BOOL)showsCube
{
    _showsCube = showsCube;
    [self setNeedsLayout];
}

- (void)setShowsDice:(BOOL)showsDice
{
    _showsDice = showsDice;
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

    if (self.showsCube)  { [self drawCubeWithScale:scale origin:origin]; }
    if (self.showsDice)  { [self drawDiceWithScale:scale origin:origin]; }
}

#pragma mark - Background

- (void)drawBackgroundWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    UIColor *boardColor = [self.elements colorNamed:@"ColorBoard"]
                       ?: [UIColor colorWithWhite:0.55 alpha:1.0];

    CGRect r = [self scaleRect:CGRectMake(0, 0, kBGGBoardWidth, kBGGBoardHeight)
                         scale:scale origin:origin];
    UIView *bg = [[UIView alloc] initWithFrame:r];
    bg.backgroundColor = boardColor;
    [self addSubview:bg];

    // Schema >= 5 may have a background image covering the playing field.
    UIImage *bgImage = [self.elements boardBackgroundImage];
    if (bgImage != nil)
    {
        CGFloat imageW = (6.0 * kBGGCheckerWidth + kBGGBarWidth + 6.0 * kBGGCheckerWidth) * scale;
        CGFloat imageH = (kBGGPointsHeight + kBGGIndicatorHeight + kBGGCheckerWidth
                          + kBGGIndicatorHeight + kBGGPointsHeight) * scale;
        CGFloat imageX = origin.x + kBGGOffWidth * scale;
        CGFloat imageY = origin.y + kBGGNumberHeight * scale;

        UIImageView *bgIV = [[UIImageView alloc] initWithFrame:CGRectMake(imageX, imageY, imageW, imageH)];
        bgIV.image = bgImage;
        bgIV.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:bgIV];
    }
}

#pragma mark - Number strips

// The number strips at the top and bottom use edgeColor, same as the off/bar/cube
// areas - that's what gives the board its consistent frame look.
- (void)drawNumberStripsWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    UIColor *edgeColor = [self.elements colorNamed:@"ColorEdge"]
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
    UIColor *edgeColor  = [self.elements colorNamed:@"ColorEdge"]
                       ?: [UIColor colorWithWhite:0.45 alpha:1.0];
    UIColor *boardColor = [self.elements colorNamed:@"ColorBoard"]
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
    UIColor *edgeColor  = [self.elements colorNamed:@"ColorEdge"]
                       ?: [UIColor colorWithWhite:0.45 alpha:1.0];
    UIColor *boardColor = [self.elements colorNamed:@"ColorBoard"]
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

    NSString *trayName = [NSString stringWithFormat:@"%ld/tray_light", (long)self.elements.schema];
    UIImage *tray = [UIImage imageNamed:trayName];
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
    UIColor *edgeColor  = [self.elements colorNamed:@"ColorEdge"]
                       ?: [UIColor colorWithWhite:0.45 alpha:1.0];
    UIColor *stripColor = [self.elements colorNamed:@"ColorBarCentralStripe"]
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
    BGGCheckerColor color = (checkers >= 0) ? BGGCheckerColorDark : BGGCheckerColorLight;
    NSInteger cnt = ABS(checkers);

    BGGPointShade     shade = (slot % 2 == 0) ? BGGPointShadeLight : BGGPointShadeDark;
    BGGPointDirection dir   = isTopRow ? BGGPointDirectionDown : BGGPointDirectionUp;

    UIImage *img = [self.elements pointImageForShade:shade
                                           direction:dir
                                        checkerColor:color
                                        checkerCount:cnt
                                          pointIndex:point];

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

// Stack individual checker images on the bar.
// Blue goes in the upper half, yellow in the lower half.
- (void)drawBarStack:(NSInteger)count
              isBlue:(BOOL)isBlue
         inUpperHalf:(BOOL)upper
               scale:(CGFloat)scale
              origin:(CGPoint)origin
{
    BGGCheckerColor color = isBlue ? BGGCheckerColorDark : BGGCheckerColorLight;
    UIImage *img = [self.elements barImageForCheckerColor:color checkerCount:count];
    if (img == nil) { return; }

    // Center the stack within the bar width.
    CGFloat nativeBarX     = kBGGOffWidth + 6.0 * kBGGCheckerWidth;
    CGFloat checkerNativeX = nativeBarX + (kBGGBarWidth - kBGGCheckerWidth) / 2.0;
    NSInteger visible      = MIN(count, 5);

    CGFloat nativeY = upper
        ? kBGGTopTongueY
        : kBGGBoardHeight - kBGGNumberHeight - (CGFloat)visible * kBGGCheckerWidth;

    CGFloat nativeH = (CGFloat)visible * kBGGCheckerWidth;
    CGRect frame = [self scaleRect:CGRectMake(checkerNativeX, nativeY,
                                               kBGGCheckerWidth, nativeH)
                             scale:scale origin:origin];
    UIImageView *iv = [[UIImageView alloc] initWithFrame:frame];
    iv.image = img;
    iv.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:iv];
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

// Bear-off checkers are shown edge-on: each off_dark / off_light asset is a
// flat horizontal bar (native 230x50). I keep its aspect ratio, fit the width
// to the cube area, and stack the checkers from the outside in.
- (void)drawOffStack:(NSInteger)count
              isBlue:(BOOL)isBlue
         inUpperHalf:(BOOL)upper
               scale:(CGFloat)scale
              origin:(CGPoint)origin
{
    BGGCheckerColor color = isBlue ? BGGCheckerColorDark : BGGCheckerColorLight;
    UIImage *checker = [self.elements offCheckerImageForColor:color];
    if (checker == nil) { return; }

    // Width fills the cube area; height follows the asset's aspect ratio.
    CGFloat barW = kBGGCubeWidth - 10.0;                          // small inset
    CGFloat barH = barW * (checker.size.height / checker.size.width);
    CGFloat nativeX = kBGGCubeAreaX + (kBGGCubeWidth - barW) / 2.0;

    for (NSInteger i = 0; i < count; i++)
    {
        // Upper player stacks downward from the top edge,
        // lower player upward from the bottom edge.
        CGFloat nativeY = upper
            ? kBGGNumberHeight + (CGFloat)i * barH
            : kBGGBoardHeight - kBGGNumberHeight - (CGFloat)(i + 1) * barH;

        CGRect frame = [self scaleRect:CGRectMake(nativeX, nativeY, barW, barH)
                                 scale:scale origin:origin];
        UIImageView *iv = [[UIImageView alloc] initWithFrame:frame];
        iv.image       = checker;
        iv.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:iv];
    }
}

#pragma mark - Cube

// The cube always sits in the left (off) area.
// Three positions:
//   centered (nobody owns it) → vertically centered between the two tray fields
//   top      (yellow owns it) → in the upper tray field area
//   bottom   (blue owns it)   → in the lower tray field area
- (void)drawCubeWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    if (self.boardState == nil) { return; }

    NSInteger cubeValue = self.boardState.cubeValue;
    if (cubeValue < 1) { cubeValue = 1; }

    // Find the right asset: cube1, cube2, cube4, cube8, cube16, cube32, cube64.
    // Values above 64 fall back to cube64.
    NSInteger assetValue = 1;
    for (NSInteger v = 1; v <= 64; v *= 2)
    {
        if (v <= cubeValue) { assetValue = v; }
    }
    NSString *cubeName = [NSString stringWithFormat:@"%ld/cube%ld",
                          (long)self.elements.schema, (long)assetValue];
    UIImage *cubeImage = [UIImage imageNamed:cubeName];
    if (cubeImage == nil) { return; }

    // The cube PNG is 290x290 (square). I size it to fit within the off area,
    // using checkerWidth as the reference - that's exactly the inner tray width.
    CGFloat cubeNativeW = kBGGCheckerWidth;
    CGFloat cubeNativeH = kBGGCheckerWidth;

    // The tray field sits at x = (kBGGOffWidth - kBGGCheckerWidth) / 2 = 15,
    // and is kBGGCheckerWidth (40) wide. Center the cube within that field.
    CGFloat trayFieldX = (kBGGOffWidth - kBGGCheckerWidth) / 2.0;   // 15
    CGFloat cubeNativeX = trayFieldX + (kBGGCheckerWidth - cubeNativeW) / 2.0 + 2.0;

    // Vertical position depends on cube owner.
    BGGPlayer owner = self.boardState.cubeOwner;
    CGFloat cubeNativeY;

    if (owner == BGGPlayerYellow)
    {
        // Upper tray field center.
        cubeNativeY = kBGGNumberHeight + (kBGGPointsHeight - cubeNativeH) / 2.0;
    }
    else if (owner == BGGPlayerBlue)
    {
        // Lower tray field center.
        cubeNativeY = kBGGBoardHeight - kBGGNumberHeight - kBGGPointsHeight
                      + (kBGGPointsHeight - cubeNativeH) / 2.0;
    }
    else
    {
        // Centered = nobody owns it yet.
        cubeNativeY = (kBGGBoardHeight - cubeNativeH) / 2.0;
    }

    CGRect frame = [self scaleRect:CGRectMake(cubeNativeX, cubeNativeY,
                                               cubeNativeW, cubeNativeH)
                             scale:scale origin:origin];
    UIImageView *iv = [[UIImageView alloc] initWithFrame:frame];
    iv.image = cubeImage;
    iv.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:iv];
}

#pragma mark - Dice

// Dice are shown in the center strip (indicator area) on the side of the
// player on roll. Two dice side by side, centered horizontally in their half.
- (void)drawDiceWithScale:(CGFloat)scale origin:(CGPoint)origin
{
    if (self.boardState == nil) { return; }

    NSInteger die1 = self.boardState.dice.die1;
    NSInteger die2 = self.boardState.dice.die2;
    if (die1 <= 0 || die2 <= 0) { return; }   // not yet rolled

    BGGPlayer onRoll = self.boardState.onRoll;

    // Dice color matches the player on roll.
    NSString *colorStr = (onRoll == BGGPlayerYellow) ? @"y" : @"b";

    NSString *die1Name = [NSString stringWithFormat:@"%ld/die_%@%ld",
                          (long)self.elements.schema, colorStr, (long)die1];
    NSString *die2Name = [NSString stringWithFormat:@"%ld/die_%@%ld",
                          (long)self.elements.schema, colorStr, (long)die2];

    UIImage *img1 = [UIImage imageNamed:die1Name];
    UIImage *img2 = [UIImage imageNamed:die2Name];

    // Native die size: 250x250. Scale to fit comfortably in the indicator strip.
    // I make each die slightly smaller than a checker so they fit side by side.
    CGFloat dieNativeSize = kBGGCheckerWidth * 0.9;

    // Dice sit in the center strip (between tongue tips).
    // The center strip Y: kBGGNumberHeight + kBGGPointsHeight + kBGGIndicatorHeight/2
    CGFloat centerStripMidY = kBGGNumberHeight + kBGGPointsHeight
                              + kBGGIndicatorHeight + kBGGCheckerWidth / 2.0;
    CGFloat dieNativeY = centerStripMidY - dieNativeSize / 2.0;

    // Dice sit on the side of the player on roll.
    // Blue moves from high to low points (right home board) → right half.
    // Yellow moves from low to high points (left home board) → left half.
    CGFloat halfCenterX;
    if (onRoll == BGGPlayerBlue)
    {
        halfCenterX = kBGGRightHalfX + 3.0 * kBGGCheckerWidth;
    }
    else
    {
        halfCenterX = kBGGOffWidth + 3.0 * kBGGCheckerWidth;
    }

    CGFloat gap = dieNativeSize * 0.2;
    CGFloat totalW = 2.0 * dieNativeSize + gap;
    CGFloat startX = halfCenterX - totalW / 2.0;

    CGRect frame1 = [self scaleRect:CGRectMake(startX, dieNativeY,
                                                dieNativeSize, dieNativeSize)
                              scale:scale origin:origin];
    CGRect frame2 = [self scaleRect:CGRectMake(startX + dieNativeSize + gap, dieNativeY,
                                                dieNativeSize, dieNativeSize)
                              scale:scale origin:origin];

    UIImageView *iv1 = [[UIImageView alloc] initWithFrame:frame1];
    iv1.image = img1;
    iv1.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:iv1];

    UIImageView *iv2 = [[UIImageView alloc] initWithFrame:frame2];
    iv2.image = img2;
    iv2.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:iv2];
}

#pragma mark - Point number labels

// Point numbers are a training aid - in a real game the board has no numbers.
// Toggle showsPointNumbers to switch them on or off.
- (void)addPointNumberLabel:(NSInteger)point
                     atRect:(CGRect)tongueRect
                   isTopRow:(BOOL)isTopRow
{
    UIColor *numColor = [self.elements colorNamed:@"ColorNumber"]
                     ?: [UIColor secondaryLabelColor];

    UILabel *lbl = [[UILabel alloc] init];
    lbl.text = [NSString stringWithFormat:@"%ld", (long)point];
    lbl.font = [UIFont monospacedDigitSystemFontOfSize:13.0 weight:UIFontWeightMedium];
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

@end
