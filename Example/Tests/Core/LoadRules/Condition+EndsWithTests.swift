//
//  Condition+EndsWithTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConditionEndsWithTests: XCTestCase {
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

    func test_endsWith_matches_string() {
        let condition = Condition.endsWith(ignoreCase: false, variable: "string", suffix: "alue")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_endsWith_doesnt_match_different_string() {
        let condition = Condition.endsWith(ignoreCase: false, variable: "string", suffix: "something_else")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_endsWith_doesnt_match_string_with_different_casing() {
        let condition = Condition.endsWith(ignoreCase: false, variable: "string", suffix: "Alue")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_endsWith_matches_string_ignoring_case() {
        let condition = Condition.endsWith(ignoreCase: true, variable: "string", suffix: "ALUE")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_endsWith_matches_int() {
        let condition = Condition.endsWith(ignoreCase: false, variable: "int", suffix: "45")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_endsWith_matches_double() {
        let condition = Condition.endsWith(ignoreCase: false, variable: "double", suffix: ".14")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_endsWith_matches_bool() {
        let condition = Condition.endsWith(ignoreCase: false, variable: "bool", suffix: "ue")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_endsWith_matches_nested_value() {
        let condition = Condition.endsWith(ignoreCase: false,
                                           variable: VariableAccessor(path: ["dictionary"],
                                                                      variable: "key"),
                                           suffix: "alue")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_endsWith_matches_array() {
        let condition = Condition.endsWith(ignoreCase: false, variable: "array", suffix: ",b,2,true")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_endsWith_matches_array_ignoring_case() {
        let condition = Condition.endsWith(ignoreCase: true, variable: "array", suffix: ",B,2,TRUE")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_endsWith_matches_nested_value_ignoring_case() {
        let condition = Condition.endsWith(ignoreCase: true,
                                           variable: VariableAccessor(path: ["dictionary"],
                                                                      variable: "key"),
                                           suffix: "UE")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_endsWith_matches_null() {
        let condition = Condition.endsWith(ignoreCase: false, variable: "null", suffix: "ull")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_endsWith_doesnt_match_standard_null_string() {
        let condition = Condition.endsWith(ignoreCase: false, variable: "null", suffix: "ull>")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_endsWith_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.endsWith(ignoreCase: false, variable: "missing", suffix: "something")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_endsWith_doesnt_match_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.endsWith(ignoreCase: false,
                                           variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                      variable: "key"),
                                           suffix: "")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_endsWith_doesnt_match_when_filter_is_nil() {
        let condition = Condition(path: nil,
                                  variable: "string",
                                  operator: .endsWith(true),
                                  filter: nil)
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_endsWith_doesnt_match_dictionary() {
        let condition = Condition.endsWith(ignoreCase: false,
                                           variable: "dictionary",
                                           suffix: "alue\"]")
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
