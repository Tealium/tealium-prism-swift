//
//  CoreSettingsConverterTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class CoreSettingsConverterTests: XCTestCase {

    func test_init_from_json_dictionary() throws {
        let dataObject = try DataItem(serializing: [
            "log_level": "trace",
            "max_queue_size": 20,
            "expiration": 50.0,
            "refresh_interval": 100.0,
            "session_timeout": 10
        ])
        guard let settings = CoreSettings.converter.convert(dataItem: dataObject) else {
            XCTFail("Settings cannot be converted")
            return
        }
        XCTAssertEqual(settings.minLogLevel, .trace)
        XCTAssertEqual(settings.maxQueueSize, 20)
        XCTAssertEqual(settings.queueExpiration, 50.seconds)
        XCTAssertEqual(settings.refreshInterval, 100.seconds)
        XCTAssertEqual(settings.sessionTimeout, 10.seconds)
    }

    func test_init_from_empty_dictionary_fills_defaults() throws {
        let dataObject = try DataItem(serializing: [:])
        guard let settings = CoreSettings.converter.convert(dataItem: dataObject) else {
            XCTFail("Settings cannot be converted")
            return
        }
        XCTAssertEqual(settings.minLogLevel, CoreSettings.Defaults.minLogLevel)
        XCTAssertEqual(settings.maxQueueSize, CoreSettings.Defaults.maxQueueSize)
        XCTAssertEqual(settings.queueExpiration, CoreSettings.Defaults.queueExpiration)
        XCTAssertEqual(settings.refreshInterval, CoreSettings.Defaults.refreshInterval)
        XCTAssertEqual(settings.sessionTimeout, CoreSettings.Defaults.sessionTimeout)
    }
}
