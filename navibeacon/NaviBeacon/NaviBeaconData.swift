//
//  NaviBeaconData.swift
//  NaviBeacon
//
//  Created by Joseph Chen on 2/7/18.
//  Copyright © 2018 Navisens. All rights reserved.
//

import CoreLocation

public class NaviBeaconData {
  public let id: String
  public let region: CLBeaconRegion
  public let latitude: Double?
  public let longitude: Double?
  public let heading: Double?
  public let floor: Int?
  
  init(_ id: String, region: CLBeaconRegion, lat: Double?, lng: Double?, hdg: Double?, flr: Int?) {
    self.id = id
    self.region = region
    self.latitude = lat
    self.longitude = lng
    self.heading = hdg
    self.floor = flr
  }
}
