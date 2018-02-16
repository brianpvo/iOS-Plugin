# NaviPoints

This plugin provides a simple implementation of the idea of keeping track of named points, and using these points to initialize the user's location easily and intuitively.

We named this plugin Points because it was originally inspired by the "Points Of Interest" or POIs concept of initializing user location. We simply extended the acronym to POInts to make it easier to remember.

The latest stable version is `0.2.2`.

Add the following to your podfile:

```ruby
pod 'NavisensPlugins/NaviPoints', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
```

## Setup

1. No additional set up is required.

## API

`NaviPoints` allows you to add named points, with a latitude, longitude, and possibly heading and floor number. You can then set the user's location easily by the name of a point, or query for nearby points.

Feel free to use the source code provided to extend functionality or customize behavior!

## Initialization

There are no initialization methods. Just add it to the `core` to begin!

```swift
  // In your ViewController
  override func viewDidLoad() {
  // ...
  core = NavisensCore(DEVKEY)
  beacon = core!.add(NaviPoints.self)
}
```

## Interface

These methods allow you to use the basic points support.

#### `func add(_ id: String, atLocation latitude: Double, _ longitude: Double, withHeading heading: Double?, andFloor floor: Int?)`

Begins keeping track of a point named `id`, and at location `latitude` and `longitude`. The `id` field must be unique. Optional `heading` and `floor` parameters are provided, in order to better set the user's location using the `setLocation` method call.

#### `func remove(_ id: String)`

Stops tracking the point with the corresponding `id`, if it exists.

#### `func setLocation(_ id: String)`

A simple way to set the user's location by the `id` of a loaded point.

