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
                subject.onNext(2 * res) // Crashes in case of reentrancy (if first was not safely handling the disposal of the observer)
                XCTAssertEqual(res, 1)
                expectation.fulfill()
            }
        subject.onNext(1)
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

    func test_first_completes_after_the_event_is_reported() {
        let emitted = expectation(description: "Only first event is reported")
        let completed = expectation(description: "Completed")
        _ = observable123.first()
            .subscribe { _ in
                emitted.fulfill()
            } onComplete: {
                completed.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_first_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable: Observable<Int> = observable.first()
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(subscribable: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

    func test_first_cleans_retain_cycles_after_first_event() {
        let expectation = expectation(description: "Retain Cycle removed")
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable: Observable<Int> = observable.first()
        _ = SubscriptionRetainCycleHelper(subscribable: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        subject.onNext(1)
        waitForDefaultTimeout()
    }

    func test_first_completes_when_upstream_has_completed() {
        let completed = expectation(description: "Observable completed")
        let observable = Observables.just(1, 2, 3)
            .first { $0 > 10 }

        _ = observable.subscribe { _ in
        } onComplete: {
            completed.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_first_completes_after_emitting_the_event() {
        let emitted = expectation(description: "Events emitted until the end")
        let completed = expectation(description: "Observable completed")
        let subject = Subject<Int>()
        let observable = subject.asObservable()
            .first()
        _ = observable.subscribe { res in
            XCTAssertEqual(res, 1)
            emitted.fulfill()
        } onComplete: {
            completed.fulfill()
        }
        subject.onNext(1)
        waitForDefaultTimeout()
    }

    func test_first_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal { $0.first() }
    }
}
