//
//  TimeFrameTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 24/05/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TimeFrameTests: XCTestCase {
    let firstOfJanuary2000: Int64 = 946_684_800_000
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

    func test_inSeconds_conversion() {
        let millisecondsFrame = 10.milliseconds
        XCTAssertEqual(millisecondsFrame.inSeconds(), 0.01)
        let secondsFrame = 10.seconds
        XCTAssertEqual(secondsFrame.inSeconds(), 10.0)
        let minutesFrame = 10.minutes
        XCTAssertEqual(minutesFrame.inSeconds(), 600.0)
        let hoursFrame = 10.hours
        XCTAssertEqual(hoursFrame.inSeconds(), 36_000.0)
        let daysFrame = 10.days
        XCTAssertEqual(daysFrame.inSeconds(), 864_000.0)
    }

    func test_inMilliseconds_conversion() {
        let millisecondsFrame = 10.milliseconds
        XCTAssertEqual(millisecondsFrame.inMilliseconds(), 10)
        let secondsFrame = 10.seconds
        XCTAssertEqual(secondsFrame.inMilliseconds(), 10_000)
        let minutesFrame = 10.minutes
        XCTAssertEqual(minutesFrame.inMilliseconds(), 600_000)
        let hoursFrame = 10.hours
        XCTAssertEqual(hoursFrame.inMilliseconds(), 36_000_000)
        let daysFrame = 10.days
        XCTAssertEqual(daysFrame.inMilliseconds(), 864_000_000)
    }

    func test_big_timeFrames_conversions() {
        let bigTimeFrame = Int.max.days
        XCTAssertEqual(bigTimeFrame.inMilliseconds(), Int64.max)
        XCTAssertLessThan(bigTimeFrame.inSeconds(), Double.greatestFiniteMagnitude)
    }

    func test_after_adds_the_timeFrame_to_a_date() {
        let date = Date(unixMilliseconds: firstOfJanuary2000)
        let newDate = 5.days.after(date: date)
        XCTAssertEqual(newDate.unixTimeMilliseconds, firstOfJanuary2000 + 5.days.inMilliseconds())
    }

    func test_before_subtracts_the_timeFrame_to_a_date() {
        let date = Date(unixMilliseconds: firstOfJanuary2000)
        let newDate = 5.days.before(date: date)
        XCTAssertEqual(newDate.unixTimeMilliseconds, firstOfJanuary2000 - 5.days.inMilliseconds())
    }

    func test_after_does_not_crash_for_overflow() {
        let date = Date(unixMilliseconds: firstOfJanuary2000)
        let newDate = Int64.max.seconds.after(date: date)
        XCTAssertEqual(newDate.unixTimeMilliseconds, Int64.max)
    }

    func test_before_does_not_crash_for_underflow() {
        let date = Date(unixMilliseconds: -firstOfJanuary2000)
        let newDate = Int64.max.seconds.before(date: date)
        XCTAssertEqual(newDate.unixTimeMilliseconds, Int64.min)
    }
}
