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

#pragma mark - Jump Point Search

- (NSArray *)jumpPointNeighborsForNode:(CGPoint)node withParent:(CGPoint)parent {
  NSMutableArray *neighbors = [[NSMutableArray alloc] init];
  if (CGPointEqualToPoint(node, self.startPoint)) {
    int allNeighbors[8][2] = { {0, -1}, {1, 0}, {0, 1}, {-1, 0}, {1, -1}, {1, 1}, {-1, 1}, {-1, -1}};
    for (int i = 0; i < 8; i++) {
      CGPoint nextPoint = CGPointMake(node.x + allNeighbors[i][0], node.y + allNeighbors[i][1]);
      if ([self canMoveToPoint:nextPoint from:node]) {
        [neighbors addObject:[NSValue valueWithCGPoint:nextPoint]];
      }
    }
    return neighbors;
  }

  int dx = node.x - parent.x;
  dx = (dx > 0) ? 1 : ((dx < 0) ? -1 : 0);
  int dy = node.y - parent.y;
  dy = (dy > 0) ? 1 : ((dy < 0) ? -1 : 0);

  if (dx && dy) {
    // diagnol move
    // natural neighbors -- (x + dx, y), (x, y + dy), (x + dx, y + dy)
    BOOL canMoveDiagnolly = NO;
    if ([self canMoveToPoint:CGPointMake(node.x + dx, node.y) from:node]) {
      [neighbors addObject:[NSValue valueWithCGPoint:CGPointMake(node.x + dx, node.y)]];
      canMoveDiagnolly = YES;
    }
    if ([self canMoveToPoint:CGPointMake(node.x, node.y + dy) from:node]) {
      [neighbors addObject:[NSValue valueWithCGPoint:CGPointMake(node.x, node.y + dy)]];
      canMoveDiagnolly = YES;
    }
    if (canMoveDiagnolly &&
        [self canMoveToPoint:CGPointMake(node.x + dx, node.y + dy) from:node]) {
      [neighbors addObject:[NSValue valueWithCGPoint:CGPointMake(node.x + dx, node.y + dy)]];
    }

    // Forced neighbors -- (x - dx, y) or (x, y - dy) have obstacles
    CGPoint leftPoint = CGPointMake(node.x - dx, node.y);
    CGPoint downPoint = CGPointMake(node.x, node.y - dy);
    if ([self isPointOnMap:leftPoint] && ![self isWalkableAtBoardPoint:leftPoint]) {
      [neighbors addObject:[NSValue valueWithCGPoint:CGPointMake(node.x - dx, node.y + dy)]];
    }
    if ([self isPointOnMap:downPoint] && ![self isWalkableAtBoardPoint:downPoint]) {
      [neighbors addObject:[NSValue valueWithCGPoint:CGPointMake(node.x + dx, node.y - dy)]];
    }

  } else if (dx) {
    // horizontal move
    // natural neighbors -- (x + dx, y)
    if ([self canMoveToPoint:CGPointMake(node.x + dx, node.y) from:node]) {
      [neighbors addObject:[NSValue valueWithCGPoint:CGPointMake(node.x + dx, node.y)]];
    }

    // Forced neighbors -- (x, y - dy) or (x, y + dy) have obstacles
    CGPoint downPoint = CGPointMake(node.x, node.y - 1);
    CGPoint upPoint = CGPointMake(node.x, node.y + 1);
    if ([self isPointOnMap:downPoint] && ![self isWalkableAtBoardPoint:downPoint]) {
      [neighbors addObject:[NSValue valueWithCGPoint:CGPointMake(node.x + dx, node.y - 1)]];
    }
    if ([self isPointOnMap:upPoint] && ![self isWalkableAtBoardPoint:upPoint]) {
      [neighbors addObject:[NSValue valueWithCGPoint:CGPointMake(node.x + dx, node.y + 1)]];
    }

  } else {
    // vertical move
    // natural neighbors -- (x, y + dy)
    if ([self canMoveToPoint:CGPointMake(node.x, node.y + dy) from:node]) {
      [neighbors addObject:[NSValue valueWithCGPoint:CGPointMake(node.x, node.y + dy)]];
    }

    // Forced neighbors -- (x - dx, y) or (x + dx, y) have obstacles
    CGPoint leftPoint = CGPointMake(node.x - 1, node.y);
    CGPoint rightPoint = CGPointMake(node.x + 1, node.y);
    if ([self isPointOnMap:leftPoint] && ![self isWalkableAtBoardPoint:leftPoint]) {
      [neighbors addObject:[NSValue valueWithCGPoint:CGPointMake(node.x - 1, node.y + dy)]];
    }
    if ([self isPointOnMap:rightPoint] && ![self isWalkableAtBoardPoint:rightPoint]) {
      [neighbors addObject:[NSValue valueWithCGPoint:CGPointMake(node.x + 1, node.y + dy)]];
    }
  }

  return neighbors;
}

