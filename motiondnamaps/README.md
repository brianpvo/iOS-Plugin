# Motion Dna Maps

This is a plugin that provides a quick-and-easy map built upon [leafletjs](http://leafletjs.com/).

To include the plugin in your code, add the following to your podfile

```ruby
  pod 'MotionDnaPlugins/MotionDnaMaps', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
```

## Setup

1. Disable bitcode by going in your app's `Build Settings`, going down to the `Build Options` section, and setting the `Enable Bitcode` option to `No`

2. Add all permissions necessary for your app. `MotionDnaSDK` requires you to add the following permission to `Info.plist`: `NSLocationWhenInUseUsageDescription`

3. Add background mode capabilities in `Capabilities`, set `Background Modes` to "ON", and check the `Location updates` option

4. The `MotionDnaMaps` is an extension of the `WKWebView` object. To add it in, go to your storyboard, and create a `Container View`. Position it however you like, and link it to your view controller. We will add the `MotionDnaMaps` in the next part.

5. Go to your view controller, import the `MotionDnaMaps`, and declare a new variable. For this example, we will be using `Swift`

```swift
  private var maps: MotionDnaMaps?
```

6. In `viewDidLoad`, we will create the `MotionDnaMaps` instance, set up any settings, add it to our storyboard, and finally begin running it

```swift
  override func viewDidLoad() {
    super.viewDidLoad()

    maps = MotionDnaMaps()
    maps!.addTo(mapsContainer).addMap(.Esri).run(DEVKEY)
  }
```

First, we create the `maps` object. Then we add it to the container we created in step 3. Then we can configure any settings we would like - here, we added Esri as the tiling map server. Finally, we run our `MotionDnaSDK`, by passing in a valid developer's key.

## Video Tutorial

Coming Soon!

## Using the Interface

#### Leaflet Basics

* Navigate map by tap-and-dragging.

* Zoom using two fingers or the zoom controls at top left.

#### Buttons

* Use the &target; (target) icon to center the map on the user or other relevant points of interest.

* When controls are enabled, click the gear icon to begin initializing your location. Alternatively, clicking-and-holding on any point on the map will also initiate the process at the touched location.
    * When setting location, tap anywhere to set location or drag the marker to desired starting location. If you get lost, use the &target; (target) icon.
    * Click the &check; (check) icon to confirm.
    * Alternatively, click the &cross; (cross) icon to cancel.
    * You can also click the marker icon (used to be the gear icon) to switch instead to initializing heading and discard changes to location.
* After location has been set, or the user decides to skip setting the location, a new mode will start for setting the heading.
    * Drag the circle to rotate the ghost user.
    * Alternatively, tap anywhere to set a marker, and the user will automatically face the location. Move the marker as normal.
    * Finally, after selecting a heading, make sure the physical phone is aligned to the desired direction such that the top points in the direction. Then confirm the new rotation.
    
#### Markers

* Tapping any marker will zoom into it.

* When controls are enabled, tapping a marker again will expand it's stats. See below on how to interpret these.
    * Tap again to hide, or zoom out to hide all.

#### Interpretation

* The heading pointer changes color depending on the current detected motion.

* All markers also display the distribution of motions at a certain location.

* For detailed marker information, percentage of motions are displayed, as well as the total number of samples while the user was at the same location.

* Red indicates that the user is fidgetting (standing still with the phone in their hand)

* Green indicates that the user is walking

* Blue indicates that the user is no longer holding the phone and it is stationary

## API

As `MotionDnaMaps` is intended to be a quick placeholder not meant for full customization support in production environments, only some small control is provided for the developer. If you wish to customize, the source code is provided alongside this document.

## Setup

Setup should be done all at once. Since setup functions return a reference of the `MotionDnaMaps` object, you can chain setup calls together. All setup calls should be invoked before calling the `run()` function, as the setup properties apply only once.

Example:
```swift
private var maps: MotionDnaMaps?

// ... loadView
maps = MotionDnaMaps().addMap(.OSM_Mapnik).addControls()

// ... viewDidLoad
if let maps = maps {
  maps.addTo(mapsContainer).run(DEV_KEY)
}
```

#### `MotionDnaMaps()`

This is the constructor you will use to create a maps instance. The maps instance is an extension of `WKWebView`, and so you should add this object to a `View Container` formatted in whatever way you want.

Once you have created a `MotionDnaMaps` object, you can use it to call further setup functions. Make sure to call all setup functions before calling the `run()` function. If you try to invoke a setup function while the `WkWebView` is in display, you will need to restart the `WkWebView` for those changes to take effect.

#### `@objc enum Maps`

These are the default tiling servers provided. You may use a custom tiling server instead with the [`addMap(url, andJSON)`](#addmapurl-string-andjson-string---motiondnamaps) method instead.

 * `OSM_Mapnik`: Open Street Maps, does not require a key, no custom map style
 * `OSM_France`: Open Street Maps, does not require a key, custom map style is France, slighty higher zoom compared to OSM_Mapnik
 * `Thunderforest`: Thunderforest tiling servers, requires a key, default style is 'outdoors'
 * `Mapbox`: Mapbox tiling servers, requires a key, default style is 'mapbox.streets'
 * `Esri`: Esri tiling servers, not fully implemented yet, current access does not require key, but has missing tiles at high zooms

#### `addMap(map: MotionDnaMaps.Maps) -> MotionDnaMaps`

Use this to add a basic map which does not require additional setup fields. Supported maps are the `.OSM_Mapnik`, `.OSM_France`, and `.Esri`

#### `addMap(map: MotionDnaMaps.Maps, withKey: String) -> MotionDnaMaps`

Use this to add a map which requires an access key. Valid maps are `.Thunderforest` and `.Mapbox`. A default styling will be selected. To specify a custom styling, use [`addMap(map, withKey, andMapId)`](#addmapmap-motiondnamapsmaps-withkey-string-andmapid-string---motiondnamaps)

#### `addMap(map: MotionDnaMaps.Maps, withKey: String, andMapId: String) -> MotionDnaMaps`

Use this to add a map which requires an access key, and specify a custom map theme.

#### `addMap(url: String, andJSON: String) -> MotionDnaMaps`

Use this to add a custom map tiling server.

`url` should point to a tiling server
`andJSON` should include any variables included with your `url`

Example:
```swift
addMap(url: "http://{s}.tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey={apikey}", andJSON: "{
    apikey: '/* THUNDERFOREST KEY */'
}");
```

For more information, please see documentation with [Leaflet](http://leafletjs.com/reference-1.1.0.html#tilelayer)

#### `addControls() -> MotionDnaMaps`

Use this to enable the user to control more features on the map. If this method is called, users will be able to do the following:

* Set a custom location
* Set a custom heading
* View all data points
* View stats on their movement (e.g. how long they stood still)

Note that this method will not do anything if you also call [`useLocalOnly()`](#uselocalonly---motiondnamaps).

#### `preventRestart() -> MotionDnaMaps`

Use this to prevent the map from running clean-up whenever the app stops and starts again. This will retain all data points from the user's previous instance, along with the map's position, zoom level, etc.

Note: This is a dangerous method to call, as it prevents cleaning up of browser memory. Although all data is compressed, overly using this method can result in the browser reaching it's maximum memory, preventing further tracking of points. It is advised to use this only while within the same application instance, when the storyboard needs to be destroyed and recreated again.

#### `useLocalOnly() -> MotionDnaMaps`

This will set navigation to local cartesian coordinates, preventing usage of GPS localization. Furthermore, no default map will be added.

You can use the custom [`addMap(url, andJSON)`](#addmapurl-string-andjson-string---motiondnamaps) with this to set custom map tiles that better reflect local coordinates (for example an open grid or virtual world).

Note: the [`addControls()`](#addcontrols---motiondnamaps) will be disabled when local coordinates are enabled, preventing the user from setting a custom location and heading.

#### `hideMarkers() -> MotionDnaMaps`

Hides the colored markers, so only a line will appear on the screen, and no stats will be visible (or stored). The arrow will still display the most recent movement types detected.

Will function with [`addConstrols()`](#addcontrols---motiondnamaps), by allowing users to set location as normal, but no longer view marker stats.

## State Changes

The following methods are used to control the state of the maps object, and will return whether they executed successfully. They always will, unless an invalid state is reached (for example trying to call [`resume()`](#resume) after calling [`stop()`](#stop)

#### `pause()`

Pauses the MotionDna algorithm, which can save battery when not in use, but remembers the user's last location, heading, etc. (as opposed to stopping the algorithm alltogether).

Use [`resume()`](#pause) to resume the algorithm.

#### `resume()`

Resumes the MotionDna algorithm if it was paused.

#### `save()`

Saves the current viewport. This allows destroying the view and restarting afterwards at the same state.

#### `restart()`

Restarts the current viewport cache. This will reset all tracked points, along with resetting the user's view position and zoom level.

#### `stop()`

Stops the MotionDna algorithm. Call this before destroying the view.

