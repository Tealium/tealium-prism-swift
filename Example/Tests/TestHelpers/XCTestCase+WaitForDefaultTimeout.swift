//
//  XCTestCase+WaitForDefaultTimeout.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 02/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

public extension XCTestCase {

    static let defaultTimeout: TimeInterval = 0.1
    func waitForDefaultTimeout() {
        waitForExpectations(timeout: Self.defaultTimeout)
    }
    static let longTimeout: TimeInterval = 10

    /// Event if the request is not actually sent, the URLProtocolMock is called on a different queue, therefore we can't wait too little or it can fail sporadically.
    func waitForLongTimeout() {
        waitForExpectations(timeout: Self.longTimeout)
    }

    func waitOnQueue(queue: TealiumQueue, timeout: TimeInterval = defaultTimeout) {
        queue.dispatchQueue.sync {
            waitForExpectations(timeout: timeout)
        }
    }
}
