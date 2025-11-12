//
//  LifecycleModuleSubscriptionTests.swift
//  LifecycleTests_iOS
//
//  Created by Enrico Zannini on 22/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LifecycleModuleSubscriptionTests: LifecycleModuleBaseTests {
    func test_manual_launch_throws_an_error_if_autotracking_enabled() {
        XCTAssertThrows(try module.launch()) { (error: LifecycleError) in
            guard case .manualTrackNotAllowed = error else {
                XCTFail("Expected manualTrackNotAllowed but got \(error)")
                return
            }
        }
    }

    func test_manual_wake_throws_an_error_if_autotracking_enabled() {
        XCTAssertThrows(try module.wake()) { (error: LifecycleError) in
            guard case .manualTrackNotAllowed = error else {
                XCTFail("Expected manualTrackNotAllowed but got \(error)")
                return
            }
        }
    }

    func test_manual_sleep_throws_an_error_if_autotracking_enabled() {
        XCTAssertThrows(try module.sleep()) { (error: LifecycleError) in
            guard case .manualTrackNotAllowed = error else {
                XCTFail("Expected manualTrackNotAllowed but got \(error)")
                return
            }
        }
    }

    func test_launch_gets_tracked_on_initialize() {
        let launchTracked = expectation(description: "Launch event is tracked")
        tracker.onTrack.subscribeOnce { dispatch in
            XCTAssertEqual(dispatch.name, "launch")
            launchTracked.fulfill()
        }
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        waitForDefaultTimeout()
    }

    func test_wake_not_tracked_on_first_foregrounded_after_launch() {
        let launchTracked = expectation(description: "Launch event is tracked")
        tracker.onTrack.subscribeOnce { dispatch in
            XCTAssertEqual(dispatch.name, "launch")
            launchTracked.fulfill()
        }
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        let wakeTracked = expectation(description: "Wake event should not be tracked")
        wakeTracked.isInverted = true
        tracker.onTrack.subscribeOnce { dispatch in
            XCTAssertEqual(dispatch.name, "wake")
            wakeTracked.fulfill()
        }
        publishApplicationStatus(ApplicationStatus(type: .foregrounded))
        waitForDefaultTimeout()
    }

    func test_launch_gets_tracked_if_first_status_is_foregrounded() {
        let launchTracked = expectation(description: "Launch event is tracked")
        tracker.onTrack.subscribeOnce { dispatch in
            XCTAssertEqual(dispatch.name, "launch")
            launchTracked.fulfill()
        }
        publishApplicationStatus(ApplicationStatus(type: .foregrounded))
        waitForDefaultTimeout()
    }

    func test_launch_and_sleep_get_tracked_if_first_status_is_backgrounded() {
        let launchTracked = expectation(description: "Launch event is tracked")
        let sleepTracked = expectation(description: "Sleep event is tracked")
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "launch" {
                launchTracked.fulfill()
            } else if dispatch.name == "sleep" {
                sleepTracked.fulfill()
            }
        }.addTo(autoDisposer)
        publishApplicationStatus(ApplicationStatus(type: .backgrounded))
        waitForDefaultTimeout()
    }

    func test_launch_and_wake_not_tracked_after_launch() {
        let launchTracked = expectation(description: "Launch event is tracked once")
        let wakeTracked = expectation(description: "Wake event should not be tracked")
        wakeTracked.isInverted = true
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "launch" {
                launchTracked.fulfill()
            } else if dispatch.name == "wake" {
                wakeTracked.fulfill()
            }
        }.addTo(autoDisposer)
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        publishApplicationStatus(ApplicationStatus(type: .foregrounded))
        waitForDefaultTimeout()
    }

    func test_wake_not_tracked_after_launch() {
        let launchTracked = expectation(description: "Launch event is tracked once")
        let wakeTracked = expectation(description: "Wake event should not be tracked")
        wakeTracked.isInverted = true
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "launch" {
                launchTracked.fulfill()
            } else if dispatch.name == "wake" {
                wakeTracked.fulfill()
            }
        }.addTo(autoDisposer)
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        publishApplicationStatus(ApplicationStatus(type: .foregrounded))
        waitForDefaultTimeout()
    }

    func test_wake_not_tracked_after_wake() {
        let launchTracked = expectation(description: "Launch event is tracked once")
        let wakeTracked = expectation(description: "Wake event is tracked once")
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "launch" {
                launchTracked.fulfill()
            } else if dispatch.name == "wake" {
                wakeTracked.fulfill()
            }
        }.addTo(autoDisposer)
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        publishApplicationStatus(ApplicationStatus(type: .backgrounded))
        publishApplicationStatus(ApplicationStatus(type: .foregrounded))
        publishApplicationStatus(ApplicationStatus(type: .foregrounded))
        waitForDefaultTimeout()
    }

    func test_sleep_not_tracked_after_sleep() {
        let launchTracked = expectation(description: "Launch event is tracked once")
        let sleepTracked = expectation(description: "Sleep event is tracked once")
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "launch" {
                launchTracked.fulfill()
            } else if dispatch.name == "sleep" {
                sleepTracked.fulfill()
            }
        }.addTo(autoDisposer)
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        publishApplicationStatus(ApplicationStatus(type: .backgrounded))
        publishApplicationStatus(ApplicationStatus(type: .backgrounded))
        waitForDefaultTimeout()
    }

    func test_launch_is_tracked_on_foregrounded_when_session_timed_out() {
        updateSettings(LifecycleSettingsBuilder().setSessionTimeoutInMinutes(0))
        let launchTracked = expectation(description: "Launch event is tracked twice")
        let wakeTracked = expectation(description: "Wake event should not be tracked")
        wakeTracked.isInverted = true
        launchTracked.expectedFulfillmentCount = 2
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "launch" {
                launchTracked.fulfill()
            } else if dispatch.name == "wake" {
                wakeTracked.fulfill()
            }
        }.addTo(autoDisposer)
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        publishApplicationStatus(ApplicationStatus(type: .backgrounded))
        publishApplicationStatus(ApplicationStatus(type: .foregrounded))
        waitForDefaultTimeout()
    }

    func test_normal_order_of_statuses_is_appropriately_tracked() {
        let launchTracked = expectation(description: "Launch event is tracked twice")
        launchTracked.expectedFulfillmentCount = 2
        let sleepTracked = expectation(description: "Sleep event is tracked twice")
        sleepTracked.expectedFulfillmentCount = 2
        let wakeTracked = expectation(description: "Wake event is tracked once")
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "launch" {
                launchTracked.fulfill()
            } else if dispatch.name == "sleep" {
                sleepTracked.fulfill()
            } else if dispatch.name == "wake" {
                wakeTracked.fulfill()
            }
        }.addTo(autoDisposer)
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        publishApplicationStatus(ApplicationStatus(type: .backgrounded))
        publishApplicationStatus(ApplicationStatus(type: .foregrounded))
        publishApplicationStatus(ApplicationStatus(type: .backgrounded))
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        waitForDefaultTimeout()
    }

    func test_events_not_tracked_when_not_selected_in_settings() {
        updateSettings(LifecycleSettingsBuilder().setTrackedLifecycleEvents([]))
        let launchTracked = expectation(description: "Launch should not be tracked")
        launchTracked.isInverted = true
        let sleepTracked = expectation(description: "Sleep should not be tracked")
        sleepTracked.isInverted = true
        let wakeTracked = expectation(description: "Wake should not be tracked")
        wakeTracked.isInverted = true
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "launch" {
                launchTracked.fulfill()
            } else if dispatch.name == "sleep" {
                sleepTracked.fulfill()
            } else if dispatch.name == "wake" {
                wakeTracked.fulfill()
            }
        }.addTo(autoDisposer)
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        publishApplicationStatus(ApplicationStatus(type: .backgrounded))
        publishApplicationStatus(ApplicationStatus(type: .foregrounded))
        publishApplicationStatus(ApplicationStatus(type: .backgrounded))
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        waitForDefaultTimeout()
    }

    func test_events_not_tracked_when_autotracking_disabled_in_settings() {
            updateSettings(LifecycleSettingsBuilder().setAutoTrackingEnabled(false))
        let launchTracked = expectation(description: "Launch should not be tracked")
        launchTracked.isInverted = true
        let sleepTracked = expectation(description: "Sleep should not be tracked")
        sleepTracked.isInverted = true
        let wakeTracked = expectation(description: "Wake should not be tracked")
        wakeTracked.isInverted = true
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "launch" {
                launchTracked.fulfill()
            } else if dispatch.name == "sleep" {
                sleepTracked.fulfill()
            } else if dispatch.name == "wake" {
                wakeTracked.fulfill()
            }
        }.addTo(autoDisposer)
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        publishApplicationStatus(ApplicationStatus(type: .backgrounded))
        publishApplicationStatus(ApplicationStatus(type: .foregrounded))
        publishApplicationStatus(ApplicationStatus(type: .backgrounded))
        publishApplicationStatus(ApplicationStatus(type: .initialized))
        waitForDefaultTimeout()
    }
}
