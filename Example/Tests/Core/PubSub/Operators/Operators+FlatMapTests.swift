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
    let observable123 = Observable.Just(1, 2, 3)

    func test_flatMap_returns_new_observables_flattening_it() {
        let flatMappedEventIsCalled = expectation(description: "FlatMapped event is called 3 times")
        flatMappedEventIsCalled.expectedFulfillmentCount = 3
        _ = observable123.flatMap { _ in
            Observable.Just("flatMapped")
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
            Observable.Callback { observer in
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
            Observable.Callback { observer in
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
        let generatedObservable: Observable<Int> = observable.flatMap { _ in Observable.Just(2) }
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
        let subject = BaseSubject<Int>()
        let innerSubject1 = BaseSubject<Int>()
        let innerSubject2 = BaseSubject<Int>()
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
        let subject = BaseSubject<Int?>()
        _ = subject.asObservable().flatMapLatest { _ in
                .Just(200)
        }.subscribe { value in
            XCTAssertEqual(value, 200)
            observerCalled.fulfill()
        }
        subject.publish(nil)
        waitForDefaultTimeout()
    }
}
