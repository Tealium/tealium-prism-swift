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
        let pub1 = BasePublisher<Int>()
        let pub2 = BasePublisher<String>()

        _ = pub1.asObservable()
            .combineLatest(pub2.asObservable())
            .subscribe { _, _ in expectation.fulfill() }
        pub1.publish(1)
        waitForDefaultTimeout()
    }

    func test_combineLatest_doesnt_send_event_if_second_has_provided_no_events() {
        let expectation = expectation(description: "CombineLatest doesn't provide event")
        expectation.isInverted = true
        let pub1 = BasePublisher<Int>()
        let pub2 = BasePublisher<String>()

        _ = pub1.asObservable()
            .combineLatest(pub2.asObservable())
            .subscribe { _, _ in expectation.fulfill() }
        pub2.publish("a")
        waitForDefaultTimeout()
    }

    func test_combineLatest_sends_event_if_both_provided_an_event() {
        let expectation = expectation(description: "CombineLatest provides an event")
        let pub1 = BasePublisher<Int>()
        let pub2 = BasePublisher<String>()

        _ = pub1.asObservable()
            .combineLatest(pub2.asObservable())
            .subscribe { _, _ in expectation.fulfill() }
        pub1.publish(1)
        pub2.publish("a")
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
        let pub1 = BasePublisher<Int>()
        let pub2 = BasePublisher<String>()

        _ = pub1.asObservable()
            .combineLatest(pub2.asObservable())
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
        pub1.publish(1)
        pub2.publish("a")
        pub1.publish(2)
        pub2.publish("b")
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_combineLatest_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<(Int, String)> = observable.combineLatest(Observable.Just("a"))
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }
}
