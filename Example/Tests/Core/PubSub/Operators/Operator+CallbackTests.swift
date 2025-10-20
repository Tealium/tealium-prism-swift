//
//  Operator+CallbackTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 11/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class OperatorCallbackTests: XCTestCase {

    let observable123 = Observables.just(1, 2, 3)

    func test_callback_emits_callback_results() {
        let emissionsReceived = expectation(description: "Emissions received")
        emissionsReceived.expectedFulfillmentCount = 3
        var count = 1
        _ = observable123.callback { number, observer in
            observer(number)
        }.subscribe { number in
            XCTAssertEqual(number, count)
            count += 1
            emissionsReceived.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_callback_doesnt_call_observer_when_disposed() {
        let subscriptionDisposed = expectation(description: "Subscription Disposed for each underlying number")
        subscriptionDisposed.expectedFulfillmentCount = 3
        let emissionsNotReceived = expectation(description: "Emissions received")
        emissionsNotReceived.isInverted = true
        let disposable = observable123.callback { number, observer in
            var cancelled = false
            DispatchQueue.main.async {
                if !cancelled {
                    observer(number)
                }
            }
            return Subscription {
                cancelled = true
                subscriptionDisposed.fulfill()
            }
        }.subscribe { _ in
            emissionsNotReceived.fulfill()
        }
        disposable.dispose()
        waitForDefaultTimeout()
    }
}
