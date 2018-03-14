//
//  NavisensCore.swift
//  NavisensCore
//
//  Created by Joseph Chen on 10/6/17.
//  Copyright © 2017 Navisens. All rights reserved.
//

import UIKit
import WebKit
import MotionDnaSDK

public class NavisensCore {
  public static let NOTHING = 0,
  MOTION_DNA      = 1,
  NETWORK_DNA     = 2,
  NETWORK_DATA    = 4,
  PLUGIN_DATA     = 8,
  ERRORS          = 16,
  ALL             = 31,
  
  OPERATION_INIT  = 0,
  OPERATION_ACK   = -1,
  OPERATION_STOP  = -2;

  let REQUEST_MDNA_PERMISSIONS = 1
  
  public private(set) static var globalSettings: NavisensSettings = NavisensSettings()
  public private(set) static var globalMotionDnaService: MotionDnaService?
  
  public var settings: NavisensSettings { get { return NavisensCore.globalSettings } }
  public var motionDna: MotionDnaService? { get { return NavisensCore.globalMotionDnaService } }
  
  private var plugins = Set<NavisensPlugin>()
  private var subscribers = Dictionary<Int, Set<NavisensPlugin>>()
  
  // MARK: Initializers
  
  public init(_ devKey: String) {
    var i = 1
    while i <= NavisensCore.ALL {
      subscribers[i] = Set<NavisensPlugin>()
      i <<= 1
    }

    NavisensCore.globalSettings = NavisensSettings()
    if NavisensCore.globalMotionDnaService == nil {
      NavisensCore.globalMotionDnaService = MotionDnaService(self)
      NavisensCore.globalMotionDnaService!.runMotionDna(devKey, receiver: NavisensCore.globalMotionDnaService!)
      applySettings()
    }
  }
  
  // MARK: Interface
  
  public func add<T: NavisensPlugin>(_ navisensPlugin: T.Type, withParams params: Any...) -> T? {
    do {
      let plugin = navisensPlugin.init()
      if try plugin.initialize(usingCore: self, andArgs: params) {
        plugins.insert(plugin)
        return plugin
      }
      if try !plugin.stop() {
        print("Issue occured when stopping plugin of type \(navisensPlugin)")
      }
    } catch let errorMessage {
      print("Error when adding new plugin of type \(navisensPlugin): \(errorMessage)")
    }
    return nil
  }

  public func stop() -> Bool {
    if !plugins.isEmpty {
      return false
    }
    if NavisensCore.globalMotionDnaService != nil {
      NavisensCore.globalMotionDnaService!.stop()
      NavisensCore.globalMotionDnaService = nil
    }
    return true
  }
  
  public func stopAll() -> Bool {
    plugins.forEach {(plugin) in stop(plugin)}
    return stop()
  }
  
  @discardableResult public func stop(_ plugin: NavisensPlugin) -> Bool {
    if plugins.contains(plugin) {
      do {
        if try !plugin.stop() {
          return false
        }
      } catch let errorMessage {
        print("Error when stopping plugin \(plugin): \(errorMessage)")
        return false
      }
      remove(plugin)
      return true
    }
    return false
  }
  
  public func remove(_ plugin: NavisensPlugin) {
    if plugins.contains(plugin) {
      unsubscribe(plugin, from: NavisensCore.ALL)
      plugins.remove(plugin)
    }
  }
  
  public func broadcast(_ tag: String, operation: Int, data: Any...) {
    for plugin in subscribers[NavisensCore.PLUGIN_DATA]! {
      do {
        try plugin.receivePluginData(tag, operation: operation, data: data)
      } catch let errorMessage {
        print("Error when broadcasting to plugin \(plugin): \(errorMessage)")
      }
    }
  }
  
  public func subscribe(_ plugin: NavisensPlugin, to which: Int) {
    var i = 1
    while i <= NavisensCore.ALL {
      if (i & which) > 0 {
        subscribers[i]!.insert(plugin)
      }
      i <<= 1
    }
  }
  
  public func unsubscribe(_ plugin: NavisensPlugin, from which: Int) {
    var i = 1
    while i <= NavisensCore.ALL {
      if (i & which) > 0 {
        subscribers[i]!.remove(plugin)
      }
      i <<= 1
    }
  }
  
  public func applySettings() {
    NavisensCore.globalMotionDnaService?.applySettings()
  }
  
  public func startServices() {
    NavisensCore.globalMotionDnaService?.startServices()
  }
  
  // MARK: NavisensSettings
  
  public class NavisensSettings {
    var arMode : Bool?
    var callbackRate : Int?
    var estimationMode : EstimationMode?
    var positioningMode : ExternalPositioningState?
    var networkRate : Int?
    var powerMode : PowerConsumptionMode?
    var room : String?
    var host : String?
    var port : String?
    
    var needRestartServices = true
    
    public func requestARMode() {
      overrideARMode(true);
    }
    
    public func overrideARMode(_ mode: Bool?) {
      arMode = mode;
    }
    
    public func requestCallbackRate(_ rate: Int) {
      if callbackRate == nil || rate < callbackRate! {
        overrideCallbackRate(rate);
      }
    }
    
    public func overrideCallbackRate(_ rate: Int?) {
      callbackRate = rate;
    }
    
