//
//  TealiumObservableCreateTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumObservableCreateTests: XCTestCase {

    func test_Just_observable_publishes_parameters_as_events() {
        let expectations = [
            expectation(description: "Event 0 is published"),
            expectation(description: "Event 1 is published"),
            expectation(description: "Event 2 is published"),
        ]
        let observable = TealiumObservable<Int>.Just(0, 1, 2)
        _ = observable.subscribe { number in
                expectations[number].fulfill()
        }
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }

    func test_Callback_observable_transforms_a_function_with_callback_into_an_observable() {
        let expectation = expectation(description: "Event is published")
        let dispatchQueue = DispatchQueue(label: "ObservableTestQueue")
        func anAsyncFunctionWithACallback(callback: @escaping (Int) -> Void) {
            dispatchQueue.async {
                callback(1)
            }
        }
        let observable = TealiumObservable<Int>.Callback(from: anAsyncFunctionWithACallback(callback:))
        _ = observable.subscribe { number in
            XCTAssertEqual(number, 1)
            expectation.fulfill()
        }

        dispatchQueue.sync {
            waitForExpectations(timeout: 2.0)
        }
    }

}
