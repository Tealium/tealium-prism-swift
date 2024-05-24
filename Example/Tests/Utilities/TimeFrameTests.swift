//
//  TimeFrameTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 24/05/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TimeFrameTests: XCTestCase {

    func test_lessThan_is_true_for_shorter_intervals_but_same_unit() {
        let time1 = TimeFrame(unit: .seconds, interval: 10)
        let time2 = TimeFrame(unit: .seconds, interval: 20)
        XCTAssertTrue(time1 < time2)
        XCTAssertFalse(time1 > time2)
    }

    func test_lessThan_is_false_for_same_intervals_and_same_unit() {
        let time1 = TimeFrame(unit: .seconds, interval: 10)
        let time2 = TimeFrame(unit: .seconds, interval: 10)
        XCTAssertFalse(time1 < time2)
        XCTAssertFalse(time1 > time2)
    }

    func test_lessThan_is_true_for_smaller_unit_but_same_interval() {
        let time1 = TimeFrame(unit: .seconds, interval: 10)
        let time2 = TimeFrame(unit: .hours, interval: 10)
        XCTAssertTrue(time1 < time2)
        XCTAssertFalse(time1 > time2)
    }

    func test_lessThan_is_true_for_shorter_absolute_timeFrame_but_different_unit_and_interval() {
        let time1 = TimeFrame(unit: .minutes, interval: 2)
        let time2 = TimeFrame(unit: .seconds, interval: 130)
        XCTAssertTrue(time1 < time2)
        XCTAssertFalse(time1 > time2)
    }

    func test_equals_is_true_for_same_intervals_and_same_unit() {
        let time1 = TimeFrame(unit: .seconds, interval: 10)
        let time2 = TimeFrame(unit: .seconds, interval: 10)
        XCTAssertTrue(time1 == time2)
    }

    func test_equals_is_false_for_smaller_unit_but_same_interval() {
        let time1 = TimeFrame(unit: .seconds, interval: 10)
        let time2 = TimeFrame(unit: .hours, interval: 10)
        XCTAssertFalse(time1 == time2)
    }

    func test_equals_is_true_for_different_units_and_interval_that_amounts_to_the_same_time() {
        let time1 = TimeFrame(unit: .minutes, interval: 2)
        let time2 = TimeFrame(unit: .seconds, interval: 120)
        XCTAssertTrue(time1 == time2)
    }
}
