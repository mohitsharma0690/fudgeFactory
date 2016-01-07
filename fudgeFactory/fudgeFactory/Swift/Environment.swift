//
//  Environment.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 29/12/15.
//
//

import Foundation

class Environment: NSObject {

  enum HeuristicType {
    case Manhattan
    case Euclidean
    case EuclideanSquared

    func distanceBetween(a: GraphNode, b: GraphNode) -> Float {
      let rowX = a.row - b.row
      let rowY = a.col - b.col
      switch self {
      case .Manhattan:
        return Float(abs(rowX) + abs(rowY))

      case .Euclidean:
        return sqrtf(Float(rowX * rowX + rowY * rowY))

      case .EuclideanSquared:
        return Float(rowX * rowX + rowY * rowY)
      }
    }

  }

  var DEBUG_COLOR_ENTRANCES = false
  let heuristicType = HeuristicType.Manhattan

  var openListImpl = OpenListImplType.OpenListArray
  var closedListImpl = ClosedListImplType.ClosedListArray
  
  func heuristicBetween(a: GraphNode, b: GraphNode) -> Float {
    return heuristicType.distanceBetween(a, b: b)
  }

}