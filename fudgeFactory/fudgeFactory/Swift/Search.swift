//
//  Search.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 07/01/16.
//
//

import Foundation

/// ======= Search Graph =======

protocol SearchGraph {
  func getNodeById(nodeId: Int) -> GraphNode?
  func canMoveFrom(a: GraphNode, toAdjacent b: GraphNode) -> Bool
}

protocol Pathfinder {
  var lastPath: [Int]? { get }
  var lastPathCost: Float { get }
  func searchPathIn(graph: SearchGraph, from: Int, to: Int) -> [Int]?
  func checkPathExistsIn(graph: SearchGraph, from: Int, to: Int) -> Bool
}

final class Search {

  private let env: Environment
  private let graph: SearchGraph
  var pathfinder: Pathfinder?

  required init(env: Environment, graph: SearchGraph) {
    self.env = env
    self.graph = graph
  }

  convenience init (env: Environment, graph: SearchGraph, pathfinder: Pathfinder) {
    self.init(env: env, graph: graph)
    self.pathfinder = pathfinder
  }

  func path(from: Int, to: Int) -> [Int]? {
    assert(pathfinder != nil, "Nil Pathfinder")
    guard let pathfinder = pathfinder else {
      return nil
    }
    return pathfinder.searchPathIn(graph, from: from, to: to)
  }

  var pathCost: Float {
    guard let p = pathfinder else {
      return DIST_INFINITY
    }
    return p.lastPathCost
  }

  var path: [Int]? {
    return pathfinder?.lastPath
  }
}