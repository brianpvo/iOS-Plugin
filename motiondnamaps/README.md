# Motion Dna Maps

This is a plugin that provides a quick-and-easy map built upon [leafletjs](http://leafletjs.com/).

The latest stable version is `0.2.0`.

To include the plugin in your code, add the following to your podfile

```ruby
  pod 'MotionDnaPlugins/MotionDnaMaps', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
```

## Setup

1. Add all permissions necessary for your app. `MotionDnaSDK` requires you to add the following permission to `Info.plist`: `NSLocationWhenInUseUsageDescription`

2. Add background mode capabilities in `Capabilities`, set `Background Modes` to "ON", and check the `Location updates` option

3. The `MotionDnaMaps` is an extension of the `WKWebView` object. To add it in, go to your storyboard, and create a `Container View`. Position it however you like, and link it to your view controller. We will add the `MotionDnaMaps` in the next part.

4. Go to your view controller, import the `MotionDnaMaps`, and declare a new variable. For this example, we will be using `Swift`

```swift
  private var maps: MotionDnaMaps?
```

5. In `viewDidLoad`, we will create the `MotionDnaMaps` instance, set up any settings, add it to our storyboard, and finally begin running it

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

Also coming soon! But really it's just the same as the [android one here](https://github.com/navisens/Android-Plugin/tree/master/motiondnamaps)
