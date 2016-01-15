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
  var toPoint: Point { get }
  func isWalkable() -> Bool
  var edges: [Edge] { get set }
}

class Graph : NSObject, SearchGraph {

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

  func outEdges(node: GraphNode) -> [Edge] {
    return node.edges
  }

  func nodeForPositionWithRow(row: Int, col: Int) -> GraphNode? {
    let nodeId = nodeIdForPositionWithRow(row, col: col)
    if let id = nodeId {
      return getNodeById(id)
    }
    return nil
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

  func positionForNodeId(nodeId: Int) -> (Int, Int) {
    return (nodeId / width, nodeId % width)
  }

  func gridNeighborsForRow(row: Int, col: Int) -> [(Int, Int)] {
    return [
      (row - 1, col - 1), (row - 1, col), (row - 1, col + 1),
      (row, col - 1), (row, col + 1),
      (row + 1, col - 1), (row + 1, col), (row + 1, col + 1)
    ]
  }

  func createGraphFromGraph(graph: Graph, startRow: Int, startCol: Int,
    width: Int, height: Int) {

      self.width = width
      self.height = height

      var nodeId = 0
      // Create Nodes
      for i in startRow.stride(to: startRow + height, by: 1) {
        for j in startCol.stride(to: startCol + width, by: 1) {
          let node = graph.nodeForPositionWithRow(i, col: j)

          let newNodeInfo = NodeInfo(row: i, col: j)
          newNodeInfo.isObstacle = (node?.isWalkable() == false)
          let newNode = Node(WithId: nodeId, info: newNodeInfo)
          nodesById[nodeId] = newNode

          nodeId += 1
        }
      }

      // Create Edges
      addEdgesToGraph()
  }

  func createGraphFromWalkabilityMap(walkability: [NSValue: Bool], width: Int, height: Int) {

    self.width = width
    self.height = height

    let nodes = walkability.map { (point, isWalkable) -> Node in
      let p = point.CGPointValue()
      let x = Int(p.x)
      let y = Int(p.y)
      let info = NodeInfo(row: y, col: x)
      info.isObstacle = !isWalkable
      return Node(WithId: nodeIdForPositionWithRow(y, col: x)!, info: info)
    }

    for node in nodes {
      nodesById[node.id] = node
    }
    addEdgesToGraph()
  }

  /// Add edges to the node (can obviously be optimized)
  func addEdgesToGraph() {
    for i in 0..<height {
      for j in 0..<width {
        let nodeId = nodeIdForPositionWithRow(i, col: j)!
        let neighbors = gridNeighborsForRow(i, col: j)
        let edges = neighbors.map { n -> Int? in
          nodeIdForPositionWithRow(n.0, col: n.1)
        }

        var node = nodesById[nodeId]!
        node.edges = edges.filter({ $0 != nil}).map { (e) -> Edge in
          return Edge(toNode: e!, cost: 1)
        }
        // node.graphEdges = ge.map { $0 as GraphEdge }
        // Umm. Interestingly this fails.
        // An array of Edges is not really an array of GraphEdges.
        //        node.graphEdges = edges.map { (e) -> Edge in
        //          let edgeInfo = EdgeInfo(WithCost: 1)
        //          return Edge(toNode: e!, info: edgeInfo)
        //        }

      }
    }
  }

  /// Walkability

  func isObstacleAtX(x: Int, y: Int) -> Bool {
    return !isObstacleAtX(x, y: y)
  }

  func isWalkableAtX(x: Int, y: Int) -> Bool {
    let nodeId = nodeIdForPositionWithRow(x, col: y)
    let node = getNodeById(nodeId!)
    assert(node != nil, "Invalid nil node at \(x, y)")
    return node!.isWalkable()
  }

  func isDiagnolMoveFrom(from: GraphNode, to: GraphNode) -> Bool {
    return from.row != to.row && from.col != to.col
  }

  func adjacentNodesForDiagnolMoveFrom(from: GraphNode,
    to: GraphNode) -> (GraphNode?, GraphNode?) {
      return (nodeForPositionWithRow(from.row, col: to.col),
        nodeForPositionWithRow(to.row, col: from.col))
  }

  func canMoveFrom(from: GraphNode, toAdjacent to: GraphNode) -> Bool {
    guard to.isWalkable() else {
      return false
    }

    // Diagnol movement with adjacent nodes occupied is avoided.
    if isDiagnolMoveFrom(from, to: to) {
      let (a, b) = adjacentNodesForDiagnolMoveFrom(from, to: to)
      return (a?.isWalkable() ?? false) && (b?.isWalkable() ?? false)
    } else {
      return true
    }

  }

}
