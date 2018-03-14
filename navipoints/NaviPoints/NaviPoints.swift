//
//  NaviPoints.swift
//  NaviPoints
//
//  Created by Joseph Chen on 2/15/18.
//  Copyright © 2018 Navisens. All rights reserved.
//

import MotionDnaSDK
import NavisensCore

public class NaviPoints: NavisensPlugin {
  // MARK: Properties
  private var locations = Dictionary<String, NaviPointCoord>()
  
  private var lastHeading = 0.0
  private var core: NavisensCore?
  private var mapsExists = false
  
  private static let PLUGIN_IDENTIFIER = "com.navisens.pojostick.navipoints",
                     MAPS_IDENTIFIER = "com.navisens.pojostick.navisensmaps",
                     OPERATION_ADD = 1,
                     OPERATION_REMOVE = 2
  
  // MARK: Initializers
  required public init() {
    super.init()
  }
  
  override public func initialize(usingCore core: NavisensCore, andArgs args: [Any]) -> Bool {
    self.core = core
    
    core.subscribe(self, to: NavisensCore.MOTION_DNA | NavisensCore.PLUGIN_DATA)
    core.broadcast(NaviPoints.PLUGIN_IDENTIFIER, operation: NavisensCore.OPERATION_INIT)
    
    return true
  }
  
  // MARK: Interface
  public func add(_ id: String, atLocation latitude: Double, _ longitude: Double) {
    add(id, atLocation: latitude, longitude, withHeading: nil)
  }

  public func add(_ id: String, atLocation latitude: Double, _ longitude: Double, withHeading heading: Double?) {
    add(id, atLocation: latitude, longitude, withHeading: nil, andFloor: nil)
  }

  public func add(_ id: String, atLocation latitude: Double, _ longitude: Double, withHeading heading: Double?, andFloor floor: Int?) {
    let coord = NaviPointCoord(latitude, longitude, heading, floor)
    locations[id] = coord
    if (mapsExists) {
      sendPoint(NaviPoints.OPERATION_ADD, id: id, lat: latitude, lng: longitude)
    }
  }
  
  public func remove(_ id: String) {
    locations.removeValue(forKey: id)
  }
  
  public func setLocation(_ id: String) {
    if let coord = locations[id] {
      self.core?.motionDna?.setLocationLatitude(coord.latitude, longitude: coord.longitude, andHeadingInDegrees: self.lastHeading)
      if let heading = coord.heading {
        self.core?.motionDna?.setHeadingInDegrees(heading)
      }
      if let floor = coord.floor {
        self.core?.motionDna?.setFloorNumber(Int32(floor))
      }
      core?.settings.overrideEstimationMode(LOCAL)
    }
  }
  
  private func sendPoint(_ operation: Int, id: String, lat: Double, lng: Double) {
    if let core = self.core {
      core.broadcast(NaviPoints.PLUGIN_IDENTIFIER, operation: operation, data: id, lat, lng)
    }
  }
  
  // MARK: Overrides
  
  override public func stop() -> Bool {
    core!.remove(self)
    core!.broadcast(NaviPoints.PLUGIN_IDENTIFIER, operation: NavisensCore.OPERATION_STOP);
    return true
  }
  
  override public func receiveMotionDna(_ motionDna: MotionDna!) throws {
    lastHeading = motionDna.getLocation().heading
  }
  
  override public func receivePluginData(_ tag: String, operation: Int, data: [Any]) throws {
    switch tag {
    case NaviPoints.MAPS_IDENTIFIER:
      mapsExists = true;
      switch operation {
      case NavisensCore.OPERATION_INIT:
        fallthrough
      case NavisensCore.OPERATION_ACK where data.first as? String == NaviPoints.PLUGIN_IDENTIFIER:
        for (name, coord) in locations {
          sendPoint(NaviPoints.OPERATION_ADD, id: name, lat: coord.latitude, lng: coord.longitude);
        }
      case NavisensCore.OPERATION_STOP:
        mapsExists = false
      default:
        break
      }
    default:
      break
    }
  }
  
  // MARK: NaviPointCoord
  
  public class NaviPointCoord {
    public var latitude: Double, longitude: Double, heading: Double?, floor: Int?
    
    init(_ latitude: Double, _ longitude: Double, _ heading: Double?, _ floor: Int?) {
      self.latitude = latitude
      self.longitude = longitude
      self.heading = heading
      self.floor = floor
    }
  }
}
