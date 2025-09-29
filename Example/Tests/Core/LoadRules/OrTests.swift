//
//  OrTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 05/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class OrTests: XCTestCase {

    func or(conditions: [Matchable]) -> Rule<Matchable> {
        .or(conditions.map { .just($0) })
    }

    func test_or_with_empty_conditions_returns_false() {
        let orCondition = or(conditions: [])
        XCTAssertFalse(try orCondition.matches(payload: [:]))
    }

    func test_or_returns_true_if_at_least_one_contained_is_true() {
        let orCondition = or(conditions: [
            MockMatchable(result: false),
            MockMatchable(result: true),
            MockMatchable(result: false)
        ])
        XCTAssertTrue(try orCondition.matches(payload: [:]))
    }

    func test_or_returns_false_if_all_contained_return_false() {
        let orCondition = or(conditions: [
            MockMatchable(result: false),
            MockMatchable(result: false),
            MockMatchable(result: false)
        ])
        XCTAssertFalse(try orCondition.matches(payload: [:]))
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
        XCTAssertTrue(try orCondition.matches(payload: [:]))
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
        XCTAssertTrue(try orCondition.matches(payload: [:]))
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
        XCTAssertFalse(try orCondition.matches(payload: [:]))
    }

    func test_or_throws_if_there_is_no_true_returned_from_conditions_before_throwing_one() {
        let orRule = or(conditions: [
            AlwaysFalse(),
            AlwaysFalse(),
            AlwaysThrowingRuleNotFound(ruleId: "testRuleId", moduleId: "testModuleId")
        ])
        XCTAssertThrowsError(try orRule.matches(payload: [:]))
    }

    func test_or_does_not_throw_if_any_contained_condition_before_throwing_one_returns_true() {
        let orRule = or(conditions: [
            AlwaysTrue(),
            AlwaysFalse(),
            AlwaysThrowingRuleNotFound(ruleId: "testRuleId", moduleId: "testModuleId")
        ])
        let result = XCTAssertNoThrowReturn(try orRule.matches(payload: [:]))
        XCTAssertTrueOptional(result)
    }
}
