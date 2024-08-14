//
//  XCTestCase+WaitForDefaultTimeout.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 02/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import XCTest

public extension XCTestCase {

    static let defaultTimeout: TimeInterval = 0.1
    func waitForDefaultTimeout() {
        waitForExpectations(timeout: Self.defaultTimeout)
    }
}
