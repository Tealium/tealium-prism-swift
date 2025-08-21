//
//  Condition+ContainsTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConditionContainsTests: XCTestCase {
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

    func test_contains_matches_string() {
        let condition = Condition.contains(ignoreCase: false, variable: "string", string: "al")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_different_string() {
        let condition = Condition.contains(ignoreCase: false, variable: "string", string: "something_else")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_string_with_different_casing() {
        let condition = Condition.contains(ignoreCase: false, variable: "string", string: "Al")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_contains_matches_string_ignoring_case() {
        let condition = Condition.contains(ignoreCase: true, variable: "string", string: "AL")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_contains_matches_int() {
        let condition = Condition.contains(ignoreCase: false, variable: "int", string: "4")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_contains_matches_double() {
        let condition = Condition.contains(ignoreCase: false, variable: "double", string: ".1")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_contains_matches_bool() {
        let condition = Condition.contains(ignoreCase: false, variable: "bool", string: "tr")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_contains_matches_nested_value() {
        let condition = Condition.contains(ignoreCase: false,
                                           variable: VariableAccessor(path: ["dictionary"],
                                                                      variable: "key"),
                                           string: "al")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_contains_matches_array() {
        let condition = Condition.contains(ignoreCase: false, variable: "array", string: "alse,b,2,tr")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_contains_matches_array_ignoring_case() {
        let condition = Condition.contains(ignoreCase: true, variable: "array", string: "Alse,B,2,TR")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_contains_matches_nested_value_ignoring_case() {
        let condition = Condition.contains(ignoreCase: true,
                                           variable: VariableAccessor(path: ["dictionary"],
                                                                      variable: "key"),
                                           string: "AL")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_contains_matches_null() {
        let condition = Condition.contains(ignoreCase: false, variable: "null", string: "null")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_standard_null_string() {
        let condition = Condition.contains(ignoreCase: false, variable: "null", string: "<null")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.contains(ignoreCase: false, variable: "missing", string: "something")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.contains(ignoreCase: false,
                                           variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                      variable: "key"),
                                           string: "")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_when_filter_is_nil() {
        let condition = Condition(variable: "string",
                                  operator: .contains(true),
                                  filter: nil)
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_contains_doesnt_match_dictionary() {
        let condition = Condition.contains(ignoreCase: false,
                                           variable: "dictionary",
                                           string: "[\"key\": \"value\"]")
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
