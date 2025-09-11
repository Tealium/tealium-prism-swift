//
//  Condition+NotContainsTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConditionNotContainsTests: XCTestCase {
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

    func test_notContains_doesnt_match_string() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "string", string: "al")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notContains_matches_different_string() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "string", string: "something_else")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notContains_matches_string_with_different_casing() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "string", string: "Al")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_string_ignoring_case() {
        let condition = Condition.doesNotContain(ignoreCase: true, variable: "string", string: "AL")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_contained_int() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "int", string: "4")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_contained_double() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "double", string: ".1")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notContains_matches_big_double_when_filter_is_equal_string() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "bigDouble", string: "12345678901234567890.0")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notContains_matches_rounded_double_when_filter_is_dot_zero() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "roundedDouble", string: ".0")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_contained_bool() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "bool", string: "ru")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notContains_matches_different_int() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "int", string: "9")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notContains_matches_different_double() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "double", string: "9.9")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notContains_matches_different_bool() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "bool", string: "als")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_contained_nested_value() {
        let condition = Condition.doesNotContain(ignoreCase: false,
                                                 variable: VariableAccessor(path: ["dictionary"],
                                                                            variable: "key"),
                                                 string: "al")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_array() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "array", string: "alse,b,2,tr")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_array_ignoring_case() {
        let condition = Condition.doesNotContain(ignoreCase: true, variable: "array", string: "Alse,B,2,TR")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notContains_matches_standard_array_string() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "array", string: "[\"a")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_nested_value_ignoring_case() {
        let condition = Condition.doesNotContain(ignoreCase: true,
                                                 variable: VariableAccessor(path: ["dictionary"],
                                                                            variable: "key"),
                                                 string: "AL")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notContains_matches_standard_null_string() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "null", string: "<null>")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_null() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "null", string: "null")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notContains_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "missing", string: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingDataItem = operationError.type else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notContains_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.doesNotContain(ignoreCase: false,
                                                 variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                            variable: "key"),
                                                 string: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingDataItem = operationError.type else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notContains_throws_when_filter_is_nil() {
        let condition = Condition(variable: "string",
                                  operator: .notContains(true),
                                  filter: nil)
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingFilter = operationError.type else {
                XCTFail("Should be missing filter error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notContains_throws_when_data_item_is_dictionary() {
        let condition = Condition.doesNotContain(ignoreCase: true,
                                                 variable: "dictionary",
                                                 string: "value")
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

    func test_notContains_throws_when_data_item_is_array_containing_dictionary() {
        let condition = Condition.doesNotContain(ignoreCase: false,
                                                 variable: "arrayWithDictionary",
                                                 string: "Value")
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
