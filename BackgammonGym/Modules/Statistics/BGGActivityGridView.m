//
//  BGGActivityGridView.m
//  BackgammonGym
//

#import "BGGActivityGridView.h"
#import "CoreDataManager.h"

// Grid geometry.
static const NSInteger kBGGWeeks      = 53;   // columns
static const NSInteger kBGGDays       = 7;    // rows (Sun..Sat)
static const CGFloat   kBGGCellGap    = 3.0;  // gap between cells
static const CGFloat   kBGGTopLabels  = 18.0; // space for month labels
static const CGFloat   kBGGLeftLabels = 30.0; // space for weekday labels
static const CGFloat   kBGGLegendH    = 26.0; // space for the legend row

@interface BGGActivityGridView ()

// Maps "yyyy-MM-dd" -> highest level (NSNumber 1..3).
@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *levels;

// The date shown in the top-left cell (the Sunday of the leftmost column).
@property (nonatomic, strong) NSDate *gridStartDate;

@property (nonatomic, strong) NSDateFormatter *dayKeyFormatter;
@property (nonatomic, strong) NSCalendar       *calendar;

@end

@implementation BGGActivityGridView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];

        _calendar = [NSCalendar currentCalendar];

        _dayKeyFormatter = [[NSDateFormatter alloc] init];
        _dayKeyFormatter.locale     = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dayKeyFormatter.dateFormat = @"yyyy-MM-dd";

        _levels = @{};
        [self computeGridStart];
    }
    return self;
}

#pragma mark - Data

- (void)reload
{
    // Pull a bit more than 12 months so the leftmost partial week is covered.
    self.levels = [[CoreDataManager sharedManager] activityLevelsForLastDays:371];
    [self computeGridStart];
    [self setNeedsDisplay];
}

// The grid ends with today in the last column. The top cell of each column is
// a Sunday, so the start date is the Sunday (kBGGWeeks-1) weeks before the
// Sunday of the current week.
- (void)computeGridStart
{
    NSDate *today = [self.calendar startOfDayForDate:[NSDate date]];

    // weekday: 1 = Sunday ... 7 = Saturday.
    NSInteger weekday = [self.calendar component:NSCalendarUnitWeekday fromDate:today];
    NSInteger daysSinceSunday = weekday - 1;

    NSDateComponents *toSunday = [[NSDateComponents alloc] init];
    toSunday.day = -daysSinceSunday;
    NSDate *thisWeekSunday = [self.calendar dateByAddingComponents:toSunday
                                                            toDate:today
                                                           options:0];

    NSDateComponents *back = [[NSDateComponents alloc] init];
    back.day = -(kBGGWeeks - 1) * 7;
    self.gridStartDate = [self.calendar dateByAddingComponents:back
                                                        toDate:thisWeekSunday
                                                       options:0];
}

#pragma mark - Colours

// The four-level red scheme from the project doc.
- (UIColor *)colorForLevel:(NSInteger)level
{
    switch (level)
    {
        case 1:  return [self colorFromHex:0xF0997B];   // opened
        case 2:  return [self colorFromHex:0xC0392B];   // training
        case 3:  return [self colorFromHex:0x7A1414];   // workout
        default: return [self colorFromHex:0xE9E7E0];   // not used
    }
}

- (UIColor *)colorFromHex:(NSUInteger)hex
{
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8)  & 0xFF) / 255.0
                            blue:( hex        & 0xFF) / 255.0
                           alpha:1.0];
}

#pragma mark - Layout

// Cell size derives from the available width: (width - left labels) split into
// 53 columns including gaps.
- (CGFloat)cellSizeForWidth:(CGFloat)width
{
    CGFloat usable = width - kBGGLeftLabels;
    CGFloat cell = (usable - (kBGGWeeks - 1) * kBGGCellGap) / kBGGWeeks;
    if (cell < 1.0) { cell = 1.0; }
    return floor(cell);
}

