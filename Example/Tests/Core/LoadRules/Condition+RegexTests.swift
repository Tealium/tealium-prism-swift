//
//  Condition+RegexTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConditionRegexTests: XCTestCase {
    let payload: DataObject = [
        "string": "Value",
        "int": 345,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
        "dictionary": ["key": "Value"],
        "null": NSNull()
    ]

    func test_regex_matches_string() {
        let condition = Condition.regularExpression(variable: "string", regex: "al")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_regex_doesnt_match_different_string() {
        let condition = Condition.regularExpression(variable: "string", regex: "something_else")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_regex_doesnt_match_string_with_different_casing() {
        let condition = Condition.regularExpression(variable: "string", regex: "Al")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_regex_matches_string_ignoring_case() {
        let condition = Condition.regularExpression(variable: "string", regex: "(?i)AL")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_regex_matches_int() {
        let condition = Condition.regularExpression(variable: "int", regex: "4")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_regex_matches_double() {
        let condition = Condition.regularExpression(variable: "double", regex: ".1")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_regex_matches_bool() {
        let condition = Condition.regularExpression(variable: "bool", regex: "tr")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_regex_matches_nested_value() {
        let condition = Condition.regularExpression(variable: VariableAccessor(path: ["dictionary"],
                                                                               variable: "key"),
                                                    regex: "al")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_regex_matches_array() {
        let condition = Condition.regularExpression(variable: "array", regex: "a")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_regex_matches_nested_value_ignoring_case() {
        let condition = Condition.regularExpression(variable: VariableAccessor(path: ["dictionary"],
                                                                               variable: "key"),
                                                    regex: "(?i)AL")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_regex_matches_null() {
        let condition = Condition.regularExpression(variable: "null", regex: "(?i)NuLl")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_regex_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.regularExpression(variable: "missing", regex: "")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_regex_doesnt_match_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.regularExpression(variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                               variable: "key"),
                                                    regex: "")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_regex_doesnt_match_when_filter_is_nil() {
        let condition = Condition(path: nil,
                                  variable: "string",
                                  operator: .regex,
                                  filter: nil)
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
