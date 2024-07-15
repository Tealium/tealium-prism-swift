//
//  Operators+FlatMapTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumSwift
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
        waitForExpectations(timeout: 1.0)
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
        waitForExpectations(timeout: 1.0)
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
        waitForExpectations(timeout: 1.0)
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
        waitForExpectations(timeout: 1.0)
    }
}
