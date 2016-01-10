//
//  DebugViewLayer.m
//  fudgeFactory
//
//  Created by Mohit Sharma on 10/01/16.
//
//

#import "DebugViewLayer.h"

#import "GameController.h"

#define kGridSpace          16

@interface DebugViewLayer ()

@property(nonatomic, readwrite, strong) GameController *gameController;
@property (nonatomic, readwrite, assign) int boardWidth;
@property (nonatomic, readwrite, assign) int boardHeight;

// Draws lines between from and to Points respectively.
@property(nonatomic, readwrite, assign) BOOL didDrawLines;
@property(nonatomic, readwrite, strong) NSArray *fromPoints;
@property(nonatomic, readwrite, strong) NSArray *toPoints;

@end

@implementation DebugViewLayer

- (instancetype)initWithGameController:(GameController *)gameController {
  if (self = [super init]) {
    _gameController = gameController;
    _boardWidth = gameController.boardWidth;
    _boardHeight = gameController.boardHeight;
    _fromPoints = [[NSArray alloc] init];
    _toPoints = [[NSArray alloc] init];
    self.contentSize = CGSizeMake(_boardWidth * kGridSpace, _boardHeight * kGridSpace);
  }
  return self;
}

#pragma mark - CCLayer override

- (void)draw {
  glLineWidth(5);
  ccDrawColor4F(1, 0, 0, 1);
  [self drawLines];
  ccDrawColor4F(1, 1, 1, 1);
  glLineWidth(1);
}

- (void)drawLines {
  int index = 0;
  for (NSValue *fromValue in self.fromPoints) {
    NSValue *toValue = self.toPoints[index];
    ccDrawLine(fromValue.CGPointValue, toValue.CGPointValue);
    index++;
  }
}

- (void)drawLinesFrom:(NSArray *)fromPoints to:(NSArray *)toPoints {
  NSMutableArray *newFromPoints = [[NSMutableArray alloc] initWithCapacity:fromPoints.count];
  NSMutableArray *newToPoints = [[NSMutableArray alloc] initWithCapacity:toPoints.count];
  for (NSValue *fromValue in fromPoints) {
    CGPoint point = fromValue.CGPointValue;
    CGPoint viewPoint = [self positionAtBoardPointX:point.x y:point.y];
    [newFromPoints addObject:[NSValue valueWithCGPoint:viewPoint]];
  }
  for (NSValue *toValue in toPoints) {
    CGPoint point = toValue.CGPointValue;
    CGPoint viewPoint = [self positionAtBoardPointX:point.x y:point.y];
    [newToPoints addObject:[NSValue valueWithCGPoint:viewPoint]];
  }

  self.fromPoints = newFromPoints;
  self.toPoints = newToPoints;
}

- (void)clearLines {
  self.fromPoints = @[];
  self.toPoints = @[];
}

#pragma mark - Board Layer and View Layer

// TODO(Mohit): Move these into a super class or rather different object which handles it.
- (CGPoint)positionAtBoardPointX:(int)x y:(int)y {
  return CGPointMake((x+0.5f) * kGridSpace, (y+0.5f) * kGridSpace);
}

- (CGPoint)boardPointAtViewPoint:(CGPoint)viewPoint {
  return CGPointMake(((int)viewPoint.x) / kGridSpace, ((int)viewPoint.y) / kGridSpace);
}

@end
