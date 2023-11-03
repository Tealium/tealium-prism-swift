//
//  TealiumLoggerTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumLoggerTests: XCTestCase {
    var onCoreSettings = TealiumPublisher<CoreSettings>()
    lazy var logger = TealiumLogger(logger: MockLogHandler(), minLogLevel: .debug, onCoreSettings: onCoreSettings.asObservable())
    func test_getLogger_returns_logger_only_when_higherThan_or_equalTo_minLogLevel() {
        XCTAssertNil(logger.getLogger(.trace))
        XCTAssertNotNil(logger.getLogger(.debug))
        XCTAssertNotNil(logger.getLogger(.info))
        XCTAssertNotNil(logger.getLogger(.warn))
        XCTAssertNotNil(logger.getLogger(.error))
    }

    func test_shouldLog_true_only_when_higherThan_or_equalTo_minLogLevel() {
        XCTAssertFalse(logger.shouldLog(.trace))
        XCTAssertTrue(logger.shouldLog(.debug))
        XCTAssertTrue(logger.shouldLog(.info))
        XCTAssertTrue(logger.shouldLog(.warn))
        XCTAssertTrue(logger.shouldLog(.error))
    }

    func test_logger_getters_return_cached_instaces() {
        XCTAssertIdentical(logger.trace, logger.trace)
        XCTAssertIdentical(logger.debug, logger.debug)
        XCTAssertIdentical(logger.info, logger.info)
        XCTAssertIdentical(logger.warn, logger.warn)
        XCTAssertIdentical(logger.error, logger.error)
    }

    func test_logLevel_and_minLogLevel_have_same_rawValues() {
        XCTAssertEqual(TealiumLogLevel.Minimum.trace.rawValue, TealiumLogLevel.trace.rawValue)
        XCTAssertEqual(TealiumLogLevel.Minimum.debug.rawValue, TealiumLogLevel.debug.rawValue)
        XCTAssertEqual(TealiumLogLevel.Minimum.info.rawValue, TealiumLogLevel.info.rawValue)
        XCTAssertEqual(TealiumLogLevel.Minimum.warn.rawValue, TealiumLogLevel.warn.rawValue)
        XCTAssertEqual(TealiumLogLevel.Minimum.error.rawValue, TealiumLogLevel.error.rawValue)
    }

    func test_silent_minLogLevel_is_greater_than_all_logLevels() {
        for logLevel in TealiumLogLevel.allCases {
            XCTAssertGreaterThan(TealiumLogLevel.Minimum.silent.rawValue, logLevel.rawValue)
        }
    }

    func test_minLogLevel_changes_onCoreSettings_change() {
        XCTAssertEqual(logger.minLogLevel, .debug)
        onCoreSettings.publish(CoreSettings(coreDictionary: ["minLogLevel": "trace"]))
        XCTAssertEqual(logger.minLogLevel, .trace)
    }
}
