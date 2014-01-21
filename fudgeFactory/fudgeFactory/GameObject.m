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
            if (![self canMoveToPoint:neighborPoint from:currentPoint]) {
                continue;
            } else if ([closedSet containsObject:neighborPointValue]) {
                continue;
            }
            int distanceForNeighbor = [openSet[neighborPointValue] intValue];
            // use 1 as movement length for all neighbors
            int distanceToNeighborFromCurrentPoint = 1;
            if (distanceForNeighbor && distanceForNeighbor >= currentDistance + distanceToNeighborFromCurrentPoint) {
                continue;
            } else {
                openSet[neighborPointValue] = @(currentDistance + distanceToNeighborFromCurrentPoint);
            }
        }
    }
}

- (BOOL)canMoveToPoint:(CGPoint)neighborPoint from:(CGPoint)currentPoint {
    if ([self isWalkableAtBoardPoint:neighborPoint]) {
        int vx = neighborPoint.x - currentPoint.x;
        int vy = neighborPoint.y - currentPoint.y;
        if (vx && vy) {
            // diagnol move
            return ([self isWalkableAtBoardPoint:CGPointMake(currentPoint.x + vx, currentPoint.y)] &&
                    [self isWalkableAtBoardPoint:CGPointMake(currentPoint.x, currentPoint.y + vy)]);
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

// heuristic distance
- (int)distanceBetweenX1:(int)x1 y1:(int)y1 x2:(int)x2 y2:(int)y2 {
    return abs(x1 - x2) + abs(y1 - y2);
}

// heuristic distance
- (NSUInteger)distanceBetweenA:(CGPoint)a b:(CGPoint)b {
    return [self distanceBetweenX1:a.x y1:a.y x2:b.x y2:b.y];
}

- (NSValue *)chooseNextPointToMoveToFromOpenSet:(NSDictionary *)openSet {
    NSValue *nextPointValue;
    int minDistance = INT_MAX;
    for (NSValue *pointValue in openSet) {
        int distToPoint = [openSet[pointValue] intValue];
        int distToDestination = [self distanceBetweenA:pointValue.CGPointValue b:self.endPoint];
        if ((distToPoint + distToDestination) < minDistance) {
            minDistance = distToPoint + distToDestination;
            nextPointValue = pointValue;
        }
    }
    return nextPointValue;
}

#pragma mark - State

- (BOOL)isValidStartPoint:(CGPoint)startPoint {
    if (self.gridWalkabilityMap[[NSValue valueWithCGPoint:startPoint]] != nil) {
        // cannot have start point as end point
        return !CGPointEqualToPoint(self.endPoint, startPoint);
    } else {
        return NO;
    }
}

- (BOOL)isValidEndPoint:(CGPoint)endPoint {
    if (self.gridWalkabilityMap[[NSValue valueWithCGPoint:endPoint]] != nil) {
        // cannot have start point as end point
        return !CGPointEqualToPoint(self.startPoint, endPoint);
    } else {
        return NO;
    }
}

- (BOOL)isValidWallAtPoint:(CGPoint)wallPoint {
    if (!CGPointEqualToPoint(self.startPoint, wallPoint) && !CGPointEqualToPoint(self.endPoint, wallPoint)) {
        return self.gridWalkabilityMap[[NSValue valueWithCGPoint:wallPoint]] != nil;
    } else {
        return NO;
    }
}

- (void)didChangeStartPointTo:(CGPoint)startPoint {
    // previous start point is now walkable
    self.gridWalkabilityMap[[NSValue valueWithCGPoint:self.startPoint]] = @YES;
    self.gridWalkabilityMap[[NSValue valueWithCGPoint:startPoint]] = @YES;
    self.startPoint = startPoint;
}

- (void)didChangeEndPointTo:(CGPoint)endPoint {
    // previous end point is now walkable
    self.gridWalkabilityMap[[NSValue valueWithCGPoint:self.endPoint]] = @YES;
    self.gridWalkabilityMap[[NSValue valueWithCGPoint:endPoint]] = @YES;
    self.endPoint = endPoint;
}

- (void)toggleWallAtPoint:(CGPoint)wallPoint {
    BOOL currentWalkability = [self.gridWalkabilityMap[[NSValue valueWithCGPoint:wallPoint]] boolValue];
    self.gridWalkabilityMap[[NSValue valueWithCGPoint:wallPoint]] = @(!currentWalkability);
}

@end
