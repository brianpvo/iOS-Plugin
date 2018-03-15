# Navigator

This plugin can be used to compute and send simple routes to other plugins.

The latest stable version is `0.2.2`, and it is built on top of iOS MotionDnaSDK version `1.2.2`.

Add the following to your podfile:

```ruby
  pod 'NavisensPlugins/Navigator', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
```

## Setup

1. No setup required.

## API

`Navigator` is used to create routes between two points that can be rendered in the `NavisensMaps` plugin.

## Initialization

These functions facilitate configuring internal settings for routing.

```swift
// In your ViewController
override func viewDidLoad() {
    // ...
    core = NavisensCore(DEVKEY)
    navigator = core!.add(Navigator.self)
}
```

There are no other functions at the current time for configuring. Future releases will allow developers to set up navigable paths and maps so the algorithm can determine the best path.

## Usage

These functions are the core functionality of the Navigator plugin.

#### `func getRoute(from: (Double, Double), to: (Double, Double)) -> [(Double, Double)]`

Get a route between a from node and a to node. If no navigable paths have been configured, then a default algorithm will be used that constrains routes to 45- and 90-degree angle pathways.

#### `func getRoute(from: (Double, Double), to: (Double, Double), andPublish publish: Bool) -> [(Double, Double)]`

Functions the same way as `getRoute` above, but if `publish` is true, then also broadcast the computed pathway to all other plugins. If the maps plugin exists, then it will render the computed route.
