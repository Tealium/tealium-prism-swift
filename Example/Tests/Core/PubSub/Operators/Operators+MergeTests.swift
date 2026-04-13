//
//  Operators+MergeTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class OperatorsMergeTests: XCTestCase {
    func test_merge_publishes_events_of_both_observables() {
        let expectations = [
            expectation(description: "Event 0 is published"),
            expectation(description: "Event 1 is published"),
            expectation(description: "Event 2 is published"),
            expectation(description: "Event 3 is published"),
            expectation(description: "Event 4 is published")
        ]
        let pub1 = BasePublisher<Int>()
        let pub2 = BasePublisher<Int>()

        _ = pub1.asObservable()
            .merge(pub2.asObservable())
            .subscribe { number in
                expectations[number].fulfill()
            }
        pub1.publish(0)
        pub2.publish(1)
        pub2.publish(2)
        pub1.publish(3)
        pub2.publish(4)
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_merge_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.merge(Observables.just(2))
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

    func test_merge_disposes_subscription_when_all_upstreams_are_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 2
        let observable = subject.asObservable()
            .first()
            .merge(Observables.just(1))

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 1)
        }
        subject.publish(1)
        subject.publish(2)

        waitForDefaultTimeout()
        XCTAssertTrue(disposable.isDisposed)
    }

    func test_merge_does_not_dispose_subscription_if_upstream_is_not_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 3
        let observable = subject.asObservable().filter { $0 == 1 }
            .merge(subject.asObservable()
                .takeWhile({ $0 < 2 }, inclusive: true)
                .map { 1 + $0 })
        var count = 1
        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, count)
            count += 1
        }
        subject.publish(1)
        subject.publish(2)

        waitForDefaultTimeout()
        XCTAssertFalse(disposable.isDisposed)
    }

    func test_merge_does_not_dispose_subscription_if_merged_upstream_is_not_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 3
        let observable = subject.asObservable()
            .first()
            .merge(subject.asObservable().map { 1 + $0 })
        var count = 1
        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, count)
            count += 1
        }
        subject.publish(1)
        subject.publish(2)

        waitForDefaultTimeout()
        XCTAssertFalse(disposable.isDisposed)
    }

    func test_merge_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal {
            StateSubject(0).asObservable().merge($0)
        } assertions: {
            XCTAssertEqual($0, 0)
        }
    }
}
