//
//  NavisensMaps.swift
//  NavisensMaps
//
//  Created by Joseph Chen on 7/18/17.
//  Refactored into NavisensMaps 10/27/17
//  Copyright © 2017 Navisens. All rights reserved.
//

import UIKit
import WebKit
import MotionDnaSDK
import NavisensCore

public class NavisensMaps: NavisensPlugin {
  
  /// Usable map types are:
  /// <ul>
  ///     No API key required
  /// <li>{@link #OSM_Mapnik}</li>
  /// <li>{@link #OSM_France}</li>
  /// <br>
  ///     API key required, and custom styles available
  /// <li>{@link #Thunderforest}</li>
  /// <li>{@link #Mapbox}</li>
  /// <br>
  ///     WIP no key required
  /// <li>{@link #Esri}</li>
  /// </ul>
  ///
  /// - OSM_Mapnik: <#OSM_Mapnik description#>
  /// - OSM_France: <#OSM_France description#>
  /// - Thunderforest: <#Thunderforest description#>
  /// - Mapbox: <#Mapbox description#>
  /// - Esri: <#Esri description#>
  @objc public enum Maps: Int {
    /**
     * Open Street Maps, does not require a key, no custom map style
     */
    case OSM_Mapnik
    /**
     * Open Street Maps, does not require a key, custom map style is France, slighty higher zoom compared to {@link #OSM_Mapnik}
     */
    case OSM_France
    /**
     * Thunderforest tiling servers, requires a key, default style is 'outdoors'
     */
    case Thunderforest
    /**
     * Mapbox tiling servers, requires a key, default style is 'mapbox.streets'
     */
    case Mapbox
    /**
     * Esri tiling servers, not fully implemented yet, current access does not require key, but has missing tiles at high zooms
     */
    case Esri
    
    func toString() -> String {
      switch self {
      case .OSM_Mapnik:    return "OpenStreetMap_Mapnik"
      case .OSM_France:    return "OpenStreetMap_France"
      case .Thunderforest: return "Thunderforest"
      case .Mapbox:        return "Mapbox"
      case .Esri:          return "Esri"
      }
    }
  }
  
  // MARK: Properties
  let REQUEST_MDNA_PERMISSIONS = 1
  let DEFAULT_MAP = "addMap_OpenStreetMap_Mapnik();"
  let LOCAL_SCALING: Double = 1 // pow(2, -17)
  
  public static let PLUGIN_IDENTIFIER = "com.navisens.pojostick.navisensmaps",
                    BEACON_IDENTIFIER = "com.navisens.pojostick.navibeacon",
                    POINTS_IDENTIFIER = "com.navisens.pojostick.navipoints",
                    NAVIGATOR_IDENTIFIER = "com.navisens.pojostick.navigator"
  
  private var lastLocation: LocationStatus = UNINITIALIZED
  private var customLocation: Bool = false, shouldRestart: Bool = true
  
  private var webView: MapsWebView
  private var useDefaultMap: Bool = true, useLocal: Bool = false, shareLocation: Bool = false
  
  private var core: NavisensCore?
  
  private weak var mapsContainer: UIView?
  private var javascript: String = ""
  private var x: Double = 0, y: Double = 0, h: Double = 0
  
  private var initalizedJS = false
  private var beaconsExist = false, pointsExist = false, navigatorExist = false
  
  // MARK: Initializers
  required public init() {
    self.webView = MapsWebView()
    self.javascript = "RUN(%@);"
  }
  
