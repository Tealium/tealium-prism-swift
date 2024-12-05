//
//  LifecycleSettingsTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 25/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class LifecycleSettingsTests: XCTestCase {
    func test_init_with_empty_object_returns_settings_with_correct_defaults() {
        let settings = LifecycleSettings(moduleSettings: [:])
        XCTAssertEqual(settings.autoTrackingEnabled, true)
        XCTAssertEqual(settings.dataTarget, .lifecycleEventsOnly)
        XCTAssertEqual(settings.sessionTimeoutInMinutes, 24 * 60)
        XCTAssertEqual(settings.trackedLifecycleEvents, LifecycleEvent.allCases)
    }

    func test_init_with_dataObject_returns_correct_settings() {
        let settings = LifecycleSettings(moduleSettings: [
            "autotracking_enabled": false,
            "data_target": "allEvents",
            "session_timeout": 1,
            "tracked_lifecycle_events": ["sleep"]
        ])
        XCTAssertEqual(settings.autoTrackingEnabled, false)
        XCTAssertEqual(settings.dataTarget, .allEvents)
        XCTAssertEqual(settings.sessionTimeoutInMinutes, 1)
        XCTAssertEqual(settings.trackedLifecycleEvents, [LifecycleEvent.sleep])
    }
}
