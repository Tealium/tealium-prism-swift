//
//  TealiumQueueTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 23/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumQueueTests: XCTestCase {
    let queue = TealiumQueue(label: "test_queue", qos: .userInteractive)

    func test_isOnQueue_returns_true_when_on_that_queue() {
        dispatchPrecondition(condition: .onQueue(.main))
        XCTAssertTrue(TealiumQueue.main.isOnQueue())
    }

    func test_isOnQueue_returns_false_when_not_on_that_queue() {
        XCTAssertFalse(queue.isOnQueue())
    }

    func test_ensureOnQueue_executes_synchronously_if_on_that_queue() {
        let codeExecuted = expectation(description: "Code is executed syncronously")
        TealiumQueue.main.ensureOnQueue {
            dispatchPrecondition(condition: .onQueue(.main))
            codeExecuted.fulfill()
        }
        waitForExpectations(timeout: 0)
    }

    func test_ensureOnQueue_executes_asynchronously_if_not_on_that_queue() {
        let codeExecuted = expectation(description: "Code is executed asyncronously")
        queue.ensureOnQueue {
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            codeExecuted.fulfill()
        }
        waitForDefaultTimeout()
    }
}
