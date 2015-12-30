//
//  Node.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 29/12/15.
//
//

import Foundation

class NodeInfo {
  var row: Int
  var col: Int

  init(WithRow row: Int, col: Int) {
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

  var successors: [Int] {
    return edges.map({ (e: Edge) -> Int in
      return e.toNode
    })
  }

  var graphEdges: [GraphEdge] {
    return edges
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
