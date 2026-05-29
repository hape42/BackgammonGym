//
//  StartVC.h
//  BackgammonGym
//
//  Created by Peter Schneider on 28.05.26.
//

#import <UIKit/UIKit.h>

@interface StartVC : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, readwrite, retain, atomic) NSMutableArray *tileArray;

#define TILE_PIPCOUNT 1
#define TILE_MEQUIZ 2
#define TILE_COLLECTION 30
#define TILE_STATISTICS 40
#define TILE_ACHIEVMENTS 41
#define TILE_FEEDBACK 50



@end

