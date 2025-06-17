//
//  ConsentSettingsBuilderTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConsentSettingsBuilderTests: XCTestCase {

    func test_build_returns_consent_moduleSettings() {
        let settings = ConsentSettingsBuilder(vendorId: "vendorId")
            .setConfiguration(ConsentConfigurationBuilder()
                .setTealiumPurposeId("tealium"))
            .build()
        XCTAssertEqual(settings, [
            "configurations": [
                "vendorId": [
                    "tealium_purpose_id": "tealium",
                ]
            ]
        ])
    }

    func test_build_without_setters_returns_empty_settings() {
        let settings = ConsentSettingsBuilder(vendorId: "vendorId").build()
        XCTAssertEqual(settings, [:])
    }
}
