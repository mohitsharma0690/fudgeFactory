//
//  GameLayer.m
//  fudgeFactory
//
//  Created by Mohit Sharma on 19/01/14.
//
//

#import "GameLayer.h"

#import "cocos2d.h"

#import "DebugViewLayer.h"

#define kGridSpace          16
#define kTouchPriority      -1
#define kButtonHeight       80

#define kGoButtonImage              @"goButton.png"
#define kChangeDestinationImage     @"greenButton.png"
#define kChangeSourceImage          @"redButton.png"
#define kChangeWallImage            @"blackButton.png"

typedef enum {
  CHANGE_INVALID,
  CHANGE_START,
  CHANGE_END,
  CHANGE_WALL
} ChangeState;

@interface GameLayer ()

@property (nonatomic, readwrite, strong) GameController *gameController;

@property (nonatomic, readwrite, assign) int boardWidth;
@property (nonatomic, readwrite, assign) int boardHeight;
@property (nonatomic, readwrite, assign) ChangeState currentState;

@property (nonatomic, readwrite, strong) NSMutableDictionary *gridPointToSpriteMap;

@end

@implementation GameLayer

+ (CCScene *)scene {
  CCScene *scene = [CCScene node];
  // breaking all abstractions (sigh!!)
  GameController *gameController = [GameController createGame];
  GameLayer *layer = [[GameLayer alloc] initWithGameController:gameController];
  [gameController setGameLayer:layer];
  [scene addChild:layer];
  DebugViewLayer *debugViewLayer = [[DebugViewLayer alloc] initWithGameController:gameController];
  debugViewLayer.touchEnabled = NO;
  [scene addChild:debugViewLayer z:1];
  [gameController setDebugViewLayer:debugViewLayer];
  return scene;
}

- (id)initWithGameController:(GameController *)gameController {
  if (self = [super init]) {
    _gameController = gameController;
    _boardWidth = gameController.boardWidth;
    _boardHeight = gameController.boardHeight;
    _gridPointToSpriteMap = [NSMutableDictionary dictionaryWithCapacity:_boardWidth * _boardHeight];

    self.contentSize = CGSizeMake(_boardWidth * kGridSpace, _boardHeight * kGridSpace);
    [self setupGameBoard];
    [self setupTouch];
    [self setupDefaultStartPositions];
    [self setupButtons];
  }
  return self;
}

- (void)setupButtons {
  CCMenuItemImage *goButton = [CCMenuItemImage itemWithNormalImage:kGoButtonImage selectedImage:kGoButtonImage
                                                            target:self selector:@selector(didTapGoButton)];

  CCMenuItemImage *changeStartButton = [CCMenuItemImage itemWithNormalImage:kChangeSourceImage
                                                              selectedImage:kChangeSourceImage target:self
                                                                   selector:@selector(wantToChangeStartPosition)];

  CCMenuItemImage *changeDestButton = [CCMenuItemImage itemWithNormalImage:kChangeDestinationImage
                                                             selectedImage:kChangeDestinationImage
                                                                    target:self
                                                                  selector:@selector(wantToChangeEndPosition)];

  CCMenuItemImage *changeWalkability = [CCMenuItemImage itemWithNormalImage:kChangeWallImage
                                                              selectedImage:kChangeWallImage target:self
                                                                   selector:@selector(wantToChangeWallPosition)];

  CCMenu *menu = [CCMenu menuWithItems:goButton, changeStartButton, changeDestButton, changeWalkability, nil];

  // update positions
  menu.position = [self positionAtBoardPointX:self.boardWidth + 2 y:2];
  changeStartButton.position = ccpAdd(goButton.position, ccp(0, kButtonHeight));
  changeDestButton.position = ccpAdd(changeStartButton.position, ccp(0, kButtonHeight));
  changeWalkability.position = ccpAdd(changeDestButton.position, ccp(0, kButtonHeight));

  [self addChild:menu];

  CCLabelTTF *searchLabel = [CCLabelTTF labelWithString:@"Search/Reset" fontName:@"Marker Felt" fontSize:10];
  CCLabelTTF *greenLabel = [CCLabelTTF labelWithString:@"Change Start Point" fontName:@"Marker Felt" fontSize:10];
  CCLabelTTF *redLabel = [CCLabelTTF labelWithString:@"Change End Point" fontName:@"Marker Felt" fontSize:10];
  CCLabelTTF *blackLabel = [CCLabelTTF labelWithString:@"Toggle Wall" fontName:@"Marker Felt" fontSize:10];
  NSArray *labels = @[searchLabel, greenLabel, redLabel, blackLabel];
  CGPoint labelPosition = menu.position;
  for (CCLabelTTF *label in labels) {
    [self addChild:label];
    label.position = labelPosition;
    labelPosition = ccpAdd(labelPosition, ccp(0, kButtonHeight));
  }
}

#pragma mark - GameBoard

- (void)setupDefaultStartPositions {
  [self changeColorForSpriteAtBoardPoint:ccp(0, _boardHeight - 1) to:kStartColor];
  [self changeColorForSpriteAtBoardPoint:ccp(_boardWidth - 1, 0) to:kEndColor];
}

- (void)colorBoardAtX:(int)x y:(int)y withColor:(ccColor3B)color {
  CGPoint position = ccp(x, y);
  CCSprite *sprite = self.gridPointToSpriteMap[[NSValue valueWithCGPoint:position]];
  sprite.color = color;
}

