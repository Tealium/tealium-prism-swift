//
//  Condition+NotStartsWithTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConditionNotStartsWithTests: XCTestCase {
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

    func test_notStartsWith_doesnt_match_string() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "string", prefix: "Val")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_different_string() {
        let condition = Condition.doesNotStartWith(ignoreCase: false,
                                                   variable: "string",
                                                   prefix: "something_else")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_string_with_different_casing() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "string", prefix: "val")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_string_ignoring_case() {
        let condition = Condition.doesNotStartWith(ignoreCase: true, variable: "string", prefix: "VAL")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_int() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "int", prefix: "34")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_double() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "double", prefix: "3.1")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_bool() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "bool", prefix: "tr")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_different_int() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "int", prefix: "12")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_different_double() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "double", prefix: "2.7")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_different_bool() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "bool", prefix: "fa")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_nested_value() {
        let condition = Condition.doesNotStartWith(ignoreCase: false,
                                                   variable: VariableAccessor(path: ["dictionary"],
                                                                              variable: "key"),
                                                   prefix: "Val")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_array() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "array", prefix: "a,1,")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_array_ignoring_case() {
        let condition = Condition.doesNotStartWith(ignoreCase: true, variable: "array", prefix: "A,1,")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_standard_array_string() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "array", prefix: "[\"a")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_nested_value_ignoring_case() {
        let condition = Condition.doesNotStartWith(ignoreCase: true,
                                                   variable: VariableAccessor(path: ["dictionary"],
                                                                              variable: "key"),
                                                   prefix: "VAL")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_standard_null_string() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "null", prefix: "<nul")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_null() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "null", prefix: "nul")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notStartsWith_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "missing", prefix: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingDataItem = operationError.type else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notStartsWith_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.doesNotStartWith(ignoreCase: false,
                                                   variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                              variable: "key"),
                                                   prefix: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingDataItem = operationError.type else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notStartsWith_throws_when_filter_is_nil() {
        let condition = Condition(variable: "string",
                                  operator: .notStartsWith(true),
                                  filter: nil)
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingFilter = operationError.type else {
                XCTFail("Should be missing filter error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notStartsWith_throws_when_data_item_is_dictionary() {
        let condition = Condition.doesNotStartWith(ignoreCase: false,
                                                   variable: "dictionary",
                                                   prefix: "[")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case let .operationNotSupportedFor(itemType) = operationError.type else {
                XCTFail("Should be operation not supported for type error, found: \(error)")
                return
            }
            XCTAssertTrue(itemType == "\([String: DataItem].self)", "Expected dictionary type but got \(itemType)")
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notStartsWith_throws_when_data_item_is_array_containing_dictionary() {
        let condition = Condition.doesNotStartWith(ignoreCase: false,
                                                   variable: "arrayWithDictionary",
                                                   prefix: "[")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case let .operationNotSupportedFor(itemType) = operationError.type else {
                XCTFail("Should be operation not supported for type error, found: \(error)")
                return
            }
            XCTAssertTrue(itemType == "Array containing: \([String: DataItem].self)", "Expected array type but got \(itemType)")
            XCTAssertEqual(operationError.condition, condition)
        }
    }
}
