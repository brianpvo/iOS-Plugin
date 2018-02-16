# Navisens/iOS-Plugin

This repository contains plugins supported for iOS built on top of our [MotionDnaSDK](https://github.com/navisens/iOS-SDK).

The set up works by adding additional dependencies to your podfile.

*The source code for all plugins is also provided to allow for full customization!*

## Setup

To add an additional plugin, modify your podfile. Simply install the `navisenscore` plugin, and then add any other plugins

```ruby
target '<PROJECT NAME>' do
  # ...
  pod 'NavisensPlugins/NavisensCore', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
  pod 'NavisensPlugins/<PLUGIN NAME>', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories'
end
```

The `<PLUGIN NAME>` contains the plugin you want to install. You can provide an optional `:commit` tag if you wish to specify a specific version of the plugin.

Example: to import version 0.0.12 of the NavisensMaps plugin for a MapNavigation project, use

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.1'

target 'MapNavigation’ do
  use_frameworks!
  pod 'MotionDnaSDK', :git => 'https://github.com/navisens/iOS-SDK.git'
  pod 'NavisensPlugins/NavisensCore', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories', :commit => 'cefe3a0b77'
  pod 'NavisensPlugins/NavisensMaps', :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories', :commit => 'cefe3a0b77'
end
```

## Core

You must have the **[Navisens Core](navisenscore)** set up before you can use any plugins.

## Plugins

The following is a list of all supported plugins. Special setup instructions and relevant stable version numbers linked.

#### [Navisens Maps](navisensmaps)

Quick and easy maps support built upon [leafletjs](http://leafletjs.com)

#### [NaviShare](navishare)

Wrapper which makes it easy to connect to servers and share location or even raw data between devices.

#### [NaviBeacon](navibeacon)

Adds support for syncing your location with iBeacons.

#### [NaviPoints](navipoints)

Adds a simple way of adding named points and initializing user location based on these points.
