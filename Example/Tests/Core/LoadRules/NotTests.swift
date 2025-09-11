//
//  NotTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 05/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class NotTests: XCTestCase {

    func not(condition: Matchable) -> Rule<Matchable> {
        .not(.just(condition))
    }
    func test_not_returns_true_if_contained_is_false() {
        let not = not(condition: MockMatchable(result: false))
        XCTAssertTrue(try not.matches(payload: [:]))
    }

    func test_not_returns_false_if_contained_is_true() {
        let not = not(condition: MockMatchable(result: true))
        XCTAssertFalse(try not.matches(payload: [:]))
    }

    func test_not_nested_returns_underlying_condition() {
        let doubleNotTrue = not(condition: not(condition: MockMatchable(result: true)))
        let doubleNotFalse = not(condition: not(condition: MockMatchable(result: false)))
        XCTAssertTrue(try doubleNotTrue.matches(payload: [:]))
        XCTAssertFalse(try doubleNotFalse.matches(payload: [:]))
    }

    func test_not_throws_when_contained_throws() {
        let throwingNot = not(condition: AlwaysThrowingRuleNotFound(ruleId: "testRuleId", moduleId: "testModuleId"))
        XCTAssertThrowsError(try throwingNot.matches(payload: [:]))
    }
}
