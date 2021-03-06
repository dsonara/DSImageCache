#
# Be sure to run `pod lib lint DSImageCache.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DSImageCache'
  s.version          = '0.1.0'
  s.summary          = 'A lightweight and pure Swift implemented library for downloading and cacheing image from the web.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'DSImageCache is a lightweight, pure-Swift library for downloading and caching images from the web. This project is heavily inspired by the popular SDWebImage. It provides you a chance to use a pure-Swift alternative in your next app.'

  s.homepage         = 'https://github.com/dsonara/DSImageCache'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'dsonara' => 'dsonara@mobiquityinc.com' }
  s.source           = { :git => 'https://github.com/dsonara/DSImageCache.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'DSImageCache/Classes/**/*'
  
  # s.resource_bundles = {
  #   'DSImageCache' => ['DSImageCache/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
