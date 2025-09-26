//
//  DeviceDataSettingsBuilder.swift
//  tealium-swift
//
//  Created by Den Guzov on 19/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

public class DeviceDataSettingsBuilder: CollectorSettingsBuilder {
    typealias Keys = DeviceDataModuleConfiguration.Keys

    /// Set the custom URL from where the devices list with user friendly names (basically, retail ones) is loaded.
    public func setDeviceNamesUrl(_ deviceNamesUrl: String) -> Self {
        _configurationObject.set(deviceNamesUrl, key: Keys.deviceNamesUrl)
        return self
    }

    /// Enable or disable memory reporting by the module.
    /// If `true`, additional data related to memory usage is collected too.
    public func setMemoryReportingEnabled(_ enabled: Bool) -> Self {
        _configurationObject.set(enabled, key: Keys.memoryReportingEnabled)
        return self
    }
}
