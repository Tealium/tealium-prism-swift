//
//  JustTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 13/07/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class JustTests: XCTestCase {

    func just(condition: Matchable) -> Rule<Matchable> {
        .just(condition)
    }
    func test_just_returns_true_if_contained_is_true() {
        let just = just(condition: AlwaysTrue())
        XCTAssertTrue(try just.matches(payload: [:]))
    }

    func test_just_returns_false_if_contained_is_false() {
        let just = just(condition: AlwaysFalse())
        XCTAssertFalse(try just.matches(payload: [:]))
    }

    func test_just_nested_returns_underlying_condition() {
        let doubleJustTrue = just(condition: just(condition: AlwaysTrue()))
        let doubleJustFalse = just(condition: just(condition: AlwaysFalse()))
        XCTAssertTrue(try doubleJustTrue.matches(payload: [:]))
        XCTAssertFalse(try doubleJustFalse.matches(payload: [:]))
    }

    func test_just_throws_when_contained_throws() {
        let throwingjust = just(condition: AlwaysThrowingRuleNotFound(ruleId: "testRuleId", moduleId: "testModuleId"))
        XCTAssertThrowsError(try throwingjust.matches(payload: [:]))
    }

}
