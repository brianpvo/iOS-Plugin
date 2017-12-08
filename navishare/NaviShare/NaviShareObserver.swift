//
//  NaviShareObserver.swift
//  NaviShare
//
//  Created by Joseph Chen on 12/8/17.
//  Copyright © 2017 Navisens. All rights reserved.
//

public protocol NaviShareObserver: class {
  func messageReceived(fromDevice deviceID: String, withMessage message: String)
  func roomOccupancyChanged(_ roomOccupancy: Dictionary<String, Int>)
  func serverCapacityExceeded()
  func roomCapacityExceeded()
}
