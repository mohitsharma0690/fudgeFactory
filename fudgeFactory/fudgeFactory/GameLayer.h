//
//  GameLayer.h
//  fudgeFactory
//
//  Created by Mohit Sharma on 19/01/14.
//
//

#import "CCLayer.h"

#import "GameController.h"

@class CCScene;

@interface GameLayer : CCLayer

+ (CCScene *)scene;

- (id)initWithGameController:(GameController *)gameController;

- (void)changeColorForSpriteAtBoardPoint:(CGPoint)boardPoint to:(ccColor3B)color;

- (void)resetGameBoard;

@end
