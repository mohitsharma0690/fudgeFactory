//
//  Pathfinder.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 05/01/16.
//
//

import Foundation

protocol Pathfinder {
  func searchPathIn(world: World, from: Int, to: Int) -> [Int]?
  func checkPathExistsIn(world: World, from: Int, to: Int) -> Bool
}

protocol AStarNode : Comparable {
  var id: Int { get }
  var parent: Int? { get set }
  var g: Int { get set }
  var h: Int { get set }
  var f: Int { get }
}

func ==<T: AStarNode>(lhs: T, rhs: T) -> Bool {
  return lhs.id == rhs.id
}

func <<T: AStarNode>(lhs: T, rhs: T) -> Bool{
  return lhs.f < rhs.f
}

extension AStarNode {
  var f: Int {
    return g + h
  }
}

enum OpenListImplType {
  case OpenListArray
}

protocol OpenList {
  typealias N
  var isEmpty: Bool { get }
  var count: Int { get }
  func addNode(node: N)
  func removeNodeWith(nodeId: Int) -> Bool
  // Returns the top most node from the open list
  func pop() -> N
  func nodeWithId(nodeId: Int) -> N?
}

class AnyOpenList<T> : OpenList {
  typealias N = T

  let _isEmpty: Bool
  let _count: Int
  let _addNode: (node: T) -> ()
  let _removeNodeWithId: (nodeId: Int) -> Bool
  let _pop: () -> T
  let _nodeWithId: (nodeId: Int) -> T?

  init<U: OpenList where U.N == T>(u: U) {
    _isEmpty = u.isEmpty
    _count = u.count
    _addNode = u.addNode
    _removeNodeWithId = u.removeNodeWith
    _pop = u.pop
    _nodeWithId = u.nodeWithId
  }

  var isEmpty: Bool { return _isEmpty }
  var count: Int { return _count }

  func addNode(node: N) {
    _addNode(node: node)
  }

  func removeNodeWith(nodeId: Int) -> Bool {
    return _removeNodeWithId(nodeId: nodeId)
  }

  func pop() -> T {
    return _pop()
  }

  func nodeWithId(nodeId: Int) -> T? {
    return _nodeWithId(nodeId: nodeId)
  }

}

class OpenListArray<NODE: AStarNode> : OpenList {
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

  func nodeWithId(nodeId: Int) -> NODE? {
    let l = list.filter { $0.id == nodeId }
    assert(l.count <= 1, "Multiple similar nodes in OpenList")
    guard l.count > 0 else {
      return nil
    }
    return l[0]
  }
}

enum ClosedListImplType {
  case ClosedListArray
}

protocol ClosedList {
  typealias N
  var isEmpty: Bool { get }
  func nodeWithId(nodeId: Int) -> N?
  func add(node: N)
  func remove(node: N) -> Bool

  func pathFrom(from: Int, to: Int) -> [N]?
}

extension ClosedList where N: AStarNode {

  func pathFrom(from:Int, to: Int) -> [Self.N]? {
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
    var path = Array<N>()
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

}
