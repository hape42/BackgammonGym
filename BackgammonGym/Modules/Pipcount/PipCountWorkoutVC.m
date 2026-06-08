//
//  PipCountWorkoutVC.m
//  BackgammonGym
//

#import "PipCountWorkoutVC.h"

@implementation PipCountWorkoutVC

- (BOOL)showsPointNumbers { return NO;  }
- (BOOL)measureTime       { return YES; }
- (NSArray<NSString *> *)requiredTags { return @[@"pipcount", @"training"]; }

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Workout";
}

@end
