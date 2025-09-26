//
//  CollectSettingsBuilderTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class CollectSettingsBuilderTests: XCTestCase {

    func test_build_returns_collect_moduleSettings() {
        let settings = CollectSettingsBuilder()
            .setUrl("url")
            .setBatchUrl("batchUrl")
            .setOverrideDomain("overrideDomain")
            .setOverrideProfile("overrideProfile")
            .setEnabled(true)
            .setModuleId("ModuleID")
            .build()
        XCTAssertEqual(settings, [
            "module_id": "ModuleID",
            "configuration": [
                "url": "url",
                "batch_url": "batchUrl",
                "override_domain": "overrideDomain",
                "override_profile": "overrideProfile",
            ],
            "enabled": true
        ])
    }

    func test_build_with_nil_values_returns_collect_moduleSettings_without_nils() {
        let settings = CollectSettingsBuilder()
            .setUrl("url")
            .setOverrideDomain("overrideDomain")
            .setOverrideProfile("overrideProfile")
            .build()
        XCTAssertEqual(settings, [
            "configuration": [
                "url": "url",
                "override_domain": "overrideDomain",
                "override_profile": "overrideProfile",
            ],
        ])
    }

    func test_build_without_setters_returns_empty_configuration() {
        let settings = CollectSettingsBuilder().build()
        XCTAssertEqual(settings, ["configuration": DataObject()])
    }
}