- (CGSize)intrinsicContentSize
{
    CGFloat width = self.bounds.size.width;
    if (width <= 0) { width = UIViewNoIntrinsicMetric; }

    CGFloat cell = [self cellSizeForWidth:(width > 0 ? width : 320.0)];
    CGFloat gridHeight = kBGGDays * cell + (kBGGDays - 1) * kBGGCellGap;
    CGFloat total = kBGGTopLabels + gridHeight + kBGGLegendH;

    return CGSizeMake(UIViewNoIntrinsicMetric, ceil(total));
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    // Width drives the cell size and therefore the height.
    [self invalidateIntrinsicContentSize];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    CGFloat width = self.bounds.size.width;
    CGFloat cell  = [self cellSizeForWidth:width];
    CGFloat step  = cell + kBGGCellGap;

    CGContextRef ctx = UIGraphicsGetCurrentContext();

    UIColor *labelColor = [UIColor secondaryLabelColor];
    UIFont  *labelFont  = [UIFont systemFontOfSize:10.0 weight:UIFontWeightRegular];
    NSDictionary *labelAttrs = @{
        NSFontAttributeName:            labelFont,
        NSForegroundColorAttributeName: labelColor,
    };

    NSInteger previousMonth = -1;

    for (NSInteger col = 0; col < kBGGWeeks; col++)
    {
        for (NSInteger row = 0; row < kBGGDays; row++)
        {
            NSInteger dayOffset = col * 7 + row;
            NSDateComponents *add = [[NSDateComponents alloc] init];
            add.day = dayOffset;
            NSDate *cellDate = [self.calendar dateByAddingComponents:add
                                                              toDate:self.gridStartDate
                                                             options:0];

            // Don't draw cells in the future (after today).
            if ([cellDate compare:[NSDate date]] == NSOrderedDescending)
            {
                continue;
            }

            NSString *key   = [self.dayKeyFormatter stringFromDate:cellDate];
            NSNumber *lvlNum = self.levels[key];
            NSInteger level = lvlNum ? lvlNum.integerValue : 0;

            CGFloat x = kBGGLeftLabels + col * step;
            CGFloat y = kBGGTopLabels  + row * step;

            CGRect cellRect = CGRectMake(x, y, cell, cell);
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:cellRect
                                                           cornerRadius:2.0];
            [[self colorForLevel:level] setFill];
            [path fill];

            // Month label above the column whenever the month changes on the
            // first (top) row of that column.
            if (row == 0)
            {
                NSInteger month = [self.calendar component:NSCalendarUnitMonth
                                                  fromDate:cellDate];
                if (month != previousMonth)
                {
                    previousMonth = month;
                    NSString *name = [self shortMonthName:month];
                    [name drawAtPoint:CGPointMake(x, 2.0) withAttributes:labelAttrs];
                }
            }
        }
    }

    // Weekday labels on the left: Mon, Wed, Fri (rows 1, 3, 5).
    NSArray<NSString *> *weekdayLabels = @[@"", @"Mon", @"", @"Wed", @"", @"Fri", @""];
    for (NSInteger row = 0; row < kBGGDays; row++)
    {
        NSString *wl = weekdayLabels[row];
        if (wl.length == 0) { continue; }
        CGFloat y = kBGGTopLabels + row * step + (cell - labelFont.lineHeight) / 2.0;
        [wl drawAtPoint:CGPointMake(0, y) withAttributes:labelAttrs];
    }

    // Legend along the bottom.
    [self drawLegendInContext:ctx cell:cell labelAttrs:labelAttrs];
}

- (void)drawLegendInContext:(CGContextRef)ctx
                       cell:(CGFloat)cell
                 labelAttrs:(NSDictionary *)labelAttrs
{
    CGFloat width = self.bounds.size.width;
    CGFloat y     = self.bounds.size.height - kBGGLegendH + 6.0;
    CGFloat sw    = 12.0;   // legend swatch size
    CGFloat gap   = 5.0;

    NSArray<NSString *> *titles = @[@"Not used", @"Opened", @"Training", @"Workout"];

    // Measure total width to right-align the legend (like GitHub).
    CGFloat totalW = 0;
    NSMutableArray<NSNumber *> *textWidths = [NSMutableArray array];
    for (NSString *t in titles)
    {
        CGSize ts = [t sizeWithAttributes:labelAttrs];
        [textWidths addObject:@(ts.width)];
        totalW += sw + gap + ts.width + 12.0;
    }

    CGFloat x = width - totalW;
    if (x < kBGGLeftLabels) { x = kBGGLeftLabels; }

    for (NSInteger i = 0; i < (NSInteger)titles.count; i++)
    {
        CGRect swatch = CGRectMake(x, y, sw, sw);
        UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:swatch cornerRadius:2.0];
        [[self colorForLevel:i] setFill];
        [p fill];
        x += sw + gap;

        CGFloat tw = textWidths[i].doubleValue;
        CGFloat ty = y + (sw - [labelAttrs[NSFontAttributeName] lineHeight]) / 2.0;
        [titles[i] drawAtPoint:CGPointMake(x, ty) withAttributes:labelAttrs];
        x += tw + 12.0;
    }
}

#pragma mark - Helpers

- (NSString *)shortMonthName:(NSInteger)month
{
    static NSArray<NSString *> *names = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        names = @[@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun",
                  @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"];
    });
    if (month < 1 || month > 12) { return @""; }
    return names[month - 1];
}

@end
