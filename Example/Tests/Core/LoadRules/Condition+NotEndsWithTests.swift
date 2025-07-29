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
    let payload: DataObject = [
        "string": "Value",
        "int": 345,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
        "dictionary": ["key": "Value"],
        "null": NSNull()
    ]

    func test_notEndsWith_doesnt_match_string() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "string", suffix: "alue")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEndsWith_matches_different_string() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "string", suffix: "something_else")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notEndsWith_matches_string_with_different_casing() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "string", suffix: "Alue")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_string_ignoring_case() {
        let condition = Condition.doesNotEndWith(ignoreCase: true, variable: "string", suffix: "ALUE")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_ending_int() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "int", suffix: "45")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_ending_double() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "double", suffix: ".14")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_ending_bool() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "bool", suffix: "ue")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_ending_nested_value() {
        let condition = Condition.doesNotEndWith(ignoreCase: false,
                                                 variable: VariableAccessor(path: ["dictionary"],
                                                                            variable: "key"),
                                                 suffix: "alue")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_ending_array() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "array", suffix: "c\"]")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_nested_value_ignoring_case() {
        let condition = Condition.doesNotEndWith(ignoreCase: true,
                                                 variable: VariableAccessor(path: ["dictionary"],
                                                                            variable: "key"),
                                                 suffix: "ALUE")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEndsWith_matches_null() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "null", suffix: "Not null")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.doesNotEndWith(ignoreCase: false, variable: "missing", suffix: "something")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.doesNotEndWith(ignoreCase: false,
                                                 variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                            variable: "key"),
                                                 suffix: "")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEndsWith_doesnt_match_when_filter_is_nil() {
        let condition = Condition(path: nil,
                                  variable: "string",
                                  operator: .notEndsWith(true),
                                  filter: nil)
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
