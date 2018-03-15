# Navisens Maps

This is a plugin that provides a quick-and-easy map built upon [leafletjs](http://leafletjs.com/).

The latest stable version is `0.2.2`, and it is built on top of iOS MotionDnaSDK version `1.2.2`.

To include the plugin in your code, add the following to your app's dependencies:

```gradle
pod 'NavisensPlugins/NavisensMaps', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
```

## Setup

1. Enable background location updates. Go to your project settings and open **Capabilities**. Turn on **Background Modes**, and tick the **Location updates** checkbox.

2. Add information on location usage. Open your `info.plist` and add a new property with key `Privacy - Location When In Use Usage Description` and fill the value with some description of location usage.

If you aren't sure how to do some of these, or aren't that familiar with Xcode, check out the recommended [iOS quick start guide here](https://github.com/navisens/NaviDocs/blob/master/BEER.iOS.md)

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

As `NavisensMaps` is intended to be a quick placeholder not meant for full customization support in production environments, only some small control is provided for the developer. If you wish to customize, the source code is provided alongside this document.

## Setup

Setup should be done all at once. Since setup functions return a reference of the `NavisensMaps` object, you can chain setup calls together. All setup calls should be invoked before the maps display is added to any container, as the setup properties apply only once upon creating the View that the `NavisensMaps` view holds.

Example:
```swift
var maps: NavisensMaps? = core!.add(NavisensMaps.self)?
                                    .useLocalOnly()
                                    .showPath().hideMarkers()
                                    .addTo(mapContainer)
```

#### `func initialize(usingCore core: NavisensCore, andArgs args: [Any]) -> Bool`

**Do not call this function!** This is how `NavisensMaps` is initialized via the `NavisensCore`. If you aren't sure how to add plugins, please first read the setup for [`NavisensCore`](/navisenscore). `NavisensMaps` is a view, so you can add it to any container you have created.

Once you have initialized a `NavisensMaps` object, you can use it to call further setup functions. Make sure to call all setup functions upon object creation. If you try to invoke a setup function while maps is being displayed, you will need to restart NavisensMaps for those changes to take effect.

The source code is available if you would like to mess around with customizing how NavisensMaps behaves.

#### `NavisensMaps.Maps`

These are the default tiling servers provided. You may use a custom tiling server instead with the [`addMap(url, andJSON)`](#func-addmapurl-string-andjson-jsonoptions-string---navisensmaps) method instead.

 * `OSM_Mapnik`: Open Street Maps, does not require a key, no custom map style
 * `OSM_France`: Open Street Maps, does not require a key, custom map style is France, slighty higher zoom compared to OSM_Mapnik
 * `Thunderforest`: Thunderforest tiling servers, requires a key, default style is 'outdoors'
 * `Mapbox`: Mapbox tiling servers, requires a key, default style is 'mapbox.streets'
 * `Esri`: Esri tiling servers, not fully implemented yet, current access does not require key, but has missing tiles at high zooms

#### `func addMap(_ map: Maps) -> NavisensMaps`

Use this to add a basic map which does not require additional setup fields. Supported maps are the `.OSM_Mapnik`, `.OSM_France`, and `.Esri`

#### `func addMap(_ map: Maps, withKey key: String) -> NavisensMaps`

Use this to add a map which requires an access key. Valid maps are `.Thunderforest` and `.Mapbox`. A default styling will be selected. To specify a custom styling, use [`addMap(name, withKey, andMapId)`](#func-addmap_-map-maps-withkey-key-string-andmapid-id-string---navisensmaps).

#### `func addMap(_ map: Maps, withKey key: String, andMapId id: String) -> NavisensMaps`

Use this to add a map which requires an access key, and specify a custom map theme.

#### `func addMap(url: String, andJSON jsonOptions: String) -> NavisensMaps`

Use this to add a custom map tiling server.

`url` should point to a tiling server
`jsonOptions` should include any variables included with your `url`

Example:
```swift
addMap(url: "http://{s}.tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey={apikey}", andJSON: """{
    apikey: '/* THUNDERFOREST KEY */'
}""");
```

For more information, please see documentation with [Leaflet](http://leafletjs.com/reference-1.1.0.html#tilelayer)

#### `func addControls() -> NavisensMaps`

Use this to enable the user to control more features on the map. If this method is called, users will be able to do the following:

* Set a custom location
* Set a custom heading
* View all data points
* View stats on their movement (e.g. how long they stood still)

Note that this method will not do anything if you also call [`useLocalOnly()`](#func-uselocalonly---navisensmaps).

#### `func preventRestart() -> NavisensMaps`

Use this to prevent the map from running clean-up whenever the app stops and starts again. This will retain all data points from the user's previous instance, along with the map's position, zoom level, etc.

Note: This is a dangerous method to call, as it prevents cleaning up of browser memory. Although all data is compressed, overly using this method can result in the browser reaching it's maximum memory, preventing further tracking of points. It is advised to use this only while within the same application instance, when the current activity needs to be destroyed and recreated again.

#### `func useLocalOnly() -> NavisensMaps`

This will set navigation to local cartesian coordinates, preventing usage of GPS localization. Furthermore, no default map will be added.

You can use the custom [`addMap(url, andJSON)`](#func-addmapurl-string-andjson-jsonoptions-string---navisensmaps) with this to set custom map tiles that better reflect local coordinates (for example an open grid or virtual world).

Note: the [`addControls()`](#func-addcontrols---navisensmaps) will be disabled when local coordinates are enabled, preventing the user from setting a custom location and heading.

#### `func hideMarkers() -> NavisensMaps`

Hides the colored markers, so only a line will appear on the screen, and no stats will be visible (or stored). The arrow will still display the most recent movement types detected.

Will function with [`addControls()`](#func-addcontrols---navisensmaps), by allowing users to set location as normal, but no longer view marker stats.

#### `func showPath() -> NavisensMaps`

The central function for enabling any marker and trail display. By default, this is disabled, and so no markers or trails are rendered. Use `hideMarkers` to only display the trail and no markers. For more custom behavior, please feel free to modify the main javascript files and add your own functions as desired.

## State Changes

The following methods are used to control the state of the maps object, and will return whether they executed successfully. They always will, unless an invalid state is reached (for example trying to call [`resume()`](#boolean-resume) after calling [`stop()`](#void-stop)

#### `func pause()`

Pauses the MotionDna algorithm, which can save battery when not in use, but remembers the user's last location, heading, etc. (as opposed to stopping the algorithm alltogether).

Use [`resume()`](#func-pause) to resume the algorithm.

#### `func resume()`

Resumes the MotionDna algorithm if it was paused.

#### `func save()`

Saves the current viewport. This allows destroying the view and re-attaching afterwards at the same state.

#### `func restart()`

Restarts the current viewport cache. This will reset all tracked points, along with resetting the user's view position and zoom level.

#### `func stop() -> Bool`

Terminates `NavisensMaps` indefinitely and removes it from the `NavisensCore`.
