//
//  LifecycleConfigurationTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 25/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LifecycleConfigurationTests: XCTestCase {
    func test_init_with_empty_object_returns_settings_with_correct_defaults() {
        let configuration = LifecycleConfiguration(configuration: [:])
        XCTAssertEqual(configuration.autoTrackingEnabled, true)
        XCTAssertEqual(configuration.dataTarget, .lifecycleEventsOnly)
        XCTAssertEqual(configuration.sessionTimeoutInMinutes, 24 * 60)
        XCTAssertEqual(configuration.trackedLifecycleEvents, LifecycleEvent.allCases)
    }

    func test_init_with_dataObject_returns_correct_configuration() {
        let configuration = LifecycleConfiguration(configuration: [
            "autotracking_enabled": false,
            "data_target": "allEvents",
            "session_timeout": 1,
            "tracked_lifecycle_events": ["sleep"]
        ])
        XCTAssertEqual(configuration.autoTrackingEnabled, false)
        XCTAssertEqual(configuration.dataTarget, .allEvents)
        XCTAssertEqual(configuration.sessionTimeoutInMinutes, 1)
        XCTAssertEqual(configuration.trackedLifecycleEvents, [LifecycleEvent.sleep])
    }
}
