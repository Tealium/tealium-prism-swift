//
//  Operators+FirstTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

final class OperatorsFirstTests: XCTestCase {
    let observable123 = Observable.Just(1, 2, 3)

    func test_first_returns_only_first_event() {
        let expectation = expectation(description: "Only first event is reported")
        _ = observable123.first()
            .subscribe { _ in
                expectation.fulfill()
            }

        waitForDefaultTimeout()
    }

    func test_first_returns_only_first_event_that_is_included() {
        let expectation = expectation(description: "Only first event is reported")
        _ = observable123.first { $0 == 2 }
            .subscribe { number in
                XCTAssertEqual(number, 2)
                expectation.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_first_disposes_subscription_after_the_event_is_reported() {
        let expectation = expectation(description: "Only first event is reported")
        let subscription = observable123.first()
            .subscribe { _ in
                expectation.fulfill()
            }
        XCTAssertTrue(subscription.isDisposed)
        waitForDefaultTimeout()
    }

    func test_first_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.first()
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

    func test_first_cleans_retain_cycles_after_first_event() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.first()
        _ = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        waitForDefaultTimeout()
    }
}
