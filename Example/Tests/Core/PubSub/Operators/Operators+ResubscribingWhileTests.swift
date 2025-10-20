//
//  Operators+ResubscribingWhileTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 04/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class OperatorsResubscribingTests: XCTestCase {
    let observable123 = Observables.just(1, 2, 3)

    func test_resubscribing_on_a_synchronous_observable_only_publishes_the_first_event() {
        let onlyFirstEventIsPublished = expectation(description: "Only the first event is published on a synchronous observable")
        onlyFirstEventIsPublished.expectedFulfillmentCount = 5
        var subscription: Disposable?
        let queue = DispatchQueue(label: "test.queue")
        var count = 0
        queue.async {
            subscription = self.observable123
                .resubscribingWhile { _ in count < 5 } // Needed otherwise this DispatchQueue will never stop executing this loop
                .subscribe { number in
                    XCTAssertEqual(number, 1)
                    onlyFirstEventIsPublished.fulfill()
                    count += 1
                }
        }
        waitForDefaultTimeout()
        queue.async {
            subscription?.dispose()
        }
    }

    func test_resubscribing_on_an_asynchronous_observable_will_publish_all_events() {
        let eventsPublished = expectation(description: "Events are published")
        eventsPublished.expectedFulfillmentCount = 2
        var eventCount = 0
        _ = Observable { observer in
            if eventCount < 2 {
                DispatchQueue.main.async {
                    eventCount += 1
                    observer(eventCount)
                }
            }
            return Disposables.disposed()
        }
        .resubscribingWhile { _ in eventCount < 2 }
        .subscribe { number in
            XCTAssertEqual(number, eventCount)
            eventsPublished.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_resubscribing_on_an_asynchronous_observable_will_call_subscribe_block_on_initial_subscribe_plus_every_event() {
        let subscribeCalled = expectation(description: "Subscribe block is called")
        subscribeCalled.expectedFulfillmentCount = 2
        var eventCount = 0
        _ = Observable { observer in
            subscribeCalled.fulfill()
            if eventCount < 2 {
                DispatchQueue.main.async {
                    eventCount += 1
                    observer(eventCount)
                }
            }
            return Disposables.disposed()
        }
        .resubscribingWhile { _ in eventCount < 2 }
        .subscribe { _ in }
        waitForDefaultTimeout()
    }

    func test_resubscribing_on_an_asynchronous_observable_will_dispose_subscription_on_every_event() {
        let disposeCalled = expectation(description: "Dispose subscription is called on every event")
        disposeCalled.expectedFulfillmentCount = 2
        var eventCount = 0
        _ = Observable { observer in
            if eventCount < 2 {
                DispatchQueue.main.async {
                    eventCount += 1
                    observer(eventCount)
                }
            }
            return Subscription {
                disposeCalled.fulfill()
            }
        }
        .resubscribingWhile { _ in eventCount < 2 }
        .subscribe { _ in }
        waitForDefaultTimeout()
    }
}
