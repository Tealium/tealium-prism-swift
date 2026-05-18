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

    let observable123 = Observables.just(1, 2, 3)

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

    func test_reentrancy_events_over_conditions_are_not_emitted() {
        let expectation = expectation(description: "Only first event is reported even if downstream emits again in the upstream")
        expectation.expectedFulfillmentCount = 2
        var count = 1
        let subject = Subject<Int>()
        _ = subject.asObservable()
            .takeWhile({ $0 % 2 == 1 }, inclusive: true)
            .subscribe { res in
                XCTAssertEqual(res, count)
                count += 1
                subject.onNext(2 * res) // Crashes in case of reentrancy (if takeWhile was not safely handling the disposal of the observer)
                expectation.fulfill()
            }
        subject.onNext(1)
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
        let subject = Subject<Int>()
        _ = subject.asObservable()
            .takeWhile { $0 < 2 }
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                }
            }
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(1)
        waitForDefaultTimeout()
    }

    func test_async_events_after_unsubscription_are_not_sent_inclusive() {
        let expectations = [
            expectation(description: "Event 1 is emitted only once"),
            expectation(description: "Event 2 is emitted"),
        ]
        let subject = Subject<Int>()
        _ = subject.asObservable()
            .takeWhile({ $0 < 2 }, inclusive: true)
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                }
            }
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(1)
        waitForDefaultTimeout()
    }

    func test_subscription_completes_immediately_when_condition_is_not_met() {
        let expectations = [
            expectation(description: "Event 1 is emitted only once"),
            expectation(description: "Observable completed"),
            expectation(description: "Event 2 is not emitted"),
        ]
        expectations[2].isInverted = true
        let subject = Subject<Int>()
        _ = subject.asObservable()
            .takeWhile { $0 < 2 }
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[2].fulfill()
                }
            } onComplete: {
                expectations[1].fulfill()
            }
        subject.onNext(1)
        subject.onNext(2)
        waitForDefaultTimeout()
    }

    func test_subscription_is_completed_immediately_when_condition_is_not_met_inclusive() {
        let expectations = [
            expectation(description: "Event 1 is emitted only once"),
            expectation(description: "Event 2 is emitted"),
            expectation(description: "Observable completed"),
        ]
        let subject = Subject<Int>()
        _ = subject.asObservable()
            .takeWhile({ $0 < 2 }, inclusive: true)
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                }
            } onComplete: {
                expectations[2].fulfill()
            }
        subject.onNext(1)
        subject.onNext(2)
        waitForDefaultTimeout()
    }

    func test_takeWhile_completes_when_upstream_is_completed() {
        let completed = expectation(description: "Observable completed")
        let observable = Observables.just(1, 2, 3)
            .takeWhile { $0 < 10 }

        _ = observable.subscribe { _ in
        } onComplete: {
            completed.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_takeWhile_completes_after_emitting_last_value() {
        let emitted = expectation(description: "Events emitted until the end")
        let completed = expectation(description: "Observable completed")
        let subject = Subject<Int>()
        let observable = subject.asObservable()
            .takeWhile({ _ in false }, inclusive: true)
        observable.subscribe { res in
            XCTAssertEqual(res, 1)
            emitted.fulfill()
        } onComplete: {
            completed.fulfill()
        }
        subject.onNext(1)
        wait(for: [emitted, completed], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_takeWhile_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal { $0.takeWhile { _ in true } }
    }
}
