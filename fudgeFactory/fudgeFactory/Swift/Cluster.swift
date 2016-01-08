//
//  Cluster.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 30/12/15.
//
//

import Foundation

// For more realistic grids this should be larger.
let CLUSTER_WIDTH: Int = 5
let CLUSTER_HEIGHT: Int = 5

struct ClusterEntrance {
  var id: Int
  var absNodeId: Int
  var centerRow: Int
  var centerCol: Int
  var len: Int

  init(id: Int, absNodeId: Int, centerRow: Int, centerCol: Int, len: Int) {
    self.id = id
    self.absNodeId = absNodeId
    self.centerRow = centerRow
    self.centerCol = centerCol
    self.len = len
  }

}

class Entrance {
  var id: Int
  var row: Int
  var col: Int
  var cluster1Id: Int
  var cluster2Id: Int
  var center1Id: Int
  var center2Id: Int
  var centerRow: Int
  var centerCol: Int
  var len: Int
  var isHorizontal: Bool

  init(id: Int, row: Int, col: Int, cluster1Id: Int,
    cluster2Id: Int, centerRow: Int, centerCol: Int,
    center1Id: Int, center2Id: Int, len: Int, isHorizontal: Bool) {
      self.id = id
      self.row = row
      self.col = col
      self.cluster1Id = cluster1Id
      self.cluster2Id = cluster2Id
      self.center1Id = center1Id
      self.center2Id = center2Id
      self.centerRow = centerRow
      self.centerCol = centerCol
      self.len = len
      self.isHorizontal = isHorizontal
  }

  func description() -> String {
    return "Entrance \(id) at (\(row), \(col)) for clusters: " +
           "\(cluster1Id) and \(cluster2Id), center: " +
           "(\(centerRow), \(centerCol)), length: \(len)," +
           "isHorizontal: \(isHorizontal)"
  }

  var center1Row: Int {
    return centerRow
  }

  var center1Col: Int {
    return centerCol
  }

  var center2Row: Int {
    if isHorizontal {
      return centerRow + 1
    } else {
      return centerRow
    }
  }

  var center2Col: Int {
    if isHorizontal {
      return centerCol
    } else {
      return centerCol + 1
    }
  }

}

class Cluster {
  private let world: World
  var id: Int
  var startRow: Int
  var startCol: Int
  var width: Int
  var height: Int
  private(set) var entrances: [Entrance] = []
  private(set) var clusterEntrances = [ClusterEntrance]()
  private(set) var entrancePaths = [Int: [Int]]()
  var entranceDists = [[Float]]()

  init(id: Int, world: World, row: Int, col: Int, width: Int, height: Int) {
    self.id = id
    self.startRow = row
    self.startCol = col
    self.width = width
    self.height = height
    self.world = world
  }

  func centerForEntrance(e: ClusterEntrance) -> Int {
    return e.centerRow * width + e.centerCol
  }

  func initEntrancePaths() {
    guard clusterEntrances.count > 0 else {
      return
    }

    for _ in 0..<clusterEntrances.count {
      entranceDists.append(Array<Float>(count: clusterEntrances.count,
        repeatedValue: DIST_INFINITY))
    }
  }

  func computeEntrancePaths() {
    for i in 0..<clusterEntrances.count {
      for j in 0..<clusterEntrances.count {
        if i != j {
          let (dist, path) = computePathBetweenEntrance(clusterEntrances[i],
            and: clusterEntrances[j])
          entranceDists[i][j] = dist
          setCachedPath(path, betweenIndex: i, j)
        }
      }
    }
  }

  func computePathBetweenEntrance(e1: ClusterEntrance, and e2: ClusterEntrance) -> (Float, [Int]?) {
    let center1 = centerForEntrance(e1)
    let center2 = centerForEntrance(e2)
    if let search = world.search {
      let path = search.path(center1, to: center2)
      if path != nil {
        return (search.pathCost, path)
      }
    }
    return (DIST_INFINITY, nil)
  }

  func cachedPathBetweenEntranceIndex(i: Int, j: Int) -> [Int]? {
    return entrancePaths[cachePathKeyFor(i, j: j)]
  }

  func setCachedPath(path: [Int]?, betweenIndex i: Int, _ j: Int) {
    if let p = path {
      entrancePaths[cachePathKeyFor(i, j: j)] = p
    }
  }

  func cachePathKeyFor(i: Int, j:Int) -> Int {
    assert(self.clusterEntrances.count < 31)
    return i * 31 + j
  }

  func addEntrance(entrance: Entrance) {
    entrances.append(entrance)
  }

  func addEntrances(e: [Entrance]) {
    entrances.appendContentsOf(e)
  }

  func addClusterEntrance(clusterEntrance: ClusterEntrance) {
    clusterEntrances.append(clusterEntrance)
  }

  func addClusterEntrances(ce: [ClusterEntrance]) {
    clusterEntrances.appendContentsOf(ce)
  }

}