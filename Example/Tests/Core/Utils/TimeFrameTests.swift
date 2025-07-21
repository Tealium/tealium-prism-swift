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
        let time1 = 10.seconds
        let time2 = 20.seconds
        XCTAssertTrue(time1 < time2)
        XCTAssertFalse(time1 > time2)
    }

    func test_lessThan_is_false_for_same_intervals_and_same_unit() {
        let time1 = 10.seconds
        let time2 = 10.seconds
        XCTAssertFalse(time1 < time2)
        XCTAssertFalse(time1 > time2)
    }

    func test_lessThan_is_true_for_smaller_unit_but_same_interval() {
        let time1 = 10.seconds
        let time2 = 10.hours
        XCTAssertTrue(time1 < time2)
        XCTAssertFalse(time1 > time2)
    }

    func test_lessThan_is_true_for_shorter_absolute_timeFrame_but_different_unit_and_interval() {
        let time1 = 2.minutes
        let time2 = 130.seconds
        XCTAssertTrue(time1 < time2)
        XCTAssertFalse(time1 > time2)
    }

    func test_equals_is_true_for_same_intervals_and_same_unit() {
        let time1 = 10.seconds
        let time2 = 10.seconds
        XCTAssertTrue(time1 == time2)
    }

    func test_equals_is_false_for_smaller_unit_but_same_interval() {
        let time1 = 10.seconds
        let time2 = 10.hours
        XCTAssertFalse(time1 == time2)
    }

    func test_equals_is_true_for_different_units_and_interval_that_amounts_to_the_same_time() {
        let time1 = 2.minutes
        let time2 = 120.seconds
        XCTAssertTrue(time1 == time2)
    }

    func test_seconds_conversion() {
        let millisecondsFrame = 10.milliseconds
        XCTAssertEqual(millisecondsFrame.seconds(), 0.01)
        let secondsFrame = 10.seconds
        XCTAssertEqual(secondsFrame.seconds(), 10.0)
        let minutesFrame = 10.minutes
        XCTAssertEqual(minutesFrame.seconds(), 600.0)
        let hoursFrame = 10.hours
        XCTAssertEqual(hoursFrame.seconds(), 36_000.0)
        let daysFrame = 10.days
        XCTAssertEqual(daysFrame.seconds(), 864_000.0)
        let monthsFrame = TimeFrame(unit: .months, interval: 10)
        XCTAssertEqual(monthsFrame.seconds(), 26_280_000.0)
        let yearsFrame = TimeFrame(unit: .years, interval: 10)
        XCTAssertEqual(yearsFrame.seconds(), 315_360_000.0)
    }
}
