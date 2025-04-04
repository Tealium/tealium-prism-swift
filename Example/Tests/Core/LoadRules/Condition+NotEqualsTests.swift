//
//  Condition+NotEqualsTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConditionNotEqualsTests: XCTestCase {
    let payload: DataObject = [
        "string": "Value",
        "int": 45,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
        "dictionary": ["key": "Value"],
        "null": NSNull()
    ]

    func test_notEquals_doesnt_match_equal_string() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "string", target: "Value")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEquals_matches_string_with_different_casing() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "string", target: "value")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_string_ignoring_case() {
        let condition = Condition.doesNotEqual(ignoreCase: true, variable: "string", target: "VALUE")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_equal_int() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "int", target: "45")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEquals_matches_different_int() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "int", target: "46")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notEquals_matches_different_type_of_number() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "int", target: "45.1")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_double() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "double", target: "3.14")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEquals_matches_different_double() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "double", target: "3.15")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_bool() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "bool", target: "true")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_nested_value() {
        let condition = Condition.doesNotEqual(ignoreCase: false,
                                               path: ["dictionary"],
                                               variable: "key",
                                               target: "Value")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_array() {
        let condition = Condition.doesNotEqual(ignoreCase: false,
                                               variable: "array",
                                               target: "[\"a\", \"b\", \"c\"]")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_nested_value_ignoring_case() {
        let condition = Condition.doesNotEqual(ignoreCase: true,
                                               path: ["dictionary"],
                                               variable: "key",
                                               target: "VALUE")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_notEquals_matches_null() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "null", target: "not null")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_notEquals_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.doesNotEqual(ignoreCase: false, variable: "missing", target: "something")
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
