//
//  Search.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 07/01/16.
//
//

import Foundation

protocol Pathfinder {
  var lastPath: [Int]? { get }
  var lastPathCost: Float { get }
  func searchPathIn(graph: Graph, from: Int, to: Int) -> [Int]?
  func checkPathExistsIn(graph: Graph, from: Int, to: Int) -> Bool
}

final class Search {

  private let env: Environment
  private let graph: Graph
  var pathfinder: Pathfinder?

  required init(env: Environment, graph: Graph) {
    self.env = env
    self.graph = graph
  }

  convenience init (env: Environment, graph: Graph, pathfinder: Pathfinder) {
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