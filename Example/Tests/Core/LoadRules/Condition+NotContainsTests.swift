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
    let payload: DataObject = [
        "string": "Value",
        "int": 345,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
        "dictionary": ["key": "Value"],
        "null": NSNull()
    ]

    func test_notContains_doesnt_match_string() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "string", string: "al")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notContains_matches_different_string() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "string", string: "something_else")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notContains_matches_string_with_different_casing() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "string", string: "Al")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_string_ignoring_case() {
        let condition = Condition.doesNotContain(ignoreCase: true, variable: "string", string: "AL")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_contained_int() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "int", string: "4")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_contained_double() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "double", string: ".1")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_contained_bool() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "bool", string: "ru")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_contained_nested_value() {
        let condition = Condition.doesNotContain(ignoreCase: false,
                                                 variable: VariableAccessor(path: ["dictionary"],
                                                                            variable: "key"),
                                                 string: "al")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_contained_array() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "array", string: "a")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_nested_value_ignoring_case() {
        let condition = Condition.doesNotContain(ignoreCase: true,
                                                 variable: VariableAccessor(path: ["dictionary"],
                                                                            variable: "key"),
                                                 string: "AL")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notContains_matches_null() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "null", string: "not null")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.doesNotContain(ignoreCase: false, variable: "missing", string: "something")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.doesNotContain(ignoreCase: false,
                                                 variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                            variable: "key"),
                                                 string: "")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notContains_doesnt_match_when_filter_is_nil() {
        let condition = Condition(variable: "string",
                                  operator: .notContains(true),
                                  filter: nil)
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
