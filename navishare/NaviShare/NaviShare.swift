//
//  NaviShare.swift
//  NaviShare
//
//  Created by Joseph Chen on 12/8/17.
//  Copyright © 2017 Navisens. All rights reserved.
//

import UIKit
import WebKit
import MotionDnaSDK
import NavisensCore

public class NaviShare: NavisensPlugin {
  // MARK: Properties
  let queryInterval = DispatchTimeInterval.milliseconds(500)
  let queue = DispatchQueue.main
  private var host = ""
  private var port = ""
  private var room = ""
  private var changed = false
  private var configured = false
  private var connected = false
  
  private var core: NavisensCore?
  
  private var rooms = Set<String>()
  private var observers = [NaviShareObserver]()
  private var roomsQueriedAt = DispatchTime.now()

  // MARK: Initializers
  required public init() {
  }
  
  override public func initialize(usingCore core: NavisensCore, andArgs args: [Any]) -> Bool {
    self.core = core
    
    core.settings.requestNetworkRate(100)
    
    core.subscribe(self, to: NavisensCore.NETWORK_DATA)
    
    return true
  }
  
  // MARK: Interface
  
  public func configureHost(_ host: String, andPort port: String) -> NaviShare {
    core!.settings.overrideHost(nil, andPort: nil)
    
    self.host = host
    self.port = port
    self.changed = true
    self.configured = true
    
    return self
  }
  
  public func connectToRoom(_ room: String) -> Bool {
    core!.settings.overrideRoom(nil)
    
    if configured {
      if connected && !changed {
        core!.motionDna?.setUDPRoom(room)
      } else {
        self.disconnect()
        core!.motionDna?.startUDPRoom(room, atHost: host, andPort: port)
        connected = true
      }
      changed = false
    }
    
    return true
  }
  
  public func disconnect() {
    core!.motionDna?.stopUDP()
    connected = false
  }
  
  public func testConnect() -> Bool {
    if !connected {
      self.disconnect()
      core!.motionDna?.startUDP()
      connected = true
      return true
    }
    return false
  }
  
  public func sendMessage(_ msg: String) {
    if connected {
      core!.motionDna?.sendUDPPacket(msg)
    }
  }
  
  public func addObserver(_ observer: NaviShareObserver) {
    observers.append(observer)
  }
  
  public func removeObserver(_ observer: NaviShareObserver) {
    observers = observers.filter { $0 !== observer }
  }
  
  public func trackRoom(_ room: String) -> Bool {
    return rooms.insert(room).0
  }
  
  public func untrackRoom(_ room: String) -> Bool {
    return rooms.remove(room) != nil
  }
  
  public func refreshRoomStatus() -> Bool {
    let now = DispatchTime.now()
    let when: DispatchTime = roomsQueriedAt + queryInterval
    if connected && now.rawValue >= when.rawValue {
      roomsQueriedAt = now
      self.core?.motionDna?.sendUDPQueryRooms(NSMutableArray(array: Array(rooms)))
      return true
    }
    return false
  }
  
  // MARK: Overrides
  
  override public func stop() -> Bool {
    self.disconnect()
    core!.remove(self)
    return true
  }
  
  override public func receiveNetworkData(_ networkCode: NetworkCode, withPayload map: Dictionary<AnyHashable, Any>) throws {
    switch (networkCode) {
    case RAW_NETWORK_DATA:
      observers.forEach({ observer in
        observer.messageReceived(fromDevice: map["ID"] as! String, withMessage: map["payload"] as! String)
      })
    case ROOM_CAPACITY_STATUS:
      observers.forEach({ observer in
        observer.roomOccupancyChanged(map as! Dictionary<String, Int>)
      })
    case EXCEEDED_ROOM_CONNECTION_CAPACITY:
      observers.forEach({ observer in
        observer.roomCapacityExceeded()
      })
      self.disconnect()
    case EXCEEDED_SERVER_ROOM_CAPACITY:
      observers.forEach({ observer in
        observer.serverCapacityExceeded()
      })
      self.disconnect()
    default:
      break
    }
  }
}
