//
//  AbsWorld.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 09/01/16.
//
//

import Foundation

class AbsWorld {

  private let env: Environment
  private var world: World
  var absGraph: AbsGraph
  var nodeIdToAbsNodeId = [Int: Int]()


  init(env: Environment, world: World, absGraph: AbsGraph) {
    self.env = env
    self.world = world
    self.absGraph = absGraph
  }

  func addNodesWithEntrances(entrances: [Entrance]) {
    var absNodeId = 0
    var clusterId = 0
    var absNodes = [AbsNode]()
    for entrance in entrances {

      guard let cluster1 = world.clusterById(entrance.cluster1Id) else {
        assertionFailure("Missing cluster with id \(entrance.cluster1Id)")
        return
      }
      guard let cluster2 = world.clusterById(entrance.cluster2Id) else {
        assertionFailure("Missing cluster with id \(entrance.cluster2Id)")
        return
      }

      let node1Info = AbsNodeInfo(clusterId: entrance.cluster1Id,
        row: entrance.center1Row,
        col: entrance.center1Col,
        nodeId: entrance.center1Id)
      let node1 = AbsNode(id: absNodeId, info: node1Info)
      nodeIdToAbsNodeId[entrance.center1Id] = absNodeId
      absNodes.append(node1)

      let clEntrance1 = ClusterEntrance(id: clusterId,
        absNodeId: absNodeId,
        centerRow: entrance.center1Row,
        centerCol: entrance.center1Col,
        len: entrance.len)
      cluster1.addClusterEntrance(clEntrance1)

      absNodeId += 1; clusterId += 1

      let node2Info = AbsNodeInfo(clusterId: entrance.cluster2Id,
        row: entrance.center2Row,
        col: entrance.center2Col,
        nodeId: entrance.center2Id)
      let node2 = AbsNode(id: absNodeId, info: node2Info)
      nodeIdToAbsNodeId[entrance.center2Id] = absNodeId
      absNodes.append(node2)

      let clEntrance2 = ClusterEntrance(id: clusterId,
        absNodeId: absNodeId,
        centerRow: entrance.center2Row,
        centerCol: entrance.center2Col,
        len: entrance.len)
      cluster2.addClusterEntrance(clEntrance2)

      absNodeId += 1; clusterId += 1
    }
    absGraph.nodes = absNodes
  }

  func createEdgesAcrossClusters(entrances: [Entrance]) {
    for entrance in entrances {
      let idx1 = world.graph.nodeIdForPositionWithRow(
        entrance.center1Row, col: entrance.center1Col)
      let idx2 = world.graph.nodeIdForPositionWithRow(
        entrance.center2Row, col: entrance.center2Col)
      if let absId1 = nodeIdToAbsNodeId[idx1!],
        absId2 = nodeIdToAbsNodeId[idx2!] {
          let n1 = absGraph.nodeById(absId1)
          let n2 = absGraph.nodeById(absId2)
          addEdgeBetweenAbsNodes(n1, n2, withCost: 1)
          addEdgeBetweenAbsNodes(n2, n1, withCost: 1)
      } else {
        assertionFailure("Cannot find graph nodes with index \(idx1) and \(idx2)")
      }
    }
  }

  /// Creates intra-cluster edges.
  func createEdgesInClusters(clusters: [Cluster]) {
    clusters.forEach { createIntraClusterEdges($0) }
  }

  func createIntraClusterEdges(cluster: Cluster) {
    let count = cluster.entrances.count
    for (i, e1) in cluster.entrances.enumerate() {
      for j in (i+1)..<count {
        let e2 = cluster.entrances[j]
        // Bidirectional edges
        addIntraEdgeInCluster(cluster, between: e1, e2)
        addIntraEdgeInCluster(cluster, between: e2, e1)
      }
    }
  }

  func addIntraEdgeInCluster(cluster: Cluster,
    between e1: ClusterEntrance, _ e2: ClusterEntrance) {
      if cluster.isEntrance(e1, connectedWith: e2) {
        let cost = cluster.costBetweenEntrances(e1, e2)
        let n1 = absGraph.nodeById(e1.absNodeId)
        let n2 = absGraph.nodeById(e2.absNodeId)
        addEdgeBetweenAbsNodes(n1, n2, withCost: cost)
      }
  }

  func addEdgeBetweenAbsNodes(n1: AbsNode, _ n2: AbsNode, withCost cost: Float) {
    let edge = newEdgeBetweenAbsNodes(n1, n2, withCost: cost)
    n1.addAbsEdge(edge)
  }

  func newEdgeBetweenAbsNodes(n1: AbsNode, _ n2: AbsNode,
    withCost cost: Float) -> AbsEdge {
      let info = AbsEdgeInfo(cost: cost, isInter: false)
      return AbsEdge(to: n2.id, info: info)
  }
}
