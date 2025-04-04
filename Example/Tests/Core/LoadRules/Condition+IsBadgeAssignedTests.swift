//
//  Condition+IsBadgeAssignedTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

// Behavior is identical to isDefined
final class ConditionIsBadgeAssignedTests: XCTestCase {
    let payload: DataObject = [
        "string": "Value",
        "int": 45,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
        "dictionary": ["key": "Value"],
        "null": NSNull()
    ]

    func test_isBadgeAssigned_matches_every_key_present_in_the_payload() {
        for key in payload.keys {
            let condition = Condition.isBadgeAssigned(variable: key)
            XCTAssertTrue(condition.matches(payload: payload))
        }
    }

    func test_isBadgeAssigned_matches_null() {
        let condition = Condition.isBadgeAssigned(variable: "null")
        XCTAssertTrue(condition.matches(payload: payload))
    }

    func test_isBadgeAssigned_doesnt_match_keys_missing_from_the_payload() {
        let condition = Condition.isBadgeAssigned(variable: "missing")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_isBadgeNotAssigned_doesnt_match_any_key_present_in_the_payload() {
        for key in payload.keys {
            let condition = Condition.isBadgeNotAssigned(variable: key)
            XCTAssertFalse(condition.matches(payload: payload))
        }
    }

    func test_isBadgeNotAssigned_doesnt_match_null() {
        let condition = Condition.isBadgeNotAssigned(variable: "null")
        XCTAssertFalse(condition.matches(payload: payload))
    }

    func test_isBadgeNotAssigned_matches_every_keys_missing_from_the_payload() {
        let condition = Condition.isBadgeNotAssigned(variable: "missing")
        XCTAssertTrue(condition.matches(payload: payload))
    }
}
