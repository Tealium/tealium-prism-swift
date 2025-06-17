//
//  DeviceDataProviderIOSTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 28/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import UIKit
import XCTest

class DeviceDataProviderIOSTests: XCTestCase {
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
            "iPhone14,8": [
                "device_model": "iPhone 14 Plus",
                "model_variant": "Golden Brown"
            ]
        ])
        guard let modelInfo = deviceDataProvider.getModelInfo(from: modelsObject, model: "iPhone14,8") else {
            XCTFail("No model info found")
            return
        }
        XCTAssertEqual(modelInfo.get(key: "device_type"), "iPhone14,8")
        XCTAssertEqual(modelInfo.get(key: "device_model"), "iPhone 14 Plus")
        XCTAssertEqual(modelInfo.get(key: "device"), "iPhone 14 Plus")
        XCTAssertEqual(modelInfo.get(key: "model_variant"), "Golden Brown")
    }

    func test_deviceOrigin() {
        XCTAssertEqual(deviceDataProvider.deviceOrigin, "mobile")
    }

    func test_batteryPercent() {
        let percent = deviceDataProvider.batteryPercent
        #if targetEnvironment(simulator)
        XCTAssertEqual(percent, "-100")
        #else
        XCTAssertNotEqual(percent, "-100")
        XCTAssertNotEqual(percent, "")
        #endif
    }

    func test_isCharging() {
        let isCharging = deviceDataProvider.isCharging
        #if targetEnvironment(simulator)
        XCTAssertEqual(isCharging, TealiumConstants.unknown)
        #endif
    }

    func test_resolution() {
        XCTAssertNotNil(deviceDataProvider.resolution
            .range(of: #"\d+x\d+"#, options: .regularExpression, range: nil, locale: nil))
    }

    func test_logicalResolution() {
        XCTAssertNotNil(deviceDataProvider.logicalResolution
            .range(of: #"\d+x\d+"#, options: .regularExpression, range: nil, locale: nil))
    }

    func test_getScreenOrientation_returns_unknown_orientation_when_cannot_get_it() {
        let expected = expectation(description: "Orientation is unknown")
        deviceDataProvider.getScreenOrientation { orientationData in
                XCTAssertEqual(orientationData.get(key: DeviceDataKey.orientation), TealiumConstants.unknown)
                XCTAssertEqual(orientationData.get(key: DeviceDataKey.extendedOrientation), TealiumConstants.unknown)
                expected.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_getScreenOrientation_returns_correct_orientation() {
        let expected = expectation(description: "Orientation is correct")
        expected.expectedFulfillmentCount = 2
        let deviceDataProvider1 = DeviceDataProvider(orientationProvider: {
            [
                DeviceDataKey.orientation: ExtendedOrientation.landscape,
                DeviceDataKey.extendedOrientation: ExtendedOrientation.landscapeLeft
            ]
        })
        deviceDataProvider1.getScreenOrientation { orientationData in
            XCTAssertEqual(orientationData.get(key: DeviceDataKey.orientation), ExtendedOrientation.landscape)
            XCTAssertEqual(orientationData.get(key: DeviceDataKey.extendedOrientation), ExtendedOrientation.landscapeLeft)
                expected.fulfill()
        }
        let deviceDataProvider2 = DeviceDataProvider(orientationProvider: {
            [
                DeviceDataKey.orientation: ExtendedOrientation.portrait,
                DeviceDataKey.extendedOrientation: ExtendedOrientation.portraitUpsideDown
            ]
        })
        deviceDataProvider2.getScreenOrientation { orientationData in
            XCTAssertEqual(orientationData.get(key: DeviceDataKey.orientation), ExtendedOrientation.portrait)
            XCTAssertEqual(orientationData.get(key: DeviceDataKey.extendedOrientation), ExtendedOrientation.portraitUpsideDown)
                expected.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_osName() {
        XCTAssertEqual(deviceDataProvider.osName, DeviceDataProvider.OSName.iOS)
    }
}
