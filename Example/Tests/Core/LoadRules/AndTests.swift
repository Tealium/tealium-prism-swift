//
//  AndTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 05/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class AndTests: XCTestCase {

    func and(conditions: [Matchable]) -> Rule<Matchable> {
        .and(conditions.map { .just($0) })
    }

    func test_and_with_empty_conditions_returns_true() {
        let and = and(conditions: [])
        XCTAssertTrue(and.matches(payload: [:]))
    }

    func test_and_returns_true_if_all_contained_are_true() {
        let and = and(conditions: [
            MockMatchable(result: true),
            MockMatchable(result: true),
            MockMatchable(result: true)
        ])
        XCTAssertTrue(and.matches(payload: [:]))
    }

    func test_and_returns_false_if_at_least_one_contained_returns_false() {
        let and = and(conditions: [
            MockMatchable(result: true),
            MockMatchable(result: true),
            MockMatchable(result: false)
        ])
        XCTAssertFalse(and.matches(payload: [:]))
    }

    func test_and_doesnt_request_match_after_first_false() {
        let matchRequestNotPerformed = expectation(description: "MatchRequest not performed")
        matchRequestNotPerformed.isInverted = true
        let final = MockMatchable(result: true)
        final.onMatchRequest.subscribeOnce { _ in
            matchRequestNotPerformed.fulfill()
        }
        let and = and(conditions: [
            MockMatchable(result: true),
            MockMatchable(result: false),
            final
        ])
        XCTAssertFalse(and.matches(payload: [:]))
        waitForDefaultTimeout()
    }

    func test_and_returns_true_if_all_contained_are_true_when_nesting() {
        let and = and(conditions: [
            and(conditions: [
                MockMatchable(result: true),
                MockMatchable(result: true)
            ]),
            MockMatchable(result: true),
            MockMatchable(result: true)
        ])
        XCTAssertTrue(and.matches(payload: [:]))
    }

    func test_and_returns_false_if_at_least_one_contained_returns_false_when_nesting() {
        let and = and(conditions: [
            MockMatchable(result: true),
            MockMatchable(result: true),
            and(conditions: [
                MockMatchable(result: true),
                MockMatchable(result: false)
            ])
        ])
        XCTAssertFalse(and.matches(payload: [:]))
    }

}
