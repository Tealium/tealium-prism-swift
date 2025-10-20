//
//  DeviceDataProviderWatchOSTests.swift
//  CoreTests_watchOS
//
//  Created by Enrico Zannini on 10/10/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DeviceDataProviderWatchOSTests: XCTestCase {
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
            "Watch7,8": [
                "device_model": "Apple Watch Series 10",
                "model_variant": "42mm"
            ]
        ])
        guard let modelInfo = deviceDataProvider.getModelInfo(from: modelsObject, model: "Watch7,8") else {
            XCTFail("No model info found")
            return
        }
        XCTAssertEqual(modelInfo.get(key: "device_type"), "Watch7,8")
        XCTAssertEqual(modelInfo.get(key: "device_model"), "Apple Watch Series 10")
        XCTAssertEqual(modelInfo.get(key: "device"), "Apple Watch Series 10")
        XCTAssertEqual(modelInfo.get(key: "model_variant"), "42mm")
    }

    func test_deviceOrigin() {
        XCTAssertEqual(deviceDataProvider.deviceOrigin, "watch")
    }

    func test_batteryPercent() {
        XCTAssertEqual(deviceDataProvider.batteryPercent, TealiumConstants.unknown)
    }

    func test_isCharging() {
        XCTAssertEqual(deviceDataProvider.isCharging, TealiumConstants.unknown)
    }

    func test_resolution() {
        XCTAssertNotNil(deviceDataProvider.resolution
            .range(of: #"\d+x\d+"#, options: .regularExpression, range: nil, locale: nil))
    }

    func test_logicalResolution() {
        XCTAssertNotNil(deviceDataProvider.logicalResolution
            .range(of: #"\d+x\d+"#, options: .regularExpression, range: nil, locale: nil))
    }

    func test_getScreenOrientation_returns_unknown_orientation_when_not_iOS() {
        let orientationData = deviceDataProvider.getScreenOrientation()
        XCTAssertEqual(orientationData.get(key: DeviceDataKey.orientation), TealiumConstants.unknown)
        XCTAssertEqual(orientationData.get(key: DeviceDataKey.extendedOrientation), TealiumConstants.unknown)
    }

    func test_osName() {
        XCTAssertEqual(deviceDataProvider.osName, DeviceDataProvider.OSName.watchOS)
    }
}
