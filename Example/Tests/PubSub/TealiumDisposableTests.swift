//
//  TealiumDisposableTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 14/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumDisposableTests: XCTestCase {

    func test_tealium_subscription_calls_callback_on_dispose() {
        let expectation = expectation(description: "Dispose callback is called")
        let subscription = TealiumSubscription {
            expectation.fulfill()
        }
        subscription.dispose()
        waitForExpectations(timeout: 2.0)
    }

    func test_is_disposed_true_when_subscription_is_disposed() {
        let subscription = TealiumSubscription { }
        XCTAssertFalse(subscription.isDisposed)
        subscription.dispose()
        XCTAssertTrue(subscription.isDisposed)
    }

    func test_dispose_container_disposes_all_subscriptions() {
        let subscriptionDisposedExpectation = expectation(description: "Subscription is disposed")
        subscriptionDisposedExpectation.expectedFulfillmentCount = 3
        let disposeContainer = TealiumDisposeContainer()
        disposeContainer.add(TealiumSubscription { subscriptionDisposedExpectation.fulfill() })
        disposeContainer.add(TealiumSubscription { subscriptionDisposedExpectation.fulfill() })
        disposeContainer.add(TealiumSubscription { subscriptionDisposedExpectation.fulfill() })
        disposeContainer.dispose()
        waitForExpectations(timeout: 2.0)
    }

    func test_is_disposed_true_when_dispose_container_is_disposed() {
        let container = TealiumDisposeContainer()
        XCTAssertFalse(container.isDisposed)
        container.dispose()
        XCTAssertTrue(container.isDisposed)
    }

    func test_disposed_container_automatically_disposes_new_disposable() {
        let subscriptionDisposed = expectation(description: "Subscription is disposed immediately")
        let container = TealiumDisposeContainer()
        container.dispose()
        container.add(TealiumSubscription(unsubscribe: {
            subscriptionDisposed.fulfill()
        }))
        waitForExpectations(timeout: 2.0)
    }

    func test_deinit_disposes_automatically_all_subscriptions_contained_in_automatic_disposer() {
        let subscriptionDisposedExpectation = expectation(description: "Subscription is disposed")
        subscriptionDisposedExpectation.expectedFulfillmentCount = 3
        var automaticDisposer: TealiumAutomaticDisposer? = TealiumAutomaticDisposer()
        automaticDisposer?.add(TealiumSubscription { subscriptionDisposedExpectation.fulfill() })
        automaticDisposer?.add(TealiumSubscription { subscriptionDisposedExpectation.fulfill() })
        automaticDisposer?.add(TealiumSubscription { subscriptionDisposedExpectation.fulfill() })
        automaticDisposer = nil
        waitForExpectations(timeout: 2.0)
    }
}
