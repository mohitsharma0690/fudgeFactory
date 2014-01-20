//
//  GameObject.h
//  fudgeFactory
//
//  Created by Mohit Sharma on 19/01/14.
//
//

#import <Foundation/Foundation.h>

@interface GameObject : NSObject

@property (nonatomic, readonly, assign) NSUInteger width;
@property (nonatomic, readonly, assign) NSUInteger height;
@property (nonatomic, readonly, assign) CGPoint startPoint;
@property (nonatomic, readonly, assign) CGPoint endPoint;

- (id)initWithBoardWidth:(int)width height:(int)height;

- (BOOL)isWalkableAtBoardPoint:(CGPoint)boardPoint;

- (void)startSearchForPath;

@end
