//
//  Condition+IsPopulatedTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConditionIsPopulatedTests: XCTestCase {
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

    func test_isPopulated_matches_every_key_present_in_the_payload_that_is_not_empty() {
        for key in payload.keys.filter({ !$0.contains("empty") }) {
            let condition = Condition.isPopulated(variable: VariableAccessor(variable: key))
            XCTAssertTrue(condition.matches(payload: payload))
        }
    }

    func test_isPopulated_doesnt_match_every_key_present_in_the_payload_that_is_empty() {
        for key in payload.keys.filter({ $0.contains("empty") }) {
            let condition = Condition.isPopulated(variable: VariableAccessor(variable: key))
            XCTAssertFalse(condition.matches(payload: payload))
        }
    }

    func test_isPopulated_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.isPopulated(variable: "missing")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_isPopulated_doesnt_match_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.isPopulated(variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                         variable: "key"))
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_isNotPopulated_doesnt_match_every_key_present_in_the_payload_that_is_not_empty() {
        for key in payload.keys.filter({ !$0.contains("empty") }) {
            let condition = Condition.isNotPopulated(variable: VariableAccessor(variable: key))
            XCTAssertFalse(condition.matches(payload: payload))
        }
    }

    func test_isNotPopulated_matches_every_key_present_in_the_payload_that_is_empty() {
        for key in payload.keys.filter({ $0.contains("empty") }) {
            let condition = Condition.isNotPopulated(variable: VariableAccessor(variable: key))
            XCTAssertTrue(condition.matches(payload: payload))
        }
    }

    func test_isNotPopulated_doesnt_match_any_keys_missing_from_the_payload() {
        let condition = Condition.isNotPopulated(variable: "missing")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_isNotPopulated_doesnt_match_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.isNotPopulated(variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                            variable: "key"))
        XCTAssertFalse(condition.matches(payload: payload))
    }
}
