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
    var listener: ApplicationStatusListener?

    func test_initialized_status_is_published_on_launch() {
        let published = expectation(description: "Initialized status published")
        listener = ApplicationStatusListener(graceTimeInterval: 1.0)
        listener?.onApplicationStatus.subscribeOnce { status in
            switch status.type {
            case .initialized:
                published.fulfill()
            default:
                return
            }
        }
        waitForDefaultTimeout()
    }

    func test_cache_cleared_after_grace_timeout() {
        let notCleared = expectation(description: "Cache is not cleared")
        notCleared.isInverted = true
        let subscriptionCalled = expectation(description: "Subscription called")
        listener = ApplicationStatusListener(graceTimeInterval: 0.0)
        queue.asyncAfter(deadline: .now() + .milliseconds(50)) {
            self.listener?.onApplicationStatus.subscribeOnce {_ in
                notCleared.fulfill()
            }
            subscriptionCalled.fulfill()
        }
        waitForExpectations(timeout: 3 * Self.defaultTimeout)
    }

    func test_backgrounded_status_is_published() {
        let published = expectation(description: "Backgrounded status published")
        published.assertForOverFulfill = false
        published.expectedFulfillmentCount = 2
        listener = ApplicationStatusListener(graceTimeInterval: 1.0)
        let automaticDisposer = AutomaticDisposer()
        listener?.onApplicationStatus.subscribe { status in
            switch status.type {
            case .backgrounded, .initialized:
                published.fulfill()
            default:
                return
            }
        }.addTo(automaticDisposer)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        waitForDefaultTimeout()
    }

    func test_foregrounded_status_is_published() {
        let published = expectation(description: "Foregrounded status published")
        published.assertForOverFulfill = false
        published.expectedFulfillmentCount = 2
        listener = ApplicationStatusListener(graceTimeInterval: 1.0)
        let automaticDisposer = AutomaticDisposer()
        listener?.onApplicationStatus.subscribe { status in
            switch status.type {
            case .foregrounded, .initialized:
                published.fulfill()
            default:
                return
            }
        }.addTo(automaticDisposer)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        waitForDefaultTimeout()
    }

    func test_listener_can_be_deinitialized() {
        let helper = RetainCycleHelper(variable: ApplicationStatusListener(graceTimeInterval: 1.0))
        helper.forceAndAssertObjectDeinit()
    }
}
