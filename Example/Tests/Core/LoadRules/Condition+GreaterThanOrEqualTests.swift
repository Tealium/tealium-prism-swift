//
//  Condition+GreaterThanOrEqualTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConditionGreaterThanOrEqualTests: XCTestCase {
    let payload: DataObject = [
        "string": "45",
        "int": 45,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
        "dictionary": ["key": 45],
        "null": NSNull()
    ]

    func test_greaterThanOrEqual_doesnt_match_strings() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "string", number: "10")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_doesnt_match_bools() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "bool", number: "10")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_doesnt_match_arrays() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "array", number: "10")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_doesnt_match_dictionaries() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "dictionary", number: "10")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_matches_if_int_greater_than_filter() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "int", number: "4")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_matches_if_double_greater_than_filter() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "double", number: "3.13")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_matches_if_int_equals_filter() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "int", number: "45")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_matches_if_double_equals_filter() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "double", number: "3.14")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_doesnt_match_if_int_less_than_filter() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "int", number: "46")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_doesnt_match_if_double_less_than_filter() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "double", number: "3.15")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_matches_if_int_greater_than_filter_in_nested_object() {
        let condition = Condition.isGreaterThan(orEqual: true,
                                                path: ["dictionary"],
                                                variable: "key",
                                                number: "44")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_doesnt_match_null() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "null", number: "1")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_greaterThanOrEqual_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.isGreaterThan(orEqual: true, variable: "missing", number: "1")
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
