//
//  Operators+TakeWhileTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 13/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class OperatorsTakeWhileTests: XCTestCase {

    let observable123 = Observable.Just(1, 2, 3)

    func test_events_over_conditions_are_not_emitted() {
        let expectations = [
            expectation(description: "Event 1 is emitted"),
            expectation(description: "Event 2 is not emitted"),
            expectation(description: "Event 3 is not emitted")
        ]
        expectations[1].isInverted = true
        expectations[2].isInverted = true
        _ = observable123
            .takeWhile { $0 < 2 }
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                } else if event == 3 {
                    expectations[2].fulfill()
                }
            }
        waitForDefaultTimeout()
    }

    func test_events_over_conditions_are_not_emitted_inclusive() {
        let expectations = [
            expectation(description: "Event 1 is emitted"),
            expectation(description: "Event 2 is emitted"),
            expectation(description: "Event 3 is not emitted")
        ]
        expectations[2].isInverted = true
        _ = observable123
            .takeWhile({ $0 < 2 }, inclusive: true)
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                } else if event == 3 {
                    expectations[2].fulfill()
                }
            }
        waitForDefaultTimeout()
    }

    func test_events_after_unsubscription_are_not_sent() {
        let expectations = [
            expectation(description: "Event 1 is emitted"),
            expectation(description: "Event 2 is not emitted"),
            expectation(description: "Event 3 is not emitted")
        ]
        expectations[1].isInverted = true
        expectations[2].isInverted = true
        _ = observable123
            .takeWhile { $0 != 2 }
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                } else if event == 3 {
                    expectations[2].fulfill()
                }
            }
        waitForDefaultTimeout()
    }

    func test_events_after_unsubscription_are_not_sent_inclusive() {
        let expectations = [
            expectation(description: "Event 1 is emitted"),
            expectation(description: "Event 2 is emitted"),
            expectation(description: "Event 3 is not emitted")
        ]
        expectations[2].isInverted = true
        _ = observable123
            .takeWhile({ $0 != 2 }, inclusive: true)
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                } else if event == 3 {
                    expectations[2].fulfill()
                }
            }
        waitForDefaultTimeout()
    }

    func test_async_events_after_unsubscription_are_not_sent() {
        let expectations = [
            expectation(description: "Event 1 is emitted only once"),
            expectation(description: "Event 2 is not emitted"),
        ]
        expectations[1].isInverted = true
        let pub = BasePublisher<Int>()
        _ = pub.asObservable()
            .takeWhile { $0 < 2 }
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                }
            }
        pub.publish(1)
        pub.publish(2)
        pub.publish(1)
        waitForDefaultTimeout()
    }

    func test_async_events_after_unsubscription_are_not_sent_inclusive() {
        let expectations = [
            expectation(description: "Event 1 is emitted only once"),
            expectation(description: "Event 2 is emitted"),
        ]
        let pub = BasePublisher<Int>()
        _ = pub.asObservable()
            .takeWhile({ $0 < 2 }, inclusive: true)
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                }
            }
        pub.publish(1)
        pub.publish(2)
        pub.publish(1)
        waitForDefaultTimeout()
    }

    func test_subscription_is_disposed_immediately_when_condition_is_not_met() {
        let expectations = [
            expectation(description: "Event 1 is emitted only once"),
            expectation(description: "Event 2 is not emitted"),
        ]
        expectations[1].isInverted = true
        let pub = BasePublisher<Int>()
        let subscription = pub.asObservable()
            .takeWhile { $0 < 2 }
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                }
            }
        pub.publish(1)
        XCTAssertFalse(subscription.isDisposed)
        pub.publish(2)
        XCTAssertTrue(subscription.isDisposed)
        waitForDefaultTimeout()
    }

    func test_subscription_is_disposed_immediately_when_condition_is_not_met_inclusive() {
        let expectations = [
            expectation(description: "Event 1 is emitted only once"),
            expectation(description: "Event 2 is emitted"),
        ]
        let pub = BasePublisher<Int>()
        let subscription = pub.asObservable()
            .takeWhile({ $0 < 2 }, inclusive: true)
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                }
            }
        pub.publish(1)
        XCTAssertFalse(subscription.isDisposed)
        pub.publish(2)
        XCTAssertTrue(subscription.isDisposed)
        waitForDefaultTimeout()
    }
}
