//
//  NavisensPlugin.swift
//  NavisensCore
//
//  Created by Joseph Chen on 10/12/17.
//  Copyright © 2017 Navisens. All rights reserved.
//

import MotionDnaSDK

open class NavisensPlugin : Hashable {
  enum NavisensError: Error {
    case Unimplemented(String)
  }
  
  public static var pluginDescriptor: Int = 1
  
  open var hashValue: Int
  
  open static func ==(lhs: NavisensPlugin, rhs: NavisensPlugin) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
  
  required public init() {
    self.hashValue = NavisensPlugin.pluginDescriptor
    NavisensPlugin.pluginDescriptor += 1
  }
  open func initialize(usingCore core: NavisensCore, andArgs args: [Any]) throws -> Bool {
    throw NavisensError.Unimplemented("NavisensPlugin used but missing implementation for initialize.")
  }
  open func stop() throws -> Bool {
    throw NavisensError.Unimplemented("NavisensPlugin used but missing implementation for stop.")
  }
  open func receiveMotionDna(_ motionDna: MotionDna!) throws {
    throw NavisensError.Unimplemented("NavisensPlugin used but missing implementation for receiveMotionDna.")
  }
  open func receiveNetworkData(_ motionDna: MotionDna!) throws {
    throw NavisensError.Unimplemented("NavisensPlugin used but missing implementation for receiveNetworkData.")
  }
  open func receiveNetworkData(_ networkCode: NetworkCode, withPayload map: Dictionary<AnyHashable, Any>) throws {
    throw NavisensError.Unimplemented("NavisensPlugin used but missing implementation for receiveNetworkData.")
  }
  open func receivePluginData(_ tag: String, data: Any) throws {
    throw NavisensError.Unimplemented("NavisensPlugin used but missing implementation for receivePluginData.")
  }
  open func reportError(_ errorCode: ErrorCode, withMessage s: String) throws {
    throw NavisensError.Unimplemented("NavisensPlugin used but missing implementation for reportError.")
  }
}
