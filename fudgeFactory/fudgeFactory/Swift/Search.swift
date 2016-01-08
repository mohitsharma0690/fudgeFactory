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
  func searchPathIn(world: World, from: Int, to: Int) -> [Int]?
  func checkPathExistsIn(world: World, from: Int, to: Int) -> Bool
}

final class Search {

  private let env: Environment
  private let world: World
  var pathfinder: Pathfinder?

  required init(env: Environment, world: World) {
    self.env = env
    self.world = world
  }

  func path(from: Int, to: Int) -> [Int]? {
    assert(pathfinder != nil, "Nil Pathfinder")
    guard let pathfinder = pathfinder else {
      return nil
    }
    return pathfinder.searchPathIn(world, from: from, to: to)
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