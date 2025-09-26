//
//  ModuleSettingsBuilderTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
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
                        "rules": try DataItem(serializing: [
                            "operator": "and",
                            "children": [
                                "ruleId"
                            ]
                        ])
                       ])
    }

    func test_build_returns_mappings_when_passed() {
        let build = builder
            .setMappings([
                .from("inputVariable", to: "destinationVariable")
            ])
            .build()
        XCTAssertEqual(build, [
            "configuration": DataObject(),
            "mappings": try DataItem(serializing: [[
                "destination": [
                    "variable": "destinationVariable"
                ],
                "parameters": [
                    "key": [
                        "variable": "inputVariable"
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
}
