//
//  Tools.m
//  Kohle
//
//  Created by Peter Schneider on 12.02.26.
//

#import "Tools.h"

@implementation Tools

+ (void)showNotImplementedAlertFromViewController:(UIViewController *)viewController
                                          feature:(NSString *)featureName
                                      description:(nullable NSString *)description
{
    
    NSString *title = @"🚧 Not yet programmed";
    NSString *message = description ?: [NSString stringWithFormat:@"the function \"%@\" is still under development.", featureName];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    
    [alert addAction:okAction];
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (NSString *)currentBoardDesign
{
    NSInteger schema = [[NSUserDefaults standardUserDefaults]
                        integerForKey:@"BoardSchema"];
    if (schema < 4) { schema = 4; }
    return [NSString stringWithFormat:@"%ld", (long)schema];
}
@end
