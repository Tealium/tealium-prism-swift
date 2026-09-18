//
//  ContextAPISettingsBuilderTests.swift
//  ContextAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ContextAPISettingsBuilderTests: XCTestCase {
    func test_build_without_setters_has_no_region() {
        let settings = ContextAPISettingsBuilder().build()
        let configuration = settings.getDataDictionary(key: "configuration")?.toDataObject() ?? [:]

        // Configuration without region should return nil when creating ContextAPIConfiguration
        let contextAPIConfig = ContextAPIConfiguration(configuration: configuration)
        XCTAssertNil(contextAPIConfig, "Configuration should return nil when region is missing")
    }

    func test_build_returns_correct_module_settings() {
        let settings = ContextAPISettingsBuilder()
            .setRegion(.oregon)
            .setReferrer("https://example.com/custom-referrer")
            .build()
        let configuration = settings.getDataDictionary(key: "configuration")?.toDataObject() ?? [:]

        let contextAPIConfig = ContextAPIConfiguration(configuration: configuration)
        XCTAssertNotNil(contextAPIConfig)
        XCTAssertEqual(contextAPIConfig?.region, .oregon)
        XCTAssertEqual(contextAPIConfig?.referrer, "https://example.com/custom-referrer")
    }
}
