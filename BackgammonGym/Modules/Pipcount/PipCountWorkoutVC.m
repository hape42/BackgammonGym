//
//  PipCountWorkoutVC.m
//  BackgammonGym
//

#import "PipCountWorkoutVC.h"
#import "BGGLocalization.h"

@implementation PipCountWorkoutVC

- (BOOL)showsPointNumbers { return NO;  }
- (BOOL)measureTime       { return YES; }
- (NSArray<NSString *> *)requiredTags { return @[@"pipcount", @"training"]; }
- (NSString *)modeIdentifier { return @"workout"; }
- (NSInteger)activityLevelForCompletedSession { return 3; }

- (NSString *)infoText
{
    return BGGLocalizedString(@"No numbers on the board, just like at a real table. The timer "
           @"runs live so you train under tournament conditions.");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Workout";   // brand term, stays English
}

@end
