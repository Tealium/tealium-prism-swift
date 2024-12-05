//
//  ObservableTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 12/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ObservableTests: XCTestCase {

    let pub = BasePublisher<Int>()

    func test_as_observable_receives_events() {
        let expectation = expectation(description: "Event is published to the observable")
        let obs = pub.asObservable()
        _ = obs.subscribe { number in
            expectation.fulfill()
            XCTAssertEqual(number, 1)
        }
        pub.publish(1)
        waitForDefaultTimeout()
    }

    func test_observers_are_called_in_order() {
        let expectations = [
            expectation(description: "First event is called"),
            expectation(description: "Second event is called"),
            expectation(description: "Third event is called"),
        ]
        let obs = pub.asObservable()
        _ = obs.subscribe { number in
            expectations[0].fulfill()
            XCTAssertEqual(number, 1)
        }
        _ = obs.subscribe { number in
            expectations[1].fulfill()
            XCTAssertEqual(number, 1)
        }
        _ = obs.subscribe { number in
            expectations[2].fulfill()
            XCTAssertEqual(number, 1)
        }
        pub.publish(1)
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_create_custom_observable_calls_subscription_handler_on_subscription() {
        let expectation = expectation(description: "Subscription handler is called")
        let observable: CustomObservable<Int> = CustomObservable<Int> { _ in
            expectation.fulfill()
            return Subscription { }
        }
        _ = observable.subscribe { _ in }
        waitForDefaultTimeout()
    }

}
