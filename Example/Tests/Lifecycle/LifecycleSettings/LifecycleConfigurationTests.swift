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

    func test_lifecycleEvent_rawValue_is_lowercase() {
        XCTAssertEqual(LifecycleEvent.launch.rawValue, "launch")
        XCTAssertEqual(LifecycleEvent.wake.rawValue, "wake")
        XCTAssertEqual(LifecycleEvent.sleep.rawValue, "sleep")
    }

    func test_init_with_non_lowercased_tracked_events_creates_correct_events() {
        let configuration = LifecycleConfiguration(configuration: [
            "tracked_lifecycle_events": ["LAUNCH", "SleEp"]
        ])
        XCTAssertEqual(configuration.trackedLifecycleEvents, [.launch, .sleep])
    }

    func test_lifecycleDataTarget_rawValue_is_lowercase() {
        XCTAssertEqual(LifecycleDataTarget.allEvents.rawValue, "allevents")
        XCTAssertEqual(LifecycleDataTarget.lifecycleEventsOnly.rawValue, "lifecycleeventsonly")
    }

    func test_lifecycleDataTarget_init_is_case_insensitive() {
        XCTAssertEqual(LifecycleDataTarget(rawValue: "ALLEVENTS"), .allEvents)
        XCTAssertEqual(LifecycleDataTarget(rawValue: "allEvents"), .allEvents)
        XCTAssertEqual(LifecycleDataTarget(rawValue: "LIFECYCLEEVENTSONLY"), .lifecycleEventsOnly)
        XCTAssertEqual(LifecycleDataTarget(rawValue: "lifecycleEventsOnly"), .lifecycleEventsOnly)
    }

    func test_init_with_non_lowercased_data_target_creates_correct_target() {
        let configuration = LifecycleConfiguration(configuration: [
            "data_target": "AllEvents"
        ])
        XCTAssertEqual(configuration.dataTarget, .allEvents)
    }
}
