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
    return Point(X: col, y: row)
  }

  var successors: [Int] {
    return edges.map { $0.toNode }
  }

  var graphEdges: [Edge] {
    get {
      return edges
    }

    set {
      edges = newValue
    }
  }

  func isWalkable() -> Bool {
    return info.isObstacle == false
  }
}

class Edge {
  let toNode: Int
  let cost: Float

  init(toNode: Int, cost: Float) {
    self.toNode = toNode
    self.cost = cost
  }

  func description() -> String {
    return "Edge to node: \(toNode), cost: \(cost)"
  }

}
