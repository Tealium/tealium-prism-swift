//
//  Operators+StartsWithTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class OperatorsStartsWithTests: XCTestCase {
    let observable123 = Observable.Just(1, 2, 3)

    func test_start_with_prefixes_the_events_with_provided_events() {
        let expectations = [
                expectation(description: "Event 0 is reported"),
                expectation(description: "Event 1 is reported"),
                expectation(description: "Event 2 is reported"),
                expectation(description: "Event 3 is reported")
        ]
        _ = observable123.startWith(0)
            .subscribe { number in
                expectations[number].fulfill()
            }
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_startWith_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.startWith(0)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }
}
