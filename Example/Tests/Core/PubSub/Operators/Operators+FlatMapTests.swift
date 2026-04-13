//
//  Operators+FlatMapTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class OperatorsFlatMapTests: XCTestCase {
    let observable123 = Observables.just(1, 2, 3)

    func test_flatMap_returns_new_observables_flattening_it() {
        let flatMappedEventIsCalled = expectation(description: "FlatMapped event is called 3 times")
        flatMappedEventIsCalled.expectedFulfillmentCount = 3
        _ = observable123.flatMap { _ in
            Observables.just("flatMapped")
        }.subscribe { event in
            XCTAssertEqual(event, "flatMapped")
            flatMappedEventIsCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_flatMap_emits_events_form_all_returned_observables() {
        let flatMappedEventIsCalled = expectation(description: "FlatMapped event is called 3 times")
        flatMappedEventIsCalled.expectedFulfillmentCount = 3
        _ = observable123.flatMap { element in
            Observables.callback { observer in
                DispatchQueue.main.async {
                    observer(element)
                }
            }
        }.subscribe { _ in
            flatMappedEventIsCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_only_emits_events_from_latest_returned_observable() {
        let flatMappedEventIsCalled = expectation(description: "FlatMapped event is called only once")
        _ = observable123.flatMapLatest { element in
            Observables.callback { observer in
                DispatchQueue.main.async {
                    observer(element)
                }
            }
        }.subscribe { element in
            XCTAssertEqual(element, 3)
            flatMappedEventIsCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_flatMap_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.flatMap { _ in Observables.just(2) }
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_disposes_previous_subscriptions_when_reentrant_emission_occurs() {
        let observerCalled = expectation(description: "Observer called")
        let subject = Subject<Int>()
        let innerSubject1 = Subject<Int>()
        let innerSubject2 = Subject<Int>()
        _ = subject.asObservable().flatMapLatest { value in
            if value == 1 {
                subject.publish(2)
                subject.publish(3)
                subject.publish(4)
                return innerSubject1.asObservable()
            } else {
                return innerSubject2.asObservable()
            }
        }.subscribe { value in
            XCTAssertEqual(value, 200)
            observerCalled.fulfill()
        }
        subject.publish(1)
        innerSubject1.publish(100)
        innerSubject2.publish(200)
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_doesnt_drop_legitimate_nil_values() {
        let observerCalled = expectation(description: "Observer called")
        let subject = Subject<Int?>()
        _ = subject.asObservable().flatMapLatest { _ in
            Observables.just(200)
        }.subscribe { value in
            XCTAssertEqual(value, 200)
            observerCalled.fulfill()
        }
        subject.publish(nil)
        waitForDefaultTimeout()
    }

    func test_flatMap_does_not_dispose_subscription_when_upstream_is_disposed_but_downstream_is_not() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let other = StateSubject<Int>(5)
        let observable = subject.asObservable()
            .first()
            .flatMap { _ in other.asObservable() }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 5)
        }
        subject.publish(1)
        subject.publish(2)

        XCTAssertFalse(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMap_does_not_dispose_subscription_when_downstream_is_disposed_but_upstream_is_not() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 2
        let observable = subject.asObservable()
            .flatMap { Observables.just($0 + $0) }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 2)
        }
        subject.publish(1)
        subject.publish(1)

        XCTAssertFalse(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMap_disposes_after_upstream_and_all_of_downstreams_have_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 2
        let observable0 = subject.asObservable()
        let observable1 = subject.asObservable().first(where: { $0 == 3 })
        let observable2 = subject.asObservable().first()

        let observable = observable0
            .takeWhile({ $0 < 3 }, inclusive: false)
            .flatMap {
                if $0 == 1 {
                    observable1
                } else {
                    observable2
                }
            }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 3)
        }
        subject.publish(1)
        subject.publish(2)
        XCTAssertFalse(disposable.isDisposed)

        subject.publish(3)
        XCTAssertTrue(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMap_disposes_subscription_when_upstream_and_downstream_are_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let observable = subject.asObservable()
            .first()
            .flatMap { Observables.just($0 + $0) }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 2)
        }
        subject.publish(1)
        subject.publish(5)

        XCTAssertTrue(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_does_not_dispose_subscription_when_upstream_is_disposed_but_downstream_is_not() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let other = StateSubject<Int>(5)
        let observable = subject.asObservable()
            .first()
            .flatMapLatest { _ in other.asObservable() }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 5)
        }
        subject.publish(1)
        subject.publish(2)

        XCTAssertFalse(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_does_not_dispose_subscription_when_downstream_is_disposed_but_upstream_is_not() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 2
        let observable = subject.asObservable()
            .flatMapLatest { Observables.just($0 + $0) }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 2)
        }
        subject.publish(1)
        subject.publish(1)

        XCTAssertFalse(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_disposes_after_upstream_and_all_of_downstreams_have_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let observable0 = subject.asObservable()
        let observable1 = subject.asObservable().first(where: { $0 == 3 })
        let observable2 = subject.asObservable().first()

        let observable = observable0
            .takeWhile({ $0 < 3 }, inclusive: false)
            .flatMapLatest {
                if $0 == 1 {
                    observable1
                } else {
                    observable2
                }
            }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 3)
        }
        subject.publish(1)
        subject.publish(2)
        XCTAssertFalse(disposable.isDisposed)

        subject.publish(3)
        XCTAssertTrue(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_disposes_subscription_when_upstream_and_downstream_are_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let observable = subject.asObservable()
            .first()
            .flatMapLatest { Observables.just($0 + $0) }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 2)
        }
        subject.publish(1)
        subject.publish(2)

        XCTAssertTrue(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMap_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal { $0.flatMap { Observables.just($0) } }
    }

    func test_flatMapLatest_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal { $0.flatMapLatest { Observables.just($0) } }
    }

}
