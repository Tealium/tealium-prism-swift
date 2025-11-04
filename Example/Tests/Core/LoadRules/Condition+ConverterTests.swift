//
//  Condition+ConverterTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConditionConverterTests: XCTestCase {
    let converter = Condition.converter

    func test_convert_converts_full_dataItem() throws {
        let conditionObject = try DataItem(serializing: [
            "variable": ["path": "container.pageName"],
            "operator": "equals",
            "filter": ["value": "Home"]
        ])
        let expected = Condition(variable: JSONPath["container"]["pageName"],
                                 operator: .equals(false),
                                 filter: "Home")
        let converted = converter.convert(dataItem: conditionObject)
        XCTAssertEqual(expected, converted)
    }

    func test_convert_converts_dataItem_with_just_operator_and_variable() throws {
        let conditionObject = try DataItem(serializing: [
            "variable": ["key": "pageName"],
            "operator": "defined"
        ])
        let expected = Condition(variable: "pageName",
                                 operator: .isDefined,
                                 filter: nil)
        let converted = converter.convert(dataItem: conditionObject)
        XCTAssertEqual(expected, converted)
    }

    func test_convert_fails_conversion_if_operator_is_missing() throws {
        let conditionObject = DataItem(converting: [
            "variable": "pageName"
        ])
        let converted = converter.convert(dataItem: conditionObject)
        XCTAssertNil(converted)
    }

    func test_convert_fails_conversion_if_variable_is_missing() throws {
        let conditionObject = DataItem(converting: [
            "operator": "defined"
        ])
        let converted = converter.convert(dataItem: conditionObject)
        XCTAssertNil(converted)
    }

    func test_convert_fails_conversion_if_operator_doesnt_exist() throws {
        let conditionObject = DataItem(converting: [
            "operator": "wrong",
            "variable": "pageName"
        ])
        let converted = converter.convert(dataItem: conditionObject)
        XCTAssertNil(converted)
    }

    func test_convert_fails_conversion_if_item_is_not_a_json_object() throws {
        let conditionObject = DataItem(converting: [[
            "variable": "pageName",
            "operator": "defined"
        ]])
        let converted = converter.convert(dataItem: conditionObject)
        XCTAssertNil(converted)
    }

    func test_convert_fails_conversion_if_item_is_not_dictionary() throws {
        let conditionObject = DataItem(converting: "variable")
        let converted = converter.convert(dataItem: conditionObject)
        XCTAssertNil(converted)
    }

    func test_convert_succeeds_with_non_lowercased_operator() throws {
        let conditionObject = try DataItem(serializing: [
            "variable": ["path": "container.pageName"],
            "operator": "eQuaLs",
            "filter": ["value": "Home"]
        ])
        let expected = Condition(variable: JSONPath["container"]["pageName"],
                                 operator: .equals(false),
                                 filter: "Home")
        let converted = converter.convert(dataItem: conditionObject)
        XCTAssertEqual(expected, converted)
    }
}
