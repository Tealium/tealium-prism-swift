//
//  DateFormatterTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 01/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DateFormatterTests: XCTestCase {
    let firstOfJanuary2000: Int64 = 946_684_800_000
    let firstOfJuly2025: Int64 = 1_751_371_200_000
    let currentTimezone = TimeZone.current.identifier

    override func tearDown() {
        setTimezone(currentTimezone)
    }

    func test_ISO8601_formatter_ends_with_Z() {
        let date = Date()
        XCTAssertTrue(Date.Formatter.iso8601.string(from: date).hasSuffix("Z"))
    }

    func test_ISO8601_formatter_formats_correct_date() {
        let date = Date(unixMilliseconds: firstOfJuly2025)
        XCTAssertEqual(Date.Formatter.iso8601.string(from: date), "2025-07-01T12:00:00Z")
    }

    func test_MMDDYYYY_formatter_formats_in_MMDDYYYY() {
        let date = Date(unixMilliseconds: firstOfJuly2025)
        XCTAssertEqual(Date.Formatter.MMDDYYYY.string(from: date), "07/01/2025")
    }

    func test_ISO8601_local_formatter_with_summer_date() {
        let date = Date(unixMilliseconds: firstOfJuly2025)
        let formatter = Date.Formatter.iso8601Local
        let losAngeles = "America/Los_Angeles"  // -8:00 (-7 with daylight savings)
        setTimezone(losAngeles)
        let losAngelesDate = formatter.string(from: date)
        XCTAssertEqual(losAngelesDate, "2025-07-01T05:00:00")

        let katmandu = "Asia/Katmandu"  // +5:45 (no daylight savings in katmandu)
        setTimezone(katmandu)
        let katmanduDate = formatter.string(from: date)
        XCTAssertEqual(katmanduDate, "2025-07-01T17:45:00")
    }

    func test_ISO8601_local_with_offset_formatter_with_summer_date() {
        let date = Date(unixMilliseconds: firstOfJuly2025)
        let formatter = Date.Formatter.iso8601LocalWithOffset

        let losAngeles = "America/Los_Angeles"  // -8:00 (-7 with daylight savings)
        setTimezone(losAngeles)
        let losAngelesDate = formatter.string(from: date)
        XCTAssertEqual(losAngelesDate, "2025-07-01T05:00:00-07:00")

        let katmandu = "Asia/Katmandu"  // +5:45 (no daylight savings in katmandu)
        setTimezone(katmandu)
        let katmanduDate = formatter.string(from: date)
        XCTAssertEqual(katmanduDate, "2025-07-01T17:45:00+05:45")
    }

    func test_ISO8601_local_formatter_with_winter_date() {
        let date = Date(unixMilliseconds: firstOfJanuary2000)
        let formatter = Date.Formatter.iso8601Local
        let losAngeles = "America/Los_Angeles"  // -8:00
        setTimezone(losAngeles)
        let losAngelesDate = formatter.string(from: date)
        XCTAssertEqual(losAngelesDate, "1999-12-31T16:00:00")

        let katmandu = "Asia/Katmandu"  // +5:45
        setTimezone(katmandu)
        let katmanduDate = formatter.string(from: date)
        XCTAssertEqual(katmanduDate, "2000-01-01T05:45:00")
    }

    func test_ISO8601_local_with_offset_formatter_with_winter_date() {
        let date = Date(unixMilliseconds: firstOfJanuary2000)
        let formatter = Date.Formatter.iso8601LocalWithOffset

        let losAngeles = "America/Los_Angeles"  // -8:00
        setTimezone(losAngeles)
        let losAngelesDate = formatter.string(from: date)
        XCTAssertEqual(losAngelesDate, "1999-12-31T16:00:00-08:00")

        let katmandu = "Asia/Katmandu"  // +5:45
        setTimezone(katmandu)
        let katmanduDate = formatter.string(from: date)
        XCTAssertEqual(katmanduDate, "2000-01-01T05:45:00+05:45")
    }

    func setTimezone(_ timezone: String) {
        setenv("TZ", timezone, 1)
        CFTimeZoneResetSystem()
        XCTAssertEqual(TimeZone.current.identifier, timezone)
    }
}
