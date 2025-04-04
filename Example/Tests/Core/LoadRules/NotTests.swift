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
        XCTAssertTrue(not.matches(payload: [:]))
    }

    func test_not_returns_false_if_contained_is_true() {
        let not = not(condition: MockMatchable(result: true))
        XCTAssertFalse(not.matches(payload: [:]))
    }

    func test_not_nested_returns_underlying_condition() {
        let doubleNotTrue = not(condition: not(condition: MockMatchable(result: true)))
        let doubleNotFalse = not(condition: not(condition: MockMatchable(result: false)))
        XCTAssertTrue(doubleNotTrue.matches(payload: [:]))
        XCTAssertFalse(doubleNotFalse.matches(payload: [:]))
    }
}
