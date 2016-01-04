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

#import "fudgeFactory-Swift.h"

@interface GameController ()

@property (nonatomic, readwrite, strong) GameObject *gameObject;
@property (nonatomic, readwrite, weak) GameLayer *gameLayer;

// used for resetting
@property (nonatomic, readwrite, assign) BOOL didColorCellsForDebugging;
@property (nonatomic, readwrite, assign) int cellsToColor;
@property (nonatomic, readwrite, assign) BOOL didPerformSearch;

@end

@implementation GameController

static inline BOOL areColorEqual(ccColor3B a, ccColor3B b) {
  return a.r == b.r && a.g == b.g && a.b == b.b;
}

+ (GameController *)createGame {
  GameObject *gameObject = [[GameObject alloc] initWithBoardWidth:30 height:30];
  GameController *gameController = [[GameController alloc] initWithGameObject:gameObject];

  // TODO(mosharma): This should be done once we want to start the search after setting up
  // the environment. Each search would reset this later on.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                     [self importGameObjectToSwift:gameObject];
                 });

  return gameController;
}

+ (void)importGameObjectToSwift:(GameObject *)gameObject {
  Graph *graph = [[Graph alloc] init];
  [graph createGraphFromWalkabilityMap:[gameObject walkabilityMap]
                                 width:gameObject.width
                                height:gameObject.height];

  Environment *env = [[Environment alloc] init];
  World *world = [[World alloc] initWithEnv:env graph:graph];
  [world createAbstractGraph];
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(colorNodes:)
                                                 name:@"colorNodes"
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

- (void)didChangeSpriteColorAt:(CGPoint)boardPoint
                          from:(ccColor3B)oldColor
                            to:(ccColor3B)newColor {
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

- (void)colorNodes:(NSNotification *)notification {
  if (self.didColorCellsForDebugging) {
    [self resetColorNodes];
  }
  NSDictionary *userInfo = notification.userInfo;
  NSArray *colorNodes = userInfo[@"nodes"];
  for (NSValue *pointValue in colorNodes) {
    [self colorNodeAtPoint:pointValue];
  }
  self.didColorCellsForDebugging = YES;
}

- (void)resetColorNodes {
  [self.gameLayer resetGameBoard];
}

- (void)colorNodeAtPoint:(NSValue *)pointValue {
  [self.gameLayer changeColorForSpriteAtBoardPoint:pointValue.CGPointValue to:ccGRAY];
}

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
