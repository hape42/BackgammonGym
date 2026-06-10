//
//  PipCountTrainingVC.m
//  BackgammonGym
//

#import "PipCountTrainingVC.h"

@implementation PipCountTrainingVC

- (BOOL)showsPointNumbers { return YES; }
- (BOOL)measureTime       { return NO;  }
- (NSArray<NSString *> *)requiredTags { return @[@"pipcount", @"training"]; }
- (NSString *)modeIdentifier { return @"training"; }

- (NSString *)infoText
{
    return @"Point numbers are shown on the board. Take as much time as you "
           @"like — the timer is just for your information.";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Training";
}

@end
