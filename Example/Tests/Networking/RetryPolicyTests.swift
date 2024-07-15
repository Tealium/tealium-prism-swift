//
//  RetryPolicyTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 16/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class RetryPolicyTests: XCTestCase {

    func test_do_not_retry_should_never_retry() {
        let policy = RetryPolicy.doNotRetry
        let expect = expectation(description: "Retry should never happen")
        expect.isInverted = true
        let result = policy.shouldRetry(onQueue: .main) {
            expect.fulfill()
        }
        XCTAssertFalse(result)
        waitForExpectations(timeout: 3.0)
    }

    func test_after_delay_should_retry_once_on_queue() {
        let policy = RetryPolicy.afterDelay(0.0)
        let expect = expectation(description: "Retry should happen once")
        let queue = DispatchQueue(label: "test_label")
        let result = policy.shouldRetry(onQueue: queue) {
            dispatchPrecondition(condition: .onQueue(queue))
            expect.fulfill()
        }
        XCTAssertTrue(result)
        waitForExpectations(timeout: 3.0)
    }

    func test_after_event_subscribes_once_on_queue() {
        let queue = DispatchQueue(label: "queue_label")
        let otherQueue = DispatchQueue(label: "other_label")
        let expect = expectation(description: "Retry should subscribe once")
        let policy = RetryPolicy.afterEvent(CustomObservable({ observer in
            defer { expect.fulfill() }
            dispatchPrecondition(condition: .onQueue(queue))
            otherQueue.async {
                observer(())
            }
            return Subscription { }
        }))
        let result = policy.shouldRetry(onQueue: queue) { }
        XCTAssertTrue(result)
        waitForExpectations(timeout: 3.0)
    }

    func test_after_event_should_retry_once_on_queue() {
        let queue = DispatchQueue(label: "queue_label")
        let otherQueue = DispatchQueue(label: "other_label")
        let policy = RetryPolicy.afterEvent(CustomObservable({ observer in
            dispatchPrecondition(condition: .onQueue(queue))
            otherQueue.async {
                observer(())
            }
            return Subscription { }
        }))
        let expect = expectation(description: "Retry should happen once")
        let result = policy.shouldRetry(onQueue: queue) {
            dispatchPrecondition(condition: .onQueue(queue))
            expect.fulfill()
        }
        XCTAssertTrue(result)
        waitForExpectations(timeout: 3.0)
    }

}
