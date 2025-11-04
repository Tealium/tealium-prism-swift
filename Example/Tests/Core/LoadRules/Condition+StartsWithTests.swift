//
//  Condition+StartsWithTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConditionStartsWithTests: XCTestCase {
    var payload: DataObject = [
        "string": "Value",
        "int": 345,
        "double": 3.14,
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

    func test_startsWith_matches_string() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "string", prefix: "Val")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_startsWith_doesnt_match_different_string() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "string", prefix: "something_else")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_startsWith_doesnt_match_string_with_different_casing() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "string", prefix: "val")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_startsWith_matches_string_ignoring_case() {
        let condition = Condition.startsWith(ignoreCase: true, variable: "string", prefix: "VAL")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_startsWith_matches_int() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "int", prefix: "34")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_startsWith_matches_double() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "double", prefix: "3.1")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_startsWith_matches_bool() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "bool", prefix: "tr")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_startsWith_doesnt_match_different_int() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "int", prefix: "12")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_startsWith_doesnt_match_different_double() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "double", prefix: "2.7")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_startsWith_doesnt_match_different_bool() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "bool", prefix: "fa")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_startsWith_doesnt_match_standard_array_string() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "array", prefix: "[\"a")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_startsWith_matches_nested_value() {
        let condition = Condition.startsWith(ignoreCase: false,
                                             variable: JSONPath["dictionary"]["key"],
                                             prefix: "Val")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_startsWith_matches_array() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "array", prefix: "a,1,false,b")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_startsWith_matches_array_ignoring_case() {
        let condition = Condition.startsWith(ignoreCase: true, variable: "array", prefix: "A,1,FALSE,b")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_startsWith_matches_nested_value_ignoring_case() {
        let condition = Condition.startsWith(ignoreCase: true,
                                             variable: JSONPath["dictionary"]["key"],
                                             prefix: "VAL")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_startsWith_matches_null() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "null", prefix: "nul")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_startsWith_doesnt_match_standard_null_string() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "null", prefix: "<nul")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_startsWith_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "missing", prefix: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case .missingDataItem = operationError.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_startsWith_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.startsWith(ignoreCase: false,
                                             variable: JSONPath["dictionary"]["missing"]["key"],
                                             prefix: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case .missingDataItem = operationError.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_startsWith_throws_when_filter_is_nil() {
        let condition = Condition(variable: "string",
                                  operator: .startsWith(true),
                                  filter: nil)
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case .missingFilter = operationError.kind else {
                XCTFail("Should be missing filter error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_startsWith_throws_when_data_item_is_dictionary() {
        let condition = Condition.startsWith(ignoreCase: false,
                                             variable: "dictionary",
                                             prefix: "[")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case let .operationNotSupportedFor(itemType) = operationError.kind else {
                XCTFail("Should be operation not supported for type error, found: \(error)")
                return
            }
            XCTAssertTrue(itemType == "\([String: DataItem].self)", "Expected dictionary type but got \(itemType)")
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_startsWith_throws_when_data_item_is_array_containing_dictionary() {
        let condition = Condition.startsWith(ignoreCase: false,
                                             variable: "arrayWithDictionary",
                                             prefix: "[")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case let .operationNotSupportedFor(itemType) = operationError.kind else {
                XCTFail("Should be operation not supported for type error, found: \(error)")
                return
            }
            XCTAssertTrue(itemType == "Array containing: \([String: DataItem].self)", "Expected array type but got \(itemType)")
            XCTAssertEqual(operationError.condition, condition)
        }
    }
}
