//
//  Condition+EqualsTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
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
        "null": NSNull()
    ]

    func test_equals_matches_string() {
        let condition = Condition.equals(ignoreCase: false, variable: "string", target: "Value")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_string() {
        let condition = Condition.equals(ignoreCase: false, variable: "string", target: "something_else")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_string_with_different_casing() {
        let condition = Condition.equals(ignoreCase: false, variable: "string", target: "value")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_matches_string_ignoring_case() {
        let condition = Condition.equals(ignoreCase: true, variable: "string", target: "VALUE")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_matches_int() {
        let condition = Condition.equals(ignoreCase: false, variable: "int", target: "345")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_int() {
        let condition = Condition.equals(ignoreCase: false, variable: "int", target: "346")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_type_of_number() {
        let condition = Condition.equals(ignoreCase: false, variable: "int", target: "345.1")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_matches_double() {
        let condition = Condition.equals(ignoreCase: false, variable: "double", target: "3.14")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_double() {
        let condition = Condition.equals(ignoreCase: false, variable: "double", target: "3.15")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_matches_bool() {
        let condition = Condition.equals(ignoreCase: false, variable: "bool", target: "true")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_bool() {
        let condition = Condition.equals(ignoreCase: false, variable: "bool", target: "false")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_matches_nested_value() {
        let condition = Condition.equals(ignoreCase: false,
                                         variable: VariableAccessor(path: ["dictionary"],
                                                                    variable: "key"),
                                         target: "Value")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_matches_array() {
        let condition = Condition.equals(ignoreCase: false, variable: "array", target: "a,1,false,b,2,true")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_matches_array_ignoring_case() {
        let condition = Condition.equals(ignoreCase: true, variable: "array", target: "A,1,FALSE,B,2,TRUE")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_standard_array_string() {
        let condition = Condition.equals(ignoreCase: false, variable: "array", target: "[\"a\", 1, false, [\"b\", 2, true]]")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_matches_nested_value_ignoring_case() {
        let condition = Condition.equals(ignoreCase: true,
                                         variable: VariableAccessor(path: ["dictionary"],
                                                                    variable: "key"),
                                         target: "VALUE")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_matches_null() {
        let condition = Condition.equals(ignoreCase: false, variable: "null", target: "null")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_standard_null_string() {
        let condition = Condition.equals(ignoreCase: false, variable: "null", target: "<null>")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.equals(ignoreCase: true, variable: "missing", target: "something")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.equals(ignoreCase: true,
                                         variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                    variable: "key"),
                                         target: "something")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_when_filter_is_nil() {
        let condition = Condition(variable: "string",
                                  operator: .equals(true),
                                  filter: nil)
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_missing_key_when_filter_is_nil() {
        let condition = Condition(variable: "missing",
                                  operator: .equals(true),
                                  filter: nil)
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_dictionary() {
        let condition = Condition.equals(ignoreCase: false,
                                         variable: "dictionary",
                                         target: "[\"key\": \"Value\"]")
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
