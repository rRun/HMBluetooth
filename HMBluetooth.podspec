#
# Be sure to run `pod lib lint HMBluetooth.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HMBluetooth'
  s.version          = '0.1.5'
  s.summary          = '蓝牙测量设备整理'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                    蓝牙测量设备整理,血压，血糖
                       DESC

  s.homepage         = 'https://github.com/rRun/HMBluetooth'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'hexy' => 'hexy@cdfortis.com' }
  s.source           = { :git => 'https://github.com/rRun/HMBluetooth.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '7.0'

  s.source_files = 'HMBluetooth/Classes/**/*'
  
  # s.resource_bundles = {
  #   'HMBluetooth' => ['HMBluetooth/Assets/*.png']
  # }

  #  s.public_header_files = 'HMBluetooth/Classes/HMBluetooth.h'

  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

end
