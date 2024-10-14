//
//  TealiumLoggerTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumLoggerTests: XCTestCase {
    let logHandler = MockLogHandler()
    let onLogLevel = ReplaySubject<LogLevel.Minimum>()
    var forceLevel: LogLevel.Minimum?
    lazy var logger = createLogger()
    func createLogger() -> TealiumLogger {
        TealiumLogger(logHandler: logHandler, onLogLevel: onLogLevel.asObservable(), forceLevel: forceLevel)
    }

    func test_shouldLog_returns_true_for_higher_log_levels() {
        forceLevel = .info
        XCTAssertFalse(logger.shouldLog(level: .trace))
        XCTAssertFalse(logger.shouldLog(level: .debug))
        XCTAssertTrue(logger.shouldLog(level: .info))
        XCTAssertTrue(logger.shouldLog(level: .warn))
        XCTAssertTrue(logger.shouldLog(level: .error))
    }

    func test_shouldLog_returns_true_when_minimumLevel_is_nil() {
        XCTAssertTrue(logger.shouldLog(level: .trace))
        XCTAssertTrue(logger.shouldLog(level: .debug))
        XCTAssertTrue(logger.shouldLog(level: .info))
        XCTAssertTrue(logger.shouldLog(level: .warn))
        XCTAssertTrue(logger.shouldLog(level: .error))
    }

    func test_minimum_log_level_changes_when_observable_publishes_new_level() {
        XCTAssertNil(logger.minimumLevel)
        onLogLevel.publish(.trace)
        XCTAssertEqual(logger.minimumLevel, .trace)
        onLogLevel.publish(.debug)
        XCTAssertEqual(logger.minimumLevel, .debug)
        onLogLevel.publish(.info)
        XCTAssertEqual(logger.minimumLevel, .info)
        onLogLevel.publish(.warn)
        XCTAssertEqual(logger.minimumLevel, .warn)
        onLogLevel.publish(.error)
        XCTAssertEqual(logger.minimumLevel, .error)
    }

    func test_log_requests_are_ignored_when_log_level_is_lower_than_minimum() {
        let errorLevelIsLogged = expectation(description: "Error level is the only one logged")
        forceLevel = .error
        _ = logHandler.onLogged.subscribe { logEvent in
            errorLevelIsLogged.fulfill()
            XCTAssertEqual(logEvent.level, .error)
        }
        logger.trace(category: "category", "message")
        logger.debug(category: "category", "message")
        logger.info(category: "category", "message")
        logger.warn(category: "category", "message")
        logger.error(category: "category", "message")
        waitForDefaultTimeout()
    }

    func test_logs_wait_for_first_log_level_to_be_sent_or_discarded() {
        logger.trace(category: "category", "message")
        logger.error(category: "category", "message")
        let nothingWillBeLoggedYet = expectation(description: "Nothing will be logged yet")
        nothingWillBeLoggedYet.isInverted = true
        let subscription = logHandler.onLogged.subscribe { _ in
            nothingWillBeLoggedYet.fulfill()
        }
        waitForDefaultTimeout()
        subscription.dispose()
        let errorLevelIsLogged = expectation(description: "Error level is the only one logged")
        _ = logHandler.onLogged.subscribe { logEvent in
            errorLevelIsLogged.fulfill()
            XCTAssertEqual(logEvent.level, .error)
        }
        onLogLevel.publish(.info)
        waitForDefaultTimeout()
    }

    func test_message_is_calculated_after_log_is_accepted() {
        func createMessage(expectation: XCTestExpectation) -> String {
            expectation.fulfill()
            return "message"
        }
        let messageNotCreated = expectation(description: "Message is not created")
        messageNotCreated.isInverted = true
        logger.trace(category: "category", createMessage(expectation: messageNotCreated))
        waitForDefaultTimeout()
        let messageIsCreated = expectation(description: "Message is created")
        logger.error(category: "category", createMessage(expectation: messageIsCreated))
        onLogLevel.publish(.info)
        waitForLongTimeout()
    }
}
