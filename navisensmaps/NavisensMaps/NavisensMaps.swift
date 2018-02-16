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
  
  private var lastLocation: LocationStatus = UNINITIALIZED
  private var customLocation: Bool = false, shouldRestart: Bool = true
  
  private var webView: MapsWebView
  private var useDefaultMap: Bool = true, useLocal: Bool = false, shareLocation: Bool = false
  
  private var core: NavisensCore?
  
  private weak var mapsContainer: UIView?
  private var javascript: String = ""
  private var x: Double = 0, y: Double = 0, h: Double = 0
  
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
      
      if let index = bundle.path(forResource: "index.0.0.14", ofType: "html", inDirectory: "assets") {
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
    
    core.subscribe(self, to: NavisensCore.MOTION_DNA | NavisensCore.NETWORK_DNA)
    
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
    core?.remove(self)
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
  
  override public func receivePluginData(_ tag: String, data: Any) throws {
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
      }
    }
    
    func evaluateJS(_ string: String!) {
      // print ("Evaluating javascript: '\(string!)'")
      self.evaluateJavaScript(string!)
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
