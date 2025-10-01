//
//  BackgroundTaskStarterTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 25/08/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class BackgroundTaskStarterTests: XCTestCase {

    var queue: TealiumQueue = .main
    var timeout = DispatchTimeInterval.seconds(1)
    lazy var starter = BackgroundTaskStarter(queue: queue, backgroundTaskTimeout: timeout)

    func test_startBackgroundTask_emits_true_immediately() {
        let emitsOnce = expectation(description: "Start emits once")
        starter.startBackgroundTask()
            .subscribeOnce { value in
                XCTAssertTrue(value)
                emitsOnce.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_startBackgroundTask_emits_false_on_dispose() {
        let emitsTwice = expectation(description: "Start emits twice")
        emitsTwice.expectedFulfillmentCount = 2
        var count = 0
        let disposable = starter.startBackgroundTask()
            .subscribe { value in
                if count == 0 {
                    XCTAssertTrue(value)
                } else {
                    XCTAssertFalse(value)
                }
                count += 1
                emitsTwice.fulfill()
            }
        disposable.dispose()
        waitForDefaultTimeout()
    }

    func test_startBackgroundTask_emits_false_when_expires() {
        timeout = .microseconds(1)
        let emitsTwice = expectation(description: "Start emits twice")
        emitsTwice.expectedFulfillmentCount = 2
        var count = 0
        _ = starter.startBackgroundTask()
            .subscribe { value in
                if count == 0 {
                    XCTAssertTrue(value)
                } else {
                    XCTAssertFalse(value)
                }
                count += 1
                emitsTwice.fulfill()
            }
        waitForLongTimeout()
    }

    func test_startBackgroundTask_subscription_disposes_automatically_upon_expiration() {
        timeout = .microseconds(1)
        let emitsTwice = expectation(description: "Start emits twice")
        emitsTwice.expectedFulfillmentCount = 2
        let disposable = starter.startBackgroundTask()
            .subscribe { _ in
                emitsTwice.fulfill()
            }
        waitForLongTimeout()
        XCTAssertTrue(disposable.isDisposed, "Subscription is automatically disposed on expiration")
    }

    func test_startBackgroundTask_emits_from_caller_queue_when_started() {
        let emitsOnce = expectation(description: "Start emits once")
        queue = .worker
        _ = starter.startBackgroundTask().subscribeOnce { _ in
            dispatchPrecondition(condition: .onQueue(.main))
            emitsOnce.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_startBackgroundTask_emits_from_provided_queue_when_expired() {
        let emitsTwice = expectation(description: "Start emits twice")
        emitsTwice.expectedFulfillmentCount = 2
        queue = .worker
        timeout = .microseconds(1)
        _ = starter.startBackgroundTask().subscribe { value in
            if !value {
                dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            }
            emitsTwice.fulfill()
        }
        waitForLongTimeout()
    }

    func test_startBackgroundTask_emits_from_caller_queue_when_disposed() {
        let emitsTwice = expectation(description: "Start emits twice")
        emitsTwice.expectedFulfillmentCount = 2
        queue = .worker
        let disposable = starter.startBackgroundTask().subscribe { _ in
            dispatchPrecondition(condition: .onQueue(.main))
            emitsTwice.fulfill()
        }
        disposable.dispose()
        waitOnQueue(queue: queue)
    }
}
