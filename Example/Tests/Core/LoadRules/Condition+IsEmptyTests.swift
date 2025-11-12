//
//  Condition+IsEmptyTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConditionIsEmptyTests: XCTestCase {
    let payload: DataObject = [
        "string": "Value",
        "int": 45,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
        "dictionary": ["key": "Value"],
        "emptyNull": NSNull(),
        "emptyString": "",
        "emptyArray": [String](),
        "emptyDictionary": [String: String]()
    ]

    func test_isEmpty_doesnt_match_every_key_present_in_the_payload_that_is_not_empty() {
        for key in payload.keys.filter({ !$0.contains("empty") }) {
            let condition = Condition.isEmpty(variable: key)
            XCTAssertFalse(try condition.matches(payload: payload))
        }
    }

    func test_isEmpty_matches_every_key_present_in_the_payload_that_is_empty() {
        for key in payload.keys.filter({ $0.contains("empty") }) {
            let condition = Condition.isEmpty(variable: key)
            XCTAssertTrue(try condition.matches(payload: payload))
        }
    }

    func test_isEmpty_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.isEmpty(variable: "missing")
        XCTAssertThrows(try condition.matches(payload: payload)) { (error: ConditionEvaluationError) in
            guard case .missingDataItem = error.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(error.condition, condition)
        }
    }

    func test_isEmpty_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.isEmpty(variable: JSONPath["dictionary"]["missing"]["key"])
        XCTAssertThrows(try condition.matches(payload: payload)) { (error: ConditionEvaluationError) in
            guard case .missingDataItem = error.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(error.condition, condition)
        }
    }

    func test_isNotEmpty_matches_every_key_present_in_the_payload_that_is_not_empty() {
        for key in payload.keys.filter({ !$0.contains("empty") }) {
            let condition = Condition.isNotEmpty(variable: key)
            XCTAssertTrue(try condition.matches(payload: payload))
        }
    }

    func test_isNotEmpty_doesnt_match_every_key_present_in_the_payload_that_is_empty() {
        for key in payload.keys.filter({ $0.contains("empty") }) {
            let condition = Condition.isNotEmpty(variable: key)
            XCTAssertFalse(try condition.matches(payload: payload))
        }
    }

    func test_isNotEmpty_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.isNotEmpty(variable: "missing")
        XCTAssertThrows(try condition.matches(payload: payload)) { (error: ConditionEvaluationError) in
            guard case .missingDataItem = error.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(error.condition, condition)
        }
    }

    func test_isNotEmpty_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.isNotEmpty(variable: JSONPath["dictionary"]["missing"]["key"])
        XCTAssertThrows(try condition.matches(payload: payload)) { (error: ConditionEvaluationError) in
            guard case .missingDataItem = error.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(error.condition, condition)
        }
    }
}
