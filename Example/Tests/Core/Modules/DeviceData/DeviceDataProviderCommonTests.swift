//
//  DeviceDataProviderCommonTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 06/06/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DeviceDataProviderCommonTests: XCTestCase {
    let deviceDataProvider = DeviceDataProvider()

    func test_architecture() {
        let architecture = deviceDataProvider.architecture
        XCTAssert(architecture == "64" || architecture == "32")
    }

    func test_getModelInfo_returns_nil_if_model_is_unknown() {
        let modelsObject = DataObject(dictionaryInput: [
            "not_existing": [
                "device_model": "unknown",
                "model_variant": "not_known"
            ]
        ])
        XCTAssertNil(deviceDataProvider.getModelInfo(from: modelsObject))
    }

    func test_osBuild() {
        let osBuild = deviceDataProvider.osBuild
        XCTAssertNotNil(osBuild)
        XCTAssertNotEqual(osBuild, TealiumConstants.unknown)
    }

    func test_osVersion() {
        let osVersion = deviceDataProvider.osVersion
        XCTAssertNotNil(osVersion)
        XCTAssertNotEqual(osVersion, TealiumConstants.unknown)
    }

    func test_memoryUsage() {
        let memoryUsage = deviceDataProvider.memoryUsage
        XCTAssertEqual(memoryUsage.count, 7)
        XCTAssertNotNil(memoryUsage[DeviceDataKey.appMemoryUsage])
        XCTAssertNotNil(memoryUsage[DeviceDataKey.memoryActive])
        XCTAssertNotNil(memoryUsage[DeviceDataKey.memoryCompressed])
        XCTAssertNotNil(memoryUsage[DeviceDataKey.memoryFree])
        XCTAssertNotNil(memoryUsage[DeviceDataKey.memoryInactive])
        XCTAssertNotNil(memoryUsage[DeviceDataKey.memoryWired])
        XCTAssertNotNil(memoryUsage[DeviceDataKey.physicalMemory])
    }

    func test_constantData() {
        let constantData = deviceDataProvider.constantData()
        XCTAssertEqual(constantData.count, 10)
        XCTAssertNotNil(constantData[DeviceDataKey.architecture])
        XCTAssertNotNil(constantData[DeviceDataKey.cpuType])
        XCTAssertNotNil(constantData[DeviceDataKey.deviceOrigin])
        XCTAssertNotNil(constantData[DeviceDataKey.manufacturer])
        XCTAssertNotNil(constantData[DeviceDataKey.osBuild])
        XCTAssertNotNil(constantData[DeviceDataKey.osName])
        XCTAssertNotNil(constantData[DeviceDataKey.osVersion])
        XCTAssertNotNil(constantData[DeviceDataKey.platform])
        XCTAssertNotNil(constantData[DeviceDataKey.resolution])
        XCTAssertNotNil(constantData[DeviceDataKey.logicalResolution])
    }
}
