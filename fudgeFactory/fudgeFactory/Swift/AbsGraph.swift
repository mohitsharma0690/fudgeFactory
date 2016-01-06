//
//  AbsGraph.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 03/01/16.
//
//

import Foundation

class AbsNode {
  var id: Int
  var info: AbsNodeInfo
  private(set) var edges = [AbsEdge]()

  init(id: Int, info: AbsNodeInfo) {
    self.id = id
    self.info = info
  }

  func addAbsEdge(edge: AbsEdge) {
    edges.append(edge)
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

class AbsEdge {
  var toAbsNode: Int
  var info: AbsEdgeInfo

  init(to: Int, info: AbsEdgeInfo) {
    toAbsNode = to
    self.info = info
  }

}

class AbsEdgeInfo {
  var cost: Int
  var isInter: Bool

  init(cost: Int, isInter: Bool) {
    self.cost = cost
    self.isInter = isInter
  }
}

class AbsGraph {
  var nodes = [AbsNode]()
  var graph: Graph

  init(graph: Graph) {
    self.graph = graph
  }

  func nodeById(id: Int) -> AbsNode {
    assert(nodes.count < id, "Invalid abs node id \(id)")
    return nodes[id]
  }

  func successors(node: AbsNode) -> [AbsNode] {
    return node.edges.map { (edge: AbsEdge) -> AbsNode in
      nodeById(edge.toAbsNode)
    }
  }

}
