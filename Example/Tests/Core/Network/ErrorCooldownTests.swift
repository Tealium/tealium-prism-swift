//
//  ErrorCooldownTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 17/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//
@testable import TealiumPrism
import XCTest

final class ErrorCooldownTests: XCTestCase {
    let errorCooldown = ErrorCooldown(baseInterval: 10.seconds, maxInterval: 50.seconds)
    let error = NetworkError.non200Status(400)

    func testStartsNotInCooldown() {
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date()))
    }

    func testGoesInCooldownAfterError() {
        errorCooldown.newCooldownEvent(error: error)
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date()))
    }

    func testCooldownEndsAfterErrorBaseInterval() {
        errorCooldown.newCooldownEvent(error: error)
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date()))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-11)))
    }

    func testCooldownIncreasesAfterNewErrors() {
        errorCooldown.newCooldownEvent(error: error)
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date()))
        errorCooldown.newCooldownEvent(error: error)
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-11)))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-21)))
    }

    func testCooldownCantBeOverMaxInterval() {
        for _ in 0..<7 {
            errorCooldown.newCooldownEvent(error: error)
        }
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-49)))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-51)))
    }

    func testCooldownIsResetOnSuccessEvent() {
        for _ in 0..<7 {
            errorCooldown.newCooldownEvent(error: error)
        }
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-49)))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-51)))
        errorCooldown.newCooldownEvent(error: nil)
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date()))
    }

    func testCooldownIsOnBaseValueAfterBeingReset() {
        for _ in 0..<7 {
            errorCooldown.newCooldownEvent(error: error)
        }
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-49)))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-51)))
        errorCooldown.newCooldownEvent(error: nil)
        errorCooldown.newCooldownEvent(error: error)
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-9)))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-11)))
    }

    func testInitializationFailsWithoutBaseInterval() {
        let errorCooldown = ErrorCooldown(baseInterval: nil, maxInterval: 50.seconds)
        XCTAssertNil(errorCooldown)
    }
}