  override public func initialize(usingCore core: NavisensCore, andArgs args: [Any]) -> Bool {
    self.core = core
    
    do {
      guard let bundle = Bundle.init(identifier: "com.navisens.pojostick.NavisensMaps"), let assets = bundle.path(forResource: "assets", ofType: "") else {
        print ("Missing assets")
        return false
      }
      
      if let index = bundle.path(forResource: "index.0.0.18", ofType: "html", inDirectory: "assets") {
        let html = try String(contentsOfFile: index, encoding: .utf8)
        let url = URL(fileURLWithPath: assets)
        self.webView.loadHTMLString(html as String, baseURL: url)
      } else {
        print ("Missing index.html")
        return false
      }
    }
    catch {
      print ("File HTML error")
      return false
    }
    
    core.subscribe(self, to: NavisensCore.MOTION_DNA | NavisensCore.NETWORK_DNA | NavisensCore.PLUGIN_DATA)
    core.broadcast(NavisensMaps.PLUGIN_IDENTIFIER, operation: NavisensCore.OPERATION_INIT)
    
    return true
  }
  
  // MARK: Interface
  
  public func addMap(_ map: Maps) -> NavisensMaps {
    javascript += "addMap_\(map.toString())();"
    useDefaultMap = false;
    return self
  }
  
  public func addMap(_ map: Maps, withKey key: String) -> NavisensMaps {
    javascript += "addMap_\(map.toString())('\(key)');"
    useDefaultMap = false;
    return self
  }
  
  public func addMap(_ map: Maps, withKey key: String, andMapId id: String) -> NavisensMaps {
    javascript += "addMap_\(map.toString())('\(key)', '\(id)');"
    useDefaultMap = false;
    return self
  }
  
  public func addMap(url: String, andJSON jsonOptions: String) -> NavisensMaps {
    javascript += "addMap('\(url)', '\(jsonOptions)');"
    useDefaultMap = false;
    return self
  }
  
  public func addControls() -> NavisensMaps {
    javascript += "UI();"
    return self
  }
  
  public func preventRestart() -> NavisensMaps {
    shouldRestart = false
    return self
  }
  
  public func useLocalOnly() -> NavisensMaps {
    javascript = "setSimple();" + javascript
    useLocal = true
    customLocation = true
    core?.settings.overrideEstimationMode(LOCAL)
    useDefaultMap = false
    return self
  }
  
  public func hideMarkers() -> NavisensMaps {
    javascript += "hideClustering();"
    return self
  }
  
  public func pause() {
    core?.motionDna?.pause()
  }
  
  public func resume() {
    core?.motionDna?.resume()
  }
  
  public func save() {
    self.webView.evaluateJS("if (typeof SAVE !== 'undefined') SAVE();")
  }
  
  public func restart() {
    self.webView.evaluateJS("START();")
  }
  
  override public func stop() -> Bool {
    self.webView.evaluateJS("STOP();")
    core!.remove(self)
    core!.broadcast(NavisensMaps.PLUGIN_IDENTIFIER, operation: NavisensCore.OPERATION_STOP)
    return true
  }
  
  public func showPath() -> NavisensMaps {
    javascript += "DEBUG();"
    return self
  }
  
  public func enableLocationSharing() -> NavisensMaps {
    shareLocation = true
    return self
  }
  
  public func addTo(_ container: UIView) -> NavisensMaps {
    mapsContainer = container
    self.webView.initialize(self, inContainer: container)
    return self
  }
  
  private func addBeacon(_ lat: Double, _ lng: Double) {
    let js = "ADD_BEACON(\(lat), \(lng));"
    if self.initalizedJS {
      self.webView.evaluateJS(js)
    } else {
      javascript += js
    }
  }
  
  private func addPoint(_ id: String, _ lat: Double, _ lng: Double) {
    let js = "ADD_POINT('\(id)', \(lat), \(lng));"
    if self.initalizedJS {
      self.webView.evaluateJS(js)
    } else {
      javascript += js
    }
  }

  private func removePoint(_ id: String) {
    let js = "REMOVE_POINT('\(id)');"
    if self.initalizedJS {
      self.webView.evaluateJS(js)
    } else {
      javascript += js
    }
  }
  
