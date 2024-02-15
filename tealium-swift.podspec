#
# Be sure to run `pod lib lint tealium-swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'tealium-swift'
  s.module_name      = "TealiumSwift"
  s.version          = '3.0.0'
  s.summary          = 'Tealium Swift Integration Library'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                       Supports Tealium's iQ and UDH suite of products on iOS, macOS, tvOS and watchOS
                       DESC

  s.homepage         = 'https://github.com/Tealium/tealium-swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => "Commercial", :file => "LICENSE" }
  s.authors          = { "Tealium Inc." => "tealium@tealium.com",
                         "craigrouse"   => "craig.rouse@tealium.com",
                         "Enrico Zannini" => "enrico.zannini@tealium.com" }
  s.source       = { :git => "https://github.com/Tealium/tealium-swift-v3.git", :tag => "#{s.version}" }
  s.social_media_url = "http://twitter.com/tealium"

  s.ios.deployment_target = '12.0'

  s.swift_version = '5.0'
  s.dependency 'SQLite.swift', '~> 0.14.0'
  
  s.subspec "Core" do |core|
      core.source_files = "tealium-swift/Core/**/*.{swift,h,m}"
    end
end
