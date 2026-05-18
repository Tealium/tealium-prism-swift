//
//  Operators+CombineLatestTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class OperatorsCombineLatestTests: XCTestCase {
    func test_combineLatest_doesnt_send_event_if_first_has_provided_no_events() {
        let expectation = expectation(description: "CombineLatest doesn't provide event")
        expectation.isInverted = true
        let subject1 = Subject<Int>()
        let subject2 = Subject<String>()

        _ = subject1.asObservable()
            .combineLatest(subject2.asObservable())
            .subscribe { _, _ in expectation.fulfill() }
        subject1.onNext(1)
        waitForDefaultTimeout()
    }

    func test_combineLatest_doesnt_send_event_if_second_has_provided_no_events() {
        let expectation = expectation(description: "CombineLatest doesn't provide event")
        expectation.isInverted = true
        let subject1 = Subject<Int>()
        let subject2 = Subject<String>()

        _ = subject1.asObservable()
            .combineLatest(subject2.asObservable())
            .subscribe { _, _ in expectation.fulfill() }
        subject2.onNext("a")
        waitForDefaultTimeout()
    }

    func test_combineLatest_sends_event_if_both_provided_an_event() {
        let expectation = expectation(description: "CombineLatest provides an event")
        let subject1 = Subject<Int>()
        let subject2 = Subject<String>()

        _ = subject1.asObservable()
            .combineLatest(subject2.asObservable())
            .subscribe { _, _ in expectation.fulfill() }
        subject1.onNext(1)
        subject2.onNext("a")
        waitForDefaultTimeout()
    }

    func test_combineLatest_after_first_sends_events_at_each_event_from_both_observables() {
        let expectations = [
            expectation(description: "CombineLatest provides event (1, a)"),
            expectation(description: "CombineLatest provides event (2, a)"),
            expectation(description: "CombineLatest provides event (2, b)"),
            expectation(description: "CombineLatest provides no other events")
        ]
        expectations[3].isInverted = true
        let subject1 = Subject<Int>()
        let subject2 = Subject<String>()

        _ = subject1.asObservable()
            .combineLatest(subject2.asObservable())
            .subscribe { number, string in
                switch (number, string) {
                case (1, "a"):
                    expectations[0].fulfill()
                case (2, "a"):
                    expectations[1].fulfill()
                case (2, "b"):
                    expectations[2].fulfill()
                default:
                    expectations[3].fulfill()
                }
            }
        subject1.onNext(1)
        subject2.onNext("a")
        subject1.onNext(2)
        subject2.onNext("b")
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_combineLatest_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable: Observable<(Int, String)> = observable.combineLatest(Observables.just("a"))
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(subscribable: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        subject.onNext(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

    func test_combineLatest_completes_when_both_upstreams_are_completed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let observableCompleted = expectation(description: "Observable completed")
        let observable = subject.asObservable()
            .first()
            .combineLatest(Observables.just(1))

        _ = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res.0, 1)
            XCTAssertEqual(res.1, 1)
        } onComplete: {
            observableCompleted.fulfill()
        }
        subject.onNext(1)
        subject.onNext(2)
        wait(for: [eventEmitted, observableCompleted], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_combineLatest_does_not_dispose_subscription_if_upstream_is_not_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 2
        let observable = subject.asObservable().filter { $0 == 1 }
            .combineLatest(subject.asObservable()
                .takeWhile({ $0 < 2 }, inclusive: true))
        var count = 1
        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res.0, 1)
            XCTAssertEqual(res.1, count)
            count += 1
        }
        subject.onNext(1)
        subject.onNext(2)

        waitForDefaultTimeout()
        XCTAssertFalse(disposable.isDisposed)

    }

    func test_combineLatest_does_not_dispose_subscription_if_combined_upstream_is_not_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 2
        let observable = subject.asObservable()
            .first()
            .combineLatest(subject.asObservable())
        var count = 1
        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res.0, 1)
            XCTAssertEqual(res.1, count)
            count += 1
        }
        subject.onNext(1)
        subject.onNext(2)

        waitForDefaultTimeout()
        XCTAssertFalse(disposable.isDisposed)
    }

    func test_combineLatest_completes_when_upstream_completes_without_emitting() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is not emitted")
        eventEmitted.isInverted = true
        let completed = expectation(description: "Observable completed")
        _ = subject.asObservable()
            .combineLatest(subject.asObservable())
            .subscribe { _ in
                eventEmitted.fulfill()
            } onComplete: {
                completed.fulfill()
            }
        subject.onComplete()
        waitForDefaultTimeout()
    }

    func test_combineLatest_completes_when_one_side_completes_without_ever_emitting() {
        let emitting = Subject<Int>()
        let silent = Subject<Int>()
        let eventEmitted = expectation(description: "Event is not emitted")
        eventEmitted.isInverted = true
        let completed = expectation(description: "Observable completed")
        _ = emitting.asObservable()
            .combineLatest(silent.asObservable())
            .subscribe { _ in
                eventEmitted.fulfill()
            } onComplete: {
                completed.fulfill()
            }
        emitting.onNext(1)
        silent.onComplete()
        waitForDefaultTimeout()
    }

    func test_combineLatest_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal {
            StateSubject(0).asObservable().combineLatest($0)
        } assertions: {
            XCTAssertEqual($0.1, 1)
        }
    }
}
