//
//  BGGBoardView.h
//  BackgammonGym
//
//  Datengetriebene Board-View: bekommt ein BGGBoardState (reine Zahlen)
//  und ein Board-Design (z.B. @"4"), platziert daraus die fertigen PNGs.
//
//  Kein DailyGammon-HTML, keine Move-Logik, keine Würfel-Pflicht.
//  Nur Anzeige.
//

#import <UIKit/UIKit.h>

@class BGGBoardState;

NS_ASSUME_NONNULL_BEGIN

@interface BGGBoardView : UIView

//  Die anzuzeigende Stellung. Nach dem Setzen wird neu gezeichnet.
@property (nonatomic, strong, nullable) BGGBoardState *boardState;

//  Welches Board-Design (entspricht dem Asset-Namespace-Ordner,
//  z.B. @"4" lädt Bilder als "4/pt_lt_down_b7").
//  Default: @"4".
@property (nonatomic, copy) NSString *boardDesign;

//  Zungen-Nummern (1–24) am Rand anzeigen? Im echten Spiel stehen
//  keine Nummern am Brett – daher abschaltbar (Trainings-Feature).
//  Default: NO.
@property (nonatomic, assign) BOOL showsPointNumbers;

//  Convenience: setzt Stellung und Design in einem Rutsch.
- (void)configureWithBoardState:(nullable BGGBoardState *)state
                          design:(NSString *)design;

@end

NS_ASSUME_NONNULL_END
