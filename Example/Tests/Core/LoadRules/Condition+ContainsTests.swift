//
//  Condition+ContainsTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConditionContainsTests: XCTestCase {
    var payload: DataObject = [
        "string": "Value",
        "int": 345,
        "double": 3.14,
        "bigDouble": 12_345_678_901_234_567_890.0,
        "roundedDouble": 1.0,
        "bool": true,
        "array": [
            DataItem(value: "a"),
            DataItem(value: 1),
            DataItem(value: false),
            DataItem(value: ["b", 2, true])],
        "dictionary": ["key": "Value"],
        "arrayWithDictionary": [DataItem(value: ["key": "Value"])],
        "null": NSNull()
    ]

    func test_contains_matches_string() {
        let condition = Condition.contains(ignoreCase: false, variable: "string", string: "al")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_different_string() {
        let condition = Condition.contains(ignoreCase: false, variable: "string", string: "something_else")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_string_with_different_casing() {
        let condition = Condition.contains(ignoreCase: false, variable: "string", string: "Al")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_contains_matches_string_ignoring_case() {
        let condition = Condition.contains(ignoreCase: true, variable: "string", string: "AL")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_matches_int() {
        let condition = Condition.contains(ignoreCase: false, variable: "int", string: "4")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_matches_double() {
        let condition = Condition.contains(ignoreCase: false, variable: "double", string: ".1")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_matches_big_double_with_rounding() {
        let condition = Condition.contains(ignoreCase: false, variable: "bigDouble", string: "12345678901234600000")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_matches_rounded_double() {
        let condition = Condition.contains(ignoreCase: false, variable: "roundedDouble", string: "1")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_matches_bool() {
        let condition = Condition.contains(ignoreCase: false, variable: "bool", string: "tr")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_different_int() {
        let condition = Condition.contains(ignoreCase: false, variable: "int", string: "9")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_different_double() {
        let condition = Condition.contains(ignoreCase: false, variable: "double", string: "9.9")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_different_bool() {
        let condition = Condition.contains(ignoreCase: false, variable: "bool", string: "als")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_standard_array_string() {
        let condition = Condition.contains(ignoreCase: false, variable: "array", string: "[\"a")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_contains_matches_nested_value() {
        let condition = Condition.contains(ignoreCase: false,
                                           variable: JSONPath["dictionary"]["key"],
                                           string: "al")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_matches_array() {
        let condition = Condition.contains(ignoreCase: false, variable: "array", string: "alse,b,2,tr")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_matches_array_ignoring_case() {
        let condition = Condition.contains(ignoreCase: true, variable: "array", string: "Alse,B,2,TR")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_matches_nested_value_ignoring_case() {
        let condition = Condition.contains(ignoreCase: true,
                                           variable: JSONPath["dictionary"]["key"],
                                           string: "AL")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_matches_null() {
        let condition = Condition.contains(ignoreCase: false, variable: "null", string: "null")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_standard_null_string() {
        let condition = Condition.contains(ignoreCase: false, variable: "null", string: "<null")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_contains_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.contains(ignoreCase: false, variable: "missing", string: "something")
        XCTAssertThrows(try condition.matches(payload: payload)) { (error: ConditionEvaluationError) in
            guard case .missingDataItem = error.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(error.condition, condition)
        }
    }

    func test_contains_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.contains(ignoreCase: false,
                                           variable: JSONPath["dictionary"]["missing"]["key"],
                                           string: "something")
        XCTAssertThrows(try condition.matches(payload: payload)) { (error: ConditionEvaluationError) in
            guard case .missingDataItem = error.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(error.condition, condition)
        }
    }

    func test_contains_throws_when_filter_is_nil() {
        let condition = Condition(variable: "string",
                                  operator: .contains(true),
                                  filter: nil)
        XCTAssertThrows(try condition.matches(payload: payload)) { (error: ConditionEvaluationError) in
            guard case .missingFilter = error.kind else {
                XCTFail("Should be missing filter error, found: \(error)")
                return
            }
            XCTAssertEqual(error.condition, condition)
        }
    }

    func test_contains_throws_when_data_item_is_dictionary() {
        let condition = Condition.contains(ignoreCase: true,
                                           variable: "dictionary",
                                           string: "value")
        XCTAssertThrows(try condition.matches(payload: payload)) { (error: ConditionEvaluationError) in
            guard case let .operationNotSupportedFor(itemType) = error.kind else {
                XCTFail("Should be operation not supported for type error, found: \(error)")
                return
            }
            XCTAssertTrue(itemType == "\([String: DataItem].self)", "Expected dictionary type but got \(itemType)")
            XCTAssertEqual(error.condition, condition)
        }
    }

    func test_contains_throws_when_data_item_is_array_containing_dictionary() {
        let condition = Condition.contains(ignoreCase: false,
                                           variable: "arrayWithDictionary",
                                           string: "Value")
        XCTAssertThrows(try condition.matches(payload: payload)) { (error: ConditionEvaluationError) in
            guard case let .operationNotSupportedFor(itemType) = error.kind else {
                XCTFail("Should be operation not supported for type error, found: \(error)")
                return
            }
            XCTAssertTrue(itemType == "Array containing: \([String: DataItem].self)", "Expected array type but got \(itemType)")
            XCTAssertEqual(error.condition, condition)
        }
    }
}
