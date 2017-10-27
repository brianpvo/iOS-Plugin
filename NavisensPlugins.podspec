#
# Be sure to run `pod lib lint NavisensPlugins.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'NavisensPlugins'
s.version          = '1.0.0'
s.summary          = 'Provides different plugins for MotionDnaSDK.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

s.description      = <<-DESC
NavisensPlugins contains a list of various plugin to be used with MotionDnaSDK. They provide additional functionality in an easy-to-use and modular format. Make sure you have access to a MotionDnaSDK developer key before using this! See navisens.com for more information.
DESC

s.homepage         = 'https://github.com/navisens/iOS-Plugin'
s.license          = { :type => 'BSD-3', :file => 'LICENSE' }
s.author           = { 'Joseph Chen' => 'joseph.chen@navisens.com' }
s.source           = {
  :git => 'https://github.com/navisens/iOS-Plugin.git',
  :branch => 'repositories',
  :submodules => true,
  :tag => s.version.to_s
}

s.ios.deployment_target = '9.1'

# s.subspec 'MotionDnaMaps' do |maps|
#   maps.ios.vendored_frameworks = 'motiondnamaps/MotionDnaMaps.framework'
# end

s.subspec 'NavisensCore' do |core|
  core.ios.vendored_frameworks = 'navisenscore/NavisensCore.framework'
end

end
