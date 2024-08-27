//
//  DebouncerTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DebouncerTests: XCTestCase {

    let debouncer = Debouncer(queue: .main)

    func test_debounce_completes_after_timeout() {
        let debounceCompleted = expectation(description: "Debounce is completed")
        debouncer.debounce(time: 0.01) {
            dispatchPrecondition(condition: .onQueue(.main))
            debounceCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_debounce_is_delayed_on_each_call_and_completes_once() {
        let debounceCompleted = expectation(description: "Debounce is completed")
        for _ in 0..<10 {
            Thread.sleep(forTimeInterval: 0.01)
            debouncer.debounce(time: 0.02) {
                dispatchPrecondition(condition: .onQueue(.main))
                debounceCompleted.fulfill()
            }
        }
        waitForDefaultTimeout()
    }

    func test_cancel_prevents_debounce_to_complete() {
        let debounceCompleted = expectation(description: "Debounce is completed")
        debounceCompleted.isInverted = true
        debouncer.debounce(time: 0.01) {
            dispatchPrecondition(condition: .onQueue(.main))
            debounceCompleted.fulfill()
        }
        debouncer.cancel()
        waitForDefaultTimeout()
    }

    func test_debounce_with_negative_time_completes_immediately() {
        let debounceCompleted = expectation(description: "Debounce is completed")
        debouncer.debounce(time: 0) {
            dispatchPrecondition(condition: .onQueue(.main))
            debounceCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }
}
