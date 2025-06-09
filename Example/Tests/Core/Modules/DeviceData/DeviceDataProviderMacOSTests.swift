//
//  DeviceDataProviderMacOSTests.swift
//  CoreTests_tvOS
//
//  Created by Den Guzov on 28/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DeviceDataProviderMacOSTests: XCTestCase {
    let deviceDataProvider = DeviceDataProvider()

    func test_cpuType() {
        let cpuType = deviceDataProvider.cpuType
        let desktopCPUs = ["x86", "ARM64e"]
        XCTAssertTrue(desktopCPUs.contains(cpuType))
    }

    func test_basicModel() {
        let basicModel = DeviceDataProvider.basicModel
        XCTAssertNotNil(basicModel)
        XCTAssertNotEqual(basicModel, "")
    }

    func test_getModelInfo_returns_expected_data_if_model_info_exists() {
        let modelsObject = DataObject(dictionaryInput: [
            "Mac15,7": [
                "device_model": "MacBook Pro (16-inch, M3 Pro, Late 2023)",
                "model_variant": "3.5mm headphone jack"
            ]
        ])
        guard let modelInfo = deviceDataProvider.getModelInfo(from: modelsObject, model: "Mac15,7") else {
            XCTFail("No model info found")
            return
        }
        XCTAssertEqual(modelInfo.get(key: "device_type"), "Mac15,7")
        XCTAssertEqual(modelInfo.get(key: "device_model"), "MacBook Pro (16-inch, M3 Pro, Late 2023)")
        XCTAssertEqual(modelInfo.get(key: "device"), "MacBook Pro (16-inch, M3 Pro, Late 2023)")
        XCTAssertEqual(modelInfo.get(key: "model_variant"), "3.5mm headphone jack")
    }

    func test_deviceOrigin() {
        XCTAssertEqual(deviceDataProvider.deviceOrigin, "desktop")
    }

    func test_batteryPercent() {
        XCTAssertEqual(deviceDataProvider.batteryPercent, TealiumConstants.unknown)
    }

    func test_isCharging() {
        XCTAssertEqual(deviceDataProvider.isCharging, TealiumConstants.unknown)
    }

    func test_resolution() {
        XCTAssertEqual(deviceDataProvider.resolution, TealiumConstants.unknown)
    }

    func test_logicalResolution() {
        XCTAssertEqual(deviceDataProvider.logicalResolution, TealiumConstants.unknown)
    }

    func test_getScreenOrientation_returns_unknown_orientation_when_not_iOS() {
        let expected = expectation(description: "Orientation is unknown")
        deviceDataProvider.getScreenOrientation { orientationData in
                XCTAssertEqual(orientationData.get(key: DeviceDataKey.orientation), TealiumConstants.unknown)
                XCTAssertEqual(orientationData.get(key: DeviceDataKey.extendedOrientation), TealiumConstants.unknown)
                expected.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_osName() {
        XCTAssertEqual(deviceDataProvider.osName, DeviceDataProvider.OSName.macOS)
    }
}
