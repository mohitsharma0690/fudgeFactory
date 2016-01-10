//
//  DebugViewLayer.h
//  fudgeFactory
//
//  Created by Mohit Sharma on 10/01/16.
//
//

#import "CCLayer.h"

@class GameController;

@interface DebugViewLayer : CCLayer

- (instancetype)initWithGameController:(GameController *)gameController;

#pragma mark - Lines

- (void)drawLinesFrom:(NSArray *)fromPoints to:(NSArray *)toPoints;
- (void)clearLines;

@end
