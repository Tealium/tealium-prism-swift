//
//  Condition+LessThanTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConditionLessThanTests: XCTestCase {
    let payload: DataObject = [
        "string": "45",
        "int": 45,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
        "dictionary": ["key": 45],
        "null": NSNull()
    ]

    func test_lessThan_doesnt_match_strings() {
        let condition = Condition.isLessThan(orEqual: false, variable: "string", number: "10")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_lessThan_doesnt_match_bools() {
        let condition = Condition.isLessThan(orEqual: false, variable: "bool", number: "10")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_lessThan_doesnt_match_arrays() {
        let condition = Condition.isLessThan(orEqual: false, variable: "array", number: "10")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_lessThan_doesnt_match_dictionaries() {
        let condition = Condition.isLessThan(orEqual: false, variable: "dictionary", number: "10")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_lessThan_doesnt_match_if_int_greater_than_filter() {
        let condition = Condition.isLessThan(orEqual: false, variable: "int", number: "4")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_lessThan_doesnt_match_if_double_greater_than_filter() {
        let condition = Condition.isLessThan(orEqual: false, variable: "double", number: "3.13")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_lessThan_doesnt_match_if_int_equals_filter() {
        let condition = Condition.isLessThan(orEqual: false, variable: "int", number: "45")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_lessThan_doesnt_match_if_double_equals_filter() {
        let condition = Condition.isLessThan(orEqual: false, variable: "double", number: "3.14")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_lessThan_matches_if_int_less_than_filter() {
        let condition = Condition.isLessThan(orEqual: false, variable: "int", number: "46")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_lessThan_matches_if_double_less_than_filter() {
        let condition = Condition.isLessThan(orEqual: false, variable: "double", number: "3.15")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_lessThan_matches_if_int_less_than_filter_in_nested_object() {
        let condition = Condition.isLessThan(orEqual: false,
                                             variable: VariableAccessor(path: ["dictionary"],
                                                                        variable: "key"),
                                             number: "46")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_lessThan_doesnt_match_null() {
        let condition = Condition.isLessThan(orEqual: false, variable: "null", number: "1")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_lessThan_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.isLessThan(orEqual: false, variable: "missing", number: "1")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_lessThan_doesnt_match_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.isLessThan(orEqual: false,
                                             variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                        variable: "key"),
                                             number: "1")
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
