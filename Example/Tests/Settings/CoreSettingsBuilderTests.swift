//
//  CoreSettingsBuilderTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 24/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class CoreSettingsBuilderTests: XCTestCase {
    func test_build_returns_core_moduleSettings() {
        let settings = CoreSettingsBuilder()
            .setMinLogLevel(.trace)
            .setQueueExpiration(TimeFrame(unit: .seconds, interval: 50))
            .setRefreshInterval(TimeFrame(unit: .seconds, interval: 100))
            .setMaxQueueSize(20)
            .setScopedTransformations([ScopedTransformation(id: "transformationId",
                                                            transformerId: "transformerId", scopes: [
                                                                .allDispatchers,
                                                                .dispatcher("custom")
                                                            ])])
            .setScopedBarriers([ScopedBarrier(barrierId: "barrierId", scopes: [.all, .dispatcher("custom")])])
            .build()
        XCTAssertEqual(settings, [
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
        ])
    }

    func test_build_with_nil_values_returns_core_moduleSettings_without_nils() {
        let settings = CoreSettingsBuilder()
            .setQueueExpiration(TimeFrame(unit: .seconds, interval: 50))
            .setRefreshInterval(TimeFrame(unit: .seconds, interval: 100))
            .setMaxQueueSize(20)
            .setScopedBarriers([ScopedBarrier(barrierId: "barrierId", scopes: [.all, .dispatcher("custom")])])
            .build()
        XCTAssertEqual(settings, [
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
    }
}
