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
    func test_merge_emits_events_of_both_observables() {
        let expectations = [
            expectation(description: "Event 0 is emitted"),
            expectation(description: "Event 1 is emitted"),
            expectation(description: "Event 2 is emitted"),
            expectation(description: "Event 3 is emitted"),
            expectation(description: "Event 4 is emitted")
        ]
        let subject1 = Subject<Int>()
        let subject2 = Subject<Int>()

        _ = subject1.asObservable()
            .merge(subject2.asObservable())
            .subscribe { number in
                expectations[number].fulfill()
            }
        subject1.onNext(0)
        subject2.onNext(1)
        subject2.onNext(2)
        subject1.onNext(3)
        subject2.onNext(4)
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_merge_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable: Observable<Int> = observable.merge(Observables.just(2))
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(subscribable: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        subject.onNext(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

    func test_merge_completes_when_all_upstreams_are_completed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 2
        let completed = expectation(description: "Observable completed")
        let observable = subject.asObservable()
            .first()
            .merge(Observables.just(1))

        _ = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 1)
        } onComplete: {
            completed.fulfill()
        }
        subject.onNext(1)
        subject.onNext(2)

        wait(for: [eventEmitted, completed], timeout: Self.defaultTimeout, enforceOrder: true)

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
        subject.onNext(1)
        subject.onNext(2)

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
        subject.onNext(1)
        subject.onNext(2)

        waitForDefaultTimeout()
        XCTAssertFalse(disposable.isDisposed)
    }

    func test_merge_completes_when_upstream_completes_without_emitting() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is not emitted")
        eventEmitted.isInverted = true
        let completed = expectation(description: "Observable completed")
        _ = subject.asObservable()
            .merge(subject.asObservable())
            .subscribe { _ in
                eventEmitted.fulfill()
            } onComplete: {
                completed.fulfill()
            }
        subject.onComplete()
        waitForDefaultTimeout()
    }

    func test_merge_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal {
            StateSubject(0).asObservable().merge($0)
        } assertions: {
            XCTAssertEqual($0, 0)
        }
    }
}
