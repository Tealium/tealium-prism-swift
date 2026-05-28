//
//  ExpiryPolicyTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 20/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ExpiryPolicyTests: XCTestCase {

    func test_resolve_session() {
        XCTAssertEqual(ExpiryPolicy.session.resolve(), .session)
    }

    func test_resolve_untilRestart() {
        XCTAssertEqual(ExpiryPolicy.untilRestart.resolve(), .untilRestart)
    }

    func test_resolve_forever() {
        XCTAssertEqual(ExpiryPolicy.forever.resolve(), .forever)
    }

    func test_resolve_duration_produces_after_expiry() {
        let result = ExpiryPolicy.duration(5.minutes).resolve()
        guard case .after(let date) = result else {
            XCTFail("Expected .after case")
            return
        }
        let expectedMin = Date().addingTimeInterval(5 * 60 - 1)
        let expectedMax = Date().addingTimeInterval(5 * 60 + 1)
        XCTAssertGreaterThan(date, expectedMin)
        XCTAssertLessThan(date, expectedMax)
    }

    func test_resolve_duration_produces_fresh_timestamp_each_call() {
        let policy = ExpiryPolicy.duration(1.hours)
        let first = policy.resolve().expiryTime()
        let second = policy.resolve().expiryTime()
        XCTAssertGreaterThanOrEqual(second, first)
    }

    func test_equality_same_cases() {
        XCTAssertEqual(ExpiryPolicy.session, .session)
        XCTAssertEqual(ExpiryPolicy.forever, .forever)
        XCTAssertEqual(ExpiryPolicy.untilRestart, .untilRestart)
        XCTAssertEqual(ExpiryPolicy.duration(5.minutes), .duration(5.minutes))
    }

    func test_equality_different_durations() {
        XCTAssertNotEqual(ExpiryPolicy.duration(5.minutes), .duration(10.minutes))
    }

    func test_equality_different_cases() {
        XCTAssertNotEqual(ExpiryPolicy.session, .forever)
        XCTAssertNotEqual(ExpiryPolicy.session, .duration(5.minutes))
    }

    // MARK: - toDataInput

    func test_toDataInput_forever() {
        guard let value = ExpiryPolicy.forever.toDataInput() as? Int64 else {
            XCTFail("Expected Int64")
            return
        }
        XCTAssertEqual(value, -1)
    }

    func test_toDataInput_session() {
        guard let value = ExpiryPolicy.session.toDataInput() as? Int64 else {
            XCTFail("Expected Int64")
            return
        }
        XCTAssertEqual(value, -2)
    }

    func test_toDataInput_untilRestart() {
        guard let value = ExpiryPolicy.untilRestart.toDataInput() as? Int64 else {
            XCTFail("Expected Int64")
            return
        }
        XCTAssertEqual(value, -3)
    }

    func test_toDataInput_duration() {
        guard let value = ExpiryPolicy.duration(5.minutes).toDataInput() as? Int64 else {
            XCTFail("Expected Int64")
            return
        }
        XCTAssertEqual(value, 300)
    }

    // MARK: - Round-trip (toDataInput -> DataItem -> Converter)

    func test_converter_roundTrip_session() {
        let dataItem = DataItem(value: ExpiryPolicy.session.toDataInput())
        XCTAssertEqual(ExpiryPolicy.converter.convert(dataItem: dataItem), .session)
    }

    func test_converter_roundTrip_forever() {
        let dataItem = DataItem(value: ExpiryPolicy.forever.toDataInput())
        XCTAssertEqual(ExpiryPolicy.converter.convert(dataItem: dataItem), .forever)
    }

    func test_converter_roundTrip_untilRestart() {
        let dataItem = DataItem(value: ExpiryPolicy.untilRestart.toDataInput())
        XCTAssertEqual(ExpiryPolicy.converter.convert(dataItem: dataItem), .untilRestart)
    }

    func test_converter_roundTrip_duration() {
        let dataItem = DataItem(value: ExpiryPolicy.duration(5.minutes).toDataInput())
        XCTAssertEqual(ExpiryPolicy.converter.convert(dataItem: dataItem), .duration(TimeFrame(unit: .seconds, interval: 300)))
    }

    // MARK: - Converter invalid input

    func test_converter_returns_nil_for_invalid_sentinel() {
        let dataItem = DataItem(value: Int64(-99))
        XCTAssertNil(ExpiryPolicy.converter.convert(dataItem: dataItem))
    }

    func test_converter_returns_nil_for_non_numeric_input() {
        let dataItem = DataItem(value: "not a number")
        XCTAssertNil(ExpiryPolicy.converter.convert(dataItem: dataItem))
    }
}
