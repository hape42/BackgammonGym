//
//  METWorkoutVC.m
//  BackgammonGym
//

#import "METWorkoutVC.h"

@implementation METWorkoutVC

- (BOOL)measureTime      { return YES; }
- (BOOL)showsHelpButtons { return NO;  }
- (NSString *)modeIdentifier { return @"workout"; }
- (NSInteger)activityLevelForCompletedSession { return 3; }

- (NSString *)infoText
{
    return @"No hints, just like at a real table. The timer runs live so you "
           @"train under tournament conditions.";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Workout";
}

@end
