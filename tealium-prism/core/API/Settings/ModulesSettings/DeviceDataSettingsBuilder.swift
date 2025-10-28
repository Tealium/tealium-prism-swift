//
//  DeviceDataSettingsBuilder.swift
//  tealium-prism
//
//  Created by Den Guzov on 19/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// Builder for configuring `DeviceData` module settings.
public class DeviceDataSettingsBuilder: CollectorSettingsBuilder {
    typealias Keys = DeviceDataModuleConfiguration.Keys

    /// Set the custom URL from where the devices list with user friendly names (basically, retail ones) is loaded.
    public func setDeviceNamesUrl(_ deviceNamesUrl: String) -> Self {
        _configurationObject.set(deviceNamesUrl, key: Keys.deviceNamesUrl)
        return self
    }

    /// Enable or disable memory info reporting by the module.
    /// If `true`, additional data related to memory usage is collected too.
    public func setMemoryReportingEnabled(_ enabled: Bool) -> Self {
        _configurationObject.set(enabled, key: Keys.memoryReportingEnabled)
        return self
    }

    /// Enable or disable battery info reporting by the module.
    /// If `true`, additional data related to battery charge is collected too.
    public func setBatteryReportingEnabled(_ enabled: Bool) -> Self {
        _configurationObject.set(enabled, key: Keys.batteryReportingEnabled)
        return self
    }

    /// Enable or disable screen info reporting by the module.
    /// If `true`, additional data related to screen resolution and orientation is collected too.
    public func setScreenReportingEnabled(_ enabled: Bool) -> Self {
        _configurationObject.set(enabled, key: Keys.screenReportingEnabled)
        return self
    }
}
