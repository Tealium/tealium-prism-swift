//
//  Condition+EqualsTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConditionEqualsTests: XCTestCase {
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

    func test_equals_matches_string() {
        let condition = Condition.equals(ignoreCase: false, variable: "string", target: "Value")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_string() {
        let condition = Condition.equals(ignoreCase: false, variable: "string", target: "something_else")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_string_with_different_casing() {
        let condition = Condition.equals(ignoreCase: false, variable: "string", target: "value")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_equals_matches_string_ignoring_case() {
        let condition = Condition.equals(ignoreCase: true, variable: "string", target: "VALUE")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_int() {
        let condition = Condition.equals(ignoreCase: false, variable: "int", target: "345")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_int() {
        let condition = Condition.equals(ignoreCase: false, variable: "int", target: "346")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_type_of_number() {
        let condition = Condition.equals(ignoreCase: false, variable: "int", target: "345.1")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_equals_matches_double() {
        let condition = Condition.equals(ignoreCase: false, variable: "double", target: "3.14")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_double() {
        let condition = Condition.equals(ignoreCase: false, variable: "double", target: "3.15")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_equals_matches_bool() {
        let condition = Condition.equals(ignoreCase: false, variable: "bool", target: "true")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_bool() {
        let condition = Condition.equals(ignoreCase: false, variable: "bool", target: "false")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_equals_matches_nested_value() {
        let condition = Condition.equals(ignoreCase: false,
                                         variable: VariableAccessor(path: ["dictionary"],
                                                                    variable: "key"),
                                         target: "Value")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_array() {
        let condition = Condition.equals(ignoreCase: false, variable: "array", target: "a,1,false,b,2,true")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_array_ignoring_case() {
        let condition = Condition.equals(ignoreCase: true, variable: "array", target: "A,1,FALSE,B,2,TRUE")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_standard_array_string() {
        let condition = Condition.equals(ignoreCase: false, variable: "array", target: "[\"a\", 1, false, [\"b\", 2, true]]")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_equals_matches_nested_value_ignoring_case() {
        let condition = Condition.equals(ignoreCase: true,
                                         variable: VariableAccessor(path: ["dictionary"],
                                                                    variable: "key"),
                                         target: "VALUE")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_null() {
        let condition = Condition.equals(ignoreCase: false, variable: "null", target: "null")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_standard_null_string() {
        let condition = Condition.equals(ignoreCase: false, variable: "null", target: "<null>")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_equals_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.equals(ignoreCase: true, variable: "missing", target: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case .missingDataItem = operationError.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_equals_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.equals(ignoreCase: true,
                                         variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                    variable: "key"),
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

    func test_equals_throws_when_filter_is_nil() {
        let condition = Condition(variable: "string",
                                  operator: .equals(false),
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

    func test_equals_throws_when_data_item_is_dictionary() {
        let condition = Condition.equals(ignoreCase: false,
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

    func test_equals_throws_when_data_item_is_array_containing_dictionary() {
        let condition = Condition.equals(ignoreCase: false,
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

    func test_equals_matches_NaN() {
        let condition = Condition.equals(ignoreCase: false, variable: "nan", target: "NaN")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_NaN_ignore_case() {
        let condition = Condition.equals(ignoreCase: true, variable: "nan", target: "nan")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_infinity() {
        let condition = Condition.equals(ignoreCase: false, variable: "infinity", target: "Infinity")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_infinity_ignore_case() {
        let condition = Condition.equals(ignoreCase: true, variable: "infinity", target: "infinitY")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_negative_infinity() {
        let condition = Condition.equals(ignoreCase: false, variable: "negativeInfinity", target: "-Infinity")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_negative_infinity_ignore_case() {
        let condition = Condition.equals(ignoreCase: true, variable: "negativeInfinity", target: "-infinitY")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_NaN_string() {
        let condition = Condition.equals(ignoreCase: false, variable: "nanString", target: "NaN")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_NaN_string_ignore_case() {
        let condition = Condition.equals(ignoreCase: true, variable: "nanString", target: "nan")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_infinity_string() {
        let condition = Condition.equals(ignoreCase: false, variable: "infinityString", target: "Infinity")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_infinity_string_ignore_case() {
        let condition = Condition.equals(ignoreCase: true, variable: "infinityString", target: "infinitY")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_negative_infinity_string() {
        let condition = Condition.equals(ignoreCase: false, variable: "negativeInfinityString", target: "-Infinity")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_equals_matches_negative_infinity_string_ignore_case() {
        let condition = Condition.equals(ignoreCase: true, variable: "negativeInfinityString", target: "-infinitY")
        XCTAssertTrue(try condition.matches(payload: payload))
    }
}
