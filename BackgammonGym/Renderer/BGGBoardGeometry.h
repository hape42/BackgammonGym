//
//  BGGBoardGeometry.h
//  BackgammonGym
//
//  All board measurements in one place.
//  I planned these numbers on paper to get the best board representation,
//  then verified them in DailyGammon where they have been working ever since.
//
//  All values are native (unscaled). The renderer applies a single zoomFactor
//  so everything scales proportionally without distortion.
//

#ifndef BGGBoardGeometry_h
#define BGGBoardGeometry_h

#import <CoreGraphics/CoreGraphics.h>

// ── Base measurements (native, unscaled) ──────────────────────────────────

static const CGFloat kBGGCheckerWidth    = 40.0;
static const CGFloat kBGGOffWidth        = 70.0;   // left edge (off checkers)
static const CGFloat kBGGBarWidth        = 40.0;   // center divider (bar)
static const CGFloat kBGGCubeWidth       = 70.0;   // right edge (cube area)
static const CGFloat kBGGPointsHeight    = 200.0;  // tongue height
static const CGFloat kBGGNumberHeight    = 30.0;   // point number strip (doubled for legibility)
static const CGFloat kBGGIndicatorHeight = 22.0;   // gap between tongue tip and center strip

// ── Derived board dimensions ───────────────────────────────────────────────
//
//  boardWidth  = offWidth + 6*checker + bar + 6*checker + cubeWidth
//              = 70 + 240 + 40 + 240 + 70 = 660
//
//  boardHeight = numberHeight + pointsHeight + indicatorHeight
//              + checkerWidth (center strip)
//              + indicatorHeight + pointsHeight + numberHeight
//              = 30 + 200 + 22 + 40 + 22 + 200 + 30 = 544

static const CGFloat kBGGBoardWidth  = 660.0;
static const CGFloat kBGGBoardHeight = 544.0;

// ── Horizontal zone offsets (from left, unscaled) ─────────────────────────

// Where the tongue area starts (after the left off strip)
static const CGFloat kBGGPointsAreaX = kBGGOffWidth;                                                              // 70

// Where the right half of tongues starts (after off + 6 checkers + bar)
static const CGFloat kBGGRightHalfX  = kBGGOffWidth + 6.0 * kBGGCheckerWidth + kBGGBarWidth;                     // 350

// Where the right cube/off strip starts
static const CGFloat kBGGCubeAreaX   = kBGGOffWidth + 6.0 * kBGGCheckerWidth + kBGGBarWidth + 6.0 * kBGGCheckerWidth;  // 590

// ── Vertical zone offsets (from top, unscaled) ────────────────────────────

// Upper tongues start right below the number strip
static const CGFloat kBGGTopTongueY    = kBGGNumberHeight;                                                         // 15

// Lower tongues start so that they end exactly above the bottom number strip
static const CGFloat kBGGBottomTongueY = kBGGBoardHeight - kBGGNumberHeight - kBGGPointsHeight;                   // 299

// ── Helper: left edge X of a tongue for a given slot (0..11) ─────────────
//
//  Slots 0..5  = left half  (points 13–18 top row, 12–7 bottom row)
//  Slots 6..11 = right half (points 19–24 top row,  6–1 bottom row)
//
static inline CGFloat BGGTongueLeftX(NSInteger slot)
{
    if (slot < 6)
    {
        return kBGGPointsAreaX + (CGFloat)slot * kBGGCheckerWidth;
    }
    return kBGGRightHalfX + (CGFloat)(slot - 6) * kBGGCheckerWidth;
}

// ── Off tray inner area (the light recess that holds borne-off checkers) ──
//
//  A real board's off tray is exactly as tall as the tongue area and holds
//  exactly 15 checkers. So the tray height equals kBGGPointsHeight and each
//  borne-off checker is kBGGPointsHeight / 15 tall.
//  There are two trays, aligned vertically with the upper and lower tongues.
//  Horizontally the tray is one checker wide, centred in the cube strip.

static const CGFloat kBGGOffTrayWidth  = kBGGCheckerWidth;                       // 40
static const CGFloat kBGGOffTrayX      = kBGGCubeAreaX + (kBGGCubeWidth - kBGGCheckerWidth) / 2.0;  // centred
static const CGFloat kBGGOffTrayHeight = kBGGPointsHeight;                       // 200, holds 15

static const CGFloat kBGGOffTopTrayY    = kBGGTopTongueY;     // aligns with upper tongues
static const CGFloat kBGGOffBottomTrayY = kBGGBottomTongueY;  // aligns with lower tongues

#endif /* BGGBoardGeometry_h */