- (NSValue *)jumpFromNode:(CGPoint)node
               withParent:(CGPoint)parent {
  NSValue *nodeValue = [NSValue valueWithCGPoint:node];
  if ([self isEndPoint:node]) {
    return nodeValue;
  }
  if (![self isWalkableAtBoardPoint:node]) {
    return nil;
  }

  int dx = node.x - parent.x;
  dx = (dx > 0) ? 1 : ((dx < 0) ? -1 : 0);

  int dy = node.y - parent.y;
  dy = (dy > 0) ? 1 : ((dy < 0) ? -1 : 0);

  if (dx && dy) {
    // Invalid diagnol move.
    CGPoint firstNeighbor = CGPointMake(parent.x + dx, parent.y);
    CGPoint secondNeighbor = CGPointMake(parent.x, parent.y + dy);
    if ([self isPointOnMap:firstNeighbor] && ![self isWalkableAtBoardPoint:firstNeighbor] &&
        [self isPointOnMap:secondNeighbor] && ![self isWalkableAtBoardPoint:secondNeighbor]) {
      return nil;
    }
  }


  if (dx && dy) {
    // diagnoal move
    // Forced neighbors -- (x - dx, y) or (x, y - dy) have obstacles
    CGPoint leftPoint = CGPointMake(node.x - dx, node.y);
    CGPoint forcedLeftPoint = CGPointMake(node.x - dx, node.y + dy);
    if ([self isWalkableAtBoardPoint:forcedLeftPoint] &&
        ![self isWalkableAtBoardPoint:leftPoint]) {
      return nodeValue;
    }

    CGPoint downPoint = CGPointMake(node.x, node.y - dy);
    CGPoint forcedDownPoint = CGPointMake(node.x + dx, node.y - dy);
    if ([self isWalkableAtBoardPoint:forcedDownPoint] &&
        ![self isWalkableAtBoardPoint:downPoint]) {
      return nodeValue;
    }

  } else if (dx) {
    // horizontal move
    // Forced neigbors -- (x, y - dy) or (x, y + dy) have obstacles
    CGPoint upPoint = CGPointMake(node.x, node.y + 1);
    CGPoint forcedUpPoint = CGPointMake(node.x + dx, node.y + 1);
    if ([self isWalkableAtBoardPoint:forcedUpPoint] && ![self isWalkableAtBoardPoint:upPoint]) {
      return nodeValue;
    }

    CGPoint downPoint = CGPointMake(node.x, node.y - 1);
    CGPoint forcedDownPoint = CGPointMake(node.x + dx, node.y - 1);
    if ([self isWalkableAtBoardPoint:forcedDownPoint] &&
        ![self isWalkableAtBoardPoint:downPoint]) {
      return nodeValue;
    }

  } else {
    // vertical move
    // Forced neighbors -- (x - dx, y) or (x + dx, y) have obstacles
    CGPoint leftPoint = CGPointMake(node.x - 1, node.y);
    CGPoint forcedLeftPoint = CGPointMake(node.x - 1, node.y + dy);
    if ([self isWalkableAtBoardPoint:forcedLeftPoint] &&
        ![self isWalkableAtBoardPoint:leftPoint]) {
      return nodeValue;
    }

    CGPoint rightPoint = CGPointMake(node.x + 1, node.y);
    CGPoint forcedRightPoint = CGPointMake(node.x + 1, node.y + dy);
    if ([self isWalkableAtBoardPoint:forcedRightPoint] &&
        ![self isWalkableAtBoardPoint:rightPoint]) {
      return nodeValue;
    }

  }

  if (dx && dy) {
    // Prefer horizontal moves over diagnoal ones for jumps.
    if ([self jumpFromNode:CGPointMake(node.x + dx, node.y) withParent:node]) {
      return nodeValue;
    }
    if ([self jumpFromNode:CGPointMake(node.x, node.y + dy) withParent:node]) {
      return nodeValue;
    }
  }

  return [self jumpFromNode:CGPointMake(node.x + dx, node.y + dy) withParent:node];
}

