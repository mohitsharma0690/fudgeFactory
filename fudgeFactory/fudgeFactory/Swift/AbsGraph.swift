//
//  AbsGraph.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 03/01/16.
//
//

import Foundation

class AbsNode : GraphNode {
  var id: Int
  var info: AbsNodeInfo
  var edges = [Edge]()

  init(id: Int, info: AbsNodeInfo) {
    self.id = id
    self.info = info
  }

  func addAbsEdge(edge: AbsEdge) {
    edges.append(edge)
  }

  func removeEdgeToNode(nodeId: Int) -> Edge? {
    guard let index = edges.indexOf({ $0.toNode == nodeId }) else {
      return nil
    }
    return edges.removeAtIndex(index)
  }

  /// ===== GraphNode =====
  var row: Int { return info.row }
  var col: Int { return info.col }

  var successors: [Int] {
    return edges.map { $0.toNode }
  }

  var toPoint: Point {
    return Point(X: row, y: col)
  }

  func isWalkable() -> Bool {
    return true
  }
}

struct AbsNodeInfo {

  // TODO(Mohit): Add levels to abstract nodes.
  var clusterId: Int
  var row: Int  // The actual row in the original graph
  var col: Int  // The actual col in the original graph
  var nodeId: Int  // nodeId for the center node of the entrance

  init(clusterId: Int, row: Int, col: Int, nodeId: Int) {
    self.clusterId = clusterId
    self.row = row
    self.col = col
    self.nodeId = nodeId
  }

  var graphNodeId: Int {
    // TODO(Mohit): This would change based on levels.
    return nodeId
  }

}

class AbsEdge: Edge {
  var isInter: Bool = false

  override init(toNode: Int, cost: Float) {
    super.init(toNode: toNode, cost: cost)
  }

  convenience init(toNode: Int, cost: Float, isInter: Bool) {
    self.init(toNode: toNode, cost: cost)
    self.isInter = isInter
  }

}

// TODO(Mohit): Rename SearchGraph to Searchable
class AbsGraph : SearchGraph {
  // Use array since it would be much faster as we only use
  // it as a list i.e. either first or last.
  var nodes = [AbsNode]()
  var graph: Graph

  init(graph: Graph) {
    self.graph = graph
  }

  func nodeById(id: Int) -> AbsNode {
    assert(id < nodes.count, "Invalid abs node id \(id)")
    return nodes[id]
  }

  func successors(node: AbsNode) -> [AbsNode] {
    return node.edges.map { nodeById($0.toNode) }
  }

  var maxNodeId: Int? {
    guard nodes.count > 0 else {
      return nil
    }
    return nodes.count - 1
  }

  func addAbsNode(absNode: AbsNode) {
    assert(absNode.id == nodes.count)
    nodes.append(absNode)
  }

  func removeAbsNode(node: AbsNode) {
    assert(node.id == nodes.last?.id,
      "Trying to remove non last node breaks index.")

    // Remove edges to node.
    for succ in node.successors {
      let succNode = nodeById(succ)
      succNode.removeEdgeToNode(node.id)
    }
    nodes.removeLast()

  }

  /// ===== Search Graph =====

  func getNodeById(nodeId: Int) -> GraphNode? {
    return nodeById(nodeId)
  }

  func canMoveFrom(a: GraphNode, toAdjacent b: GraphNode) -> Bool {
    // You can always move between edges in an abstract graph.
    return true
  }

}
