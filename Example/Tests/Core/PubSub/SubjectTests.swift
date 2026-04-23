//
//  SubjectTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 17/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class SubjectTests: XCTestCase {

    func testPublishSubject() {
        let eventNotified = expectation(description: "Event is notified")
        let value = 2
        let subject = Subject<Int>()
        _ = subject.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        subject.publish(value)
        waitForDefaultTimeout()
    }

    func test_subscribeOnce_Subject_calls_the_observer_only_once() {
        let publisher = BasePublisher<Int>()
        subscribeOnce_calls_the_observer_only_once(publisher)
    }

    func subscribeOnce_calls_the_observer_only_once(_ publisher: BasePublisher<Int>) {
        let eventNotified = expectation(description: "Event is notified")
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
        waitForDefaultTimeout()
    }

    func test_complete_notifies_existing_subscribers() {
        let completed = expectation(description: "onComplete is received")
        let subject = Subject<Int>()
        _ = subject.subscribe { _ in } onComplete: {
            completed.fulfill()
        }
        subject.complete()
        waitForDefaultTimeout()
    }

    func test_publish_after_complete_is_ignored() {
        let eventReceived = expectation(description: "Event is NOT received after complete")
        eventReceived.isInverted = true
        let subject = Subject<Int>()
        _ = subject.subscribe { _ in
            eventReceived.fulfill()
        }
        subject.complete()
        subject.publish(1)
        waitForDefaultTimeout()
    }

    func test_subscribing_to_completed_subject_immediately_receives_onComplete() {
        let completed = expectation(description: "onComplete is received immediately")
        let subject = Subject<Int>()
        subject.complete()
        _ = subject.subscribe { _ in } onComplete: {
            completed.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_complete_is_idempotent() {
        let completed = expectation(description: "onComplete is received once")
        completed.expectedFulfillmentCount = 1
        completed.assertForOverFulfill = true
        let subject = Subject<Int>()
        _ = subject.subscribe { _ in } onComplete: {
            completed.fulfill()
        }
        subject.complete()
        subject.complete()
        waitForDefaultTimeout()
    }
}
