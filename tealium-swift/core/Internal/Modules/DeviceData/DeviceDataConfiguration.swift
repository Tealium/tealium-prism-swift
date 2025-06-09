//
//  DeviceDataConfiguration.swift
//  tealium-swift
//
//  Created by Den Guzov on 15/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct DeviceDataConfiguration {
    let deviceNamesUrl: String
    let memoryReportingEnabled: Bool

    enum Keys {
        static let deviceNamesUrl = "device_names_url"
        static let memoryReportingEnabled = "memory_reporting_enabled"
    }

    enum Defaults {
        // TODO: what address should we use here in production?
        static let deviceNamesUrl: String = "https://api.npoint.io/a75cd05931ea972d6577"
        static let memoryReportingEnabled: Bool = false
    }

    init(configuration: DataObject) {
        deviceNamesUrl = configuration.get(key: Keys.deviceNamesUrl) ?? Defaults.deviceNamesUrl
        memoryReportingEnabled = configuration.get(key: Keys.memoryReportingEnabled) ?? Defaults.memoryReportingEnabled
    }
}
