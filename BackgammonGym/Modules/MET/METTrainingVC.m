//
//  METTrainingVC.m
//  BackgammonGym
//

#import "METTrainingVC.h"
#import "BGGLocalization.h"

@implementation METTrainingVC

- (BOOL)measureTime      { return NO;  }
- (BOOL)showsHelpButtons { return YES; }
- (NSString *)modeIdentifier { return @"training"; }
- (NSInteger)activityLevelForCompletedSession { return 2; }

- (NSString *)infoText
{
    return BGGLocalizedString(@"Estimate from the score. Take as much time as you like — your "
           @"time is shown afterwards, just for your information. Optional hints are available.");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Training";
}

@end
