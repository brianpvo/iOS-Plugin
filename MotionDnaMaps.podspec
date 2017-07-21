#
# Be sure to run `pod lib lint MotionDnaMaps.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MotionDnaMaps'
  s.version          = '0.1.1'
  s.summary          = 'Provides placeholder simple maps view for displaying MotionDnaSDK location.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
MotionDnaMaps allows easy adding of a simple maps view, for displaying location data streamed from a MotionDnaSDK instance. Make sure you have access to a MotionDnaSDK developer key before using this! See navisens.com for more information.
                       DESC

  s.homepage         = 'https://github.com/navisens/iOS-Plugin'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'BSD-3', :file => 'LICENSE' }
  s.author           = { 'Joseph Chen' => 'joseph.chen@navisens.com' }
s.source           = { :git => 'https://github.com/navisens/iOS-Plugin.git', :branch => 'repositories', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.1'

  # s.source_files = 'MotionDnaMaps/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MotionDnaMaps' => ['MotionDnaMaps/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

  s.ios.vendored_frameworks = 'MotionDnaMaps.framework'

end
