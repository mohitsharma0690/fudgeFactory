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
  var search: Search?
  var nodeIdToAbsNodeId = [Int: Int]()
  var targetNodeIsAbsNode = [Bool](count: 2, repeatedValue: false)

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
          let e1 = addEdgeBetweenAbsNodes(n1, n2, withCost: 1)
          let e2 = addEdgeBetweenAbsNodes(n2, n1, withCost: 1)
          e1.isInter = true
          e2.isInter = true
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
    for (i, e) in cluster.entrances.enumerate() {
      createIntraEdgesForCluster(cluster, entrance: e, atIndex: i) { i < $0 }
    }
  }

  func createIntraEdgesForCluster(cluster: Cluster,
    entrance e1: ClusterEntrance, atIndex idx: Int, filter: Int -> Bool) {
    for (j, e2) in cluster.entrances.enumerate() {
      if filter(j) {
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

  func addEdgeBetweenAbsNodes(n1: AbsNode, _ n2: AbsNode, withCost cost: Float) -> AbsEdge {
    let edge = newEdgeBetweenAbsNodes(n1, n2, withCost: cost)
    n1.addAbsEdge(edge)
    return edge
  }

  func newEdgeBetweenAbsNodes(n1: AbsNode, _ n2: AbsNode,
    withCost cost: Float) -> AbsEdge {
      return AbsEdge(toNode: n2.id, cost: cost)
  }

  func nodeForAbsNode(absNode: AbsNode) -> GraphNode? {
    return world.graph.getNodeById(absNode.info.nodeId)
  }

  /// Debug abstract world.
  func debugAbstractWorld() {
    debugColorAbstractNodes()
    debugColorAbsEdges()
  }

  func debugColorAbstractNodes() {
    if env.DEBUG_COLOR_ABS_NODES {
      let absPoints = absGraph.nodes.map { return (nodeForAbsNode($0)?.toPoint)! }
      let points = absPoints.map { NSValue(CGPoint: $0.toCGPoint()) }
      NSNotificationCenter.defaultCenter().postNotificationName(
        "colorNodes",
        object: nil,
        userInfo: ["nodes": points])
    }
  }

  func debugColorAbsEdges() {
    let (fromPoints, toPoints) = absGraph.nodes.reduce(([Point](), [Point]()), combine: {
      let (from, to) = colorAbsEdgesForNode($1)
      return ($0.0 + from, $0.1 + to)
    })

    let fromValues = fromPoints.map { NSValue(CGPoint: $0.toCGPoint()) }
    let toValues = toPoints.map{ NSValue(CGPoint: $0.toCGPoint()) }
    NSNotificationCenter.defaultCenter().postNotificationName(
      "createLines",
      object: nil,
      userInfo: ["fromPoints": fromValues, "toPoints": toValues])
  }

  func colorAbsEdgesForNode(node: AbsNode) -> ([Point], [Point]) {
    let toPoints = successorPointsForNode(node)
    let fromPoints = [Point](count: toPoints.count,
      repeatedValue: (nodeForAbsNode(node)?.toPoint)!)
    return (fromPoints, toPoints)
  }

  func successorPointsForNode(node: AbsNode) -> [Point] {
    let successors = absGraph.successors(node)
    return successors.map { return (nodeForAbsNode($0)?.toPoint)! }
  }

  /// Insert start, end nodes to abstract graph

  func insertNodeToAbsGraph(nodeId: Int, atRow row: Int, col: Int, index: Int) -> Int? {
    guard index == 0 || index == 1 else {
      assertionFailure("Invalid index \(index)")
      return nil
    }

    if let absNodeId = nodeIdToAbsNodeId[nodeId] {
      // Node ID is already there in the abstract graph
      targetNodeIsAbsNode[index] = true
      return absNodeId
    } else {
      let absNodeId = absGraph.maxNodeId! + 1
      targetNodeIsAbsNode[index] = false
      guard let cluster = world.clusterForNodeId(nodeId) else {
        assertionFailure("No cluster for node \(nodeId)")
        return nil
      }

      // Add cluster entrance for node
      let entrance = ClusterEntrance(id: cluster.id,
        absNodeId: absNodeId, centerRow: row, centerCol: col, len: 1)
      cluster.addClusterEntrance(entrance)

      // Add abstract node.
      let info = AbsNodeInfo(clusterId: cluster.id,
        row: row, col: col, nodeId: nodeId)
      let node = AbsNode(id: absNodeId, info: info)
      absGraph.addAbsNode(node)

      // Add paths from entrance to other cluster entrances
      cluster.resizeEntrancePaths()
      cluster.recomputeEntrancePathsFrom(entrance)
      // Create Intra cluster edges
      createIntraEdgesForCluster(cluster,
        entrance: entrance,
        atIndex: cluster.entrances.count - 1) {
          $0 != cluster.entrances.count - 1
      }

      return absNodeId
    }
  }

  func initSearch() {
    search = env.initNewSearchWithGraph(absGraph)
  }

  /// Path in an abstract graph which consists of the actual
  /// nodeIds'.
  func searchPathFrom(startId: Int, to endId: Int) -> [Int]? {
    if search == nil {
      initSearch()
    }
    guard let path = search?.path(startId, to: endId) else {
      return nil
    }
    return path.map { absGraph.nodeById($0).info.nodeId }
  }

}
