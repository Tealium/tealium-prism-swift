//
//  Condition+IsDefinedTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConditionIsDefinedTests: XCTestCase {
    let payload: DataObject = [
        "string": "Value",
        "int": 45,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
        "dictionary": ["key": "Value"],
        "null": NSNull()
    ]

    func test_isDefined_matches_every_key_present_in_the_payload() {
        for key in payload.keys {
            let condition = Condition.isDefined(variable: key)
            XCTAssertTrue(try condition.matches(payload: payload))
        }
    }

    func test_isDefined_matches_null() {
        let condition = Condition.isDefined(variable: "null")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_isDefined_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.isDefined(variable: "missing")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_isDefined_doesnt_match_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.isDefined(variable: JSONPath["dictionary"]["missing"]["key"])
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_isNotDefined_doesnt_match_any_key_present_in_the_payload() {
        for key in payload.keys {
            let condition = Condition.isNotDefined(variable: key)
            XCTAssertFalse(try condition.matches(payload: payload))
        }
    }

    func test_isNotDefined_doesnt_match_null() {
        let condition = Condition.isNotDefined(variable: "null")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_isNotDefined_matches_every_keys_missing_from_the_payload() {
        let condition = Condition.isNotDefined(variable: "missing")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_isNotDefined_matches_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.isNotDefined(variable: JSONPath["dictionary"]["missing"]["key"])
        XCTAssertTrue(try condition.matches(payload: payload))
    }
}
