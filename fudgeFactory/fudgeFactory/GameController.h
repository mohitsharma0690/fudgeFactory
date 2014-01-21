//
//  GameController.h
//  fudgeFactory
//
//  Created by Mohit Sharma on 19/01/14.
//
//

#import <Foundation/Foundation.h>

#import "cocos2d.h"

#define kStartColor         (ccColor3B){255, 0, 0}
#define kEndColor           (ccColor3B){0, 255, 0}
#define kWalkableColor      (ccColor3B){255, 255, 255}
#define kUnwalkableColor    (ccColor3B){0, 0, 0}

@class GameLayer;
@class GameObject;

@interface GameController : NSObject

+ (GameController *)createGame;

- (id)initWithGameObject:(GameObject *)gameObject;

- (void)setGameLayer:(GameLayer *)gameLayer;

- (NSUInteger)boardWidth;
- (NSUInteger)boardHeight;

- (CGPoint)startPoint;
- (CGPoint)endPoint;

- (BOOL)isValidStartPoint:(CGPoint)boardStartPoint;
- (BOOL)isValidEndPoint:(CGPoint)boardEndPoint;
- (BOOL)isValidWallPoint:(CGPoint)boardWallPoint;
- (void)didChangeStartPointTo:(CGPoint)startPoint;
- (void)didChangeEndPointTo:(CGPoint)endPoint;
- (void)toggleWallAtPoint:(CGPoint)wallPoint;

- (BOOL)isWalkableAtBoardPoint:(CGPoint)boardPoint;

#pragma mark - StateChange

- (void)didChangeSpriteColorAt:(CGPoint)boardPoint from:(ccColor3B)oldColor to:(ccColor3B)newColor;

#pragma mark - Touch Callbacks
- (void)didTapGoButton;

@end
