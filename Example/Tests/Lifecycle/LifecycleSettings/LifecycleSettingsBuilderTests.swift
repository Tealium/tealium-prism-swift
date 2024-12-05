//
//  LifecycleSettingsBuilderTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 25/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class LifecycleSettingsBuilderTests: XCTestCase {
    func test_build_without_setters_returns_empty_dictionary() {
        let settings = LifecycleSettingsBuilder().build()
        XCTAssertEqual(settings, [:])
    }

    func test_build_returns_correct_module_settings() {
        let settings = LifecycleSettingsBuilder()
            .setAutoTrackingEnabled(false)
            .setDataTarget(.allEvents)
            .setSessionTimeoutInMinutes(1)
            .setTrackedLifecycleEvents([])
            .build()
        XCTAssertEqual(settings, [
            "autotracking_enabled": false,
            "data_target": "allEvents",
            "session_timeout": 1,
            "tracked_lifecycle_events": [String]()
        ])
    }
}