/**
 *  Find the successors for the current node.
 *
 *  @param node      The current node to be expanded.
 *  @param openSet   The current open set.
 *  @param closedSet The current closed set.
 *
 *  @return TBD
 */
- (void)updateSuccessorsForNode:(CGPoint)node
                    withOpenSet:(NSMutableSet *)openSet
                      closedSet:(NSMutableSet *)closedSet
                    parentNodes:(NSMutableDictionary *)parentNodes
                   heuristicMap:(NSMutableDictionary *)heuristicMap
                    distanceMap:(NSMutableDictionary *)distanceMap {
  CGPoint parent = [parentNodes[[NSValue valueWithCGPoint:node]] CGPointValue];
  NSArray *neighbors = [self jumpPointNeighborsForNode:node withParent:parent];

  for (NSValue *neighborValue in neighbors) {
    CGPoint neighbor = neighborValue.CGPointValue;

    if (![self isWalkableAtBoardPoint:neighbor]) {
      NSLog(@"ERROR: Neighbor point isn't a valid walk point (%d, %d)",
            (int)neighbor.x, (int)neighbor.y);
      continue;
    }

    NSValue *jumpPointValue = [self jumpFromNode:neighbor
                                      withParent:node];
    if (jumpPointValue) {
      CGPoint jumpPoint = jumpPointValue.CGPointValue;
      if (![closedSet containsObject:jumpPointValue]) {
        double distanceFromCurrent = [self euclideanDistanceBetweenA:node andB:jumpPoint];
        double newOpenSetDistance =
            [distanceMap[[NSValue valueWithCGPoint:node]] doubleValue] + distanceFromCurrent;
        // Add to open set
        if (![openSet containsObject:jumpPointValue] ||
            [distanceMap[jumpPointValue] doubleValue] > newOpenSetDistance) {
          [openSet addObject:jumpPointValue];
          distanceMap[jumpPointValue] = @(newOpenSetDistance);

          // update it's parent
          parentNodes[jumpPointValue] = [NSValue valueWithCGPoint:node];
        }

        // update heuristic if required
        if (!heuristicMap[jumpPointValue]) {
          heuristicMap[jumpPointValue] = @([self heuristicFromPoint:jumpPoint]);
        }
      }
    }
  }
}

