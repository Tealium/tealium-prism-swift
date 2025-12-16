Pod::Spec.new do |s|
  s.name             = 'tealium-prism'
  s.module_name      = "TealiumPrism"
  s.version          = '0.2.0'
  s.summary          = 'Tealium Prism Integration Library'

  s.description      = <<-DESC
                       Integrates the Tealium CDP into your iOS, macOS, tvOS and watchOS apps.
                       DESC

  s.homepage         = 'https://github.com/Tealium/tealium-prism'
  s.license          = { :type => "Commercial", :file => "LICENSE" }
  s.authors          = { "Tealium Inc." => "dev@tealium.com" }
  s.source       = { :git => "https://github.com/Tealium/tealium-prism-swift.git", :tag => "#{s.version}" }
  s.social_media_url = "http://twitter.com/tealium"

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = "10.15"
  s.watchos.deployment_target = "7.0"
  s.tvos.deployment_target = "13.0"

  s.swift_version = '5.0'
  s.dependency 'SQLite.swift', '~> 0.15.0'
  
  s.subspec "Core" do |core|
      core.source_files = "tealium-prism/Core/**/*.{swift,h,m}"
    end

  s.subspec "Lifecycle" do |lifecycle|
      lifecycle.source_files = "tealium-prism/Lifecycle/**/*.{swift,h,m}"
      lifecycle.dependency "tealium-prism/Core"
    end
end
