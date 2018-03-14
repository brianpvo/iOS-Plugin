//
//  NaviBeacon.swift
//  NaviBeacon
//
//  Created by Joseph Chen on 2/7/18.
//  Copyright © 2018 Navisens. All rights reserved.
//

import UIKit
import WebKit
import CoreLocation
import MotionDnaSDK
import NavisensCore

public class NaviBeacon: NavisensPlugin {
  // MARK: Properties
  
  public static let PLUGIN_IDENTIFIER = "com.navisens.pojostick.navibeacon",
                    MAPS_IDENTIFIER = "com.navisens.pojostick.navisensmaps",
                    OPERATION_ADD = 1;
  
  private var lastHeading = 0.0
  private var resetRequired = 0
  private var mapsExists = false
  
  public lazy var defaultOnBeaconChanged: (CLBeacon, NaviBeaconData) -> () = { [unowned self] beacon, data in
    let RESET_DURATION = 5
    
    switch (beacon.proximity) {
    case .immediate:
      if self.resetRequired == 0 {
        self.resetRequired = RESET_DURATION
        if let latitude = data.latitude, let longitude = data.longitude {
          self.core?.motionDna?.setLocationLatitude(latitude, longitude: longitude, andHeadingInDegrees: self.lastHeading)
        }
        if let heading = data.heading {
          self.core?.motionDna?.setHeadingInDegrees(heading)
        }
        if let floor = data.floor {
          self.core?.motionDna?.setFloorNumber(Int32(floor))
        }
        self.core?.settings.overrideEstimationMode(LOCAL)
      }
    case .near:
      if self.resetRequired > 0 {
        self.resetRequired -= 1;
      }
    default:
      break
    }
  }
  public var onBeaconChanged: ((CLBeacon, NaviBeaconData) -> ())?
  
  let locationManager = CLLocationManager()

  private var beaconDelegate: NaviBeaconDelegate! = nil
  private var beacons = [UUID: NaviBeaconData]()
  private var ranging = true

  private var core: NavisensCore?
  
  // MARK: Initializers
  required public init() {
    super.init()
    beaconDelegate = NaviBeaconDelegate(self)
    onBeaconChanged = defaultOnBeaconChanged
  }
  
  override public func initialize(usingCore core: NavisensCore, andArgs args: [Any]) -> Bool {
    self.core = core
    
    core.subscribe(self, to: NavisensCore.MOTION_DNA | NavisensCore.PLUGIN_DATA)
    core.broadcast(NaviBeacon.PLUGIN_IDENTIFIER, operation: NavisensCore.OPERATION_INIT)
    
    locationManager.requestAlwaysAuthorization()
    locationManager.delegate = beaconDelegate!
    
    return true
  }
  
  // MARK: Interface
  
  public func addBeacon(identifier: String, uuid: UUID, latitude: Double?, longitude: Double?, heading: Double?, floor: Int?) -> NaviBeacon {
    let region = CLBeaconRegion.init(proximityUUID: uuid, identifier: identifier)
    let beacon = NaviBeaconData(identifier, region: region, lat: latitude, lng: longitude, hdg: heading, flr: floor)
    beacons[uuid] = beacon
    locationManager.startRangingBeacons(in: region)
    if let latitude = latitude, let longitude = longitude, mapsExists {
      sendBeacon(latitude, longitude);
    }
    return self
  }
  
  public func resumeScanning() {
    if !ranging {
      for beacon in beacons.values {
        locationManager.startRangingBeacons(in: beacon.region)
      }
      ranging = true
    }
  }
  
  public func pauseScanning() {
    if ranging {
      for beacon in beacons.values {
        locationManager.stopRangingBeacons(in: beacon.region)
      }
      ranging = false
    }
  }
  
  private func sendBeacon(_ latitude: Double?, _ longitude: Double?) {
    if let core = self.core, let latitude = latitude, let longitude = longitude {
      core.broadcast(NaviBeacon.PLUGIN_IDENTIFIER, operation: NaviBeacon.OPERATION_ADD, data: latitude, longitude)
    }
  }
  
  // MARK: Overrides
  
  override public func stop() -> Bool {
    self.pauseScanning()
    core!.remove(self)
    core!.broadcast(NaviBeacon.PLUGIN_IDENTIFIER, operation: NavisensCore.OPERATION_STOP)
    return true
  }
  
  override public func receiveMotionDna(_ motionDna: MotionDna!) throws {
    lastHeading = motionDna.getLocation().heading
  }
  
  override public func receivePluginData(_ tag: String, operation: Int, data: [Any]) throws {
    switch tag {
    case NaviBeacon.MAPS_IDENTIFIER:
      mapsExists = true;
      switch operation {
      case NavisensCore.OPERATION_INIT:
        fallthrough
      case NavisensCore.OPERATION_ACK where data.first as? String == NaviBeacon.PLUGIN_IDENTIFIER:
        for (_, beaconData) in beacons {
          sendBeacon(beaconData.latitude, beaconData.longitude);
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
  
  // MARK: NaviBeaconDelegate
  
  class NaviBeaconDelegate: NSObject, CLLocationManagerDelegate {
    unowned let parent: NaviBeacon
    
    init(_ parent: NaviBeacon) {
      self.parent = parent
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
      if let callback = parent.onBeaconChanged {
        for beacon in beacons {
          if let data = parent.beacons[beacon.proximityUUID] {
            callback(beacon, data)
          }
        }
      }
    }
  }
}
