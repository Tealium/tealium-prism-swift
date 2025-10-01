//
//  Operators+FilterTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class OperatorsFilterTests: XCTestCase {
    let observable123 = Observable.Just(1, 2, 3)

    func test_filter_removes_events() {
        let expectations = [
            expectation(description: "Event 1 is reported"),
            expectation(description: "Event 2 is not reported"),
            expectation(description: "Event 3 is reported")
        ]
        expectations[1].isInverted = true
        _ = observable123.filter { $0 != 2 }
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                } else if event == 3 {
                    expectations[2].fulfill()
                }
            }
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_filter_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.filter { $0 != 2 }
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        pub.publish(2)
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

}
