//
//  Tools.h
//  Kohle
//
//  Created by Peter Schneider on 12.02.26.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tools : NSObject

// Alert für nicht-implementierte Features
+ (void)showNotImplementedAlertFromViewController:(UIViewController *)viewController
                                          feature:(NSString *)featureName
                                      description:(nullable NSString *)description;

// Returns the board design string for BGGBoardView and BGGBoardCard.
// Reads BoardSchema from NSUserDefaults, defaults to schema 4.
+ (NSString *)currentBoardDesign;

@end

NS_ASSUME_NONNULL_END
