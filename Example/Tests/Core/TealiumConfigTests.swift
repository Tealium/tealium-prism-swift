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
        let settings1: DataObject = ["module1_key": "module1_value"]
        let settings2: DataObject = ["module2_key": "module2_value"]
        config.addModule(DefaultModuleFactory<MockDispatcher1>(enforcedSettings: settings1))
        config.addModule(DefaultModuleFactory<MockDispatcher2>(enforcedSettings: settings2))
        let settings = config.getEnforcedSDKSettings()
        XCTAssertEqual(settings, ["modules": [
            MockDispatcher1.id: settings1,
            MockDispatcher2.id: settings2,
        ]])
    }

    func test_getEnforcedSDKSettings_returns_settings_with_coreSettings() throws {
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
        XCTAssertEqual(settings, [
            "core": [
                "max_queue_size": DataItem(value: 17),
                "barriers": try DataItem(serializing: [
                    [
                        "barrier_id": "someId",
                        "scopes": ["all", "custom"]
                    ]
                ])
            ]
        ])
    }

    func test_getEnforcedSDKSettings_returns_settings_with_loadRules() throws {
        var config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "dev",
                                   modules: [],
                                   settingsFile: nil,
                                   settingsUrl: nil)
        config.setLoadRule(.just(.isDefined(variable: "key1")), forId: "rule1")
        config.setLoadRule(.just(.isDefined(variable: "key2")), forId: "rule2")
        let settings = config.getEnforcedSDKSettings()
        XCTAssertEqual(settings, [
            "load_rules": try DataItem(serializing: [
                "rule1": [
                    "id": "rule1",
                    "conditions": [
                        "variable": "key1",
                        "operator": "defined"
                    ]
                ],
                "rule2": [
                    "id": "rule2",
                    "conditions": [
                        "variable": "key2",
                        "operator": "defined"
                    ]
                ]
            ])
        ])
    }
}
