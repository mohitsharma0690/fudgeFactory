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

  init(id: Int, absNodeId: Int, centerRow: Int,
    centerCol: Int, len: Int) {
    self.id = id
    self.absNodeId = absNodeId
    self.centerRow = centerRow
    self.centerCol = centerCol
    self.len = len
  }

  func description() -> String {
    return "id: \(id), absNodeId: \(absNodeId), row: \(centerRow), " +
           "col: \(centerCol), len: \(len)"
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
    center1Id: Int, center2Id: Int, len: Int,
    isHorizontal: Bool) {
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
  private let graph: Graph
  private let env: Environment
  var id: Int
  var startRow: Int
  var startCol: Int
  var width: Int
  var height: Int
  private(set) var entrances = [ClusterEntrance]()
  private(set) var entrancePaths = [Int: [Int]]()
  var entranceDists = [[Float]]()

  lazy var search: Search = {
    [unowned self] in
    return self.env.initNewSearchWithGraph(self.graph)
  } ()

  init(id: Int, env: Environment, graph: Graph, row: Int,
    col: Int, width: Int, height: Int) {
    self.id = id
    self.env = env
    self.graph = graph
    self.startRow = row
    self.startCol = col
    self.width = width
    self.height = height
  }

  /// Returns local center for the cluster entrance.
  func centerForEntrance(e: ClusterEntrance) -> Int {
    return (e.centerRow - startRow) * width + (e.centerCol - startCol)
  }

  func entranceAtRow(row: Int, col: Int) -> ClusterEntrance? {
    let e = entrances.filter {
      $0.centerRow == row && $0.centerCol == col
    }
    return e.first
  }

  func initEntrancePaths() {
    guard entrances.count > 0 else {
      return
    }
    entranceDists = createDistsArray(entrances.count)
  }

  func resizeEntrancePaths() {
    guard entranceDists.count < entrances.count else {
      NSLog("Entrance paths don't need resizing.")
      return;
    }
    guard entrances.count - entranceDists.count == 1 else {
      assertionFailure("Invalid resizing.")
      return
    }

    var newDists = [[Float]]()
    for dists in entranceDists {
      var d = dists  // creates a copy
      d.append(DIST_INFINITY)
      newDists.append(d)
    }
    newDists.append(Array<Float>(count: entrances.count,
      repeatedValue: DIST_INFINITY))
    entranceDists = newDists
  }

  func createDistsArray(count: Int) -> [[Float]] {
    var dists = [[Float]]()
    for _ in 0..<count {
      dists.append(Array<Float>(count: count,
        repeatedValue: DIST_INFINITY))
    }
    return dists
  }

  func computeEntrancePaths() {
    for (i, entrance) in entrances.enumerate() {
      computeEntrancePathFrom(entrance, atIndex: i) { i < $0 }
    }
  }

  func recomputeEntrancePathsFrom(entrance: ClusterEntrance) {
    guard let idx = entrances.indexOf({ $0.id == entrance.id }) else {
      assertionFailure("Cannot find cluster entrance \(entrance)")
      return
    }
    computeEntrancePathFrom(entrance, atIndex: idx) { idx != $0 }
  }

  /// Compute entrance paths only for entrances which return true from
  /// the filter.
  func computeEntrancePathFrom(entrance: ClusterEntrance,
    atIndex index: Int, filter: Int -> Bool) {
    for (j, entrance2) in entrances.enumerate() {
      if filter(j) {
        let (dist, path) = computePathBetweenEntrance(entrance,
          and: entrance2)
        entranceDists[index][j] = dist
        setCachedPath(path, betweenIndex: index, j)
        entranceDists[j][index] = dist
        setCachedPath(path?.reverse(), betweenIndex: j, index)
      }
    }
  }

  func computePathBetweenEntrance(e1: ClusterEntrance,
    and e2: ClusterEntrance) -> (Float, [Int]?) {
    let center1 = centerForEntrance(e1)
    let center2 = centerForEntrance(e2)

    let path = search.path(center1, to: center2)
    if path != nil {
      return (search.pathCost, path)
    }
    return (DIST_INFINITY, nil)
  }

  /// Returns the cached path between entrances. The path contains
  /// indexes of both start and end.
  func cachedPathBetweenEntrance(e1: ClusterEntrance, _ e2: ClusterEntrance) -> [Int]? {
    let idx1 = entrances.indexOf { $0.id == e1.id }
    let idx2 = entrances.indexOf { $0.id == e2.id }
    return cachedPathBetweenEntranceIndex(idx1!, j: idx2!)
  }

  func cachedPathBetweenEntranceIndex(i: Int, j: Int) -> [Int]? {
    return entrancePaths[cachePathKeyFor(i, j: j)]
  }

  /// returns DIST_INFINITY if there is no path between the
  /// two entrances.
  func cachedPathDistBetweenEntranceIndex(i: Int, j: Int) -> Float {
    return entranceDists[i][j]
  }

  func costBetweenEntrances(e1: ClusterEntrance,
    _ e2: ClusterEntrance) -> Float {
    let idx1 = entrances.indexOf { $0.id == e1.id }
    let idx2 = entrances.indexOf { $0.id == e2.id }
    return cachedPathDistBetweenEntranceIndex(idx1!, j:idx2!)
  }

  func setCachedPath(path: [Int]?, betweenIndex i: Int, _ j: Int) {
    if let p = path {
      entrancePaths[cachePathKeyFor(i, j: j)] = p
    }
  }

  func cachePathKeyFor(i: Int, j:Int) -> Int {
    assert(entrances.count < 31)
    return i * 31 + j
  }

  func isEntrance(e1: ClusterEntrance,
    connectedWith e2: ClusterEntrance) -> Bool {
    return costBetweenEntrances(e1, e2) != DIST_INFINITY
  }

  func addClusterEntrance(clusterEntrance: ClusterEntrance) {
    entrances.append(clusterEntrance)
  }

  func addClusterEntrances(ce: [ClusterEntrance]) {
    entrances.appendContentsOf(ce)
  }

  func convertPath(path: [Int], toGlobalGraph graph: Graph) -> [Int] {
    return path.map {
      graph.width * startRow + startCol + /* convert cluster */
        ($0 / width) * graph.width + ($0 % width)
    }
  }

}
