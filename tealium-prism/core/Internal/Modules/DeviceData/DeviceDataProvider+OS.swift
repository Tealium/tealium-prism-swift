//
//  DeviceDataProvider+OS.swift
//  tealium-prism
//
//  Created by Den Guzov on 21/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if os(OSX)
import Foundation
#else
import UIKit
#endif
#if os(watchOS)
import WatchKit
#endif

extension DeviceDataProvider {
    enum OSName {
        static let iOS: String = "iOS"
        static let tvOS: String = "tvOS"
        static let watchOS: String = "watchOS"
        static let macOS: String = "macOS"
    }

    var osBuild: String {
        guard let build = Bundle.main.infoDictionary?["DTSDKBuild"] as? String else {
            return TealiumConstants.unknown
        }
        return build
    }

    var osName: String {
        #if os(iOS)
        return OSName.iOS
        #elseif os(tvOS)
        return OSName.tvOS
        #elseif os(watchOS)
        return OS.watchOS
        #elseif os(OSX)
        return OSName.macOS
        #else
        return TealiumConstants.unknown
        #endif
    }

    var osVersion: String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(tvOS)
        return UIDevice.current.systemVersion
        #elseif os(watchOS)
        return WKInterfaceDevice.current().systemVersion
        #elseif os(OSX)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #else
        return TealiumConstants.unknown
        #endif
    }
}