  public func showRoute(_ route: [(Double, Double)]) {
    let js = "SHOW_ROUTE(\(route.map{[$0, $1]}));"
    if self.initalizedJS {
      self.webView.evaluateJS(js)
    } else {
      javascript += js
    }
  }
  
  public func clearRoute() {
    let js = "CLEAR_ROUTE();"
    if self.initalizedJS {
      self.webView.evaluateJS(js)
    } else {
      javascript += js
    }
  }
  
  // MARK: Overrides
  
  override public func receiveMotionDna(_ motionDna: MotionDna!) throws {
    let location = motionDna.getLocation()
    
    if useLocal {
      x = location.localLocation.x * LOCAL_SCALING
      y = location.localLocation.y * LOCAL_SCALING
      h = location.heading
      // System.out.println(x + ", " + y + ", " + h);
      self.webView.evaluateJS(
        String(format: "if (typeof SESSION_RELOADED !== 'undefined') addPoint('\(motionDna.getID()!)', %.7f, %.7f, %d);",
               y,
               x,
               motionDna.getMotion().motionType.rawValue)
      );
      self.webView.evaluateJS(
        String(format: "if (typeof SESSION_RELOADED !== 'undefined') move('\(motionDna.getID()!)', %.7f, %.7f, %.7f, %d);",
               y,
               x,
               h,
               motionDna.getMotion().motionType.rawValue)
      );
    } else {
      if lastLocation != location.locationStatus {
        switch location.locationStatus {
        case NAVISENS_INITIALIZING:
          self.webView.evaluateJS("acquiredGPS();");
        case NAVISENS_INITIALIZED:
          self.webView.evaluateJS("acquiredLocation();");
        default:
          break
        }
        lastLocation = location.locationStatus;
      }
      
      if customLocation || location.locationStatus == NAVISENS_INITIALIZED {
        self.webView.evaluateJS(
          String(format: "if (typeof SESSION_RELOADED !== 'undefined') addPoint('\(motionDna.getID()!)', %.7f, %.7f, %d);",
                 location.globalLocation.latitude,
                 location.globalLocation.longitude,
                 motionDna.getMotion().motionType.rawValue)
        )
      }
      self.webView.evaluateJS(
        String(format: "if (typeof SESSION_RELOADED !== 'undefined') move('\(motionDna.getID()!)', %.7f, %.7f, %.7f, %d);",
               location.globalLocation.latitude,
               location.globalLocation.longitude,
               location.heading,
               motionDna.getMotion().motionType.rawValue)
      )
    }
  }
  
  override public func receiveNetworkData(_ motionDna: MotionDna!) throws {
    try receiveMotionDna(motionDna)
  }
  
  override public func receiveNetworkData(_ networkCode: NetworkCode, withPayload map: Dictionary<AnyHashable, Any>) throws {
  }
  
  override public func receivePluginData(_ tag: String, operation: Int, data: [Any]) throws {
    switch tag {
    case NavisensMaps.BEACON_IDENTIFIER:
      handleBeaconPlugin(operation: operation, data: data)
    case NavisensMaps.POINTS_IDENTIFIER:
      handlePointsPlugin(operation: operation, data: data)
    case NavisensMaps.NAVIGATOR_IDENTIFIER:
      handleNavigatorPlugin(operation: operation, data: data)
    default:
      break
    }
  }
  
  private func handleBeaconPlugin(operation: Int, data: [Any]) {
    beaconsExist = true
    switch operation {
    case NavisensCore.OPERATION_INIT:
      core?.broadcast(NavisensMaps.PLUGIN_IDENTIFIER, operation: NavisensCore.OPERATION_ACK, data: NavisensMaps.BEACON_IDENTIFIER)
    case NavisensCore.OPERATION_STOP:
      beaconsExist = false
    default:
      if data.count >= 2, let lat = data[0] as? Double, let lng = data[1] as? Double {
        addBeacon(lat, lng)
      }
    }
  }
  
