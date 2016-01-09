//
//  World.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 01/01/16.
//
//

import Foundation
import UIKit

// holds most things and acts on them.
class World : NSObject {

  private(set) var search: Search?
  var graph: Graph
  var absGraph: AbsGraph?
  var clusters: [Cluster] = [Cluster]()
  var nodeIdToAbsNodeId = [Int: Int]()
  var astarNodesByNodeId = [Int: GraphAStarNode]()

  var env: Environment

  init(env: Environment, graph: Graph) {
    self.env = env
    self.graph = graph
  }

  func initSearch() {
    search = Search(env: env, world: self)
    search?.pathfinder = env.initPathfinder()
  }

  func canMoveFrom(from: GraphNode, toAdjacent to: GraphNode) -> Bool {
    guard to.isWalkable() else {
      return false
    }
    // TODO(Mohit): Diagnol movement with the adjacent nodes occupied
    // should also theoretically be avoided.
    return true
  }

  func astarNodeForGraphNode(graphNode: GraphNode) -> GraphAStarNode {
    guard let node = astarNodesByNodeId[graphNode.id] else {
      let astarNode = GraphAStarNode(node: graphNode)
      astarNodesByNodeId[graphNode.id] = astarNode
      return astarNode
    }
    return node
  }

  func graphNodeForAstarNode(astarNode: GraphAStarNode) -> GraphNode {
    return astarNode.node
  }

  func clusterIdForRow(row: Int, col: Int) -> Int {
    assert(row >= 0 && row < graph.width && col >= 0 && col < graph.height)

    var clustersPerRow = graph.width / CLUSTER_HEIGHT
    if graph.width % CLUSTER_HEIGHT != 0 {
      clustersPerRow += 1
    }
    return (row / CLUSTER_HEIGHT) * clustersPerRow + (col / CLUSTER_WIDTH)
  }

  func createAbstractGraph() {
    // create clusters
    clusters = createClusters()
    linkClustersWithEntrances()

    absGraph = createAbstractGraph()
    addNodesToAbstractGraph()

    computeClusterEntrancePaths()
    createAbsGraphEdges()
  }

  private func createClusters() -> [Cluster] {
    var clusterId = 0
    var entranceId = 0
    var row = 0, col = 0
    var clusters: [Cluster] = []
    // Clusters by id
    // |6|7|8|
    // |3|4|5|
    // |0|1|2|
    for currRow in 0.stride(to: graph.height, by: CLUSTER_HEIGHT) {
      col = 0
      for currCol in 0.stride(to: graph.width, by: CLUSTER_WIDTH) {
        let width = min(CLUSTER_WIDTH, graph.width - currRow)
        let height = min(CLUSTER_HEIGHT, graph.height - currCol)
        let cluster = Cluster(id: clusterId, world: self, row: currRow,
          col: currCol, width: width, height: height)
        clusters.append(cluster)
        clusterId += 1

        if currRow + height < graph.height {
          // create horizontal entrances
          let entrances =
            createHorizontalEntrancesForRow(currRow + height - 1, colStart: currCol,
              colEnd: currCol + width - 1, clusterRow: row, clusterCol: col,
              entranceId: &entranceId)
          cluster.addEntrances(entrances)
        }

        if currCol + width < graph.width  {
          // create vertical entrances
          let entrances =
            createVerticalEntrancesForCol(currCol + width - 1, rowStart: currRow,
              rowEnd: currRow + height - 1, clusterRow: row, clusterCol: col,
              entranceId: &entranceId)
          cluster.addEntrances(entrances)
        }

        col += 1
      }
      row += 1
    }

    if env.DEBUG_COLOR_ENTRANCES {
      var entrancePoints = [Point]()
      for cluster in clusters {
        let allEntrancePoints = cluster.entrances.reduce([Point]()) {
          (var points: [Point], e: Entrance) -> [Point] in
          let n1 = graph.getNodeById(e.center1Id)! as! Node
          let n2 = graph.getNodeById(e.center2Id)! as! Node
          points.append(n1.toPoint)
          points.append(n2.toPoint)
          return points
        }
        entrancePoints.appendContentsOf(allEntrancePoints)
      }
      let points = entrancePoints.map { NSValue(CGPoint:$0.toCGPoint()) }
      NSNotificationCenter.defaultCenter().postNotificationName(
        "colorNodes",
        object: nil,
        userInfo: ["nodes": points])
    }

    return clusters
  }

