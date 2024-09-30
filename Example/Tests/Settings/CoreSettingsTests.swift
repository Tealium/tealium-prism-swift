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

    func test_init_from_json_dictionary() throws {
        let dataObject: DataObject = [
            "log_level": "trace",
            "barriers": try DataItem(serializing: [
                [
                    "barrier_id": "barrierId",
                    "scopes": [
                        "all",
                        "custom"
                    ]
                ]
            ]),
            "transformations": try DataItem(serializing: [
                [
                    "transformation_id": "transformationId",
                    "transformer_id": "transformerId",
                    "scopes": [
                        "alldispatchers",
                        "custom"
                    ]
                ]
            ]),
            "max_queue_size": 20,
            "expiration": 50.0,
            "refresh_interval": 100.0
        ]
        let settings = CoreSettings(coreDataObject: dataObject)
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
        let dataObject: DataObject = [:]
        let settings = CoreSettings(coreDataObject: dataObject)
        XCTAssertEqual(settings.minLogLevel, CoreSettings.Defaults.minLogLevel)
        XCTAssertEqual(settings.scopedBarriers, [])
        XCTAssertEqual(settings.scopedTransformations, [])
        XCTAssertEqual(settings.maxQueueSize, CoreSettings.Defaults.maxQueueSize)
        XCTAssertEqual(settings.queueExpiration, CoreSettings.Defaults.queueExpiration)
        XCTAssertEqual(settings.refreshInterval, CoreSettings.Defaults.refreshInterval)
    }
}
