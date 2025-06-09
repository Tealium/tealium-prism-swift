//
//  DeviceDataConfigurationTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 30/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DeviceDataConfigurationTests: XCTestCase {
    func test_init_with_empty_object_returns_settings_with_correct_defaults() {
        let configuration = DeviceDataConfiguration(configuration: [:])
        XCTAssertEqual(configuration.deviceNamesUrl, DeviceDataConfiguration.Defaults.deviceNamesUrl)
        XCTAssertEqual(configuration.memoryReportingEnabled, DeviceDataConfiguration.Defaults.memoryReportingEnabled)
    }

    func test_init_with_dataObject_returns_correct_configuration() {
        let configuration = DeviceDataConfiguration(configuration: [
            "device_names_url": "test.it",
            "memory_reporting_enabled": true
        ])
        XCTAssertEqual(configuration.deviceNamesUrl, "test.it")
        XCTAssertEqual(configuration.memoryReportingEnabled, true)
    }
}
