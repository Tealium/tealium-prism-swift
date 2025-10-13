//
//  DeviceDataModuleConfigurationTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 30/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DeviceDataModuleConfigurationTests: XCTestCase {
    func test_init_with_empty_object_returns_settings_with_correct_defaults() {
        let configuration = DeviceDataModuleConfiguration(configuration: [:])
        XCTAssertEqual(configuration.deviceNamesUrl, DeviceDataModuleConfiguration.Defaults.deviceNamesUrl)
        XCTAssertEqual(configuration.memoryReportingEnabled, DeviceDataModuleConfiguration.Defaults.memoryReportingEnabled)
        XCTAssertEqual(configuration.batteryReportingEnabled, DeviceDataModuleConfiguration.Defaults.batteryReportingEnabled)
        XCTAssertEqual(configuration.screenReportingEnabled, DeviceDataModuleConfiguration.Defaults.screenReportingEnabled)
    }

    func test_init_with_dataObject_returns_correct_configuration() {
        let configuration = DeviceDataModuleConfiguration(configuration: [
            "device_names_url": "test.it",
            "memory_reporting_enabled": true,
            "battery_reporting_enabled": false,
            "screen_reporting_enabled": false
        ])
        XCTAssertEqual(configuration.deviceNamesUrl, "test.it")
        XCTAssertEqual(configuration.memoryReportingEnabled, true)
        XCTAssertEqual(configuration.batteryReportingEnabled, false)
        XCTAssertEqual(configuration.screenReportingEnabled, false)
    }
}
