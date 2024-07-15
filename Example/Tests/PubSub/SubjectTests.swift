//
//  SubjectTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class SubjectTests: XCTestCase {

    func testPublishSubject() {
        let eventNotified = XCTestExpectation()
        let value = 2
        let subject = BaseSubject<Int>()
        _ = subject.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        subject.publish(value)
        wait(for: [eventNotified], timeout: 0)
    }

    func test_subscribeOnce_Subject_calls_the_observer_only_once() {
        let publisher = BasePublisher<Int>()
        subscribeOnce_calls_the_observer_only_once(publisher)
    }

    func subscribeOnce_calls_the_observer_only_once(_ publisher: BasePublisher<Int>) {
        let eventNotified = expectation(description: "Event is notified")
        eventNotified.assertForOverFulfill = true
        let eventNotNotified = expectation(description: "Event is NOT notified")
        eventNotNotified.isInverted = true
        publisher.publish(1)
        publisher.publish(1)
        publisher.asObservable().subscribeOnce { val in
            if val == 1 {
                eventNotified.fulfill()
            }
            if val == 2 {
                eventNotNotified.fulfill()
            }
        }
        publisher.publish(1)
        publisher.publish(2)
        waitForExpectations(timeout: 2.0)
    }
}
