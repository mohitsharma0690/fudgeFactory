//
//  AStar.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 06/01/16.
//
//

import Foundation

let DIST_INFINITY = 1<<30

class GraphAStarNode: AStarNode {
  var node: GraphNode
  var parent: Int?
  var g: Int = DIST_INFINITY
  var h: Int = DIST_INFINITY

  init(node: GraphNode) {
    self.node = node
  }

  var id: Int {
    return node.id
  }
}

class AStar : Pathfinder {

  private var env: Environment
  private var openList: AnyOpenList<GraphAStarNode>
  private var closedList: AnyClosedList<GraphAStarNode>

  init(env: Environment) {
    self.env = env
    switch env.openListImpl {
    case OpenListImplType.OpenListArray:
      openList = AnyOpenList(OpenListArray<GraphAStarNode>())
    }

    switch env.closedListImpl {
    case ClosedListImplType.ClosedListArray:
      closedList = AnyClosedList(ClosedListArray<GraphAStarNode>())
    }
  }

  func searchPathIn(world: World, from: Int, to: Int) -> [Int]? {
    return nil
  }

  func checkPathExistsIn(world: World, from: Int, to: Int) -> Bool {
    return searchPathIn(world, from: from, to: to) != nil
  }
}
