//
//  CustomObservableTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 13/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class CustomObservableTests: XCTestCase {

    func test_Just_observable_publishes_parameters_as_events() {
        let expectations = [
            expectation(description: "Event 0 is published"),
            expectation(description: "Event 1 is published"),
            expectation(description: "Event 2 is published"),
        ]
        let observable = Observable<Int>.Just(0, 1, 2)
        _ = observable.subscribe { number in
                expectations[number].fulfill()
        }
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_Callback_observable_transforms_a_function_with_callback_into_an_observable() {
        let expectation = expectation(description: "Event is published")
        let dispatchQueue = DispatchQueue(label: "ObservableTestQueue")
        func anAsyncFunctionWithACallback(callback: @escaping (Int) -> Void) {
            dispatchQueue.async {
                callback(1)
            }
        }
        let observable = Observable<Int>.Callback(from: anAsyncFunctionWithACallback(callback:))
        _ = observable.subscribe { number in
            XCTAssertEqual(number, 1)
            expectation.fulfill()
        }

        dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }

    func test_CombineLatest_observable_is_notified_immediately_on_sync_observables() {
        let combineLatestIsNotifiedImmediately = expectation(description: "Combine latest event is notified immediately")
        let sub = Observable<String>.CombineLatest([.Just("a1"), .Just("b1"), .Just("c1")])
            .subscribe { result in
                XCTAssertEqual(result, ["a1", "b1", "c1"])
                combineLatestIsNotifiedImmediately.fulfill()
            }
        waitForDefaultTimeout()
        sub.dispose()
    }

    func test_CombineLatest_observable_is_notified_after_all_observables_have_pushed_at_least_one_event() {
        let combineLatestIsNotified = expectation(description: "Combine latest event is notified")
        let pubA = BasePublisher<String>()
        let pubB = BasePublisher<String>()
        let pubC = BasePublisher<String>()
        let sub = Observable<String>.CombineLatest([pubA.asObservable(), pubB.asObservable(), pubC.asObservable()])
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

    func test_CombineLatest_observable_is_notified_after_each_event_after_every_observable_notified_at_least_one() {
        let combineLatestIsNotified = expectation(description: "Combine latest event is notified 3 times")
        combineLatestIsNotified.expectedFulfillmentCount = 3
        let pubA = BasePublisher<String>()
        let pubB = BasePublisher<String>()
        let pubC = BasePublisher<String>()
        let sub = Observable<String>.CombineLatest([pubA.asObservable(), pubB.asObservable(), pubC.asObservable()])
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

    func test_CombineLatest_observable_is_notified_immediately_with_an_empty_array_when_provided_with_an_empty_array() {
        let combineLatestIsNotified = expectation(description: "Combine latest event is notified")
        let sub = Observable<String>.CombineLatest([])
            .subscribe { result in
                XCTAssertEqual(result, [])
                combineLatestIsNotified.fulfill()
            }
        waitForDefaultTimeout()
        sub.dispose()
    }
}
