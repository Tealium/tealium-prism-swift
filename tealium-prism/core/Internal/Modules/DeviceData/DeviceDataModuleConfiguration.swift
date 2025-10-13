//
//  DeviceDataModuleConfiguration.swift
//  tealium-prism
//
//  Created by Den Guzov on 15/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct DeviceDataModuleConfiguration {
    let deviceNamesUrl: String
    let memoryReportingEnabled: Bool
    let batteryReportingEnabled: Bool
    let screenReportingEnabled: Bool

    enum Keys {
        static let deviceNamesUrl = "device_names_url"
        static let memoryReportingEnabled = "memory_reporting_enabled"
        static let batteryReportingEnabled = "battery_reporting_enabled"
        static let screenReportingEnabled = "screen_reporting_enabled"
    }

    enum Defaults {
        private static let deviceNamesEndpoint = "/dle/tealiummobile/lib/device_names.json"
        static let deviceNamesUrl: String = TealiumConstants.tiqCdn + deviceNamesEndpoint
        static let memoryReportingEnabled: Bool = false
        static let batteryReportingEnabled: Bool = true
        static let screenReportingEnabled: Bool = true
    }

    init(configuration: DataObject) {
        deviceNamesUrl = configuration.get(key: Keys.deviceNamesUrl) ?? Defaults.deviceNamesUrl
        memoryReportingEnabled = configuration.get(key: Keys.memoryReportingEnabled) ?? Defaults.memoryReportingEnabled
        batteryReportingEnabled = configuration.get(key: Keys.batteryReportingEnabled) ?? Defaults.batteryReportingEnabled
        screenReportingEnabled = configuration.get(key: Keys.screenReportingEnabled) ?? Defaults.screenReportingEnabled
    }
}
