//
//  Navigator.swift
//  Navigator
//
//  Created by Joseph Chen on 3/14/18.
//  Copyright © 2018 Navisens. All rights reserved.
//

import MotionDnaSDK
import NavisensCore

public class Navigator: NavisensPlugin {
  // MARK: Properties
  
  public static let PLUGIN_IDENTIFIER = "com.navisens.pojostick.navigator",
                    OPERATION_ROUTE = 1;

  private var core: NavisensCore?
  private var routes: NavigableRoutes?
  
  // MARK: Initializers
  
  override public func initialize(usingCore core: NavisensCore, andArgs args: [Any]) throws -> Bool {
    self.core = core
    core.broadcast(Navigator.PLUGIN_IDENTIFIER, operation: NavisensCore.OPERATION_INIT)
    return true
  }
  
  // MARK: Interface
  
  private func addNode(_ node: (Double, Double)) {
    
  }
  
  private func connectNode(_ left: (Double, Double), with right: (Double, Double)) {
    
  }
  
  public func getRoute(from: (Double, Double), to: (Double, Double)) -> [(Double, Double)] {
    if let router = routes {
      return router.path(from: NavigableNode(from), to: NavigableNode(to)).map {($0.latitude, $0.longitude)}
    }
    
    let diffX = abs(to.0 - from.0)
    let diffY = abs(to.1 - from.1)
    
    if diffX < diffY {
      let signY = from.1 < to.1 ? 1.0 : -1.0
      return [from, (to.0, from.1 + diffX * signY), to]
    } else {
      let signX = from.0 < to.0 ? 1.0 : -1.0
      return [from, (from.0 + diffY * signX, to.1), to]
    }
  }
  
  public func getRoute(from: (Double, Double), to: (Double, Double), andPublish publish: Bool) -> [(Double, Double)] {
    let answer = getRoute(from: from, to: to)
    if publish {
      core?.broadcast(Navigator.PLUGIN_IDENTIFIER, operation: Navigator.OPERATION_ROUTE, data: answer)
    }
    return answer
  }

  // MARK: Overrides

  override public func stop() throws -> Bool {
    core!.remove(self)
    core!.broadcast(Navigator.PLUGIN_IDENTIFIER, operation: NavisensCore.OPERATION_STOP)
    return true
  }
  
  // MARK: NavigableRoutes
  
  public class NavigableRoutes {
    public var nodes = Dictionary<NavigableNode, Dictionary<NavigableNode, Double>>()
    
    func add(_ node: NavigableNode) -> Bool {
      guard !contains(node) else {
        return false
      }
      nodes[node] = Dictionary<NavigableNode, Double>()
      return true
    }
    
    func connect(from: NavigableNode, to: NavigableNode) -> Bool {
      guard contains(from) && contains(to) else {
        return false
      }
      let dist = from - to
      nodes[from]![to] = dist
      nodes[to]![from] = dist
      return true
    }
    
    func contains(_ node: NavigableNode) -> Bool {
      return nodes[node] != nil
    }
    
    func neighbors(of node: NavigableNode) -> [NavigableNode] {
      if let adjacency = nodes[node] {
        return Array(adjacency.keys)
      }
      return []
    }
    
    func path(from: NavigableNode, to: NavigableNode) -> [NavigableNode] {
      // TODO: implement A* algorithm
      return [from, to]
    }
  }
  
  // MARK: NavigableNode
  
  public class NavigableNode: Hashable {
    public let hashValue: Int, latitude: Double, longitude: Double
    
    public static func ==(lhs: NavigableNode, rhs: NavigableNode) -> Bool {
      return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public static func -(lhs: NavigableNode, rhs: NavigableNode) -> Double {
      // TODO: compute latitude longitudinal distance
      let diffX = lhs.latitude - rhs.latitude
      let diffY = lhs.longitude - rhs.longitude
      return sqrt(diffX * diffX + diffY * diffY)
    }

    init(_ lat: Double, _ lng: Double) {
      self.latitude = lat
      self.longitude = lng
      self.hashValue = (lat.hashValue << 16) | (lng.hashValue & 0xffff)
    }
    
    convenience init(_ pair: (Double, Double)) {
      self.init(pair.0, pair.1)
    }
  }
}
