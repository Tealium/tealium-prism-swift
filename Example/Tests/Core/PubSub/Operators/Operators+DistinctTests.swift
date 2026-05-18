//
//  Operators+DistinctTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class OperatorsDistinctTests: XCTestCase {
    func test_distinct_only_provides_different_events() {
        let expectations = [
            expectation(description: "Event 0 is provided"),
            expectation(description: "Event 1 is provided"),
            expectation(description: "Event 2 is provided"),
        ]
        let observable = Observables.just(0, 0, 0, 0, 0, 1, 1, 2)
        _ = observable.distinct()
            .subscribe { number in
                expectations[number].fulfill()
            }

        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_distinct_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable: Observable<Int> = observable.distinct()
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(subscribable: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        subject.onNext(1)
        subject.onNext(1)
        subject.onNext(2)
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

    func test_distinct_detects_equal_elements_for_synchronous_refire_in_the_chain() {
        let eventProvided = expectation(description: "Event is provided")
        let subject = Subject<Int>()
        _ = subject.asObservable()
            .distinct()
            .map { element in
                subject.onNext(element)
                return element
            }
            .subscribe { _ in
                eventProvided.fulfill()
            }
        subject.onNext(1)
        waitForDefaultTimeout()
    }

    func test_distinct_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal { $0.distinct() }
    }
}
