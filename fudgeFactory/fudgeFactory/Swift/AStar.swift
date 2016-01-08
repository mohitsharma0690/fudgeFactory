//
//  AStar.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 06/01/16.
//
//

import Foundation

/// ======= Nodes =======

protocol AStarNode : Comparable {
  var id: Int { get }
  var parent: Int? { get set }
  var g: Float { get set }  // Actual distance
  var h: Float { get set }  // Heuristic distance
  var f: Float { get }
  func reset()
}

func ==<T: AStarNode>(lhs: T, rhs: T) -> Bool {
  return lhs.id == rhs.id
}

func <<T: AStarNode>(lhs: T, rhs: T) -> Bool{
  return lhs.f < rhs.f
}

extension AStarNode {
  var f: Float {
    return g + h
  }
}

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

/// ======= Open List =======

enum OpenListImplType {
  case OpenListArray
}

protocol OpenList {
  typealias ItemType
  var isEmpty: Bool { get }
  var count: Int { get }
  func addNode(node: ItemType)
  func removeNodeWith(nodeId: Int) -> Bool
  /// Returns the top most node from the open list
  func pop() -> ItemType
  /// Did update node in OpenList. Maybe reheapify or something.
  func didUpdateNode(node: ItemType)
  func nodeWithId(nodeId: Int) -> ItemType?
  func reset()
}

class AnyOpenList<T> : OpenList {
  typealias ItemType = T

  let _isEmpty: Bool
  let _count: Int
  let _addNode: (T -> Void)
  let _removeNodeWithId: (Int -> Bool)
  let _pop: (Void -> T)
  let _didUpateNode: (T -> Void)
  let _nodeWithId: (Int -> T?)
  let _reset: Void -> Void

  init<U: OpenList where U.ItemType == T>(_ u: U) {
    _isEmpty = u.isEmpty
    _count = u.count
    _addNode = u.addNode
    _removeNodeWithId = u.removeNodeWith
    _pop = u.pop
    _didUpateNode = u.didUpdateNode
    _nodeWithId = u.nodeWithId
    _reset = u.reset
  }

  var isEmpty: Bool { return _isEmpty }
  var count: Int { return _count }

  func addNode(node: T) {
    _addNode(node)
  }

  func removeNodeWith(nodeId: Int) -> Bool {
    return _removeNodeWithId(nodeId)
  }

  func pop() -> T {
    return _pop()
  }

  func didUpdateNode(node: T) {
    _didUpateNode(node)
  }

  func nodeWithId(nodeId: Int) -> T? {
    return _nodeWithId(nodeId)
  }

  func reset() {
    _reset()
  }
}

class OpenListArray<NODE: AStarNode> : OpenList {
  typealias N = NODE
  var list = [NODE]()

  var isEmpty: Bool {
    return list.isEmpty
  }

  var count: Int {
    return list.count
  }

  func addNode(node: NODE) {
    list.append(node)
  }

  func addNodes(nodes: [NODE]) {
    list.appendContentsOf(nodes)
  }

  func removeNodeWith(nodeId: Int) -> Bool {
    let nodeIdx = list.indexOf {
      $0.id == nodeId
    }
    guard let idx = nodeIdx else {
      return false
    }
    list.removeAtIndex(idx)
    return true
  }

  func pop() -> NODE {
    let node = list.minElement()
    if let n = node {
      list.removeAtIndex(list.indexOf(n)!)
    }
    return node!
  }

  func didUpdateNode(node: NODE) {
    // Do nothing.
  }

  func nodeWithId(nodeId: Int) -> NODE? {
    let l = list.filter { $0.id == nodeId }
    assert(l.count <= 1, "Multiple similar nodes in OpenList")
    guard l.count > 0 else {
      return nil
    }
    return l[0]
  }

  func reset() {
    for node in list {
      node.reset()
    }
    list.removeAll()
  }
  
}

/// ======= Open List =======

enum ClosedListImplType {
  case ClosedListArray
}

protocol ClosedList {
  typealias ItemType
  var isEmpty: Bool { get }
  func nodeWithId(nodeId: Int) -> ItemType?
  func add(node: ItemType)
  func remove(node: ItemType) -> Bool
  func pathFrom(from: Int, to: Int) -> [ItemType]?
  func reset()
}

class AnyClosedList<T> : ClosedList {
  typealias ItemType = T

  let _isEmpty: Bool
  let _nodeWithId: (Int -> T?)
  let _add: (ItemType -> Void)
  let _remove: (ItemType -> Bool)
  let _pathFrom: (Int, Int) -> [ItemType]?
  let _reset: Void -> Void

  init<U: ClosedList where U.ItemType == T>(_ u: U) {
    _isEmpty = u.isEmpty
    _nodeWithId = u.nodeWithId
    _add = u.add
    _remove = u.remove
    _pathFrom = u.pathFrom
    _reset = u.reset
  }

  var isEmpty: Bool { return _isEmpty }

  func nodeWithId(nodeId: Int) -> T? {
    return _nodeWithId(nodeId)
  }

  func add(node: ItemType) {
    return _add(node)
  }

  func remove(node: ItemType) -> Bool {
    return _remove(node)
  }

  func pathFrom(from: Int, to: Int) -> [T]? {
    return _pathFrom(from, to)
  }

  func reset() {
    _reset()
  }
}

extension ClosedList where ItemType: AStarNode {

  func pathFrom(from:Int, to: Int) -> [ItemType]? {
    guard from != to else {
      return []
    }
    // If from doesn't exist return nil.
    let fromNode = nodeWithId(from)
    guard let f_node = fromNode else {
      return nil
    }
    // If to doesn't exist return nil.
    var currNode = nodeWithId(to)
    guard var node = currNode else {
      return nil
    }
    var path = Array<ItemType>()
    while from != node.id {
      path.append(node)
      guard let parent = node.parent else {
        return nil
      }
      currNode = nodeWithId(parent)
      if currNode == nil {
        return nil
      }
      node = currNode!
    }

    path.append(f_node)
    return path.reverse()
  }
}

class ClosedListArray<NODE: AStarNode> : ClosedList {
  var list = [NODE]()

  var isEmpty: Bool {
    return list.isEmpty
  }

  func add(node: NODE) {
    list.append(node)
  }

  func nodeWithId(nodeId: Int) -> NODE? {
    let nodes = list.filter { $0.id == nodeId }
    guard nodes.count > 0 else {
      return nil
    }
    assert(nodes.count == 1)
    return nodes[0]
  }

  func remove(node: NODE) -> Bool {
    let nodeIdx = list.indexOf(node)
    guard let idx = nodeIdx else {
      return false
    }
    list.removeAtIndex(idx)
    return true
  }

  func reset() {
    for node in list {
      node.reset()
    }
    list.removeAll()
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
