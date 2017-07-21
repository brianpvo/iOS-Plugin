//
//  MotionDnaMaps.swift
//  MotionDnaMaps
//
//  Created by Joseph Chen on 7/18/17.
//  Copyright © 2017 Navisens. All rights reserved.
//

import UIKit
import WebKit
import MotionDnaSDK

public class MotionDnaMaps: WKWebView, WKNavigationDelegate, WKScriptMessageHandler {
    
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
    public enum Maps: String {
        /**
         * Open Street Maps, does not require a key, no custom map style
         */
        case OSM_Mapnik = "OpenStreetMap_Mapnik"
        /**
         * Open Street Maps, does not require a key, custom map style is France, slighty higher zoom compared to {@link #OSM_Mapnik}
         */
        case OSM_France = "OpenStreetMap_France"
        /**
         * Thunderforest tiling servers, requires a key, default style is 'outdoors'
         */
        case Thunderforest = "Thunderforest"
        /**
         * Mapbox tiling servers, requires a key, default style is 'mapbox.streets'
         */
        case Mapbox = "Mapbox"
        /**
         * Esri tiling servers, not fully implemented yet, current access does not require key, but has missing tiles at high zooms
         */
        case Esri = "Esri"
    }

    // MARK: Properties
    let DEFAULT_MAP = "addMap_OpenStreetMap_Mapnik();"

    private weak var mapsContainer: UIView?
    
    let REQUEST_MDNA_PERMISSIONS = 1
    
    private var shouldRestart: Bool = true
    private var motionDnaService: MotionDnaService?
    private var useDefaultMap: Bool = true
    
