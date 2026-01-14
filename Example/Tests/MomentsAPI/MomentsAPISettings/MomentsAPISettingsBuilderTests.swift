//
//  MomentsAPISettingsBuilderTests.swift
//  MomentsAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class MomentsAPISettingsBuilderTests: XCTestCase {
    func test_build_without_setters_has_no_region() {
        let settings = MomentsAPISettingsBuilder().build()
        let configuration = settings.getDataDictionary(key: "configuration")?.toDataObject() ?? [:]

        // Configuration without region should return nil when creating MomentsAPIConfiguration
        let momentsAPIConfig = MomentsAPIConfiguration(configuration: configuration)
        XCTAssertNil(momentsAPIConfig, "Configuration should return nil when region is missing")
    }

    func test_build_returns_correct_module_settings() {
        let settings = MomentsAPISettingsBuilder()
            .setRegion(.oregon)
            .setReferrer("https://example.com/custom-referrer")
            .build()
        let configuration = settings.getDataDictionary(key: "configuration")?.toDataObject() ?? [:]

        let momentsAPIConfig = MomentsAPIConfiguration(configuration: configuration)
        XCTAssertNotNil(momentsAPIConfig)
        XCTAssertEqual(momentsAPIConfig?.region, .oregon)
        XCTAssertEqual(momentsAPIConfig?.referrer, "https://example.com/custom-referrer")
    }
}
