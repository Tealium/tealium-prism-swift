//
//  TealiumReplaySubjectTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumReplaySubjectTests: TealiumSubjectTests {
    let subject = TealiumReplaySubject<Int>(cacheSize: 5)

    func test_events_are_cached() {
        subject.publish(0)
        XCTAssertEqual(subject.last(), 0)
    }

    func test_init_with_initialValue_immediately_publishes_the_initialValue() {
        let subject = TealiumReplaySubject(initialValue: 1)
        XCTAssertEqual(subject.last(), 1)
    }

    func test_cached_events_are_returned_in_order() {
        let expectations = [
            expectation(description: "Event 0 is published"),
            expectation(description: "Event 1 is published"),
            expectation(description: "Event 2 is published"),
            expectation(description: "Event 3 is published"),
            expectation(description: "Event 4 is published")
        ]
        subject.publish(0)
        subject.publish(1)
        subject.publish(2)
        subject.publish(3)
        subject.publish(4)
        _ = subject.subscribe { number in
            expectations[number].fulfill()
        }
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }

    func test_oldest_event_is_the_first_to_be_removed_from_the_cache() {
        let expectation = expectation(description: "Event is published")
        subject.publish(0)
        subject.publish(1)
        subject.publish(2)
        subject.publish(3)
        subject.publish(4)
        subject.publish(5)
        subject.subscribeOnce { number in
            XCTAssertEqual(number, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func test_clear_removes_all_cached_events() {
        let expectation = expectation(description: "Event is not published")
        expectation.isInverted = true
        subject.publish(0)
        subject.publish(1)
        subject.publish(2)
        subject.publish(3)
        subject.publish(4)
        subject.clear()
        subject.subscribeOnce { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func test_events_are_directly_sent_to_subscribed_observers() {
        let expectations = [
            expectation(description: "Event 0 is published"),
            expectation(description: "Event 1 is published"),
            expectation(description: "Event 2 is published"),
            expectation(description: "Event 3 is published"),
            expectation(description: "Event 4 is published")
        ]
        expectations.forEach { $0.expectedFulfillmentCount = 2 }
        _ = subject.subscribe { number in
            expectations[number].fulfill()
        }
        subject.publish(0)
        subject.publish(1)
        subject.publish(2)
        _ = subject.subscribe { number in
            expectations[number].fulfill()
        }
        subject.publish(3)
        subject.publish(4)
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }

    func test_subscribeOnce_ReplaySubject_calls_the_observer_only_once() {
        let publisher = TealiumReplaySubject<Int>(cacheSize: 2)
        subscribeOnce_calls_the_observer_only_once(publisher)
    }
}
