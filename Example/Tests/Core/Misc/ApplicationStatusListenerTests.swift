//
//  ApplicationStatusListenerTests.swift
//  tealium-prism
//
//  Created by Denis Guzov on 20/08/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ApplicationStatusListenerTests: XCTestCase {
    let notificationCenter = NotificationCenter()
    var graceTimeInterval: TimeInterval = 1.0
    var queue: DispatchQueue {
        listener.queue.dispatchQueue
    }
    lazy var listener = ApplicationStatusListener(graceTimeInterval: graceTimeInterval,
                                                  leeway: .nanoseconds(0),
                                                  queue: TealiumQueue(label: "testQueue",
                                                                      qos: .userInteractive),
                                                  notificationCenter: notificationCenter)

    func test_initialized_status_is_emitted_on_launch() {
        let emitted = expectation(description: "Initialized status emitted")
        graceTimeInterval = 1.0
        listener.onApplicationStatus.subscribeOnce { status in
            switch status.type {
            case .initialized:
                emitted.fulfill()
            default:
                return
            }
        }
        waitForDefaultTimeout()
    }

    func test_cache_resized_after_grace_timeout() {
        let applicationStatusReceived = expectation(description: "Application status is received only once because it should be resized to 1")
        let subscriptionCalled = expectation(description: "Subscription called")
        graceTimeInterval = 0.01
        _ = listener
        notificationCenter.postBecomeActiveNotification()
        let automaticDisposer = AutomaticDisposer()
        queue.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.listener.onApplicationStatus.subscribe {_ in
                applicationStatusReceived.fulfill()
            }.addTo(automaticDisposer)
            subscriptionCalled.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_backgrounded_status_is_emitted() {
        let emitted = expectation(description: "Backgrounded status emitted")
        emitted.assertForOverFulfill = false
        emitted.expectedFulfillmentCount = 2
        graceTimeInterval = 1.0
        let automaticDisposer = AutomaticDisposer()
        listener.onApplicationStatus.subscribe { status in
            switch status.type {
            case .backgrounded, .initialized:
                emitted.fulfill()
            default:
                return
            }
        }.addTo(automaticDisposer)
        notificationCenter.postResignActiveNotification()
        waitForDefaultTimeout()
    }

    func test_foregrounded_status_is_emitted() {
        let emitted = expectation(description: "Foregrounded status emitted")
        emitted.assertForOverFulfill = false
        emitted.expectedFulfillmentCount = 2
        graceTimeInterval = 1.0
        let automaticDisposer = AutomaticDisposer()
        listener.onApplicationStatus.subscribe { status in
            switch status.type {
            case .foregrounded, .initialized:
                emitted.fulfill()
            default:
                return
            }
        }.addTo(automaticDisposer)
        notificationCenter.postBecomeActiveNotification()
        waitForDefaultTimeout()
    }

    func test_listener_can_be_deinitialized() {
        let helper = RetainCycleHelper(variable: ApplicationStatusListener(graceTimeInterval: 1.0))
        helper.forceAndAssertObjectDeinit()
    }
}
