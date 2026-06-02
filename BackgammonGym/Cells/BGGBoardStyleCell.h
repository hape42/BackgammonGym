//
//  BGGBoardStyleCell.h
//  BackgammonGym
//
//  Table view cell for the board style picker in SettingsVC.
//  Shows a board preview image, the style name and the designer.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BGGBoardStyleCell : UITableViewCell

- (void)configureWithSchema:(NSInteger)schema
                       name:(NSString *)name
                   designer:(NSString *)designer
                 isSelected:(BOOL)isSelected;

@end

NS_ASSUME_NONNULL_END
