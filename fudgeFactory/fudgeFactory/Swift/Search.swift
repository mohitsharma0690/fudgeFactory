//
//  Search.swift
//  fudgeFactory
//
//  Created by Mohit Sharma on 07/01/16.
//
//

import Foundation

protocol Pathfinder {
  func searchPathIn(world: World, from: Int, to: Int) -> [Int]?
  func checkPathExistsIn(world: World, from: Int, to: Int) -> Bool
}
