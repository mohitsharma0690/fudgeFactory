//
//  GameObject.m
//  fudgeFactory
//
//  Created by Mohit Sharma on 19/01/14.
//
//

#import "GameObject.h"

@interface GameObject ()

@property (nonatomic, readwrite, assign) NSUInteger width;
@property (nonatomic, readwrite, assign) NSUInteger height;
@property (nonatomic, readwrite, assign) CGPoint startPoint;
@property (nonatomic, readwrite, assign) CGPoint endPoint;
@property (nonatomic, readwrite, strong) NSMutableDictionary *gridWalkabilityMap;

@end

@implementation GameObject

- (id)initWithBoardWidth:(int)width height:(int)height {
    if (self = [super init]) {
        _width = width;
        _height = height;
        _gridWalkabilityMap = [NSMutableDictionary dictionaryWithCapacity:_width * _height];
        // entire grid is walkable
        for (int i = 0; i < _width; i++) {
            for (int j = 0; j < _height;j++) {
                _gridWalkabilityMap[[NSValue valueWithCGPoint:CGPointMake(i, j)]] = @YES;
            }
        }
        // set start and end by default
        _startPoint = CGPointMake(0, _height - 1);
        _endPoint = CGPointMake(_width - 1, 0);
    }
    return self;
}

#pragma mark - GridWalkability 

- (BOOL)isWalkableAtBoardPoint:(CGPoint)boardPoint {
    return [self.gridWalkabilityMap[[NSValue valueWithCGPoint:boardPoint]] boolValue];
}

- (void)startSearchForPath {
    NSMutableDictionary *openSet = [NSMutableDictionary dictionary];
    NSMutableSet *closedSet = [NSMutableSet set];
    
    openSet[[NSValue valueWithCGPoint:self.startPoint]] = @(0);
    while (openSet.count) {
        NSValue *currPointValue = [self chooseNextPointToMoveToFromOpenSet:openSet];
        if (CGPointEqualToPoint(self.endPoint, currPointValue.CGPointValue)) {
            // did find end point
            return;
        }
        int currentDistance = [openSet[currPointValue] intValue];
        [openSet removeObjectForKey:currPointValue];
        if ([closedSet containsObject:currPointValue]) {
            continue;
        }
        [closedSet addObject:currPointValue];
        
        // don't color the start location
        if (currentDistance) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"didAddToClosedSet" object:currPointValue];
        }
        
        int neighbors[8][2] = { {0, -1}, {1, 0}, {0, 1}, {-1, 0}, {1, -1}, {1, 1}, {-1, 1}, {-1, -1}};
        CGPoint currentPoint = currPointValue.CGPointValue;
        for (int i = 0; i < 8; i++) {
            CGPoint neighborPoint = CGPointMake(currentPoint.x + neighbors[i][0], currentPoint.y + neighbors[i][1]);
            NSValue *neighborPointValue = [NSValue valueWithCGPoint:neighborPoint];
            if (![self isWalkableAtBoardPoint:neighborPoint]) {
                continue;
            } else if ([closedSet containsObject:neighborPointValue]) {
                continue;
            }
            int distanceForNeighbor = [openSet[neighborPointValue] intValue];
            if (distanceForNeighbor && distanceForNeighbor > currentDistance + 1) {
                continue;
            } else {
                openSet[neighborPointValue] = @(currentDistance + 1);
            }
            
        }
    }
}

- (unsigned short)distanceBetweenX1:(unsigned short)x1 y1:(unsigned short)y1 x2:(unsigned short)x2 y2:(unsigned short)y2 {
    return abs(x1 - x2) + abs(y1 - y2);
}

- (NSUInteger)distanceBetweenA:(CGPoint)a b:(CGPoint)b {
    return [self distanceBetweenX1:a.x y1:a.y x2:b.x y2:b.y];
}

- (NSValue *)chooseNextPointToMoveToFromOpenSet:(NSDictionary *)openSet {
    NSValue *nextPointValue;
    int maxDistance = INT_MAX;
    for (NSValue *pointValue in openSet) {
        int distToPoint = [openSet[pointValue] intValue];
        int distToDestination = [self distanceBetweenA:pointValue.CGPointValue b:self.endPoint];
        if ((distToPoint + distToDestination) < maxDistance) {
            maxDistance = distToPoint + distToDestination;
            nextPointValue = pointValue;
        }
    }
    return nextPointValue;
}

@end