- (void)startJumpPointSearch {
  NSMutableSet *openSet = [[NSMutableSet alloc] init];
  NSMutableSet *closedSet = [[NSMutableSet alloc] init];
  NSMutableDictionary *parentNodes = [[NSMutableDictionary alloc] init];
  NSMutableDictionary *distanceMap = [[NSMutableDictionary alloc] init];
  NSMutableDictionary *heuristicMap = [[NSMutableDictionary alloc] init];

  NSValue *startPointValue = [NSValue valueWithCGPoint:self.startPoint];
  [openSet addObject:startPointValue];
  distanceMap[startPointValue] = @(0);
  heuristicMap[startPointValue] = @([self heuristicFromPoint:self.startPoint]);

  while (openSet.count) {
    NSValue *currentNodeValue = [self nextPointFromOpenSet:openSet
                                           withDistanceMap:distanceMap
                                              heuristicMap:heuristicMap];
    CGPoint currentPoint = currentNodeValue.CGPointValue;
    if ([self isEndPoint:currentPoint]) {
      NSLog(@"Did successfully reach end point");
      NSArray *path = [self constructPathFromParentNodes:parentNodes];
      [[NSNotificationCenter defaultCenter] postNotificationName:@"didFindPath" object:path];
      return;
    }

    [self updateSuccessorsForNode:currentPoint
                      withOpenSet:openSet
                        closedSet:closedSet
                      parentNodes:parentNodes
                     heuristicMap:heuristicMap
                      distanceMap:distanceMap];

    [openSet removeObject:currentNodeValue];
    [closedSet addObject:currentNodeValue];

    if (![self isStartPoint:currentPoint]) {
      [[NSNotificationCenter defaultCenter] postNotificationName:@"didAddToClosedSet"
                                                          object:currentNodeValue];
    }
  }
  NSLog(@"Failed to find a path to end point");
}

- (double)euclideanDistanceBetweenA:(CGPoint)a andB:(CGPoint)b {
  int dx = a.x - b.x;
  int dy = a.y - b.y;
  return sqrt(dx * dx + dy * dy);
}

- (double)heuristicFromPoint:(CGPoint)point {
  // using euclidean distance
  return [self euclideanDistanceBetweenA:self.endPoint andB:point];
}

- (NSArray *)constructPathFromParentNodes:(NSMutableDictionary *)parentNodes {
  NSMutableArray *path =
      [NSMutableArray arrayWithObject:[NSValue valueWithCGPoint:self.endPoint]];
  CGPoint currentPoint = self.endPoint;
  do {
    NSValue *currentPointValue = [NSValue valueWithCGPoint:currentPoint];
    [path addObject:currentPointValue];
    currentPoint = [parentNodes[currentPointValue] CGPointValue];
  } while (!CGPointEqualToPoint(currentPoint, self.startPoint));
  [path addObject:[NSValue valueWithCGPoint:self.startPoint]];
  return [[path reverseObjectEnumerator] allObjects];
}

#pragma mark - GridWalkability

- (BOOL)isPointOnMap:(CGPoint)point {
  return point.x >= 0 && point.x < self.width && point.y >= 0 && point.y < self.height;
}

- (BOOL)isWalkableAtBoardPoint:(CGPoint)boardPoint {
    return [self.gridWalkabilityMap[[NSValue valueWithCGPoint:boardPoint]] boolValue];
}

- (void)startSearchForPath {
  [self startJumpPointSearch];
}

- (void)startAStarSearchForPath {
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
            if (distanceForNeighbor && distanceForNeighbor >=
                currentDistance + distanceToNeighborFromCurrentPoint) {
                continue;
            } else {
                openSet[neighborPointValue] =
                    @(currentDistance + distanceToNeighborFromCurrentPoint);
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

- (NSValue *)nextPointFromOpenSet:(NSMutableSet *)openSet
                  withDistanceMap:(NSMutableDictionary *)distanceMap
                     heuristicMap:(NSMutableDictionary *)heuristicMap {
  NSValue *nextPointValue;
  double minDistance = INT_MAX;
  for (NSValue *pointValue in openSet) {
    NSAssert(distanceMap[pointValue], @"Missing distance value");
    NSAssert(heuristicMap[pointValue], @"Missing heuristic value");
    double distToPoint = [distanceMap[pointValue] doubleValue];
    double distToDestination = [heuristicMap[pointValue] doubleValue];

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

- (BOOL)isEndPoint:(CGPoint)point {
  return CGPointEqualToPoint(point, self.endPoint);
}

- (BOOL)isStartPoint:(CGPoint)point {
  return CGPointEqualToPoint(point, self.startPoint);
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
