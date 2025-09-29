//
//  Condition+RegexTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConditionRegexTests: XCTestCase {
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

    func test_regex_matches_string() {
        let condition = Condition.regularExpression(variable: "string", regex: "al")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_regex_doesnt_match_different_string() {
        let condition = Condition.regularExpression(variable: "string", regex: "something_else")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_regex_doesnt_match_string_with_different_casing() {
        let condition = Condition.regularExpression(variable: "string", regex: "Al")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_regex_matches_string_ignoring_case() {
        let condition = Condition.regularExpression(variable: "string", regex: "(?i)AL")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_regex_matches_int() {
        let condition = Condition.regularExpression(variable: "int", regex: "4")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_regex_matches_double() {
        let condition = Condition.regularExpression(variable: "double", regex: ".1")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_regex_matches_bool() {
        let condition = Condition.regularExpression(variable: "bool", regex: "tr")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_regex_doesnt_match_different_int() {
        let condition = Condition.regularExpression(variable: "int", regex: "9")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_regex_doesnt_match_different_double() {
        let condition = Condition.regularExpression(variable: "double", regex: "9\\.9")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_regex_doesnt_match_different_bool() {
        let condition = Condition.regularExpression(variable: "bool", regex: "als")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_regex_doesnt_match_standard_array_string() {
        let condition = Condition.regularExpression(variable: "array", regex: "\\[\"a")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_regex_matches_nested_value() {
        let condition = Condition.regularExpression(variable: VariableAccessor(path: ["dictionary"],
                                                                               variable: "key"),
                                                    regex: "al")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_regex_matches_array() {
        let condition = Condition.regularExpression(variable: "array", regex: "a,1,false,b,2,true")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_regex_matches_array_ignoring_case() {
        let condition = Condition.regularExpression(variable: "array", regex: "(?i)A,1,false,b,2,TRUE")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_regex_matches_nested_value_ignoring_case() {
        let condition = Condition.regularExpression(variable: VariableAccessor(path: ["dictionary"],
                                                                               variable: "key"),
                                                    regex: "(?i)AL")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_regex_matches_null() {
        let condition = Condition.regularExpression(variable: "null", regex: "(?i)NuLl")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_regex_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.regularExpression(variable: "missing", regex: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingDataItem = operationError.type else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_regex_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.regularExpression(variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                               variable: "key"),
                                                    regex: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingDataItem = operationError.type else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_regex_doesnt_match_standard_null_string() {
        let condition = Condition.regularExpression(variable: "null", regex: "<null")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_regex_throws_when_filter_is_nil() {
        let condition = Condition(variable: "string",
                                  operator: .regex,
                                  filter: nil)
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingFilter = operationError.type else {
                XCTFail("Should be missing filter error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_regex_throws_when_data_item_is_dictionary() {
        let condition = Condition.regularExpression(variable: "dictionary",
                                                    regex: "Value")
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

    func test_regex_throws_when_data_item_is_array_containing_dictionary() {
        let condition = Condition.regularExpression(variable: "arrayWithDictionary",
                                                    regex: "Value")
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
