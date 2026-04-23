//
//  ObservableTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 12/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
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
        let observable: Observable<Int> = Observables.create { _ in
            expectation.fulfill()
            return Disposables.disposed()
        }
        _ = observable.subscribe { _ in }
        waitForDefaultTimeout()
    }

    func test_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        let disposable = Disposables.composite()
        let observerCalled = expectation(description: "Observer is called once")
        let observable: Observable<Int> = Observables.create { observer in
            let disposable = Disposables.composite()
            DispatchQueue.main.async {
                observer(1)
                // The following is a synchronous observer call,
                // done without checking if disposable is already disposed.
                observer(2)
            }
            return disposable
        }

        observable.subscribe { number in
            if number == 1 {
                // The disposal that would be caused by a side effect
                disposable.dispose()
            }
            observerCalled.fulfill()
        }.addTo(disposable)
        waitForDefaultTimeout()
    }

}
