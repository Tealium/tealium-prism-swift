//
//  ObservablesTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 13/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class ObservablesTests: XCTestCase {

    func test_just_publishes_parameters_as_events() {
        let expectations = [
            expectation(description: "Event 0 is published"),
            expectation(description: "Event 1 is published"),
            expectation(description: "Event 2 is published"),
        ]
        let observable = Observables.just(0, 1, 2)
        _ = observable.subscribe { number in
                expectations[number].fulfill()
        }
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_callback_transforms_a_function_with_callback_into_an_observable() {
        let expectation = expectation(description: "Event is published")
        func anAsyncFunctionWithACallback(callback: @escaping (Int) -> Void) {
            DispatchQueue.main.async {
                callback(1)
            }
        }
        let observable = Observables.callback(from: anAsyncFunctionWithACallback(callback:))
        _ = observable.subscribe { number in
            XCTAssertEqual(number, 1)
            expectation.fulfill()
        }

        waitForDefaultTimeout()
    }

    func test_combineLatest_is_notified_immediately_on_sync_observables() {
        let combineLatestIsNotifiedImmediately = expectation(description: "Combine latest event is notified immediately")
        let sub = Observables.combineLatest([Observables.just("a1"), Observables.just("b1"), Observables.just("c1")])
            .subscribe { result in
                XCTAssertEqual(result, ["a1", "b1", "c1"])
                combineLatestIsNotifiedImmediately.fulfill()
            }
        waitForDefaultTimeout()
        sub.dispose()
    }

    func test_combineLatest_is_notified_after_all_observables_have_pushed_at_least_one_event() {
        let combineLatestIsNotified = expectation(description: "Combine latest event is notified")
        let pubA = BasePublisher<String>()
        let pubB = BasePublisher<String>()
        let pubC = BasePublisher<String>()
        let sub = Observables.combineLatest([pubA.asObservable(), pubB.asObservable(), pubC.asObservable()])
            .subscribe { result in
                XCTAssertEqual(result, ["a3", "b1", "c1"])
                combineLatestIsNotified.fulfill()
            }
        pubA.publish("a1")
        pubA.publish("a2")
        pubA.publish("a3")
        pubC.publish("c1")
        pubB.publish("b1")
        waitForDefaultTimeout()
        sub.dispose()
    }

    func test_combineLatest_is_notified_after_each_event_after_every_observable_notified_at_least_one() {
        let combineLatestIsNotified = expectation(description: "Combine latest event is notified 3 times")
        combineLatestIsNotified.expectedFulfillmentCount = 3
        let pubA = BasePublisher<String>()
        let pubB = BasePublisher<String>()
        let pubC = BasePublisher<String>()
        let sub = Observables.combineLatest([pubA.asObservable(), pubB.asObservable(), pubC.asObservable()])
            .subscribe { result in
                XCTAssertEqual(result, ["a", "b1", "c1"])
                combineLatestIsNotified.fulfill()
            }
        pubA.publish("a")
        pubC.publish("c1")
        pubB.publish("b1")
        pubA.publish("a")
        pubA.publish("a")
        waitForDefaultTimeout()
        sub.dispose()
    }

    func test_combineLatest_is_notified_immediately_with_an_empty_array_when_provided_with_an_empty_array() {
        let combineLatestIsNotified = expectation(description: "Combine latest event is notified")
        _ = Observables.combineLatest([])
            .subscribe { result in
                XCTAssertEqual(result, [])
                combineLatestIsNotified.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_combineLatest_completes_when_all_upstreams_are_completed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let completed = expectation(description: "Observable completed")
        let observable = Observables.combineLatest([
            subject.asObservable().first(),
            Observables.just(3)
        ])

        _ = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res[0], 1)
            XCTAssertEqual(res[1], 3)
        } onComplete: {
            completed.fulfill()
        }
        subject.publish(1)
        subject.publish(2)
        waitForDefaultTimeout()
    }

    func test_combineLatest_does_not_dispose_subscription_at_least_one_upstream_is_not_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 2
        let observable = Observables.combineLatest([
            subject.asObservable().filter { $0 == 1 },
            subject.asObservable().takeWhile({ $0 < 2 }, inclusive: true)
        ])
        var count = 1
        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res[0], 1)
            XCTAssertEqual(res[1], count)
            count += 1
        }
        subject.publish(1)
        subject.publish(2)

        waitForDefaultTimeout()
        XCTAssertFalse(disposable.isDisposed)
    }

    func test_combineLatest_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal {
            Observables.combineLatest([StateSubject(0).asObservable(), $0])
        } assertions: {
            XCTAssertTrue($0.contains(1))
        }
    }
}
