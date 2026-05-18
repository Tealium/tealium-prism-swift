//
//  ReplaySubjectTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 13/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ReplaySubjectTests: SubjectTests {
    let subject = ReplaySubject<Int>(cacheSize: 5)

    func test_events_are_cached() {
        subject.onNext(0)
        XCTAssertEqual(subject.last(), 0)
    }

    func test_init_with_initialValue_immediately_emits_the_initialValue() {
        let subject = ReplaySubject(1)
        XCTAssertEqual(subject.last(), 1)
    }

    func test_cached_events_are_returned_in_order() {
        let expectations = [
            expectation(description: "Event 0 is emitted"),
            expectation(description: "Event 1 is emitted"),
            expectation(description: "Event 2 is emitted"),
            expectation(description: "Event 3 is emitted"),
            expectation(description: "Event 4 is emitted")
        ]
        subject.onNext(0)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        _ = subject.subscribe { number in
            expectations[number].fulfill()
        }
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_oldest_event_is_the_first_to_be_removed_from_the_cache() {
        let expectation = expectation(description: "Event is emitted")
        subject.onNext(0)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.onNext(5)
        subject.subscribeOnce { number in
            XCTAssertEqual(number, 1)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_clear_removes_all_cached_events() {
        let expectation = expectation(description: "Event is not emitted")
        expectation.isInverted = true
        subject.onNext(0)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.clear()
        subject.subscribeOnce { _ in
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_events_are_directly_sent_to_subscribed_observers() {
        let expectations = [
            expectation(description: "Event 0 is emitted"),
            expectation(description: "Event 1 is emitted"),
            expectation(description: "Event 2 is emitted"),
            expectation(description: "Event 3 is emitted"),
            expectation(description: "Event 4 is emitted")
        ]
        expectations.forEach { $0.expectedFulfillmentCount = 2 }
        _ = subject.subscribe { number in
            expectations[number].fulfill()
        }
        subject.onNext(0)
        subject.onNext(1)
        subject.onNext(2)
        _ = subject.subscribe { number in
            expectations[number].fulfill()
        }
        subject.onNext(3)
        subject.onNext(4)
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_subscribeOnce_ReplaySubject_calls_the_observer_only_once() {
        let subject = ReplaySubject<Int>(cacheSize: 2)
        subscribeOnce_calls_the_observer_only_once(subject)
    }

    func test_resize_to_less_size_leaves_latest_cached_events() {
        var sum = 0
        subject.onNext(0)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.resize(3)
        _ = subject.subscribe { number in
            sum += number
        }
        XCTAssertEqual(sum, 9)
    }

    func test_resize_to_greater_size_leaves_all_cached_events() {
        var sum = 0
        subject.onNext(5)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.resize(10)
        _ = subject.subscribe { number in
            sum += number
        }
        XCTAssertEqual(sum, 15)
    }

    func test_resize_to_negative_size_increases_cache_size() {
        var sum = 0
        subject.onNext(5)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.resize(-3)
        subject.onNext(10)
        _ = subject.subscribe { number in
            sum += number
        }
        XCTAssertEqual(sum, 25)
    }

    func test_resize_to_zero_clears_cache() {
        let cacheNotEmpty = expectation(description: "Cache is not empty")
        cacheNotEmpty.isInverted = true
        subject.onNext(5)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.resize(0)
        _ = subject.subscribe { _ in
            cacheNotEmpty.fulfill()
        }
        waitForDefaultTimeout()
    }
}
