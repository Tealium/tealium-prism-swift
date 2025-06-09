//
//  DeviceDataProvider+Battery.swift
//  tealium-swift
//
//  Created by Den Guzov on 21/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if os(OSX)
#else
import UIKit
#endif

extension DeviceDataProvider {
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .none
        return formatter
    }()
    /// - Returns: `String` battery percentage
    var batteryPercent: String {
        // only available on iOS
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel * 100
        return Self.formatter.string(from: NSNumber(value: batteryLevel)) ?? TealiumConstants.unknown
        #else
        return TealiumConstants.unknown
        #endif
    }

    /// - Returns: `String` true if charging
    var isCharging: String {
        // only available on iOS
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        let state = UIDevice.current.batteryState
        switch state {
        case .charging:
            return "true"
        case .full:
            return "false"
        case .unplugged:
            return "false"
        default:
            return TealiumConstants.unknown
        }
        #else
        return TealiumConstants.unknown
        #endif
    }
}