    public func requestGlobalMode() {
      overrideEstimationMode(GLOBAL);
    }
    
    public func overrideEstimationMode(_ mode: EstimationMode?) {
      estimationMode = mode;
    }
    
    public func requestPositioningMode(_ mode: ExternalPositioningState) {
      if positioningMode == nil
        || (positioningMode != HIGH_ACCURACY
          && (mode == LOW_ACCURACY
            || mode == HIGH_ACCURACY)) {
        overridePositioningMode(mode);
      }
    }
    
    public func overridePositioningMode(_ mode: ExternalPositioningState?) {
      positioningMode = mode;
    }
    
    public func requestNetworkRate(_ rate: Int) {
      if networkRate == nil || rate < networkRate! {
        overrideNetworkRate(rate);
      }
    }
    
    public func overrideNetworkRate(_ rate: Int?) {
      networkRate = rate;
    }
    
    public func requestPowerMode(_ mode: PowerConsumptionMode) {
      if powerMode == nil || powerMode!.rawValue < mode.rawValue {
        overridePowerMode(mode);
      }
    }
    
    public func overridePowerMode(_ mode: PowerConsumptionMode?) {
      powerMode = mode;
    }
    
    public func requestHost(_ host: String, andPort port: String) {
      overrideHost(host, andPort: port);
    }
    
    public func overrideHost(_ host: String?, andPort port: String?) {
      self.host = host;
      self.port = port;
      needRestartServices = true
    }
    
    public func requestRoom(_ room: String) {
      overrideRoom(room);
    }
    
    public func overrideRoom(_ room: String?) {
      self.room = room;
      needRestartServices = true
    }
  }
  
  // MARK: MotionDnaService
  
  public class MotionDnaService: MotionDnaSDK {
    weak var parent: NavisensCore! = nil
    var needsApplySettings: Bool = true
    
    convenience init(_ NavisensCore: NavisensCore!) {
      self.init()
      parent = NavisensCore
    }
    
    func applySettings() {
      self.setARModeEnabled(NavisensCore.globalSettings.arMode != nil ?
        NavisensCore.globalSettings.arMode! : false);
      self.setBinaryFileLoggingEnabled(true);
      self.setCallbackUpdateRateInMs(Double(NavisensCore.globalSettings.callbackRate != nil ?
        NavisensCore.globalSettings.callbackRate! : 100));
      self.setExternalPositioningState(NavisensCore.globalSettings.positioningMode != nil ?
        NavisensCore.globalSettings.positioningMode! : HIGH_ACCURACY);
      self.setMapCorrectionEnabled(true)
      self.setNetworkUpdateRateInMs(Double(NavisensCore.globalSettings.networkRate != nil ?
        NavisensCore.globalSettings.networkRate! : 100));
      self.setPowerMode(NavisensCore.globalSettings.powerMode != nil ?
        NavisensCore.globalSettings.powerMode! : PERFORMANCE);
      self.needsApplySettings = false;
    }
    
    func startServices() {
      if !NavisensCore.globalSettings.needRestartServices {
        return
      }
      if NavisensCore.globalSettings.estimationMode == GLOBAL {
        self.setLocationNavisens();
      }
      if NavisensCore.globalSettings.host != nil && NavisensCore.globalSettings.port != nil {
        self.stopUDP();
        if NavisensCore.globalSettings.room == nil {
          self.startUDPHost(NavisensCore.globalSettings.host!, andPort: NavisensCore.globalSettings.port!);
        } else {
          self.startUDPRoom(NavisensCore.globalSettings.room!, atHost: NavisensCore.globalSettings.host!, andPort: NavisensCore.globalSettings.port!);
        }
      }
    }
    
    override public func receive(_ motionDna: MotionDna!) {
      for plugin in parent.subscribers[NavisensCore.MOTION_DNA]! {
        do {
          try plugin.receiveMotionDna(motionDna)
        } catch let errorMessage {
          print("Error when plugin \(plugin) tried to process internal MotionDna: \(errorMessage)")
        }
      }
    }
    
    override public func receiveNetworkData(_ motionDna: MotionDna!) {
      for plugin in parent.subscribers[NavisensCore.NETWORK_DNA]! {
        do {
          try plugin.receiveNetworkData(motionDna)
        } catch let errorMessage {
          print("Error when plugin \(plugin) tried to process network MotionDna: \(errorMessage)")
        }
      }
    }
    
    override public func receiveNetworkData(_ networkCode: NetworkCode, withPayload map: Dictionary<AnyHashable, Any>) {
      for plugin in parent.subscribers[NavisensCore.NETWORK_DATA]! {
        do {
          try plugin.receiveNetworkData(networkCode, withPayload: map)
        } catch let errorMessage {
          print("Error when plugin \(plugin) tried to process raw network data: \(errorMessage)")
        }
      }
    }
    
    override public func reportError(_ errorCode: ErrorCode, withMessage s: String) {
      for plugin in parent.subscribers[NavisensCore.ERRORS]! {
        do {
          try plugin.reportError(errorCode, withMessage: s)
        } catch let errorMessage {
          print("Error when plugin \(plugin) tried to process an error: \(errorMessage)")
        }
      }
    }
  }
}
