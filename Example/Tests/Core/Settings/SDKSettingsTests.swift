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
            "core": try DataItem(serializing: [
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
            "modules": try DataItem(serializing: [
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
            "load_rules": try DataItem(serializing: [
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
        guard let rule = result.loadRules["ruleId"] else {
            XCTFail("LoadRule not found.")
            return
        }
        let expected = Condition(variable: "variable", operator: .isDefined, filter: nil)
        guard case let .and(children) = rule.conditions else {
            XCTFail("Rule conditions \(rule.conditions) should be AND")
            return
        }
        XCTAssertEqual(children.count, 1)
        guard case let .just(item) = children.first else {
            XCTFail("Rule conditions \(children) should be JUST item")
            return
        }
        XCTAssertEqual(item as? Condition, expected)
    }

    func test_initialization_with_transformations_returns_transformations() throws {
        let input: DataObject = [
            "transformations": try DataItem(serializing: [
                "transformerId-transformationId": [
                    "transformation_id": "transformationId",
                    "transformer_id": "transformerId",
                    "scopes": ["afterCollectors"],
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
        XCTAssertEqual(transformation.scopes, [.afterCollectors])
        XCTAssertEqual(transformation.configuration, ["key": "value"])
    }

    func test_initialization_with_barriers_returns_barriers() throws {
        let input: DataObject = [
            "barriers": try DataItem(serializing: [
                "barrierId": [
                    "barrier_id": "barrierId",
                    "scopes": ["all"],
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
        XCTAssertEqual(barrier.scopes, [.all])
        XCTAssertEqual(barrier.configuration, ["key": "value"])
    }
}
