//
//  TealiumCollectFactoryTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumCollectFactoryTests: XCTestCase {

    func test_enforcedSettings_return_the_settings_built_in_the_init() {
        let factory = TealiumCollect.Factory { enforcedSettings in
            enforcedSettings
                .setUrl("url")
                .setBatchUrl("batchUrl")
        }
        XCTAssertEqual(factory.getEnforcedSettings(), ["url": "url", "batch_url": "batchUrl"])
    }

    func test_changing_builder_after_init_doesnt_change_the_enforcedSettings() {
        var settingsBuilder: CollectSettingsBuilder?
        let factory = TealiumCollect.Factory { enforcedSettings in
            let builder = enforcedSettings
                .setUrl("url")
                .setBatchUrl("batchUrl")
            settingsBuilder = builder
            return builder
        }
        XCTAssertNotNil(settingsBuilder?.setOverrideProfile("overrideProfile"))
        XCTAssertEqual(factory.getEnforcedSettings(), ["url": "url", "batch_url": "batchUrl"])
    }
}
