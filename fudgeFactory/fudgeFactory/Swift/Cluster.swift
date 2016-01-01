//
//  Cluster.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 30/12/15.
//
//

import Foundation

let CLUSTER_WIDTH: Int = 10
let CLUSTER_HEIGHT: Int = 10

class Entrance {
  var id: Int
  var row: Int
  var col: Int
  var cluster1Id: Int
  var cluster2Id: Int
  var centerRow: Int
  var centerCol: Int
  var len: Int
  var isHorizontal: Bool

  init(id: Int, row: Int, col: Int, cluster1Id: Int,
    cluster2Id: Int, centerRow: Int, centerCol: Int,
    len: Int, isHorizontal: Bool) {
      self.id = id
      self.row = row
      self.col = col
      self.cluster1Id = cluster1Id
      self.cluster2Id = cluster2Id
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

}

class Cluster {
  var id: Int
  var startRow: Int
  var startCol: Int
  var width: Int
  var height: Int
  var entrances: [Entrance]

  init(id: Int, row: Int, col: Int, width: Int, height: Int, entrances: [Entrance]) {
    self.id = id
    self.startRow = row
    self.startCol = col
    self.width = width
    self.height = height
    self.entrances = entrances
  }

}