//
//  CoreSettingsTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class CoreSettingsTests: XCTestCase {

    func test_init_from_json_dictionary() {
        let jsonDictionary: [String: Any] = [
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
            "transformations": [
                [
                    "transformation_id": "transformationId",
                    "transformer_id": "transformerId",
                    "scopes": [
                        "alldispatchers",
                        "custom"
                    ]
                ]
            ],
            "max_queue_size": 20,
            "expiration": 50.0,
            "refresh_interval": 100.0
        ]
        let settings = CoreSettings(coreDictionary: jsonDictionary)
        XCTAssertEqual(settings.minLogLevel, .trace)
        XCTAssertEqual(settings.scopedBarriers, [ScopedBarrier(barrierId: "barrierId", scopes: [.all, .dispatcher("custom")])])
        XCTAssertEqual(settings.scopedTransformations, [ScopedTransformation(id: "transformationId",
                                                                             transformerId: "transformerId",
                                                                             scopes: [.allDispatchers, .dispatcher("custom")])])
        XCTAssertEqual(settings.maxQueueSize, 20)
        XCTAssertEqual(settings.queueExpiration, TimeFrame(unit: .seconds, interval: 50.0))
        XCTAssertEqual(settings.refreshInterval, TimeFrame(unit: .seconds, interval: 100.0))
    }

    func test_init_from_empty_dictionary_fills_defaults() {
        let jsonDictionary: [String: Any] = [:]
        let settings = CoreSettings(coreDictionary: jsonDictionary)
        XCTAssertEqual(settings.minLogLevel, CoreSettings.Defaults.minLogLevel)
        XCTAssertEqual(settings.scopedBarriers, [])
        XCTAssertEqual(settings.scopedTransformations, [])
        XCTAssertEqual(settings.maxQueueSize, CoreSettings.Defaults.maxQueueSize)
        XCTAssertEqual(settings.queueExpiration, TimeFrame(unit: .seconds, interval: CoreSettings.Defaults.queueExpirationSeconds))
        XCTAssertEqual(settings.refreshInterval, TimeFrame(unit: .seconds, interval: CoreSettings.Defaults.refreshIntervalSeconds))
    }
}
