//
//  GameController.m
//  fudgeFactory
//
//  Created by Mohit Sharma on 19/01/14.
//
//

#import "GameController.h"

#import "GameLayer.h"
#import "GameObject.h"

@interface GameController ()

@property (nonatomic, readwrite, strong) GameObject *gameObject;
@property (nonatomic, readwrite, weak) GameLayer *gameLayer;

// used for resetting
@property (nonatomic, readwrite, assign) int cellsToColor;
@property (nonatomic, readwrite, assign) BOOL didPerformSearch;

@end

@implementation GameController

static inline BOOL areColorEqual(ccColor3B a, ccColor3B b) {
	return a.r == b.r && a.g == b.g && a.b == b.b;
}

+ (GameController *)createGame {
    GameObject *gameObject = [[GameObject alloc] initWithBoardWidth:25 height:20];
    GameController *gameController = [[GameController alloc] initWithGameObject:gameObject];
    return gameController;
}

- (id)initWithGameObject:(GameObject *)gameObject {
    if (self = [super init]) {
      _gameObject = gameObject;
      [[NSNotificationCenter defaultCenter] addObserver:self 
                                               selector:@selector(didAddPointToClosedSet:)
                                                   name:@"didAddToClosedSet"
                                                 object:nil];

      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(didFindPath:)
                                                   name:@"didFindPath"
                                                 object:nil];
    }
    return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setGameLayer:(GameLayer *)gameLayer {
    _gameLayer = gameLayer;
}

#pragma mark - Game Config
- (NSUInteger)boardWidth {
    return self.gameObject.width;
}

- (NSUInteger)boardHeight {
    return self.gameObject.height;
}

#pragma mark - State

- (CGPoint)startPoint {
    return self.gameObject.startPoint;
}

- (CGPoint)endPoint {
    return self.gameObject.endPoint;
}

- (BOOL)isValidStartPoint:(CGPoint)boardStartPoint {
    return [self.gameObject isValidStartPoint:boardStartPoint];
}

- (BOOL)isValidEndPoint:(CGPoint)boardEndPoint {
    return [self.gameObject isValidEndPoint:boardEndPoint];
}

- (BOOL)isValidWallPoint:(CGPoint)boardWallPoint {
    return [self.gameObject isValidWallAtPoint:boardWallPoint];
}

- (void)didChangeStartPointTo:(CGPoint)startPoint {
    return [self.gameObject didChangeStartPointTo:startPoint];
}

- (void)didChangeEndPointTo:(CGPoint)endPoint {
    return [self.gameObject didChangeEndPointTo:endPoint];
}

- (void)toggleWallAtPoint:(CGPoint)wallPoint {
    return [self.gameObject toggleWallAtPoint:wallPoint];
}

- (BOOL)isWalkableAtBoardPoint:(CGPoint)boardPoint {
    return [self.gameObject isWalkableAtBoardPoint:boardPoint];
}

- (void)didChangeSpriteColorAt:(CGPoint)boardPoint from:(ccColor3B)oldColor to:(ccColor3B)newColor {
}

#pragma mark - Touch Callbacks

- (void)didTapGoButton {
    if (self.cellsToColor == 0 && !self.didPerformSearch) {
        [self.gameObject startSearchForPath];
    } else if (self.cellsToColor == 0 && self.didPerformSearch) {
        [self.gameLayer resetGameBoard];
        delay = 1.0f;
        self.didPerformSearch = NO;
    }
}

#pragma mark - Notifications
static float delay = 1;

- (void)didFindPath:(NSNotification *)notification {
  NSArray *path = notification.object;
  int startIndex = 0, endIndex = path.count - 1;
  int index = 0;
  for (NSValue *pointValue in path) {
    if (index != startIndex && index != endIndex) {
      [self performSelector:@selector(didReachPathAtPoint:)
                 withObject:pointValue
                 afterDelay:delay];
      delay += 0.1f;
      self.cellsToColor += 1;
    }
    index++;
  }
}

- (void)didReachPathAtPoint:(NSValue *)pointValue {
  [self.gameLayer changeColorForSpriteAtBoardPoint:pointValue.CGPointValue to:ccYELLOW];
  self.cellsToColor -= 1;
}

- (void)didAddPointToClosedSet:(NSNotification *)notification {
    NSValue *pointValue = notification.object;
    
    [self performSelector:@selector(didReachSpriteAtBoardPoint:)
               withObject:pointValue
               afterDelay:delay];
    delay += 0.3f;
    self.cellsToColor += 1;
    self.didPerformSearch = YES;
}

- (void)didReachSpriteAtBoardPoint:(NSValue *)pointValue {
    [self.gameLayer changeColorForSpriteAtBoardPoint:pointValue.CGPointValue to:ccORANGE];
    self.cellsToColor -= 1;
}

@end
