#
# Be sure to run `pod lib lint novid20Proximity.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'novid20Proximity'
  s.version          = '0.1.0'
  s.summary          = 'A short description of novid20Proximity.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/mahmoud@eldesouky.com/novid20Proximity'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mahmoud@eldesouky.com' => 'eldesouky@dolph.in' }
  s.source           = { :git => 'https://github.com/mahmoud@eldesouky.com/novid20Proximity.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  s.source_files = 'novid20Proximity/Classes/**/*.{h,m,swift}'

  s.frameworks = 'UIKit', 'Coredata'
  s.resources = 'novid20Proximity/**/*.{xcdatamodeld, swift}'
  end
