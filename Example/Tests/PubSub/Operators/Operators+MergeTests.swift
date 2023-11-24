//
//  Operators+MergeTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

final class OperatorsMergeTests: XCTestCase {
    func test_merge_publishes_events_of_both_observables() {
        let expectations = [
            expectation(description: "Event 0 is published"),
            expectation(description: "Event 1 is published"),
            expectation(description: "Event 2 is published"),
            expectation(description: "Event 3 is published"),
            expectation(description: "Event 4 is published")
        ]
        let pub1 = TealiumPublisher<Int>()
        let pub2 = TealiumPublisher<Int>()

        _ = pub1.asObservable()
            .merge(pub2.asObservable())
            .subscribe { number in
                expectations[number].fulfill()
            }
        pub1.publish(0)
        pub2.publish(1)
        pub2.publish(2)
        pub1.publish(3)
        pub2.publish(4)
        wait(for: expectations, timeout: 1.0, enforceOrder: true)
    }

    func test_merge_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.merge(TealiumObservable.Just(2))
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 1.0)
    }
}
