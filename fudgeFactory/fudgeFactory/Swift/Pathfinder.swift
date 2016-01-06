//
//  Pathfinder.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 05/01/16.
//
//

import Foundation

protocol Pathfinder {
  func searchPathInWorld(world: World, from: Int, to: Int) -> [Int]?
  func checkPathExistsInWorld(world: World, from: Int, to: Int) -> Bool
}

protocol AStarNode : Comparable {
  var id: Int { get }
  var parent: Int { get set }
  var g: Int { get set }
  var h: Int { get set }
  var f: Int { get }
}

protocol OpenList {
  typealias N

  func isEmpty() -> Bool
  func addNode(node: N)
  func removeNodeWith(nodeId: Int) -> Bool
  // Returns the top most node from the open list
  func pop() -> N
  func searchNodeWith(nodeId: Int) -> N?
  var count: Int { get }
}

class OpenListArray<NODE: AStarNode> : OpenList {
  var list = [NODE]()

  func isEmpty() -> Bool {
    return list.isEmpty
  }

  var count: Int {
    return list.count
  }

  func addNode(node: NODE) {
    list.append(node)
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

  func searchNodeWith(nodeId: Int) -> NODE? {
    let l = list.filter { $0.id == nodeId }
    assert(l.count <= 1, "Multiple similar nodes in OpenList")
    guard l.count > 0 else {
      return nil
    }
    return l[0]
  }
}

/* class AStar : Pathfinder {

}
*/
