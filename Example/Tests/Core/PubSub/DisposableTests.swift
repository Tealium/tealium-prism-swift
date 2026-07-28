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
        let disposeContainer = DisposableContainer()
        disposeContainer.add(Subscription { subscriptionDisposedExpectation.fulfill() })
        disposeContainer.add(Subscription { subscriptionDisposedExpectation.fulfill() })
        disposeContainer.add(Subscription { subscriptionDisposedExpectation.fulfill() })
        disposeContainer.dispose()
        waitForDefaultTimeout()
    }

    func test_is_disposed_true_when_dispose_container_is_disposed() {
        let container = DisposableContainer()
        XCTAssertFalse(container.isDisposed)
        container.dispose()
        XCTAssertTrue(container.isDisposed)
    }

    func test_disposed_container_automatically_disposes_new_disposable() {
        let subscriptionDisposed = expectation(description: "Subscription is disposed immediately")
        let container = DisposableContainer()
        container.dispose()
        container.add(Subscription {
            subscriptionDisposed.fulfill()
        })
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
    func test_AsyncDisposableContainer_disposes_on_given_queue() {
        let queue = TealiumQueue.worker
        let disposer = AsyncDisposableContainer(queue: queue)
        let disposed = expectation(description: "Subscription is disposed")
        disposer.onDispose {
            dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
            disposed.fulfill()
        }
        let queueDrained = expectation(description: "queue drained")
        queue.dispatchQueue.sync { queueDrained.fulfill() }
        wait(for: [queueDrained], timeout: Self.defaultTimeout)
        disposer.dispose()
        waitOnQueue(queue: queue)
    }

    func test_AsyncDisposableContainer_disposes_on_given_queue_when_adding_disposable_after_dispose() {
        let queue = TealiumQueue.worker
        let disposer = AsyncDisposableContainer(queue: queue)
        let disposed = expectation(description: "Subscription is disposed")
        disposer.dispose()
        disposer.onDispose {
            dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
            disposed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_AsyncDisposableContainer_isDisposed_is_immediately_true() {
        let queue = TealiumQueue.worker
        let disposer = AsyncDisposableContainer(queue: queue)
        disposer.dispose()
        XCTAssertTrue(disposer.isDisposed)
    }

    func test_remove_removes_disposable_from_container() {
        let container = DisposableContainer()
        let subscription = Subscription { }
        container.add(subscription)
        XCTAssertEqual(container.count, 1)
        container.remove(subscription)
        XCTAssertEqual(container.count, 0)
    }

    func test_remove_does_not_dispose_removed_disposable() {
        let container = DisposableContainer()
        let subscription = Subscription { }
        container.add(subscription)
        container.remove(subscription)
        XCTAssertFalse(subscription.isDisposed)
    }

    func test_unsubscribing_observer_removes_itself_from_container_on_completion() {
        let container = DisposableContainer()
        let subject = Subject<Int>()
        subject.asObservable().subscribe(composite: container, observer: AnonymousObserver(
            onNext: { _ in },
            onComplete: { }
        ))
        XCTAssertEqual(container.count, 1)
        subject.onComplete()
        XCTAssertEqual(container.count, 0)
    }

    func test_unsubscribing_observer_removes_itself_from_container_on_disposal() {
        let container = DisposableContainer()
        let subject = Subject<Int>()
        let observer = subject.asObservable().subscribe(composite: container, observer: AnonymousObserver(
            onNext: { _ in },
            onComplete: { }
        ))
        XCTAssertEqual(container.count, 1)
        observer.dispose()
        XCTAssertEqual(container.count, 0)
    }
}