  private func handlePointsPlugin(operation: Int, data: [Any]) {
    pointsExist = true
    switch operation {
    case NavisensCore.OPERATION_INIT:
      core?.broadcast(NavisensMaps.PLUGIN_IDENTIFIER, operation: NavisensCore.OPERATION_ACK, data: NavisensMaps.POINTS_IDENTIFIER)
    case NavisensCore.OPERATION_STOP:
      pointsExist = false
    case 1:
      if data.count >= 3, let id = data[0] as? String, let lat = data[1] as? Double, let lng = data[2] as? Double {
        addPoint(id, lat, lng)
      } else {
        print("Invalid format 1: \(data) with types: \(data.map{type(of: $0)})")
      }
    case 2:
      if data.count >= 1, let id = data[0] as? String {
        removePoint(id)
      } else {
        print("Invalid format 2: \(data) with types: \(data.map{type(of: $0)})")
      }
    default:
      break
    }
  }
  
  private func handleNavigatorPlugin(operation: Int, data: [Any]) {
    navigatorExist = true
    switch operation {
    case NavisensCore.OPERATION_STOP:
      navigatorExist = false
    case 1:
      if data.count >= 1, let route = data[0] as? [(Double, Double)] {
        showRoute(route)
      }
    default:
      break
    }
  }
  
  override public func reportError(_ error: ErrorCode, withMessage message: String!) throws {
  }
  
  // MARK: MapsWebView
  
  class MapsWebView: WKWebView, WKNavigationDelegate, WKScriptMessageHandler {
    weak var parent: NavisensMaps?
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
      super.init(frame: frame, configuration: configuration)
      self.navigationDelegate = self
      self.configuration.userContentController.add(self, name: "customLocationInitialized")
    }
    
    required public init?(coder: NSCoder) {
      super.init(coder: coder)
      self.navigationDelegate = self
    }
    
    public func initialize(_ parent: NavisensMaps, inContainer container: UIView) {
      self.parent = parent
      container.addSubview(self)
      self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      self.frame = CGRect(origin: CGPoint.zero, size: container.frame.size)
    }
    
    // https://stackoverflow.com/a/36231713
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      if navigationAction.navigationType == .linkActivated {
        if let url = navigationAction.request.url, UIApplication.shared.canOpenURL(url) {
          UIApplication.shared.openURL(url)
        }
        decisionHandler(.cancel)
      } else {
        decisionHandler(.allow)
      }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      if let parent = parent {
        parent.core?.settings.requestCallbackRate(100)
        if (!parent.useLocal) {
          parent.core?.settings.requestGlobalMode()
          parent.core?.settings.requestPositioningMode(HIGH_ACCURACY)
        }
        parent.core?.applySettings()
        parent.core?.startServices()

        if parent.shouldRestart {
          parent.shouldRestart = false
          parent.restart()
        }
        parent.javascript = "SET_ID('\(parent.core?.motionDna?.getDeviceID()! ?? "")');\(parent.javascript)";
        self.evaluateJS(String(format: parent.javascript, (!parent.useLocal && parent.lastLocation == UNINITIALIZED).description))
        if parent.useDefaultMap {
          self.evaluateJS(parent.DEFAULT_MAP)
        }
        if parent.shareLocation {
          parent.core?.motionDna?.startUDP()
        }
        parent.initalizedJS = true
      }
    }
    
    func evaluateJS(_ string: String!) {
      // print ("Evaluating javascript: '\(string!)'")
      DispatchQueue.main.async {
        self.evaluateJavaScript(string!)
      }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      if message.name == "customLocationInitialized" {
        if let parent = parent, let custom = message.body as? [Double] {
          if parent.useLocal {
            // no local support at the moment
          } else {
            parent.core?.motionDna?.setLocationLatitude(custom[0], longitude: custom[1], andHeadingInDegrees: custom[2])
          }
          parent.customLocation = true
        }
      }
    }
  }
}
