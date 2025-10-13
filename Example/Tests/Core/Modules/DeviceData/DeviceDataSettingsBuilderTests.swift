//
//  DeviceDataSettingsBuilderTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 28/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DeviceDataSettingsBuilderTests: XCTestCase {
    func test_build_without_setters_returns_empty_configuration() {
        let settings = DeviceDataSettingsBuilder().build()
        XCTAssertEqual(settings, ["configuration": DataObject()])
    }

    func test_build_returns_correct_module_settings() throws {
        let settings = DeviceDataSettingsBuilder()
            .setEnabled(true)
            .setDeviceNamesUrl("someUrl")
            .setMemoryReportingEnabled(true)
            .setBatteryReportingEnabled(false)
            .setScreenReportingEnabled(false)
            .build()
        XCTAssertEqual(settings,
                       [
                        "enabled": true,
                        "configuration":
                            try DataItem(serializing: [
                                "device_names_url": "someUrl",
                                "memory_reporting_enabled": true,
                                "battery_reporting_enabled": false,
                                "screen_reporting_enabled": false
                            ])
                       ])
    }
}
