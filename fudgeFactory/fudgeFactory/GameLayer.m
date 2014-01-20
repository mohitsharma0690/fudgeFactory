//
//  GameLayer.m
//  fudgeFactory
//
//  Created by Mohit Sharma on 19/01/14.
//
//

#import "GameLayer.h"

#import "cocos2d.h"

#define kGridSpace          16
#define kTouchPriority      -1
#define kButtonHeight       80

#define kGoButtonImage              @"goButton.png"
#define kChangeDestinationImage     @"greenButton.png"
#define kChangeSourceImage          @"redButton.png"
#define kChangeWallImage            @"blackButton.png"

@interface GameLayer ()

@property (nonatomic, readwrite, strong) GameController *gameController;

@property (nonatomic, readwrite, assign) int boardWidth;
@property (nonatomic, readwrite, assign) int boardHeight;
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
                                                               selectedImage:kChangeDestinationImage target:self
                                                                    selector:@selector(wantToChangeDestinationPosition)];
    
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
}

#pragma mark - GameBoard

- (void)setupDefaultStartPositions {
    [self changeColorAtBoardPoint:ccp(0, _boardHeight - 1) to:kStartColor];
    [self changeColorAtBoardPoint:ccp(_boardWidth - 1, 0) to:kEndColor];
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

- (void)scaleBoardSpriteToFitNode {
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
    [self changeColorAtBoardPoint:[self boardPointAtViewPoint:viewPoint] to:newColor];
}

- (void)changeColorAtBoardPoint:(CGPoint)boardPoint to:(ccColor3B)newColor {
    CCSprite *sprite = self.gridPointToSpriteMap[[NSValue valueWithCGPoint:boardPoint]];
    ccColor3B oldColor = sprite.color;
    sprite.color = newColor;
    [self.gameController didChangeSpriteColorAt:boardPoint from:oldColor to:newColor];
}

- (void)changeColorForSpriteAtBoardPoint:(CGPoint)boardPoint to:(ccColor3B)color {
    CCSprite *sprite = self.gridPointToSpriteMap[[NSValue valueWithCGPoint:boardPoint]];
    if (sprite) {
        sprite.color = color;
    } else {
        NSLog(@"ERROR");
    }
}

#pragma mark - Touch

- (void)setupTouch {
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kTouchPriority
                                                       swallowsTouches:YES];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    return YES;
}

- (void)didTapGoButton {
    [self.gameController didTapGoButton];
}

- (void)wantToChangeSourcePosition {
    
}

- (void)wantToChangeDestinationPosition {
    
}

- (void)wantToChangeWallPosition {
    
}

@end
