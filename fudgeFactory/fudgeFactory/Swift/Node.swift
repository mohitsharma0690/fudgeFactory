//
//  Node.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 29/12/15.
//
//

import Foundation
import UIKit

struct Point {
  var x: Int
  var y: Int

  init(X x: Int, y: Int) {
    self.x = x
    self.y = y
  }

  func toCGPoint() -> CGPoint {
    return CGPointMake(CGFloat(x), CGFloat(y))
  }
}

class NodeInfo {
  var row: Int
  var col: Int
  var isObstacle = false

  init(row: Int, col: Int) {
    self.row = row
    self.col = col
  }
}

class Node : GraphNode {
  var id: Int
  var info: NodeInfo
  var edges: [Edge] = []

  init(WithId id: Int, info: NodeInfo) {
    self.id = id
    self.info = info
  }

  func addEdge(edge: Edge) {
    edges.append(edge)
  }

  var row: Int {
    return info.row
  }

  var col: Int {
    return info.col
  }

  var toPoint: Point {
    return Point(X: row, y: col)
  }

  var successors: [Int] {
    return edges.map({ (e: Edge) -> Int in
      return e.toNode
    })
  }

  var graphEdges: [GraphEdge] {
    get {
      return edges
    }

    set {
      if let e = newValue as? [Edge] {
        edges = e
      }
    }
  }

  func isWalkable() -> Bool {
    return info.isObstacle == false
  }
}

class EdgeInfo {
  var cost: Int

  init(WithCost cost: Int) {
    self.cost = cost
  }
}

class Edge : GraphEdge {
  var toNode: Int
  var info: EdgeInfo

  init(toNode: Int, info: EdgeInfo) {
    self.toNode = toNode
    self.info = info
  }

  var cost: Int {
    return info.cost
  }
}
