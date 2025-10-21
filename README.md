# tealium-prism

[![Version](https://img.shields.io/cocoapods/v/tealium-prism.svg?style=flat)](https://cocoapods.org/pods/tealium-prism)
[![License](https://img.shields.io/cocoapods/l/tealium-prism.svg?style=flat)](https://github.com/Tealium/tealium-prism/blob/main/LICENSE.txt)
[![Platform](https://img.shields.io/cocoapods/p/tealium-prism.svg?style=flat)](https://cocoapods.org/pods/tealium-prism)

A library to integrate the Tealium CDP into your iOS, macOS, tvOS and watchOS apps.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
Minimum OS versions:
- iOS: 13.0
- tvOS: 13.0
- macOS: 10.15
- watchOS: 7.0

## Installation

### Swift Package Manager
tealium-prism is currently available via [Swift Package Manager](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/). To install:

1. In your Xcode project, select File > Add Package Dependencies.
2. Enter the repository URL: https://github.com/tealium/tealium-prism-swift
3. Configure the version rules. Typically, Up to next major is recommended. If the current Tealium Prism library version does not appear in the list, then reset your Swift package cache.
4. Select the modules to install, and select the app target you want the modules to be installed in.

### Cocoapods (Coming Soon)
tealium-prism will be available through [CocoaPods](https://cocoapods.org). To install
it once it's released, simply add the following line to your Podfile:

```ruby
pod 'tealium-prism'
```

### Carthage (Coming Soon)
tealium-prism will be available through [Carthage](https://github.com/Carthage/Carthage). To install once it's released:


1. Add the following to your Cartfile:

```
github "tealium/tealium-prism-swift"
```

2. To produce frameworks for iOS, macOS, tvOS and watchOS, run the following command:

```
carthage update --use-xcframeworks
```

3. Drag the frameworks you require into your Xcode project’s General > Embedded Binaries section.

## Usage
To start using the library:

1. Import the necessary modules
2. Initialize a `Tealium` instance
3. Start tracking events.

```swift
#if COCOAPODS
import TealiumPrism
#else
import TealiumPrismCore
import TealiumPrismLifecycle
#endif

let config = TealiumConfig(account: "my_account",
                           profile: "my_profile",
                           environment: "prod",
                           modules: [
                            Modules.appData(),
                            Modules.collect(),
                            Modules.connectivityData(),
                            Modules.deepLink(),
                            Modules.deviceData(),
                            Modules.lifecycle(),
                            Modules.timeData(),
                            Modules.trace(),
                           ],
                           settingsFile: nil,
                           settingsUrl: nil)
let tealium = Tealium.create(config: config)
tealium.track("An Event")
```

## License

tealium-prism is available under a commercial license. See the [LICENSE](./LICENSE) file for more info.
