//
//  Condition+NotEqualsTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConditionNotEqualsTests: XCTestCase {
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
        "null": NSNull(),
        "infinityString": "Infinity",
        "negativeInfinityString": "-Infinity",
        "nanString": "NaN",
        "infinity": Double.infinity,
        "negativeInfinity": -Double.infinity,
        "nan": Double.nan,
    ]

    func test_notEquals_doesnt_match_equal_string() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "string", target: "Value")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_matches_different_string() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "string", target: "something_else")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEquals_matches_string_with_different_casing() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "string", target: "value")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_string_ignoring_case() {
        let condition = Condition.doesNotEqual(ignoreCase: true, variable: "string", target: "VALUE")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_equal_int() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "int", target: "345")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_matches_different_int() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "int", target: "346")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEquals_matches_different_type_of_number() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "int", target: "345.1")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_double() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "double", target: "3.14")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_matches_different_double() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "double", target: "3.15")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_bool() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "bool", target: "true")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_matches_different_bool() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "bool", target: "false")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_nested_value() {
        let condition = Condition.doesNotEqual(ignoreCase: false,
                                               variable: JSONPath["dictionary"]["key"],
                                               target: "Value")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_array() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "array", target: "a,1,false,b,2,true")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_array_ignoring_case() {
        let condition = Condition.doesNotEqual(ignoreCase: true, variable: "array", target: "A,1,FALSE,B,2,TRUE")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_matches_standard_array_string() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "array", target: "[\"a\", 1, false, [\"b\", 2, true]]")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_nested_value_ignoring_case() {
        let condition = Condition.doesNotEqual(ignoreCase: true,
                                               variable: JSONPath["dictionary"]["key"],
                                               target: "VALUE")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_matches_standard_null_string() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "null", target: "<null>")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_null() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "null", target: "null")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "missing", target: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case .missingDataItem = operationError.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notEquals_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.doesNotEqual(ignoreCase: true,
                                               variable: JSONPath["dictionary"]["missing"]["key"],
                                               target: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case .missingDataItem = operationError.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notEquals_throws_when_filter_is_nil() {
        let condition = Condition(variable: "string",
                                  operator: .notEquals(true),
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

    func test_notEquals_throws_when_data_item_is_dictionary() {
        let condition = Condition.doesNotEqual(ignoreCase: false,
                                               variable: "dictionary",
                                               target: "[\"key\": \"Value\"]")
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

    func test_notEquals_throws_when_data_item_is_array_containing_dictionary() {
        let condition = Condition.doesNotEqual(ignoreCase: false,
                                               variable: "arrayWithDictionary",
                                               target: "[[\"key\": \"Value\"]]")
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

    func test_notEquals_doesnt_match_NaN() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "nan", target: "NaN")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_NaN_ignore_case() {
        let condition = Condition.doesNotEqual(ignoreCase: true, variable: "nan", target: "nan")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_infinity() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "infinity", target: "Infinity")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_infinity_ignore_case() {
        let condition = Condition.doesNotEqual(ignoreCase: true, variable: "infinity", target: "infinitY")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_negative_infinity() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "negativeInfinity", target: "-Infinity")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_negative_infinity_ignore_case() {
        let condition = Condition.doesNotEqual(ignoreCase: true, variable: "negativeInfinity", target: "-infinitY")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_NaN_string() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "nanString", target: "NaN")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_NaN_string_ignore_case() {
        let condition = Condition.doesNotEqual(ignoreCase: true, variable: "nanString", target: "nan")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_infinity_string() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "infinityString", target: "Infinity")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_infinity_string_ignore_case() {
        let condition = Condition.doesNotEqual(ignoreCase: true, variable: "infinityString", target: "infinitY")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_negative_infinity_string() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "negativeInfinityString", target: "-Infinity")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_negative_infinity_string_ignore_case() {
        let condition = Condition.doesNotEqual(ignoreCase: true, variable: "negativeInfinityString", target: "-infinitY")
        XCTAssertFalse(try condition.matches(payload: payload))
    }
}
