//
//  DisposableTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 14/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DisposableTests: XCTestCase {

    func test_tealium_subscription_calls_callback_on_dispose() {
        let expectation = expectation(description: "Dispose callback is called")
        let subscription = Subscription {
            expectation.fulfill()
        }
        subscription.dispose()
        waitForDefaultTimeout()
    }

    func test_is_disposed_true_when_subscription_is_disposed() {
        let subscription = Subscription { }
        XCTAssertFalse(subscription.isDisposed)
        subscription.dispose()
        XCTAssertTrue(subscription.isDisposed)
    }

    func test_dispose_container_disposes_all_subscriptions() {
        let subscriptionDisposedExpectation = expectation(description: "Subscription is disposed")
        subscriptionDisposedExpectation.expectedFulfillmentCount = 3
        let disposeContainer = DisposeContainer()
        disposeContainer.add(Subscription { subscriptionDisposedExpectation.fulfill() })
        disposeContainer.add(Subscription { subscriptionDisposedExpectation.fulfill() })
        disposeContainer.add(Subscription { subscriptionDisposedExpectation.fulfill() })
        disposeContainer.dispose()
        waitForDefaultTimeout()
    }

    func test_is_disposed_true_when_dispose_container_is_disposed() {
        let container = DisposeContainer()
        XCTAssertFalse(container.isDisposed)
        container.dispose()
        XCTAssertTrue(container.isDisposed)
    }

    func test_disposed_container_automatically_disposes_new_disposable() {
        let subscriptionDisposed = expectation(description: "Subscription is disposed immediately")
        let container = DisposeContainer()
        container.dispose()
        container.add(Subscription(unsubscribe: {
            subscriptionDisposed.fulfill()
        }))
        waitForDefaultTimeout()
    }

    func test_deinit_disposes_automatically_all_subscriptions_contained_in_automatic_disposer() {
        let subscriptionDisposedExpectation = expectation(description: "Subscription is disposed")
        subscriptionDisposedExpectation.expectedFulfillmentCount = 3
        var automaticDisposer: AutomaticDisposer? = AutomaticDisposer()
        automaticDisposer?.add(Subscription { subscriptionDisposedExpectation.fulfill() })
        automaticDisposer?.add(Subscription { subscriptionDisposedExpectation.fulfill() })
        automaticDisposer?.add(Subscription { subscriptionDisposedExpectation.fulfill() })
        automaticDisposer = nil
        waitForDefaultTimeout()
    }

    func test_AsyncDisposer_disposes_on_given_queue() {
        let queue = TealiumQueue.worker
        let disposer = AsyncDisposer(disposeOn: queue)
        let disposed = expectation(description: "Subscription is disposed")
        disposer.add(Subscription {
            dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
            disposed.fulfill()
        })
        disposer.dispose()
        waitOnQueue(queue: queue)
    }
}
