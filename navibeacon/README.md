# NaviBeacon

This plugin helps facilitate connecting with nearby beacons and allows automatically initializing user location with beacons, or doing custom actions upon entering beacon range.

The latest stable version is `0.2.1`, and it is built on top of iOS MotionDnaSDK version `1.2.2`.

Add the following to your podfile:

```pod
  pod 'NavisensPlugins/NaviBeacon', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
```

## Setup

1. Your device must have support for bluetooth capabilities, and use iOS 7.0+.

## API

`NaviBeacon` makes use of beacons that you have already set up. Beacons are finicky and take some time to configure. You should have the beacon's UUID recorded in order to tell our SDK which beacons to range for. When a device enters range of one of your beacons, you can have the plugin execute certain actions. By default, this plugin will attempt to set the device's location to a pre-set global location and heading.

When setting up your beacon, you should record a latitude, longitude, and heading that a user would be at and facing. For example, if you have a beacon set up at a front desk, you might record the latitude and longitude of a user standing in front of the front desk, and facing directly at the desk. If you do not add these latitude, longitude, and heading readings, then you should manually configure a callback to respond to beacon ranging.

Also note that the computed distances when using beacons are not very accurate unless taken over multiple samples, and thus there is some expected latency. The user should stay within range of the beacon for at least 5 seconds before the signal is stable enough for usage. If you implement a custom callback, you may choose to compute your own estimations with less latency at the expense for less accuracy.

## Initialization

These methods facilitate configuring internal settings for beacons.

```swift
// In your ViewController
override func viewDidLoad() {
    // ...
    core = NavisensCore(DEVKEY)
    beacon = core!.add(NaviBeacon.self)
}
```

#### `func addBeacon(identifier: String, uuid: UUID, latitude: Double?, longitude: Double?, heading: Double?, floor: Int?) -> NaviBeacon`

This method allows you to add a beacon so the plugin will begin tracking and attempting to range for that beacon. The `identifier` is a label you can use to distinguish beacons, while the `uuid` is the unique identifier of the beacon. You can set it this way:

```swift
    UUID.init(uuidString: "01234567-89AB-CDEF-0123-456789ABCDEF")!
```

The `latitude`, `longitude`, `heading`, and `floor` parameters are optionals. If the heading is nil, then only the latitude and longitude will be used. If either of latitude and longitude are nil, then a location will not be initialized (but a heading may still be set). The default behavior will set the device location to the parameters provided. The floor will be set if there is a non-nil floor number. If you wish to do custom actions (for example greeting the user upon entering beacon range), you should look at the [`Beacon Callback`](#beacon-callback) section.

## Control

These methods allow you to control beacon scanning behavior while the app is running.

#### `func resumeScanning() -> void`

If scanning was paused recently, continue scanning for nearby beacons.

#### `func pauseScanning() -> void`

If currently scanning for beacons, stop doing so until `resumeScanning` is called.

## Beacon Callback

The beacon ranging algorithm uses a closure as a callback for whenever it discovers a beacon. You may set one callback function, and it is assigned to the variable `onBeaconChanged`. Some examples are provided at the bottom of the page

#### `var onBeaconChanged: ((CLBeacon, NaviBeaconData) -> ())?`

This is the function declaration that you may change by directly overriding the variable with your own declaration. There are two parameters passed in. The `CLBeacon` is the CoreLocation beacon identifying the beacon that has just been ranged. You can use it to access many different variables such as a user's `proximity` or even the raw `rssi`. The `NaviBeaconData` object packs all of the other optional data for ease of access. It is defined as follows:

```swift
public class NaviBeaconData {
  let id: String
  let region: CLBeaconRegion
  let latitude: Double?
  let longitude: Double?
  let heading: Double?
  let floor: Int?
}
```

**Examples**

Let's say we want to create a custom behavior for a beacon that we have placed at the entrance of a shop above our door. When the user has entered the maximum range of the beacon, we want to greet the user. We will also add, for demonstration, a check to make sure the user doesn't get too close to the beacon. Here's how we might do it:

```swift
// In your ViewController
override func viewDidLoad() {
  // ...
  core = NavisensCore(DEVKEY)
  beacon = core!.add(NaviBeacon.self)
    .addBeacon(identifier: "com.navisens.pojostick", uuid: UUID.init(uuidString: "01234567-89AB-CDEF-0123-456789ABCDEF")!, latitude: nil, longitude: nil, heading: nil, floor: nil)
  
  beacon!.onBeaconChanged = { (beacon: CLBeacon, data: NaviBeaconData) in
    // Check that this is the beacon we care about
    if data.id != "com.navisens.navishop.frontentrance" {
      return
    }
  
    // Check the proximity to the beacon
    switch (beacon.proximity) {
    
    // When user enters range, welcome them
    case .far:
      self.notifyUserOnce("Welcome to my brand new shop!")
      
    // If user is a few dozen centimeters away, panic
    case .immediate where beacon.rssi > -30:
      self.notifyUserOnce("you shouldn't be up here...")
      
    // Otherwise don't do anything
    default:
      break
    }
  };
}
```

The default behavior of the `onBeaconChanged` function is to set the user location if they have entered within 2-3 meters of the beacon. Here is how the default beacon is set for reference. Basically, it checks if the user's `proximity` is at distance `immediate`, and if so to set the location if they are given (without changing the user heading where possible - `setLocationLatitude` will zero the heading if it is not provided). Once the user has exited the range to `near`, and remained this far for at least 5 seconds, the beacon cooldown is refreshed and can once again set location.

```swift
lazy var defaultOnBeaconChanged: (CLBeacon, NaviBeaconData) -> () = { [unowned self] beacon, data in
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
    }
  case .near:
    if self.resetRequired > 0 {
      self.resetRequired -= 1;
    }
  default:
    break
  }
}
```
