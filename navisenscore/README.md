# Navisens Core

This is the core upon which all other Navisens Plugins are built on. The `NavisensCore` is a required component of any project that uses any Navisens Plugins. For a list of plugins available, see [the main page.](https://github.com/navisens/iOS-Plugin)

The latest stable version is `2.0.1`, and it is built on top of iOS MotionDnaSDK version `1.2.2`.

Add the following to your podfile above all other plugins:

```ruby
pod 'NavisensPlugins/NavisensCore', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
```

## Setup

No additional setup is required.

## API

`NavisensCore` provides some useful utility functions to help structure your plugins.

## Setup

`NavisensCore` has one constructor, which must be called early in app creation. This sets up any framework required to get your other plugins up and running!

#### `init(_ devkey: String)`

The `NavisensCore` requires your developer's key in order to function. Please contact us to apply for a developer's key from [here](https://developer.navisens.com) if you do not have one and wish to try out `Navisens MotionDna`. Also check out the quickstart if you aren't familiar with our SDK tools [here](https://github.com/navisens/NaviDocs).

## Plugin Management and Other

The following methods are provided to help in managing your plugins. The basic operations allow add a plugin or stop a plugin. You should not need to call any other methods in the `NavisensCore`, as most plugins will make all relevant calls for you. Only call methods not listed if you absolutely know what you are doing :D.

The plugin structure is designed to be easily expandable. Check out our tutorials if you are curious in developing your own plugins!

#### `func add<T: NavisensPlugin> (_ navisensPlugin: T.Type, withParams params: Any...) -> T?`

This is your main entry point for adding and initializing any plugin. While it may seem overly complicated, this method is actually very simple. Simply pass in the type of the plugin you wish to initialize, and a new instance will be returned for you. Internally, we also add multiple hooks for setting up the plugin, but you don't need to worry about that!

The following example assumes you have imported a plugin called `NavisensMaps` and would like to initialize an instance of it.
```swift
// In your ViewController
override func viewDidLoad() {
  // ...
  core = NavisensCore(DEVKEY)
  maps = core!.add(NavisensMaps.self)?
                   .useLocalOnly()
                   .enableLocationSharing()
  // Notice that we can call methods of NavisensMaps directly after initializing!
}
```

#### `func stop() -> Bool`

Stops the `NavisensCore`. Please make sure that all other plugins have completed running, otherwise this method will return false.

#### `func stop(_ plugin: NavisensPlugin) -> Bool`

Stop a specific `NavisensPlugin`. This will return false if for some reason the plugin you passed in can not be stopped, or it does not exist anymore (i.e. it was already stopped).

#### `func stopAll() -> Bool`

Interrupts and stops all plugins, then shuts down the `NavisensCore`. This method will return false if any plugin refuses to stop. In this case, you may either call `stopAll` again at a later time, or simply quit your application.
