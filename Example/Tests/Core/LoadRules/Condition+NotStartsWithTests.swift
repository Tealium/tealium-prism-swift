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
        "null": NSNull()
    ]

    func test_notStartsWith_doesnt_match_string() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "string", prefix: "Val")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_different_string() {
        let condition = Condition.doesNotStartWith(ignoreCase: false,
                                                   variable: "string",
                                                   prefix: "something_else")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_string_with_different_casing() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "string", prefix: "val")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_string_ignoring_case() {
        let condition = Condition.doesNotStartWith(ignoreCase: true, variable: "string", prefix: "VAL")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_int() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "int", prefix: "34")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_double() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "double", prefix: "3.1")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_bool() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "bool", prefix: "tr")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_different_int() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "int", prefix: "12")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_different_double() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "double", prefix: "2.7")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_different_bool() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "bool", prefix: "fa")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_nested_value() {
        let condition = Condition.doesNotStartWith(ignoreCase: false,
                                                   variable: VariableAccessor(path: ["dictionary"],
                                                                              variable: "key"),
                                                   prefix: "Val")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_array() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "array", prefix: "a,1,")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_starting_array_ignoring_case() {
        let condition = Condition.doesNotStartWith(ignoreCase: true, variable: "array", prefix: "A,1,")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_standard_array_string() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "array", prefix: "[\"a")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_nested_value_ignoring_case() {
        let condition = Condition.doesNotStartWith(ignoreCase: true,
                                                   variable: VariableAccessor(path: ["dictionary"],
                                                                              variable: "key"),
                                                   prefix: "VAL")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_matches_standard_null_string() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "null", prefix: "<nul")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_null() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "null", prefix: "nul")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.doesNotStartWith(ignoreCase: false, variable: "missing", prefix: "something")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartWith_doesnt_match_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.doesNotStartWith(ignoreCase: false,
                                                   variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                              variable: "key"),
                                                   prefix: "")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_when_filter_is_nil() {
        let condition = Condition(path: nil,
                                  variable: "string",
                                  operator: .notStartsWith(true),
                                  filter: nil)
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notStartsWith_doesnt_match_dictionary() {
        let condition = Condition.doesNotStartWith(ignoreCase: false,
                                                   variable: "dictionary",
                                                   prefix: "[\"key")
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
