# NaviShare

This plugin helps make doing location sharing and other networking tasks easier.

The latest stable version is `0.2.2`, and it is built on top of iOS MotionDnaSDK version `1.2.2`.

Add the following to your app's dependencies:

```ruby
pod 'NavisensPlugins/NaviShare', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
```

## Setup

1. No setup is required other than that your device must have internet access.
2. (Optional) You should set up your own servers if you wish to deploy your application publicly. The open-source server is written in Golang and can be found [here](https://github.com/navisens/NaviServer).

## API

`NaviShare` is built assuming you are connecting to one of our servers, whether we or you are hosting it.

When you use `NaviShare`, you are connecting a device to a **room**. A **room** is an abstraction which represents a group of devices which are able to talk to each other. Devices not connected to the same room are not able to communicate with each other, while devices within the same room may.

All rooms are keyed based on a `String` that you provide. You can only access rooms that are created by other devices of your organization, and you must know the name of any rooms if you wish to join them (i.e. there is no way to get a "list" of rooms, since even the server doesn't know the room names).

## Initialization

No additional initialization steps are necessary. Just add the plugin like you would any other plugin. It is recommended you add this plugin after setting up other plugins.

```ruby
// In your ViewController
override func viewDidLoad() {
  // ...
  var core: NavisensCore? = NavisensCore(DEVKEY)
  var share: NaviShare? = core!.init(NaviShare.class)
                                     .configureHost("\(hostIP)", andPort: "\(port)");
  // share.connect(...);
}
```

## Server

These methods facilitate connecting to servers for sharing location.

#### `func configureHost(_ host: String, andPort port: String) -> NaviShare`

You must configure `NaviShare` to point to the host and port of the server. If you don't do this, the `connectToRoom` function will not work. You may use `testConnect` during testing if you do not wish to set up a server at this time. The `configureHost` function will not start any services, and you must still make a call to `connectToRoom` before location sharing will start.

#### `func connectToRoom(_ room: String) -> Bool`

Connect to a room. This starts broadcasting location to other devices on the room, and begins receiving any location updates of other devices too.

#### `func disconnect()`

Disconnect from the current room and server, freeing up space for other devices to join the room if it was full.

#### `func testConnect() -> Bool`

Connect to the public test server. You must not be connected to your own server for this to work. Don't use this in the production environment, as there is limited space on the public test server, so it may be possible that you can't make a connection.

## Data

These methods deal with sending and receiving data to/from a room.

#### `func sendMessage(_ msg: String)`

Send a message to all other devices from this device. Best practice to keep these messages web-safe, so they don't get muddled when translated through application layers, or between Android and iOS devices. All messages are encrypted securely.

#### `func addObserver(_ observer: NaviShareObserver)`

Adds an observer to receive data events from other devices, or other events (see below).

#### `func removeObserver(_ observer: NaviShareObserver)`

Removes all instances of an observer so they stop receiving events.

#### `func trackRoom(_ room: String) -> Bool`

Track a room so you can query how full it is. Returns whether the room was added successfully to be tracked.

#### `func untrackRoom(_ room: String) -> Bool`

Remove a room from being tracked.

#### `func refreshRoomStatus() -> Bool`

Sends a query to the server requesting for how many active connections are in each room. The max capacity is set by the server, and so you should know that when you set the options of your server. Returns false if the last query was made very recently.

## `NaviShareObserver`

This protocol provides four callbacks which are used to receive data from other devices in the room.

#### `func messageReceived(fromDevice deviceID: String, withMessage message: String)`

This event is triggered anytime another device sends a message to other devices. The `deviceID` is the ID of the device that sent the `message`.

#### `func roomOccupancyChanged(_ roomOccupancy: Dictionary<String, Int>)`

This event is triggered when a server processes a request to query the number of active connections in each room. To track rooms, use the `trackRoom()` method. Then use `refreshRoomStatus()` whenever you want to make a query.

The `roomOccupancy` argument is a map which maps the room name to a number of connections.

#### `func serverCapacityExceeded()`

This event is triggered when a server has reached the maximum number of rooms it may create as defined by its server properties. This occurs if you try to create a new room. A new room will be created whenever there are zero devices in that room, and rooms will be deleted once all devices have left.

This device will be **disconnected** from the server room afterwards.

#### `func roomCapacityExceeded()`

This event is triggered when a device successfully connects to a server, and attempts to access a room, but the room is already full. Each room has a maximum occupancy as defined by the server properties. If this device attempts to send messages to a room that is full, it will not be successful in sending or receiving any data.

This device will be **disconnected** from the server room afterwards.