    private var javascript: String = "RUN(%@);"

    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        self.navigationDelegate = self
        self.configuration.userContentController.add(self, name: "customLocationInitialized")
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.navigationDelegate = self
    }
    
    // MARK: Optionals
    
    public func addMap(_ map: Maps) -> MotionDnaMaps {
        javascript += "addMap_\(map.rawValue)();"
        useDefaultMap = false;
        return self
    }
    
    public func addMap(_ map: Maps, withKey key: String) -> MotionDnaMaps {
        javascript += "addMap_\(map.rawValue)('\(key)');"
        useDefaultMap = false;
        return self
    }

    public func addMap(_ map: Maps, withKey key: String, andMapId id: String) -> MotionDnaMaps {
        javascript += "addMap_\(map.rawValue)('\(key)', '\(id)');"
        useDefaultMap = false;
        return self
    }

    public func addMap(url: String, andJSON jsonOptions: String) -> MotionDnaMaps {
        javascript += "addMap('\(url)', '\(jsonOptions)');"
        useDefaultMap = false;
        return self
    }
    
    public func addControls() -> MotionDnaMaps {
        javascript += "UI();"
        return self
    }
    
    public func preventRestart() -> MotionDnaMaps {
        shouldRestart = false
        return self
    }
    
    public func useLocalOnly() -> MotionDnaMaps {
        javascript = "setSimple();" + javascript
        motionDnaService!.useLocal = true
        useDefaultMap = true
        return self
    }
    
    public func hideMarkers() -> MotionDnaMaps {
        javascript += "hideClustering();"
        return self
    }
    
    public func pause() {
        if let motionDnaService = motionDnaService {
            motionDnaService.pause()
        }
    }
    
    public func resume() {
        if let motionDnaService = motionDnaService {
            motionDnaService.resume()
        }
    }
    
    public func save() {
        self.evaluateJS("if (typeof SAVE !== 'undefined') SAVE();")
    }
    
    public func restart() {
        self.evaluateJS("START();")
    }
    
    public func stop() {
        if motionDnaService != nil {
            motionDnaService!.stop()
            motionDnaService = nil
        }
        self.evaluateJS("STOP();")
    }
    
    // MARK: Interface
    
    public func addTo(_ container: UIView) -> MotionDnaMaps {
        mapsContainer = container
        mapsContainer!.addSubview(self)
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.frame = CGRect(origin: CGPoint.zero, size: container.frame.size)
        return self
    }
    
    public func run(_ devKey: String) {
        do {
            guard let bundle = Bundle.init(identifier: "com.navisens.pojostick.MotionDnaMaps"), let assets = bundle.path(forResource: "assets", ofType: "") else {
                print ("Missing assets")
                return
            }
            
            if let index = bundle.path(forResource: "index", ofType: "html", inDirectory: "assets") {
                let html = try String(contentsOfFile: index, encoding: .utf8)
                let url = URL(fileURLWithPath: assets)
                self.loadHTMLString(html as String, baseURL: url)
            } else {
                print ("Missing index.html")
            }
        }
        catch {
            print ("File HTML error")
        }
        
        if motionDnaService == nil {
            motionDnaService = MotionDnaService(self)
            motionDnaService!.runMotionDna(devKey, receiver: motionDnaService!)
            if (motionDnaService!.useLocal) {
                motionDnaService!.customLocation = true;
            } else {
                motionDnaService!.setLocationNavisens();
                motionDnaService!.setCallbackUpdateRateInMs(100);
                motionDnaService!.setMapCorrectionEnabled(true);
                motionDnaService!.setExternalPositioningState(HIGH_ACCURACY);
                motionDnaService!.setBackgroundModeEnabled(true);
            }
        }
    }
    
    // MARK: Internals
    
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
        if shouldRestart {
            restart()
        }
        self.evaluateJS(String(format: javascript, (motionDnaService!.lastLocation == UNINITIALIZED).description))
        if useDefaultMap {
            self.evaluateJS(DEFAULT_MAP)
        }
    }
    
    func evaluateJS(_ string: String!) {
        // TESTING
        // print (string)
        // END
        self.evaluateJavaScript(string)
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "customLocationInitialized" {
            if let motionDnaService = motionDnaService, let custom = message.body as? [Double] {
                if motionDnaService.useLocal {
                    // no local support at the moment
                } else {
                    motionDnaService.setLocationLatitude(custom[0], longitude: custom[1], andHeadingInDegrees: custom[2])
                }
                motionDnaService.customLocation = true
            }
        }
    }
    
    // MARK: MotionDnaService
    
    class MotionDnaService: MotionDnaSDK {
        let LOCAL_SCALING: Double = pow(2, -17)

        weak var parent: MotionDnaMaps! = nil
        
        var lastLocation: LocationStatus = UNINITIALIZED
        var customLocation: Bool = false
        var useLocal: Bool = false

        private var x: Double = 0, y: Double = 0, h: Double = 0
        
        convenience init(_ motionDnaMaps: MotionDnaMaps!) {
            self.init()
            parent = motionDnaMaps
        }
        
        override func receive(_ motionDna: MotionDna!) {
            let location = motionDna.getLocation()
            
            if useLocal {
                x = location.localLocation.x * LOCAL_SCALING
                y = location.localLocation.y * LOCAL_SCALING
                h = location.heading
                // System.out.println(x + ", " + y + ", " + h);
                parent.evaluateJS(
                    String(format: "if (typeof SESSION_RELOADED !== 'undefined') addPoint(%.7f, %.7f, %d);",
                                  y,
                                  x,
                                  motionDna.getMotion().primaryMotion.rawValue)
                );
                parent.evaluateJS(
                    String(format: "if (typeof SESSION_RELOADED !== 'undefined') move(%.7f, %.7f, %.7f, %d);",
                                  y,
                                  x,
                                  h,
                                  motionDna.getMotion().primaryMotion.rawValue)
                );
            } else {
                if lastLocation != location.locationStatus {
                    switch location.locationStatus {
                    case NAVISENS_INITIALIZING:
                        parent.evaluateJS("acquiredGPS();");
                    case NAVISENS_INITIALIZED:
                        parent.evaluateJS("acquiredLocation();");
                    default:
                        break
                    }
                    lastLocation = location.locationStatus;
                }
                
                if customLocation || location.locationStatus == NAVISENS_INITIALIZED {
                    parent.evaluateJS(
                        String(format: "if (typeof SESSION_RELOADED !== 'undefined') addPoint(%.7f, %.7f, %d);",
                                      location.globalLocation.latitude,
                                      location.globalLocation.longitude,
                                      motionDna.getMotion().primaryMotion.rawValue)
                    )
                }
                parent.evaluateJS(
                    String(format: "if (typeof SESSION_RELOADED !== 'undefined') move(%.7f, %.7f, %.7f, %d);",
                                  location.globalLocation.latitude,
                                  location.globalLocation.longitude,
                                  location.heading,
                                  motionDna.getMotion().primaryMotion.rawValue)
                )
            }
        }
        
        override func failure(toAuthenticate msg: String!) {
        }
        
        override func reportSensorTiming(_ dt: Double, msg: String!) {
        }
    }
}
