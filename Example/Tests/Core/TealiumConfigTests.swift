//
//  TealiumConfigTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 25/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TealiumConfigTests: XCTestCase {
    var config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "dev",
                               modules: [],
                               settingsFile: nil,
                               settingsUrl: nil)

    func test_getEnforcedSDKSettings_returns_settings_for_each_module() {
        let settings1 = MultipleInstancesSettingsBuilder()
            .setOrder(10)
        let settings2 = MultipleInstancesSettingsBuilder()
            .setOrder(20)
        config.addModule(MockDispatcher1.factory(enforcedSettings: settings1))
        config.addModule(MockDispatcher2.factory(enforcedSettings: settings2))
        let settings = config.getEnforcedSDKSettings()
        XCTAssertEqual(settings, ["modules": [
            MockDispatcher1.moduleType: settings1.build(withModuleType: MockDispatcher1.moduleType),
            MockDispatcher2.moduleType: settings2.build(withModuleType: MockDispatcher2.moduleType)
        ]])
    }

    func test_getEnforcedSDKSettings_returns_settings_for_multiple_instance_module() {
        let settings1 = MultipleInstancesSettingsBuilder()
            .setModuleId("ID1")
        let settings2 = MultipleInstancesSettingsBuilder()
            .setModuleId("ID2")
        config.addModule(MockDispatcher1.factory(allowsMultipleInstances: true, enforcedSettings: settings1))
        config.addModule(MockDispatcher2.factory(allowsMultipleInstances: true, enforcedSettings: settings2))
        let settings = config.getEnforcedSDKSettings()
        XCTAssertEqual(settings, ["modules": [
            "ID1": settings1.build(withModuleType: MockDispatcher1.moduleType),
            "ID2": settings2.build(withModuleType: MockDispatcher2.moduleType)
        ]])
    }

    func test_getEnforcedSDKSettings_returns_settings_keyed_by_moduleType_if_moduleId_is_missing() {
        let settings1 = MultipleInstancesSettingsBuilder()
        let settings2 = MultipleInstancesSettingsBuilder()
            .setModuleId("ID2")
        config.addModule(MockDispatcher2.factory(allowsMultipleInstances: true, enforcedSettings: settings1, settings2))
        let settings = config.getEnforcedSDKSettings()
        XCTAssertEqual(settings, ["modules": [
            MockDispatcher2.moduleType: settings1.build(withModuleType: MockDispatcher2.moduleType),
            "ID2": settings2.build(withModuleType: MockDispatcher2.moduleType),
        ]])
    }

    func test_getEnforcedSDKSettings_returns_only_first_instance_of_settings_for_multiple_instance_module_if_moduleId_is_the_same() {
        let settings1 = MultipleInstancesSettingsBuilder()
            .setOrder(10)
            .setModuleId("ID1")
        let settings2 = MultipleInstancesSettingsBuilder()
            .setOrder(20)
            .setModuleId("ID1")
        config.addModule(MockDispatcher2.factory(allowsMultipleInstances: true, enforcedSettings: settings1, settings2))
        let settings = config.getEnforcedSDKSettings()
        XCTAssertEqual(settings, ["modules": [
            "ID1": settings1.build(withModuleType: MockDispatcher2.moduleType)
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
        })
        let settings = config.getEnforcedSDKSettings()
        XCTAssertEqual(settings, [
            "core": [
                "max_queue_size": DataItem(value: 17),
            ]
        ])
    }

    func test_getEnforcedSDKSettings_returns_settings_with_transformations() throws {
        config.setTransformation(TransformationSettings(id: "transformationId1", transformerId: "transformerId", scopes: [.allDispatchers]))
        config.setTransformation(TransformationSettings(id: "transformationId2", transformerId: "transformerId", scopes: [.dispatcher(id: "123")]))
        let settings = config.getEnforcedSDKSettings()
        XCTAssertEqual(settings, [
            "transformations": try DataItem(serializing: [
                "transformerId-transformationId1": [
                    "transformation_id": "transformationId1",
                    "transformer_id": "transformerId",
                    "scopes": ["alldispatchers"],
                    "configuration": [:]
                ],
                "transformerId-transformationId2": [
                    "transformation_id": "transformationId2",
                    "transformer_id": "transformerId",
                    "scopes": ["123"],
                    "configuration": [:]
                ]
            ])
        ])
    }

    func test_getEnforcedSDKSettings_returns_settings_with_loadRules() throws {
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
