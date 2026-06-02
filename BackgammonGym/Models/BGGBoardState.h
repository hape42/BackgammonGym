//
//  BGGBoardState.h
//  BackgammonGym
//
//  Das interne Stellungsmodell. Zentrale Drehscheibe:
//  - der Renderer liest hieraus die Steine und baut Bildnamen
//  - der PosID-Encoder liest dasselbe und erzeugt GNU/XG IDs
//  - die JSON-Stellungsdatenbank wird hierein geladen
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Die beiden Spieler, benannt nach den Steinfarben der Assets (b = blue, y = yellow).
typedef NS_ENUM(NSInteger, BGGPlayer)
{
    BGGPlayerNone   = 0,   // leerer Punkt
    BGGPlayerBlue   = 1,   // Spieler 1, intern positive Steinzahl
    BGGPlayerYellow = 2,   // Spieler 2, intern negative Steinzahl
};

/// Würfel-Wert, 0 = noch nicht gewürfelt.
typedef struct
{
    NSInteger die1;
    NSInteger die2;
} BGGDice;

/// Eine Backgammon-Stellung als reine Zahlen, unabhängig von Darstellung und ID-Format.
///
/// PUNKTE-KONVENTION:
/// - points ist 1-basiert: gültige Indizes 1...24. Index 0 wird NICHT benutzt.
/// - Ein Punkt hält IMMER nur einen Spieler (Backgammon-Regel):
///   positiv = Anzahl blaue Steine, negativ = Anzahl gelbe Steine, 0 = leer.
///   Beispiel: points[6] == 5 -> 5 blaue Steine auf Punkt 6;
///             points[6] == -3 -> 3 gelbe Steine auf Punkt 6.
///
/// GEOMETRIE (für den Renderer):
/// - Punkt 1 liegt unten rechts, 1...6 = unteres Heimfeld (rechts),
///   7...12 untere Reihe nach links, 13...24 obere Reihe von links nach rechts.
///
/// BAR und OFF:
/// - Hier können BEIDE Spieler gleichzeitig Steine haben, daher je zwei Zähler
///   (anders als bei einem Punkt). Werte sind immer >= 0, ohne Vorzeichen.
@interface BGGBoardState : NSObject

#pragma mark - Steine (Pflicht)

/// Liefert die Steinzahl auf einem Punkt (1...24). Positiv = blau, negativ = gelb, 0 = leer.
- (NSInteger)checkersOnPoint:(NSInteger)point;

/// Setzt die Steinzahl auf einem Punkt (1...24). Positiv = blau, negativ = gelb, 0 = leer.
- (void)setCheckers:(NSInteger)count onPoint:(NSInteger)point;

@property (nonatomic, assign) NSInteger barBlue;    // geschlagene blaue Steine auf der Bar
@property (nonatomic, assign) NSInteger barYellow;  // geschlagene gelbe Steine auf der Bar

@property (nonatomic, assign) NSInteger offBlue;    // rausgespielte blaue Steine
@property (nonatomic, assign) NSInteger offYellow;  // rausgespielte gelbe Steine

#pragma mark - Match-Kontext (optional, Defaults sind neutral)

@property (nonatomic, assign) BGGPlayer onRoll;     // wer am Zug ist (BGGPlayerNone, falls egal)
@property (nonatomic, assign) BGGDice dice;         // {0,0} = noch nicht gewürfelt

@property (nonatomic, assign) NSInteger cubeValue;  // 1, 2, 4, 8, ... (1 = noch nicht verdoppelt)
@property (nonatomic, assign) BGGPlayer cubeOwner;  // BGGPlayerNone = in der Mitte

@property (nonatomic, assign) NSInteger scoreBlue;
@property (nonatomic, assign) NSInteger scoreYellow;
@property (nonatomic, assign) NSInteger matchLength; // 0 = Money Game / kein Match
@property (nonatomic, assign) BOOL      isCrawford;

#pragma mark - Hilfen

/// Summe der Steine eines Spielers (Punkte + Bar + Off). Sollte für eine
/// gültige Standard-Stellung 15 ergeben.
- (NSInteger)totalCheckersForPlayer:(BGGPlayer)player;

/// Prüft, ob beide Spieler genau 15 Steine haben.
- (BOOL)isValidCheckerCount;

/// Returns the total pip count for the given player.
/// Blue:   sum of (point × checkers) for all positive points, plus bar × 25.
/// Yellow: sum of ((25 - point) × |checkers|) for all negative points, plus bar × 25.
- (NSInteger)pipCountForPlayer:(BGGPlayer)player;

/// Leeres Brett (alle Punkte 0, Bar/Off 0, Cube 1, neutraler Kontext).
+ (instancetype)emptyBoard;

/// Die Standard-Startstellung.
+ (instancetype)startingPosition;

@end

NS_ASSUME_NONNULL_END
