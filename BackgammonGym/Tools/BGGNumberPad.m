//
//  BGGNumberPad.m
//  BackgammonGym
//

#import "BGGNumberPad.h"

// Tag offsets so one action method can serve every key.
static const NSInteger kDigitTagBase = 100;   // 100…109 → digits 0…9
static const NSInteger kDeleteTag    = 200;
static const NSInteger kOKTag        = 201;

@interface BGGNumberPad ()
@property (nonatomic, strong) NSMutableArray<UIButton *> *keys;
@end

@implementation BGGNumberPad

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _okColor = [UIColor colorNamed:@"AccentColor"];
        _enabled = YES;
        [self buildKeys];
    }
    return self;
}

#pragma mark - Build

- (void)buildKeys
{
    self.keys = [NSMutableArray array];

    // Four rows: 1 2 3 / 4 5 6 / 7 8 9 / delete 0 OK.
    NSArray<NSArray<NSNumber *> *> *rows = @[
        @[@1, @2, @3],
        @[@4, @5, @6],
        @[@7, @8, @9],
        @[@(kDeleteTag), @0, @(kOKTag)],
    ];

    UIStackView *column = [[UIStackView alloc] init];
    column.axis         = UILayoutConstraintAxisVertical;
    column.spacing      = 8.0;
    column.distribution = UIStackViewDistributionFillEqually;
    column.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:column];

    for (NSArray<NSNumber *> *row in rows)
    {
        UIStackView *rowStack = [[UIStackView alloc] init];
        rowStack.axis         = UILayoutConstraintAxisHorizontal;
        rowStack.spacing      = 8.0;
        rowStack.distribution = UIStackViewDistributionFillEqually;

        for (NSNumber *item in row)
        {
            [rowStack addArrangedSubview:[self keyForItem:item.integerValue]];
        }
        [column addArrangedSubview:rowStack];
    }

    [NSLayoutConstraint activateConstraints:@[
        [column.topAnchor      constraintEqualToAnchor:self.topAnchor],
        [column.leadingAnchor  constraintEqualToAnchor:self.leadingAnchor],
        [column.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [column.bottomAnchor   constraintEqualToAnchor:self.bottomAnchor],
    ]];
}

- (UIButton *)keyForItem:(NSInteger)item
{
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.layer.cornerRadius  = 10.0;
    b.layer.cornerCurve   = kCACornerCurveContinuous;
    b.titleLabel.font     = [UIFont systemFontOfSize:24.0 weight:UIFontWeightMedium];

    if (item == kDeleteTag)
    {
        b.tag = kDeleteTag;
        [b setImage:[UIImage systemImageNamed:@"delete.left"] forState:UIControlStateNormal];
        b.tintColor       = [UIColor labelColor];
        b.backgroundColor = [UIColor secondarySystemBackgroundColor];
        [b addTarget:self action:@selector(deleteTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    else if (item == kOKTag)
    {
        b.tag = kOKTag;
        UIImage *check = [UIImage systemImageNamed:@"checkmark"];
        [b setImage:check forState:UIControlStateNormal];
        b.tintColor       = [UIColor whiteColor];
        b.backgroundColor = self.okColor;
        [b addTarget:self action:@selector(okTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        b.tag = kDigitTagBase + item;   // 0…9
        [b setTitle:[NSString stringWithFormat:@"%ld", (long)item] forState:UIControlStateNormal];
        [b setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
        b.backgroundColor = [UIColor secondarySystemBackgroundColor];
        [b addTarget:self action:@selector(digitTapped:) forControlEvents:UIControlEventTouchUpInside];
    }

    [self.keys addObject:b];
    return b;
}

#pragma mark - Actions

- (void)digitTapped:(UIButton *)sender
{
    if (!self.enabled) { return; }
    NSInteger digit = sender.tag - kDigitTagBase;
    [self.delegate numberPad:self didTapDigit:digit];
}

- (void)deleteTapped
{
    if (!self.enabled) { return; }
    [self.delegate numberPadDidTapDelete:self];
}

- (void)okTapped
{
    if (!self.enabled) { return; }
    [self.delegate numberPadDidTapOK:self];
}

#pragma mark - Enabled

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    for (UIButton *b in self.keys)
    {
        b.enabled = enabled;
        b.alpha   = enabled ? 1.0 : 0.4;
    }
}

- (void)setOkColor:(UIColor *)okColor
{
    _okColor = okColor;
    for (UIButton *b in self.keys)
    {
        if (b.tag == kOKTag) { b.backgroundColor = okColor; }
    }
}

@end
