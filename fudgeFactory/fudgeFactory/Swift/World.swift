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
  var absWorld: AbsWorld?
  var clusters: [Cluster] = [Cluster]()
  var entrances: [Entrance] = [Entrance]()
  var nodeIdToAbsNodeId = [Int: Int]()
  // TODO(Mohit): Remove this from here.

  var env: Environment

  init(env: Environment, graph: Graph) {
    self.env = env
    self.graph = graph
  }

  func initSearch() {
    search = env.initNewSearchWithGraph(graph)
  }

  func clusterIdForRow(row: Int, col: Int) -> Int {
    assert(row >= 0 && row < graph.height && col >= 0 && col < graph.width)

    var clustersPerRow = graph.width / CLUSTER_HEIGHT
    if graph.width % CLUSTER_HEIGHT != 0 {
      clustersPerRow += 1
    }
    return (row / CLUSTER_HEIGHT) * clustersPerRow + (col / CLUSTER_WIDTH)
  }

  func clusterForNodeId(nodeId: Int) -> Cluster? {
    let (row, col) = graph.positionForNodeId(nodeId)
    let clusterId = clusterIdForRow(row, col: col)
    return clusterById(clusterId)
  }

  func debugWorldVisually() {
    debugColorEntrances()
    absWorld?.debugAbstractWorld()
  }

  func createAbstractGraph() {
    initSearch()

    // create clusters
    clusters = createClusters()
    linkClustersWithEntrances()

    absWorld = createAbstractWorld()
    absWorld!.addNodesWithEntrances(entrances)

    computeClusterEntrancePaths()
    createAbsGraphEdges()

    // Finally debug world in case we want to visually see something.
    debugWorldVisually()
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
        let newGraph = Graph()
        newGraph.createGraphFromGraph(graph, startRow: currRow, startCol: currCol,
          width: width, height: height)

        let cluster = Cluster(id: clusterId, env: env, graph: newGraph,
          row: currRow, col: currCol, width: width, height: height)
        clusters.append(cluster)
        clusterId += 1

        if currRow + height < graph.height {
          // create horizontal entrances
          let clusterEntrances =
            createHorizontalEntrancesForRow(currRow + height - 1, colStart: currCol,
              colEnd: currCol + width - 1, clusterRow: row, clusterCol: col,
              entranceId: &entranceId)
          entrances.appendContentsOf(clusterEntrances)
        }

        if currCol + width < graph.width  {
          // create vertical entrances
          let clusterEntrances =
            createVerticalEntrancesForCol(currCol + width - 1, rowStart: currRow,
              rowEnd: currRow + height - 1, clusterRow: row, clusterCol: col,
              entranceId: &entranceId)
          entrances.appendContentsOf(clusterEntrances)
        }

        col += 1
      }
      row += 1
    }
    return clusters
  }

  func debugColorEntrances() {
    if env.DEBUG_COLOR_ENTRANCES {
      let entrancePoints = entrances.reduce([Point]()) {
        (var points: [Point], e: Entrance) -> [Point] in
        let n1 = graph.getNodeById(e.center1Id)! as! Node
        let n2 = graph.getNodeById(e.center2Id)! as! Node
        points.append(n1.toPoint)
        points.append(n2.toPoint)
        return points
      }

      let points = entrancePoints.map { NSValue(CGPoint:$0.toCGPoint()) }
      NSNotificationCenter.defaultCenter().postNotificationName(
        "colorNodes",
        object: nil,
        userInfo: ["nodes": points])
    }
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

  func clusterById(id: Int) -> Cluster? {
    let c = clusters.filter{ $0.id == id }
    guard c.count > 0 else {
      return nil
    }
    assert(c.count == 1, "Multiple clusters with same id")
    return c[0]
  }

  func linkClustersWithEntrances() {
    let width = graph.width

    for entrance in entrances {
      let cl1Id = clusterIdForRow(entrance.center1Row, col: entrance.center1Col)
      var cl2Id = cl1Id + 1
      if entrance.isHorizontal {
        cl2Id = cl1Id + (width / CLUSTER_WIDTH)
      }
      entrance.cluster1Id = cl1Id
      entrance.cluster2Id = cl2Id
    }
  }

  func createAbstractWorld() -> AbsWorld {
    let absGraph = AbsGraph(graph: graph)
    return AbsWorld(env: env, world: self, absGraph: absGraph)
  }

  func computeClusterEntrancePaths() {
    for cluster in clusters {
      cluster.initEntrancePaths()
      cluster.computeEntrancePaths()
    }
  }

  func createAbsGraphEdges() {
    absWorld?.createEdgesInClusters(clusters)
    absWorld?.createEdgesAcrossClusters(entrances)
  }

  /// Insert start, end nodes to abstract graph
  func addToAbsGraphStart(startRow: Int, _ startCol: Int,
    end endRow: Int, _ endCol: Int) -> (Int?, Int?)? {
      guard let startId = graph.nodeIdForPositionWithRow(startRow, col: startCol) else {
        assertionFailure("Cannot find start location in graph")
        return nil
      }

      guard let endId = graph.nodeIdForPositionWithRow(endRow, col: endCol) else {
        assertionFailure("Cannot find start location in graph")
        return nil
      }

      let absStart = absWorld?.insertNodeToAbsGraph(startId,
        atRow: startRow, col: startCol, index: 0)
      let absEnd = absWorld?.insertNodeToAbsGraph(endId,
        atRow: endRow, col: endCol, index: 1)
      return (absStart, absEnd)
  }

  func searchFromStart(startRow: Int, _ startCol: Int,
    toEnd endRow: Int, _ endCol: Int) {
      guard let (absStartId, absEndId) = addToAbsGraphStart(
        startRow, startCol, end: endRow, endCol) else {
          assertionFailure("Could not add start and end abs nodes.")
          return
      }

      absWorld?.searchPathFrom(absStartId!, to: absEndId!)
  }

}
