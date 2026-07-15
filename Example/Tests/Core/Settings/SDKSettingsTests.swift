//
//  SDKSettingsTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SDKSettingsTests: XCTestCase {

    func test_initialization_with_empty_settings_returns_default_values() {
        let input: DataObject = [:]
        let result = SDKSettings(input)
        XCTAssertEqual(result.core, CoreSettings())
        XCTAssertTrue(result.modules.isEmpty)
        XCTAssertTrue(result.loadRules.isEmpty)
    }

    func test_initialization_with_core_settings_returns_new_core() throws {
        let input: DataObject = [
            "core": try DataItem(jsonValue: [
                "log_level": "trace",
                "max_queue_size": 37,
                "refresh_interval": 45,
                "expiration": 21,
                "visitor_identity_key": "someKey"
            ])
        ]
        let result = SDKSettings(input)
        let expected = CoreSettings(minLogLevel: LogLevel.Minimum.trace,
                                    maxQueueSize: 37,
                                    queueExpiration: 21.seconds,
                                    refreshInterval: 45.seconds,
                                    visitorIdentityKey: "someKey")
        XCTAssertEqual(result.core, expected)
    }

    func test_initialization_with_module_settings_returns_moduleSettings() throws {
        let input: DataObject = [
            "modules": try DataItem(jsonValue: [
                "moduleId": [
                    "enabled": false,
                    "module_type": "moduleId",
                    "configuration": ["key": "value"]
                ]
            ])
        ]
        let result = SDKSettings(input)
        guard let module = result.modules["moduleId"] else {
            XCTFail("Module not found.")
            return
        }
        let expected = ModuleSettings(moduleType: "moduleId", enabled: false, configuration: ["key": "value"])
        XCTAssertEqual(module.configuration, expected.configuration)
        XCTAssertEqual(module.enabled, expected.enabled)
    }

    func test_initialization_with_load_rules_returns_loadRules() throws {
        let input: DataObject = [
            "load_rules": try DataItem(jsonValue: [
                "ruleId": [
                    "id": "ruleId",
                    "conditions": [
                        "operator": "and",
                        "children": [
                            [
                                "variable": ["key": "variable"],
                                "operator": "defined"
                            ]
                        ]
                    ]
                ]
            ])
        ]
        let result = SDKSettings(input)
        let condition = Condition(variable: "variable", operator: .isDefined, filter: nil)
        XCTAssertEqual(result.loadRules["ruleId"]?.conditions, .and([.just(condition)]))
    }

    func test_initialization_with_transformations_returns_transformations() throws {
        let input: DataObject = [
            "transformations": try DataItem(jsonValue: [
                "transformerId-transformationId": [
                    "transformation_id": "transformationId",
                    "transformer_id": "transformerId",
                    "scope": "aftercollectors",
                    "configuration": [
                        "key": "value"
                    ]
                ]
            ])
        ]
        let result = SDKSettings(input)
        guard let transformation = result.transformations["transformerId-transformationId"] else {
            XCTFail("Transformation not found")
            return
        }
        XCTAssertEqual(transformation.id, "transformationId")
        XCTAssertEqual(transformation.transformerId, "transformerId")
        XCTAssertEqual(transformation.scope, .afterCollectors)
        XCTAssertEqual(transformation.configuration, ["key": "value"])
    }

    func test_initialization_with_barriers_returns_barriers() throws {
        let input: DataObject = [
            "barriers": try DataItem(jsonValue: [
                "barrierId": [
                    "barrier_id": "barrierId",
                    "scope": "all",
                    "configuration": [
                        "key": "value"
                    ]
                ]
            ])
        ]
        let result = SDKSettings(input)
        guard let barrier = result.barriers["barrierId"] else {
            XCTFail("Barrier not found")
            return
        }
        XCTAssertEqual(barrier.barrierId, "barrierId")
        XCTAssertEqual(barrier.scope, .all)
        XCTAssertEqual(barrier.configuration, ["key": "value"])
    }
}
