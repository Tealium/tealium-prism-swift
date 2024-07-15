//
//  Operators+IgnoreTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

final class OperatorsIgnoreTests: XCTestCase {
    func test_ignoreN_ignores_first_N_events() {
        let expectation = expectation(description: "4th event received")
        let sub = ReplaySubject(initialValue: 0)
        let observable = sub.asObservable()
        observable.ignore(3)
            .subscribeOnce { element in
                if element == 3 {
                    expectation.fulfill()
                }
            }
        sub.publish(1)
        sub.publish(2)
        sub.publish(3)
        waitForExpectations(timeout: 1.0)
    }
}
