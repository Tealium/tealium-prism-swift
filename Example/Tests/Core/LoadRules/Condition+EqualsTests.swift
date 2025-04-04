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
    let payload: DataObject = [
        "string": "Value",
        "int": 45,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
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
        let condition = Condition.equals(ignoreCase: false, variable: "int", target: "45")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_int() {
        let condition = Condition.equals(ignoreCase: false, variable: "int", target: "46")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_different_type_of_number() {
        let condition = Condition.equals(ignoreCase: false, variable: "int", target: "45.1")
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

    func test_equals_matches_nested_value() {
        let condition = Condition.equals(ignoreCase: false,
                                         path: ["dictionary"],
                                         variable: "key",
                                         target: "Value")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_matches_array() {
        let condition = Condition.equals(ignoreCase: false, variable: "array", target: "[\"a\", \"b\", \"c\"]")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_matches_nested_value_ignoring_case() {
        let condition = Condition.equals(ignoreCase: true,
                                         path: ["dictionary"],
                                         variable: "key",
                                         target: "VALUE")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_matches_null() {
        let condition = Condition.equals(ignoreCase: true,
                                         variable: "null",
                                         target: "<null>")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_equals_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.equals(ignoreCase: true, variable: "missing", target: "something")
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
