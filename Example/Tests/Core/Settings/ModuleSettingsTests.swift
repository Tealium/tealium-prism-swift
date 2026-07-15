//
//  ModuleSettingsTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 13/07/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ModuleSettingsTests: XCTestCase {
    let converter = ModuleSettings.converter

    func test_converter_with_required_fields_only() throws {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.moduleType: "collect"
        ])
        let settings = try XCTUnwrap(converter.convert(dataItem: dataItem))
        XCTAssertEqual(settings.moduleType, "collect")
        XCTAssertEqual(settings.moduleId, "collect")
        XCTAssertTrue(settings.enabled)
        XCTAssertEqual(settings.order, Int.max)
        XCTAssertNil(settings.rules)
        XCTAssertNil(settings.mappings)
        XCTAssertEqual(settings.configuration, [:])
    }

    func test_converter_module_id_defaults_to_module_type() {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.moduleType: "collect"
        ])
        let settings = converter.convert(dataItem: dataItem)
        XCTAssertEqual(settings?.moduleId, "collect")
    }

    func test_converter_with_explicit_module_id() {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.moduleType: "collect",
            ModuleSettings.Keys.moduleId: "my-collect-instance"
        ])
        let settings = converter.convert(dataItem: dataItem)
        XCTAssertEqual(settings?.moduleId, "my-collect-instance")
        XCTAssertEqual(settings?.moduleType, "collect")
    }

    func test_converter_missing_module_type_returns_nil() {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.enabled: true
        ])
        XCTAssertNil(converter.convert(dataItem: dataItem))
    }

    func test_converter_with_enabled_false() {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.moduleType: "collect",
            ModuleSettings.Keys.enabled: false
        ])
        XCTAssertEqual(converter.convert(dataItem: dataItem)?.enabled, false)
    }

    func test_converter_with_enabled_true() {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.moduleType: "collect",
            ModuleSettings.Keys.enabled: true
        ])
        XCTAssertEqual(converter.convert(dataItem: dataItem)?.enabled, true)
    }

    func test_converter_with_order() {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.moduleType: "collect",
            ModuleSettings.Keys.order: 5
        ])
        XCTAssertEqual(converter.convert(dataItem: dataItem)?.order, 5)
    }

    func test_converter_with_configuration() {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.moduleType: "collect",
            ModuleSettings.Keys.configuration: ["key": "value"]
        ])
        XCTAssertEqual(converter.convert(dataItem: dataItem)?.configuration, ["key": "value"])
    }

    func test_converter_with_simple_string_rule() {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.moduleType: "collect",
            ModuleSettings.Keys.rules: "ruleId"
        ])
        let settings = converter.convert(dataItem: dataItem)
        XCTAssertEqual(settings?.rules, .just("ruleId"))
    }

    func test_converter_with_and_rule() {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.moduleType: "collect",
            ModuleSettings.Keys.rules: [
                "operator": "and",
                "children": ["ruleA", "ruleB"]
            ]
        ])
        let settings = converter.convert(dataItem: dataItem)
        XCTAssertEqual(settings?.rules, .and([.just("ruleA"), .just("ruleB")]))
    }

    func test_converter_with_mappings() {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.moduleType: "collect",
            ModuleSettings.Keys.mappings: [[
                "destination": ["key": "destinationVariable"],
                "parameters": ["reference": ["key": "inputVariable"]]
            ]]
        ])
        guard let settings = converter.convert(dataItem: dataItem),
              let mappings = settings.mappings else {
            XCTFail("Expected mappings"); return
        }
        XCTAssertEqual(mappings.count, 1)
        XCTAssertEqual(mappings[0].destination, .key("destinationVariable"))
        XCTAssertEqual(mappings[0].parameters.reference, .key("inputVariable"))
    }

    func test_converter_with_constant_mapping() {
        let dataItem = DataItem(value: [
            ModuleSettings.Keys.moduleType: "collect",
            ModuleSettings.Keys.mappings: [[
                "destination": ["key": "constant_key"],
                "parameters": ["map_to": ["value": 42]]
            ]]
        ])
        guard let settings = converter.convert(dataItem: dataItem),
              let mappings = settings.mappings else {
            XCTFail("Expected mappings"); return
        }
        XCTAssertEqual(mappings.count, 1)
        XCTAssertEqual(mappings[0].destination, .key("constant_key"))
        XCTAssertNil(mappings[0].parameters.reference)
        XCTAssertEqual(mappings[0].parameters.mapTo?.value.get(), 42)
    }
}
