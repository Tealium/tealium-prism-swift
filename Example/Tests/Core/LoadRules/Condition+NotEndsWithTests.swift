//
//  Condition+NotEndsWithTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConditionNotEndsWithTests: XCTestCase {
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

    func test_notEndsWith_doesnt_match_string() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "string", suffix: "alue")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEndsWith_matches_different_string() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "string", suffix: "something_else")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEndsWith_matches_string_with_different_casing() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "string", suffix: "Alue")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_string_ignoring_case() {
        let condition = Condition.doesNotEndWith(ignoreCase: true, variable: "string", suffix: "ALUE")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_ending_int() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "int", suffix: "45")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_ending_double() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "double", suffix: ".14")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_ending_bool() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "bool", suffix: "ue")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEndsWith_matches_different_int() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "int", suffix: "12")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEndsWith_matches_different_double() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "double", suffix: "2.7")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEndsWith_matches_different_bool() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "bool", suffix: "lse")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_ending_nested_value() {
        let condition = Condition.doesNotEndWith(ignoreCase: false,
                                                 variable: VariableAccessor(path: ["dictionary"],
                                                                            variable: "key"),
                                                 suffix: "alue")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_ending_array() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "array", suffix: ",b,2,true")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_ending_array_ignoring_case() {
        let condition = Condition.doesNotEndWith(ignoreCase: true, variable: "array", suffix: ",B,2,TRUE")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEndsWith_matches_standard_array_string() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "array", suffix: "]]")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_nested_value_ignoring_case() {
        let condition = Condition.doesNotEndWith(ignoreCase: true,
                                                 variable: VariableAccessor(path: ["dictionary"],
                                                                            variable: "key"),
                                                 suffix: "ALUE")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEndsWith_matches_standard_null_string() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "null", suffix: "ll>")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_null() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "null", suffix: "ull")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_notEndsWith_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "missing", suffix: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingDataItem = operationError.type else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notEndsWith_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.doesNotEndWith(ignoreCase: false,
                                                 variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                            variable: "key"),
                                                 suffix: "something")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingDataItem = operationError.type else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notEndsWith_throws_when_filter_is_nil() {
        let condition = Condition(variable: "string",
                                  operator: .notEndsWith(true),
                                  filter: nil)
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError, case .missingFilter = operationError.type else {
                XCTFail("Should be missing filter error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_notEndsWith_throws_when_data_item_is_dictionary() {
        let condition = Condition.doesNotEndWith(ignoreCase: false,
                                                 variable: "dictionary",
                                                 suffix: "]")
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

    func test_notEndsWith_throws_when_data_item_is_array_containing_dictionary() {
        let condition = Condition.doesNotEndWith(ignoreCase: false,
                                                 variable: "arrayWithDictionary",
                                                 suffix: "]")
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
