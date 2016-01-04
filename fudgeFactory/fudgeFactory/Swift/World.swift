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

  var graph: Graph
  var absGraphs: [AbsGraph] = []

  var env: Environment

  init(env: Environment, graph: Graph) {
    self.env = env
    self.graph = graph
  }

  func createAbstractGraph() {
    // create clusters
    createClusters()
    // create entrances in clusters
    // create the abstract graph using each local entrance as two nodes in the abstract
    // graph
    // find and cache paths between entrances in clusters
  }

  private func createClusters() {
    var clusterId = 0
    var entranceId = 0
    var row = 0, col = 0
    var clusters: [Cluster] = []
    // Clusters by id
    // |6|7|8|
    // |3|4|5|
    // |0|1|2|
    for currCol in 0.stride(to: graph.height, by: CLUSTER_HEIGHT) {
      col = 0
      for currRow in 0.stride(to: graph.width, by: CLUSTER_WIDTH) {
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

    var entrancePoints = [Point]()
    for cluster in clusters {
      let allEntrancePoints = cluster.entrances.reduce([Point]()) {
        (var points: [Point], e: Entrance) -> [Point] in
        if !e.isHorizontal {
          return points;
        }
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

}
