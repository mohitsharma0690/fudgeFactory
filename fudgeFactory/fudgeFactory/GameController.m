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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddPointToClosedSet:)
                                                     name:@"didAddToClosedSet" object:nil];
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

- (BOOL)isWalkableAtBoardPoint:(CGPoint)boardPoint {
    return [self.gameObject isWalkableAtBoardPoint:boardPoint];
}

- (void)didChangeSpriteColorAt:(CGPoint)boardPoint from:(ccColor3B)oldColor to:(ccColor3B)newColor {
}

#pragma mark - Touch Callbacks

- (void)didTapGoButton {
    [self.gameObject startSearchForPath];
}

#pragma mark - Notifications
static float delay = 1;
- (void)didAddPointToClosedSet:(NSNotification *)notification {
    NSValue *pointValue = notification.object;
    
    [self performSelector:@selector(didReachSpriteAtBoardPoint:) withObject:pointValue afterDelay:delay];
    delay += 0.3f;
}

- (void)didReachSpriteAtBoardPoint:(NSValue *)pointValue {
    [self.gameLayer changeColorForSpriteAtBoardPoint:pointValue.CGPointValue to:ccORANGE];
}

@end
