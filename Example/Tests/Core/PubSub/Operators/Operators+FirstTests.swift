//
//  Operators+FirstTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class OperatorsFirstTests: XCTestCase {
    let observable123 = Observables.just(1, 2, 3)

    func test_first_returns_only_first_event() {
        let expectation = expectation(description: "Only first event is reported")
        _ = observable123.first()
            .subscribe { _ in
                expectation.fulfill()
            }

        waitForDefaultTimeout()
    }

    func test_first_returns_only_first_event_even_on_reentrancy_observable() {
        let expectation = expectation(description: "Only first event is reported even if downstream emits again in the upstream")
        let subject = Subject<Int>()
        _ = subject.asObservable()
            .first()
            .subscribe { res in
                subject.publish(2 * res) // Crashes in case of reentrancy (if first was not safely handling the disposal of the observer)
                XCTAssertEqual(res, 1)
                expectation.fulfill()
            }
        subject.publish(1)
        waitForDefaultTimeout()
    }

    func test_first_returns_only_first_event_that_is_included() {
        let expectation = expectation(description: "Only first event is reported")
        _ = observable123.first { $0 == 2 }
            .subscribe { number in
                XCTAssertEqual(number, 2)
                expectation.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_first_disposes_subscription_after_the_event_is_reported() {
        let expectation = expectation(description: "Only first event is reported")
        let subscription = observable123.first()
            .subscribe { _ in
                expectation.fulfill()
            }
        XCTAssertTrue(subscription.isDisposed)
        waitForDefaultTimeout()
    }

    func test_first_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.first()
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

    func test_first_cleans_retain_cycles_after_first_event() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.first()
        _ = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        waitForDefaultTimeout()
    }

    func test_first_disposes_subscription_when_upstream_is_disposed() {
        let observable = Observables.just(1, 2, 3)
            .first { $0 > 10 }

        let disposable = observable.subscribe { _ in }

        XCTAssertTrue(disposable.isDisposed)
    }

    func test_first_disposes_subscription_after_emitting_the_event() {
        let emitted = expectation(description: "Events emitted until the end")
        let disposed = expectation(description: "Subscription id disposed")
        let subject = Subject<Int>()
        let observable = subject.asObservable()
            .first()
        observable.subscribe { res in
            XCTAssertEqual(res, 1)
            emitted.fulfill()
        }.onDispose {
            disposed.fulfill()
        }
        subject.publish(1)
        wait(for: [emitted, disposed], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_first_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal { $0.first() }
    }
}
