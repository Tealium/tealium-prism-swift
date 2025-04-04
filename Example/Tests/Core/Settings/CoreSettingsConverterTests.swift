//
//  CoreSettingsConverterTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class CoreSettingsConverterTests: XCTestCase {

    func test_init_from_json_dictionary() throws {
        let dataObject = try DataItem(serializing: [
            "log_level": "trace",
            "barriers": [
                [
                    "barrier_id": "barrierId",
                    "scopes": [
                        "all",
                        "custom"
                    ]
                ]
            ],
            "max_queue_size": 20,
            "expiration": 50.0,
            "refresh_interval": 100.0
        ])
        guard let settings = CoreSettings.converter.convert(dataItem: dataObject) else {
            XCTFail("Settings cannot be converted")
            return
        }
        XCTAssertEqual(settings.minLogLevel, .trace)
        XCTAssertEqual(settings.scopedBarriers, [ScopedBarrier(barrierId: "barrierId", scopes: [.all, .dispatcher("custom")])])
        XCTAssertEqual(settings.maxQueueSize, 20)
        XCTAssertEqual(settings.queueExpiration, TimeFrame(unit: .seconds, interval: 50.0))
        XCTAssertEqual(settings.refreshInterval, TimeFrame(unit: .seconds, interval: 100.0))
    }

    func test_init_from_empty_dictionary_fills_defaults() throws {
        let dataObject = try DataItem(serializing: [:])
        guard let settings = CoreSettings.converter.convert(dataItem: dataObject) else {
            XCTFail("Settings cannot be converted")
            return
        }
        XCTAssertEqual(settings.minLogLevel, CoreSettings.Defaults.minLogLevel)
        XCTAssertEqual(settings.scopedBarriers, [])
        XCTAssertEqual(settings.maxQueueSize, CoreSettings.Defaults.maxQueueSize)
        XCTAssertEqual(settings.queueExpiration, CoreSettings.Defaults.queueExpiration)
        XCTAssertEqual(settings.refreshInterval, CoreSettings.Defaults.refreshInterval)
    }
}
