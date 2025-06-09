//
//  DeviceDataConstants.swift
//  tealium-swift
//
//  Created by Den Guzov on 15/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

enum DeviceDataKey {
    // MARK: static data
    static let architecture = "device_architecture"
    static let cpuType = "device_cputype"
    static let device = "device"
    static let deviceModel = "device_model"
    static let deviceOrigin = "origin"
    static let deviceType = "device_type"
    static let manufacturer = "device_manufacturer"
    static let modelVariant = "model_variant"
    static let osBuild = "device_os_build"
    static let osName = "os_name"
    static let osVersion = "device_os_version"
    static let platform = "platform"
    static let resolution = "device_resolution"
    static let logicalResolution = "device_logical_resolution"
    // MARK: dynamic data
    static let batteryPercent = "device_battery_percent"
    static let isCharging = "device_ischarging"
    static let language = "device_language"
    static let appMemoryUsage = "app_memory_usage"
    static let memoryActive = "memory_active"
    static let memoryFree = "memory_free"
    static let memoryInactive = "memory_inactive"
    static let memoryCompressed = "memory_compressed"
    static let memoryWired = "memory_wired"
    static let physicalMemory = "memory_physical"
    static let orientation = "device_orientation"
    static let extendedOrientation = "device_orientation_extended"
}
