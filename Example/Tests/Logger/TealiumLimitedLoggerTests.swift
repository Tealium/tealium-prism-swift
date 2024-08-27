//
//  TealiumLimitedLoggerTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumLimitedLoggerTests: XCTestCase {
    var shouldLog: Bool? = true
    var logLevel = TealiumLogLevel.debug
    let mockLogHandler = MockLogHandler()
    lazy var logger = TealiumLimitedLogger(logLevel: logLevel, logger: mockLogHandler) { [weak self] in
        self?.shouldLog
    }

    func test_log_is_sent_when_should_log_returns_true() {
        let logged = expectation(description: "Log is sent")
        logger.log(category: "category", message: "message")
        mockLogHandler.onLogged.subscribeOnce { category, message, level in
            XCTAssertEqual(category, "category")
            XCTAssertEqual(message, "message")
            XCTAssertEqual(level, self.logLevel)
            logged.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_log_is_not_sent_when_should_log_returns_false() {
        let logged = expectation(description: "Log is NOT sent")
        logged.isInverted = true
        shouldLog = false
        logger.log(category: "category", message: "message")
        mockLogHandler.onLogged.subscribeOnce { _, _, _ in
            logged.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_log_is_not_sent_when_should_log_returns_nil() {
        let logged = expectation(description: "Log is NOT sent")
        logged.isInverted = true
        shouldLog = nil
        logger.log(category: "category", message: "message")
        mockLogHandler.onLogged.subscribeOnce { _, _, _ in
            logged.fulfill()
        }
        waitForDefaultTimeout()
    }
}
