//
//  OrTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 05/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class OrTests: XCTestCase {

    func or(conditions: [Matchable]) -> Rule<Matchable> {
        .or(conditions.map { .just($0) })
    }

    func test_or_with_empty_conditions_returns_false() {
        let orCondition = or(conditions: [])
        XCTAssertFalse(orCondition.matches(payload: [:]))
    }

    func test_or_returns_true_if_at_least_one_contained_is_true() {
        let orCondition = or(conditions: [
            MockMatchable(result: false),
            MockMatchable(result: true),
            MockMatchable(result: false)
        ])
        XCTAssertTrue(orCondition.matches(payload: [:]))
    }

    func test_or_returns_false_if_all_contained_return_false() {
        let orCondition = or(conditions: [
            MockMatchable(result: false),
            MockMatchable(result: false),
            MockMatchable(result: false)
        ])
        XCTAssertFalse(orCondition.matches(payload: [:]))
    }

    func test_or_doesnt_request_match_after_first_true() {
        let matchRequestNotPerformed = expectation(description: "MatchRequest not performed")
        matchRequestNotPerformed.isInverted = true
        let final = MockMatchable(result: true)
        final.onMatchRequest.subscribeOnce { _ in
            matchRequestNotPerformed.fulfill()
        }
        let orCondition = or(conditions: [
            MockMatchable(result: true),
            final
        ])
        XCTAssertTrue(orCondition.matches(payload: [:]))
        waitForDefaultTimeout()
    }

    func test_or_returns_true_if_at_least_one_true_when_nesting() {
        let orCondition = or(conditions: [
            or(conditions: [
                MockMatchable(result: true),
                MockMatchable(result: false)
            ]),
            MockMatchable(result: false),
            MockMatchable(result: false)
        ])
        XCTAssertTrue(orCondition.matches(payload: [:]))
    }

    func test_or_returns_false_if_all_contained_return_false_when_nesting() {
        let orCondition = or(conditions: [
            MockMatchable(result: false),
            MockMatchable(result: false),
            or(conditions: [
                MockMatchable(result: false),
                MockMatchable(result: false)
            ])
        ])
        XCTAssertFalse(orCondition.matches(payload: [:]))
    }

}
