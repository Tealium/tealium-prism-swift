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
    func test_build_returns_core_settings() {
        let settings = CoreSettingsBuilder()
            .setMinLogLevel(.trace)
            .setQueueExpiration(50.seconds)
            .setRefreshInterval(100.seconds)
            .setMaxQueueSize(20)
            .build()
            .asDictionary()
        XCTAssertEqual(settings, [
            "log_level": "trace",
            "max_queue_size": 20,
            "expiration": 50.0,
            "refresh_interval": 100.0
        ])
    }

    func test_build_with_nil_values_returns_core_settings_without_nils() {
        let settings = CoreSettingsBuilder()
            .setQueueExpiration(50.seconds)
            .setRefreshInterval(100.seconds)
            .setMaxQueueSize(20)
            .build()
            .asDictionary()
        XCTAssertEqual(settings, [
            "max_queue_size": 20,
            "expiration": 50.0,
            "refresh_interval": 100.0
        ])
    }
}
