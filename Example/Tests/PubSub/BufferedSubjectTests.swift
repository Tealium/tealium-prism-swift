//
//  BufferedSubjectTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class BufferedSubjectTests: SubjectTests {
    let subject = BufferedSubject<Int>(bufferSize: 5)
    func test_events_are_buffered() {
        let expectation = expectation(description: "Event is published")
        subject.publish(0)
        subject.subscribeOnce { number in
            XCTAssertEqual(number, 0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func test_buffered_events_are_returned_in_order() {
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

    func test_oldest_event_is_the_first_to_be_removed_from_the_buffer() {
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

    func test_events_are_directly_sent_to_subscribed_observers() {
        let expectations = [
            expectation(description: "Event 0 is published"),
            expectation(description: "Event 1 is published"),
            expectation(description: "Event 2 is published"),
            expectation(description: "Event 3 is published"),
            expectation(description: "Event 4 is published")
        ]
        _ = subject.subscribe { number in
            expectations[number].fulfill()
        }
        subject.publish(0)
        subject.publish(1)
        subject.publish(2)
        subject.publish(3)
        subject.publish(4)
        _ = subject.subscribe { number in
            expectations[number].fulfill() // Nothing should be published here
        }
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }

    func test_buffering_stops_on_first_subscription() {
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
        _ = subject.subscribe { number in
            expectations[number].fulfill()
        }
        subject.publish(3)
        subject.publish(4)

        _ = subject.subscribe { number in
            expectations[number].fulfill() // Nothing should be published here
        }
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }

    func test_subscribeOnce_BufferedSubject_calls_the_observer_only_once() {
        let publisher = BufferedSubject<Int>(bufferSize: 2)
        subscribeOnce_calls_the_observer_only_once(publisher)
    }
}
