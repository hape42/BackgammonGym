//
//  UIViewController+BGGHomeButton.m
//  BackgammonGym
//

#import "UIViewController+BGGHomeButton.h"

@implementation UIViewController (BGGHomeButton)

- (void)installHomeButton
{
    UIImage *icon = [UIImage systemImageNamed:@"house"];
    UIBarButtonItem *homeButton = [[UIBarButtonItem alloc]
                                   initWithImage:icon
                                           style:UIBarButtonItemStylePlain
                                          target:self
                                          action:@selector(bgg_homeTapped)];
    homeButton.tintColor = [UIColor colorNamed:@"AccentColor"];
    self.navigationItem.leftBarButtonItem  = homeButton;
    self.navigationItem.hidesBackButton    = YES;
}

- (void)bgg_homeTapped
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
