//
//  Graph.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 29/12/15.
//
//

import Foundation
import UIKit

protocol GraphNode {

  var id: Int { get }
  var row: Int { get }
  var col: Int {get}
  var successors: [Int] { get }
  var graphEdges: [GraphEdge] { get set }
  func isWalkable() -> Bool
}

protocol GraphEdge {

  var cost: Int { get }
  var toNode: Int { get }
}

class Graph : NSObject {

  var nodesById = [Int: GraphNode]()
  var width = 0
  var height = 0

  func getNodeById(nodeId: Int) -> GraphNode? {
    return nodesById[nodeId]
  }

  func successors(node: GraphNode) -> [GraphNode] {
    let successorIds = node.successors
    return successorIds.map { (nodeId: Int) -> GraphNode in
      getNodeById(nodeId)!
    }
  }

  func outEdges(node: GraphNode) -> [GraphEdge] {
    return node.graphEdges
  }

  func nodeIdForPositionWithRow(row: Int, col: Int) -> Int? {
    guard row >= 0 && row < height else {
      return nil
    }
    guard col >= 0 && col < width else {
      return nil
    }
    return row * width + col
  }

  func gridNeighborsForRow(row: Int, col: Int) -> [(Int, Int)] {
    return [
      (row - 1, col - 1), (row - 1, col), (row - 1, col + 1),
      (row, col - 1), (row, col + 1),
      (row + 1, col - 1), (row + 1, col), (row + 1, col + 1)
    ]
  }

  func createGraphFromWalkabilityMap(walkability: [NSValue: Bool], width: Int, height: Int) {

    self.width = width
    self.height = height

    let nodes = walkability.map { (point, isWalkable) -> Node in
      let p = point.CGPointValue()
      let x = Int(p.x)
      let y = Int(p.y)
      let info = NodeInfo(row: x, col: y)
      info.isObstacle = !isWalkable
      return Node(WithId: nodeIdForPositionWithRow(x, col: y)!, info: info)
    }

    for node in nodes {
      nodesById[node.id] = node
    }

    // Add edges to the node (can obviously be optimized)
    for i in 0..<width {
      for j in 0..<height {
        let nodeId = nodeIdForPositionWithRow(i, col: j)!
        let neighbors = gridNeighborsForRow(i, col: j)
        var edges = neighbors.map({ (n) -> Int? in
          nodeIdForPositionWithRow(n.0, col: n.1)
        })

        edges = edges.filter { $0 != nil }
        let ge = edges.map { (e) -> Edge in
          let edgeInfo = EdgeInfo(WithCost: 1)
          return Edge(toNode: e!, info: edgeInfo)
        }
        var node = nodesById[nodeId]!
        node.graphEdges = ge.map { $0 as GraphEdge }
        // Umm. Interestingly this fails.
        // An array of Edges is not really an array of GraphEdges.
//        node.graphEdges = edges.map { (e) -> Edge in
//          let edgeInfo = EdgeInfo(WithCost: 1)
//          return Edge(toNode: e!, info: edgeInfo)
//        }

      }

    }
  }

  // Walkability
  func isObstacleAtX(x: Int, y: Int) -> Bool {
    return !isObstacleAtX(x, y: y)
  }

  func isWalkableAtX(x: Int, y: Int) -> Bool {
    let nodeId = nodeIdForPositionWithRow(x, col: y)
    let node = getNodeById(nodeId!)
    assert(node != nil, "Invalid nil node at \(x, y)")
    return node!.isWalkable()
  }

}