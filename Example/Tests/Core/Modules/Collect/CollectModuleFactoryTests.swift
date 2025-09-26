//
//  CollectModuleFactoryTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class CollectModuleFactoryTests: XCTestCase {

    func test_enforcedSettings_return_the_settings_built_in_the_init() {
        let factory = CollectModule.Factory(forcingSettings: [{ enforcedSettings in
            enforcedSettings
                .setUrl("url")
                .setBatchUrl("batchUrl")
        }])
        XCTAssertEqual(factory.getEnforcedSettings().first, [
            "configuration": ["url": "url", "batch_url": "batchUrl"]
        ])
    }

    func test_changing_builder_after_init_doesnt_change_the_enforcedSettings() {
        var settingsBuilder: CollectSettingsBuilder?
        let factory = CollectModule.Factory(forcingSettings: [{ enforcedSettings in
            let builder = enforcedSettings
                .setUrl("url")
                .setBatchUrl("batchUrl")
            settingsBuilder = builder
            return builder
        }])
        XCTAssertNotNil(settingsBuilder?.setOverrideProfile("overrideProfile"))
        XCTAssertEqual(factory.getEnforcedSettings().first, [
            "configuration": ["url": "url", "batch_url": "batchUrl"]
        ])
    }

    func test_enforcedSettings_return_multiple_settings() {
        let factory = CollectModule.Factory(forcingSettings: [
            { enforcedSettings in
                enforcedSettings
                    .setUrl("url1")
                    .setBatchUrl("batchUrl1")
            },
            { enforcedSettings in
                enforcedSettings
                    .setModuleId("Collect2")
                    .setUrl("url2")
                    .setBatchUrl("batchUrl2")
            },
        ])
        let settings = factory.getEnforcedSettings()
        XCTAssertEqual(settings.count, 2)
        XCTAssertEqual(settings[0], [
            "configuration": ["url": "url1", "batch_url": "batchUrl1"]
        ])
        XCTAssertEqual(settings[1], [
            "module_id": "Collect2",
            "configuration": ["url": "url2", "batch_url": "batchUrl2"]
        ])
    }
}
