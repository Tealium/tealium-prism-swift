//
//  LifecycleModuleManualTrackingTests.swift
//  LifecycleTests_iOS
//
//  Created by Enrico Zannini on 22/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class LifecycleModuleManualTrackingTests: LifecycleModuleBaseTests {
    override func setUpWithError() throws {
        configuration = LifecycleConfiguration(configuration: ["autotracking_enabled": false])
        try super.setUpWithError()
    }

    func test_launch_gets_tracked_on_launch() throws {
        let launchTracked = expectation(description: "Launch event is tracked")
        tracker.onTrack.subscribeOnce { dispatch in
            XCTAssertEqual(dispatch.name, "launch")
            launchTracked.fulfill()
        }
        try module.launch()
        waitForDefaultTimeout()
    }

    func test_sleep_throws_invalidEventOrder_error_if_first_event() throws {
        XCTAssertThrowsError(try module.sleep()) { error in
            XCTAssertEqual(error as? LifecycleError, .invalidEventOrder)
        }
    }

    func test_wake_throws_invalidEventOrder_error_if_first_event() throws {
        XCTAssertThrowsError(try module.wake()) { error in
            XCTAssertEqual(error as? LifecycleError, .invalidEventOrder)
        }
    }

    func test_sleep_gets_tracked_on_sleep_after_launch() throws {
        let sleepTracked = expectation(description: "Sleep event is tracked")
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "sleep" {
                sleepTracked.fulfill()
            }
        }.addTo(autoDisposer)
        try module.launch()
        try module.sleep()
        waitForDefaultTimeout()
    }

    func test_sleep_gets_tracked_on_sleep_after_wake() throws {
        let sleepTracked = expectation(description: "Sleep event is tracked")
        sleepTracked.expectedFulfillmentCount = 2
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "sleep" {
                sleepTracked.fulfill()
            }
        }.addTo(autoDisposer)
        try module.launch()
        try module.sleep()
        try module.wake()
        try module.sleep()
        waitForDefaultTimeout()
    }

    func test_wake_gets_tracked_on_wake_after_sleep() throws {
        let wakeTracked = expectation(description: "Wake event is tracked")
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "wake" {
                wakeTracked.fulfill()
            }
        }.addTo(autoDisposer)
        try module.launch()
        try module.sleep()
        try module.wake()
        waitForDefaultTimeout()
    }

    func test_launch_throws_invalidEventOrder_error_on_launch_after_wake() throws {
        let launchTracked = expectation(description: "Launch event should be tracked once")
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "launch" {
                launchTracked.fulfill()
            }
        }.addTo(autoDisposer)
        try module.launch()
        try module.sleep()
        try module.wake()
        XCTAssertThrowsError(try module.launch()) { error in
            XCTAssertEqual(error as? LifecycleError, .invalidEventOrder)
        }
        waitForDefaultTimeout()
    }

    func test_launch_throws_invalidEventOrder_error_on_launch_after_launch() throws {
        let launchTracked = expectation(description: "Launch event should be tracked once")
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "launch" {
                launchTracked.fulfill()
            }
        }.addTo(autoDisposer)
        try module.launch()
        XCTAssertThrowsError(try module.launch()) { error in
            XCTAssertEqual(error as? LifecycleError, .invalidEventOrder)
        }
        waitForDefaultTimeout()
    }

    func test_wake_throws_invalidEventOrder_error_on_wake_after_wake() throws {
        let wakeTracked = expectation(description: "Wake event should be tracked once")
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "wake" {
                wakeTracked.fulfill()
            }
        }.addTo(autoDisposer)
        try module.launch()
        try module.sleep()
        try module.wake()
        XCTAssertThrowsError(try module.wake()) { error in
            XCTAssertEqual(error as? LifecycleError, .invalidEventOrder)
        }
        waitForDefaultTimeout()
    }

    func test_wake_throws_invalidEventOrder_error_on_wake_after_launch() throws {
        try module.launch()
        XCTAssertThrowsError(try module.wake()) { error in
            XCTAssertEqual(error as? LifecycleError, .invalidEventOrder)
        }
    }

    func test_sleep_throws_invalidEventOrder_error_on_sleep_after_sleep() throws {
        let sleepTracked = expectation(description: "Sleep event should be tracked once")
        tracker.onTrack.subscribe { dispatch in
            if dispatch.name == "sleep" {
                sleepTracked.fulfill()
            }
        }.addTo(autoDisposer)
        try module.launch()
        try module.sleep()
        XCTAssertThrowsError(try module.sleep()) { error in
            XCTAssertEqual(error as? LifecycleError, .invalidEventOrder)
        }
        waitForDefaultTimeout()
    }
}
