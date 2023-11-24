//
//  Operators+StartsWithTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

final class OperatorsStartsWithTests: XCTestCase {
    let observable123 = TealiumObservable.Just(1, 2, 3)

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
        wait(for: expectations, timeout: 1.0, enforceOrder: true)
    }

    func test_startWith_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.startWith(0)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 1.0)
    }
}
