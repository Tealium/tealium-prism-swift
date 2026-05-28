//
//  ModuleSettingsBuilderTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ModuleSettingsBuilderTests: XCTestCase {
    let builder = DispatcherSettingsBuilder()
    func test_build_returns_enabled_key_when_passed() {
        XCTAssertEqual(builder.setEnabled(true).build(),
                       ["enabled": true, "configuration": DataObject()])
        XCTAssertEqual(builder.setEnabled(false).build(),
                       ["enabled": false, "configuration": DataObject()])
    }

    func test_build_returns_empty_dictionary_when_enabled_not_passed() {
        XCTAssertEqual(builder.build(), [
            "configuration": DataObject()
        ])
    }

    func test_build_returns_rules_when_passed() {
        XCTAssertEqual(builder.setRules("ruleId").build(),
                       ["rules": "ruleId", "configuration": DataObject()])
        XCTAssertEqual(builder.setRules(.and(["ruleId"])).build(),
                       [
                        "configuration": DataObject(),
                        "rules": try DataItem(jsonValue: [
                            "operator": "and",
                            "children": [
                                "ruleId"
                            ]
                        ])
                       ])
    }

    func test_build_returns_mappings_when_passed() {
        let build = builder
            .setMappings({ mappings in
                mappings.mapFrom("inputVariable", to: "destinationVariable")
            })
            .build()
        XCTAssertEqual(build, [
            "configuration": DataObject(),
            "mappings": try DataItem(jsonValue: [[
                "destination": [
                    "key": "destinationVariable"
                ],
                "parameters": [
                    "reference": [
                        "key": "inputVariable"
                    ]
                ]
            ]])
        ])
    }

    func test_build_returns_module_id_when_passed() {
        let builder = MultipleInstancesSettingsBuilder()
        let build = builder.setModuleId("ModuleID")
            .build()
        XCTAssertEqual(build, [
            "configuration": DataObject(),
            "module_id": "ModuleID"
        ])
    }

    func test_custom_builder_can_use_custom_and_inherited_mappings() {
        let build = CustomSettingsBuilder()
            .setMappings { mappings in
                mappings.mapConstant(42, to: "constant_key")
                mappings.mapParamItem("item_key")
            }
            .setEnabled(true)
            .build()

        XCTAssertEqual(build, [
            "enabled": true,
            "configuration": DataObject(),
            "mappings": try DataItem(jsonValue: [[
                "destination": [
                    "key": "constant_key"
                ],
                "parameters": [
                    "map_to": [
                        "value": 42
                    ]
                ]
            ], [
                "destination": [
                    "path": "param.item_key"
                ],
                "parameters": [
                    "reference": [
                        "key": "source_key"
                    ]
                ]
            ]])
        ])
    }
}

class CustomMappings: Mappings {
    public func mapParamItem(_ item: String) {
        mapFrom("source_key", to: JSONPath["param"][item])
    }
}

class CustomSettingsBuilder: DispatcherSettingsBuilder<CustomMappings> {}
