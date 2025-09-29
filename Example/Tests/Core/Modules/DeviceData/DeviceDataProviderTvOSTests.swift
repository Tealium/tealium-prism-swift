//
//  DeviceDataProviderTvOSTests.swift
//  CoreTests_tvOS
//
//  Created by Den Guzov on 28/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import UIKit
import XCTest

final class DeviceDataProviderTvOSTests: XCTestCase {
    let deviceDataProvider = DeviceDataProvider()

    func test_cpuType() {
        let cpuType = deviceDataProvider.cpuType
        #if targetEnvironment(simulator)
        XCTAssertEqual(cpuType, "ARM64e")
        #else
        XCTAssertNotEqual(cpuType, "x86")
        #endif
        XCTAssertNotEqual(cpuType, TealiumConstants.unknown)
    }

    func test_basicModel() {
        let model = DeviceDataProvider.basicModel
        #if targetEnvironment(simulator)
        XCTAssertEqual(model, "x86_64")
        #endif
        XCTAssertNotEqual(model, TealiumConstants.unknown)
    }

    func test_getModelInfo_returns_expected_data_if_model_info_exists() {
        let modelsObject = DataObject(dictionaryInput: [
            "AppleTV14,1": [
                "device_model": "Apple TV 4K 3rd Generation",
                "model_variant": "OLED"
            ]
        ])
        guard let modelInfo = deviceDataProvider.getModelInfo(from: modelsObject, model: "AppleTV14,1") else {
            XCTFail("No model info found")
            return
        }
        XCTAssertEqual(modelInfo.get(key: "device_type"), "AppleTV14,1")
        XCTAssertEqual(modelInfo.get(key: "device_model"), "Apple TV 4K 3rd Generation")
        XCTAssertEqual(modelInfo.get(key: "device"), "Apple TV 4K 3rd Generation")
        XCTAssertEqual(modelInfo.get(key: "model_variant"), "OLED")
    }

    func test_deviceOrigin() {
        XCTAssertEqual(deviceDataProvider.deviceOrigin, "tv")
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
        let expected = expectation(description: "Orientation is unknown")
        deviceDataProvider.getScreenOrientation { orientationData in
                XCTAssertEqual(orientationData.get(key: DeviceDataKey.orientation), TealiumConstants.unknown)
                XCTAssertEqual(orientationData.get(key: DeviceDataKey.extendedOrientation), TealiumConstants.unknown)
                expected.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_osName() {
        XCTAssertEqual(deviceDataProvider.osName, DeviceDataProvider.OSName.tvOS)
    }
}
