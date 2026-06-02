//
//  PipCountTrainingVC.m
//  BackgammonGym
//

#import "PipCountTrainingVC.h"

@implementation PipCountTrainingVC

- (BOOL)showsPointNumbers { return YES; }
- (BOOL)measureTime       { return NO;  }

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Training";
}

@end
