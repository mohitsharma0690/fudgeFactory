//
//  Environment.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 29/12/15.
//
//

import Foundation

class Environment: NSObject {

  var DEBUG_COLOR_ENTRANCES = false

  var openListImpl = OpenListImplType.OpenListArray
  var closedListImpl = ClosedListImplType.ClosedListArray
  
  func heuristicBetweenStart(start: Node, target: Node) -> Int {
    return 0
  }

}