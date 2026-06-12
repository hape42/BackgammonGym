//
//  METTrainingVC.m
//  BackgammonGym
//

#import "METTrainingVC.h"

@implementation METTrainingVC

- (BOOL)measureTime      { return NO;  }
- (BOOL)showsHelpButtons { return YES; }
- (NSString *)modeIdentifier { return @"training"; }
- (NSInteger)activityLevelForCompletedSession { return 2; }

- (NSString *)infoText
{
    return @"Estimate from the score. Take as much time as you like — the "
           @"timer is just for your information. Optional hints are available.";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Training";
}

@end
