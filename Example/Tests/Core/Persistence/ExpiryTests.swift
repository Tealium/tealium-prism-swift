//
//  ExpiryTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 18/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ExpiryTests: XCTestCase {

    func test_session_expiryTime() {
        XCTAssertEqual(Expiry.session.expiryTime(), -2)
    }

    func test_untilRestart_expiryTime() {
        XCTAssertEqual(Expiry.untilRestart.expiryTime(), -3)
    }

    func test_forever_expiryTime() {
        XCTAssertEqual(Expiry.forever.expiryTime(), -1)
    }

    func test_after_expiryTime() {
        let date = Date(unixMilliseconds: 1_000_000)
        XCTAssertEqual(Expiry.after(date).expiryTime(), 1_000_000)
    }

    func test_initTimestamp_session() {
        XCTAssertEqual(Expiry(timestamp: -2), .session)
    }

    func test_initTimestamp_untilRestart() {
        XCTAssertEqual(Expiry(timestamp: -3), .untilRestart)
    }

    func test_initTimestamp_forever() {
        XCTAssertEqual(Expiry(timestamp: -1), .forever)
    }

    func test_initTimestamp_positiveValue_createsAfter() {
        let expiry = Expiry(timestamp: 1_000_000)
        XCTAssertEqual(expiry, .after(Date(unixMilliseconds: 1_000_000)))
    }
}
