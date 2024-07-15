//
//  Operators+DistinctTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

final class OperatorsDistinctTests: XCTestCase {
    func test_distinct_only_provides_different_events() {
        let expectations = [
            expectation(description: "Event 0 is provided"),
            expectation(description: "Event 1 is provided"),
            expectation(description: "Event 2 is provided"),
        ]
        let observable = Observable.Just(0, 0, 0, 0, 0, 1, 1, 2)
        _ = observable.distinct()
            .subscribe { number in
                expectations[number].fulfill()
            }

        wait(for: expectations, timeout: 1.0, enforceOrder: true)
    }

    func test_distinct_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.distinct()
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        pub.publish(1)
        pub.publish(2)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 1.0)
    }

    func test_distinct_detects_equal_elements_for_synchronous_refire_in_the_chain() {
        let eventProvided = expectation(description: "Event is provided")
        let publisher = BasePublisher<Int>()
        _ = publisher.asObservable()
            .distinct()
            .map { element in
                publisher.publish(element)
                return element
            }
            .subscribe { _ in
                eventProvided.fulfill()
            }
        publisher.publish(1)
        waitForExpectations(timeout: 1.0)
    }
}
