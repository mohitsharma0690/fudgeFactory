//
//  AStar.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 06/01/16.
//
//

import Foundation

let DIST_INFINITY: Float = 1e8

class GraphAStarNode: AStarNode {
  var node: GraphNode
  var parent: Int?
  var g: Float = DIST_INFINITY
  var h: Float = DIST_INFINITY

  init(node: GraphNode) {
    self.node = node
  }

  var id: Int {
    return node.id
  }

  func reset() {
    g = DIST_INFINITY
    h = DIST_INFINITY
    parent = nil
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

  func startNewSearch() {
    openList.reset()
    closedList.reset()
  }

  func searchPathIn(world: World, from: Int, to: Int) -> [Int]? {
    startNewSearch()
    let graph = world.graph

    guard let targetNode = graph.getNodeById(to) where targetNode.isWalkable() else {
      return nil
    }
    guard var currNode = graph.getNodeById(from) else {
      return nil
    }
    var currAstarNode = world.astarNodeForGraphNode(currNode)
    currAstarNode.g = 0
    currAstarNode.h = env.heuristicBetween(currNode, b: targetNode)
    openList.addNode(currAstarNode)
    while !openList.isEmpty {
      currAstarNode = openList.pop()
      currNode = currAstarNode.node

      if currNode.id == to {
        guard let path = closedList.pathFrom(from, to: to) else {
          return nil
        }
        return path.map { $0.id }
      }

      for edge in currNode.graphEdges {
        let successor = edge.toNode
        let succGraphNode = graph.getNodeById(successor)!

        if !world.canMoveFrom(currNode, toAdjacent: succGraphNode) {
          continue
        }

        if closedList.nodeWithId(successor) != nil {
          continue
        }

        // check in open list
        if let successorNode = openList.nodeWithId(successor) {
          let newG = currAstarNode.g + edge.cost
          assert(successorNode.h < DIST_INFINITY - 1,
            "Heuristic not set for node in open list.")
          // Update distance to reach.
          if newG < successorNode.g {
            successorNode.g = newG
            successorNode.parent = currNode.id
            openList.didUpdateNode(successorNode)
          }
          
        } else {
          // Add to open list.
          let newSuccessorNode = world.astarNodeForGraphNode(succGraphNode)
          newSuccessorNode.g = currAstarNode.g + edge.cost
          newSuccessorNode.h = env.heuristicBetween(succGraphNode, b: targetNode)
          newSuccessorNode.parent = currNode.id
          openList.addNode(newSuccessorNode)
        }
      }

    }

    return nil
  }

  func checkPathExistsIn(world: World, from: Int, to: Int) -> Bool {
    return searchPathIn(world, from: from, to: to) != nil
  }
}
