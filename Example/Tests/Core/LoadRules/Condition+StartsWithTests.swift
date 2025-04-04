//
//  Condition+StartsWithTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConditionStartsWithTests: XCTestCase {
    let payload: DataObject = [
        "string": "Value",
        "int": 45,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
        "dictionary": ["key": "Value"],
        "null": NSNull()
    ]

    func test_startsWith_matches_string() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "string", prefix: "Val")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_startsWith_doesnt_match_different_string() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "string", prefix: "something_else")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_startsWith_doesnt_match_string_with_different_casing() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "string", prefix: "val")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_startsWith_matches_string_ignoring_case() {
        let condition = Condition.startsWith(ignoreCase: true, variable: "string", prefix: "VAL")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_startsWith_matches_int() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "int", prefix: "4")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_startsWith_matches_double() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "double", prefix: "3.1")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_startsWith_matches_bool() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "bool", prefix: "tr")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_startsWith_matches_nested_value() {
        let condition = Condition.startsWith(ignoreCase: false,
                                             path: ["dictionary"],
                                             variable: "key",
                                             prefix: "Val")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_startsWith_matches_array() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "array", prefix: "[\"a")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_startsWith_matches_nested_value_ignoring_case() {
        let condition = Condition.startsWith(ignoreCase: true,
                                             path: ["dictionary"],
                                             variable: "key",
                                             prefix: "VAL")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_startsWith_matches_null() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "null", prefix: "<nul")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_startsWith_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.startsWith(ignoreCase: false, variable: "missing", prefix: "something")
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
