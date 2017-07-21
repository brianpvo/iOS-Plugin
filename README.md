# Navisens/iOS-Plugin

This repository contains plugins supported for iOS built on top of out [MotionDnaSDK](https://github.com/navisens/iOS-SDK).

The set up works by adding additional dependencies to your podfile.

## Setup

To add an additional plugin, simply add the following to your podfile

```podfile
target '<PROJECT NAME>' do
  # ...
  pod 'MotionDnaPlugins/<PLUGIN NAME>', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
end
```

The `<PLUGIN NAME>` contains the plugin you want to install. You can provide an optional `:commit` tag if you wish to specify a specific version of the plugin.

Example: to import the MotionDnaMaps plugin for a MapNavigation project, use

```podfile
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.1'

target 'MapNavigation’ do
  use_frameworks!
  pod 'MotionDnaSDK', :git => 'https://github.com/navisens/iOS-SDK.git'
  pod 'MotionDnaPlugins/MotionDnaMaps', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
end
```

The source code for projects is also provided to allow for full customization.

## Plugins

The following is a list of all supported plugins. Special setup instructions and relevant stable version numbers linked.

#### [MotionDna maps](motiondnamaps)

Quick and easy maps support built upon [leafletjs](http://leafletjs.com)

#### Coming soon...

Summary info

#### Coming soon too...

Summary info again
