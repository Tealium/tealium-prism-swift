//
//  ApplicationStatusListenerTests.swift
//  CoreTests_iOS
//
//  Created by Denis Guzov on 20/08/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

private let queue = TealiumQueue.worker.dispatchQueue

final class ApplicationStatusListenerTests: XCTestCase {
    let notificationCenter = NotificationCenter()
    var graceTimeInterval: TimeInterval = 1.0
    lazy var listener = ApplicationStatusListener(graceTimeInterval: graceTimeInterval,
                                                  leeway: .nanoseconds(0),
                                                  notificationCenter: notificationCenter)

    func test_initialized_status_is_published_on_launch() {
        let published = expectation(description: "Initialized status published")
        graceTimeInterval = 1.0
        listener.onApplicationStatus.subscribeOnce { status in
            switch status.type {
            case .initialized:
                published.fulfill()
            default:
                return
            }
        }
        waitForDefaultTimeout()
    }

    func test_cache_resized_after_grace_timeout() {
        let resized = expectation(description: "Cache is not resized to 1")
        let subscriptionCalled = expectation(description: "Subscription called")
        graceTimeInterval = 0.01
        _ = listener
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        let automaticDisposer = AutomaticDisposer()
        queue.asyncAfter(deadline: .now() + .milliseconds(100)) {
            _ = self.listener.onApplicationStatus.subscribe {_ in
                resized.fulfill()
            }.addTo(automaticDisposer)
            subscriptionCalled.fulfill()
        }
        waitForExpectations(timeout: 6 * Self.defaultTimeout)
    }

    func test_backgrounded_status_is_published() {
        let published = expectation(description: "Backgrounded status published")
        published.assertForOverFulfill = false
        published.expectedFulfillmentCount = 2
        graceTimeInterval = 1.0
        let automaticDisposer = AutomaticDisposer()
        listener.onApplicationStatus.subscribe { status in
            switch status.type {
            case .backgrounded, .initialized:
                published.fulfill()
            default:
                return
            }
        }.addTo(automaticDisposer)
        notificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        waitForDefaultTimeout()
    }

    func test_foregrounded_status_is_published() {
        let published = expectation(description: "Foregrounded status published")
        published.assertForOverFulfill = false
        published.expectedFulfillmentCount = 2
        graceTimeInterval = 1.0
        let automaticDisposer = AutomaticDisposer()
        listener.onApplicationStatus.subscribe { status in
            switch status.type {
            case .foregrounded, .initialized:
                published.fulfill()
            default:
                return
            }
        }.addTo(automaticDisposer)
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        waitForDefaultTimeout()
    }

    func test_listener_can_be_deinitialized() {
        let helper = RetainCycleHelper(variable: ApplicationStatusListener(graceTimeInterval: 1.0))
        helper.forceAndAssertObjectDeinit()
    }
}
