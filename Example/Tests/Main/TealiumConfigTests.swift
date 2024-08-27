//
//  TealiumConfigTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 25/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumConfigTests: XCTestCase {

    func test_getEnforcedSDKSettings_returns_settings_for_each_module() {
        var config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "dev",
                                   modules: [],
                                   settingsFile: nil,
                                   settingsUrl: nil)
        let settings1: [String: Any] = ["module1_key": "module1_value"]
        let settings2: [String: Any] = ["module2_key": "module2_value"]
        config.addModule(DefaultModuleFactory<MockDispatcher1>(enforcedSettings: settings1))
        config.addModule(DefaultModuleFactory<MockDispatcher2>(enforcedSettings: settings2))
        let settings = config.getEnforcedSDKSettings()
        XCTAssertEqual(settings.modulesSettings, [
            MockDispatcher1.id: settings1,
            MockDispatcher2.id: settings2,
        ])
    }

    func test_getEnforcedSDKSettings_returns_settings_with_coreSettings() {
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "dev",
                                   modules: [],
                                   settingsFile: nil,
                                   settingsUrl: nil,
                                   forcingSettings: { builder in
            builder.setMaxQueueSize(17)
                .setScopedBarriers([ScopedBarrier(barrierId: "someId",
                                                  scopes: [.all, .dispatcher("custom")])])
        })
        let settings = config.getEnforcedSDKSettings()
        XCTAssertEqual(settings.modulesSettings, [
            CoreSettings.id: [
                "max_queue_size": 17,
                "barriers": [
                    [
                        "barrier_id": "someId",
                        "scopes": ["all", "custom"]]
                ]
            ]
        ])
    }
}