- (void)setupGameBoard {
  for (int i = 0; i < self.boardWidth; i++) {
    for (int j = 0; j < self.boardHeight; j++) {
      CGPoint boardPoint = ccp(i, j);
      CCSprite *sprite = [CCSprite spriteWithFile:@"tile.png"];
      sprite.position = [self positionAtBoardPointX:i y:j];
      [self addChild:sprite];
      self.gridPointToSpriteMap[[NSValue valueWithCGPoint:boardPoint]] = sprite;
      if (![self.gameController isWalkableAtBoardPoint:boardPoint]) {
        sprite.color = kUnwalkableColor;
      }
    }
  }
  // set start and end default positions
  [(CCSprite *)self.gridPointToSpriteMap[[NSValue valueWithCGPoint:self.gameController.startPoint]] setColor:kStartColor];
  [(CCSprite *)self.gridPointToSpriteMap[[NSValue valueWithCGPoint:self.gameController.endPoint]] setColor:kEndColor];
}

- (void)resetGameBoard {
  for (int i = 0; i < self.boardWidth; i++) {
    for (int j = 0; j < self.boardHeight; j++) {
      CGPoint boardPoint = ccp(i, j);
      CCSprite *sprite = self.gridPointToSpriteMap[[NSValue valueWithCGPoint:boardPoint]];
      if ([self.gameController isWalkableAtBoardPoint:boardPoint]) {
        sprite.color = kWalkableColor;
      } else {
        sprite.color = kUnwalkableColor;
      }
    }
  }

  for (NSValue *pointValue in self.gameController.abstractGraphNodePoints) {
    [self changeColorForSpriteAtBoardPoint:pointValue.CGPointValue to:ccGRAY];

  }
  // set start and end default positions
  [(CCSprite *)self.gridPointToSpriteMap[[NSValue valueWithCGPoint:self.gameController.startPoint]] setColor:kStartColor];
  [(CCSprite *)self.gridPointToSpriteMap[[NSValue valueWithCGPoint:self.gameController.endPoint]] setColor:kEndColor];
}

- (CGPoint)positionAtBoardPointX:(int)x y:(int)y {
  return CGPointMake((x+0.5f) * kGridSpace, (y+0.5f) * kGridSpace);
}

- (CGPoint)boardPointAtViewPoint:(CGPoint)viewPoint {
  return CGPointMake(((int)viewPoint.x) / kGridSpace, ((int)viewPoint.y) / kGridSpace);
}

- (CCSprite *)spriteAtViewPoint:(CGPoint)viewPoint {
  CGPoint boardPoint = [self boardPointAtViewPoint:viewPoint];
  return self.gridPointToSpriteMap[[NSValue valueWithCGPoint:boardPoint]];
}

- (void)changeColorAtPoint:(CGPoint)viewPoint to:(ccColor3B)newColor {
  [self changeColorForSpriteAtBoardPoint:[self boardPointAtViewPoint:viewPoint] to:newColor];
}

- (void)changeColorForSpriteAtBoardPoint:(CGPoint)boardPoint to:(ccColor3B)color {
  CCSprite *sprite = self.gridPointToSpriteMap[[NSValue valueWithCGPoint:boardPoint]];
  sprite.color = color;
}

#pragma mark - Touch

- (void)setupTouch {
  [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kTouchPriority
                                                     swallowsTouches:YES];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
  CGPoint viewPoint = [self convertTouchToNodeSpace:touch];
  CGPoint boardPoint = [self boardPointAtViewPoint:viewPoint];
  if (self.currentState == CHANGE_START) {
    CGPoint currentStartPoint = [self.gameController startPoint];
    if (!CGPointEqualToPoint(currentStartPoint, boardPoint) && [self.gameController isValidStartPoint:boardPoint]) {
      [self changeColorForSpriteAtBoardPoint:boardPoint to:kStartColor];
      [self changeColorForSpriteAtBoardPoint:currentStartPoint to:kWalkableColor];
      [self.gameController didChangeStartPointTo:boardPoint];
    }
    return YES;
  } else if (self.currentState == CHANGE_END) {
    CGPoint currentEndPoint = [self.gameController endPoint];
    if (!CGPointEqualToPoint(currentEndPoint, boardPoint) && [self.gameController isValidStartPoint:boardPoint]) {
      [self changeColorForSpriteAtBoardPoint:boardPoint to:kEndColor];
      [self changeColorForSpriteAtBoardPoint:currentEndPoint to:kWalkableColor];
      [self.gameController didChangeEndPointTo:boardPoint];
    }
    return YES;
  } else if (self.currentState == CHANGE_WALL) {
    if ([self.gameController isValidWallPoint:boardPoint]) {
      [self.gameController toggleWallAtPoint:boardPoint];
      if ([self.gameController isWalkableAtBoardPoint:boardPoint]) {
        [self changeColorForSpriteAtBoardPoint:boardPoint to:kWalkableColor];
      } else {
        [self changeColorForSpriteAtBoardPoint:boardPoint to:kUnwalkableColor];
      }
    }
    return YES;
  } else {
    return NO;
  }
}

- (void)didTapGoButton {
  [self.gameController didTapGoButton];
}

- (void)wantToChangeStartPosition {
  self.currentState = CHANGE_START;
}

- (void)wantToChangeEndPosition {
  self.currentState = CHANGE_END;
}

- (void)wantToChangeWallPosition {
  self.currentState = CHANGE_WALL;
}

@end