  func createVerticalEntrancesForCol(col: Int, rowStart: Int, rowEnd: Int,
    clusterRow: Int, clusterCol: Int, inout entranceId: Int) -> [Entrance] {
      var entrances = [Entrance]()

      var entranceStart = rowStart

      while entranceStart <= rowEnd {
        if (!graph.isWalkableAtX(entranceStart, y: col) ||
          !graph.isWalkableAtX(entranceStart, y: col + 1)) {
            entranceStart += 1
            continue
        }

        var entranceEnd = entranceStart
        while entranceEnd <= rowEnd &&
          graph.isWalkableAtX(entranceEnd, y: col) &&
          graph.isWalkableAtX(entranceEnd, y: col + 1) {
            entranceEnd += 1
        }

        // entranceStart <= i < entranceEnd is walkable
        let entranceMid: Int = (entranceStart + entranceEnd - 1) / 2
        // Still creating clusters. Set clusterId's later on.
        let entrance =
        Entrance(id: entranceId, row: clusterRow, col: clusterCol,
          cluster1Id: -1, cluster2Id: -1, centerRow: entranceMid, centerCol: col,
          center1Id: graph.nodeIdForPositionWithRow(entranceMid, col: col)!,
          center2Id: graph.nodeIdForPositionWithRow(entranceMid, col: col + 1)!,
          len: entranceEnd - entranceStart, isHorizontal: false)

        entranceId += 1
        entrances.append(entrance)
        entranceStart = entranceEnd
      }

      return entrances
  }

  func createHorizontalEntrancesForRow(row: Int, colStart: Int, colEnd: Int,
    clusterRow: Int, clusterCol: Int, inout entranceId: Int) -> [Entrance] {
      var entrances = [Entrance]()

      var entranceStart = colStart

      while entranceStart <= colEnd {
        if (!graph.isWalkableAtX(row, y: entranceStart) ||
          !graph.isWalkableAtX(row + 1, y: entranceStart)) {
            entranceStart += 1
            continue
        }

        var entranceEnd = entranceStart + 1
        while entranceEnd <= colEnd &&
          graph.isWalkableAtX(row, y: entranceEnd) &&
          graph.isWalkableAtX(row + 1, y: entranceEnd) {
            entranceEnd += 1
        }
        // entranceStart <= i < entranceEnd is walkable
        let entranceMid: Int = (entranceStart + entranceEnd - 1) / 2
        // Still creating clusters. Set clusterId's later on.
        let entrance = Entrance(id: entranceId,
          row: clusterRow, col: clusterCol, cluster1Id: -1, cluster2Id: -1,
          centerRow: row, centerCol: entranceMid,
          center1Id: graph.nodeIdForPositionWithRow(row, col: entranceMid)!,
          center2Id: graph.nodeIdForPositionWithRow(row + 1, col: entranceMid)!,
          len: entranceEnd - entranceStart, isHorizontal: true)

        entranceId += 1
        entrances.append(entrance)
        entranceStart = entranceEnd
      }

      return entrances
  }

  func linkClustersWithEntrances() {
    let width = graph.width

    for cluster in clusters {
      for entrance in cluster.entrances {
        let cl1Id = cluster.id
        var cl2Id = cl1Id + 1
        if entrance.isHorizontal {
          cl2Id = cl1Id + (width / CLUSTER_WIDTH)
        }
        entrance.cluster1Id = cl1Id
        entrance.cluster2Id = cl2Id
      }
    }
  }

  func createAbstractGraph() -> AbsGraph {
    let absGraph = AbsGraph(graph: graph)
    return absGraph;
  }

  func addNodesToAbstractGraph() {
    assert(absGraph != nil)
    var absNodeId = 0
    var absNodes = [AbsNode]()
    for cluster in clusters {
      for entrance in cluster.entrances {

        let node1Info = AbsNodeInfo(clusterId: entrance.cluster1Id,
          row: entrance.center1Row - cluster.startRow,
          col: entrance.center1Col - cluster.startCol,
          nodeId: entrance.center1Id)
        let node1 = AbsNode(id: absNodeId, info: node1Info)
        nodeIdToAbsNodeId[entrance.center1Id] = absNodeId
        absNodes.append(node1)

        absNodeId += 1

        let node2Info = AbsNodeInfo(clusterId: entrance.cluster2Id,
          row: entrance.center2Row - cluster.startRow,
          col: entrance.center2Col - cluster.startCol,
          nodeId: entrance.center2Id)
        let node2 = AbsNode(id: absNodeId, info: node2Info)
        nodeIdToAbsNodeId[entrance.center2Id] = absNodeId
        absNodes.append(node2)

        absNodeId += 1
        // TODO(Mohit): Add the cluster local entrances here.
      }
    }
    absGraph!.nodes = absNodes
  }

  func computeClusterEntrancePaths() {
    for cluster in clusters {
      cluster.initEntrancePaths()
      cluster.computeEntrancePaths()
    }
  }

  func createAbsGraphEdges() {
    if var absGraph = absGraph {

      for n1 in absGraph.nodes {
        for n2 in absGraph.nodes {
          let c1 = n1.info.clusterId
          let c2 = n1.info.clusterId

          if c1 == c2 {

          } else {

          }

        }
      }

    }
  }

}
