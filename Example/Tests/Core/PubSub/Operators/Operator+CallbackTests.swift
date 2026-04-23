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

    func test_callback_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal {
            $0.callback(fromDisposable: { number, observer in
                observer(number)
                return Disposables.composite()
            })
        }
    }

    /// Verifies that the non-disposable `callback` overload (fire-and-forget) still guards
    /// downstream delivery when disposed before the callback fires. The async block has no
    /// upstream disposable to cancel — the `CallbackObserver`'s `isStopped` guard is what
    /// prevents the late `observer(value)` call from reaching the subscriber.
    func test_callback_fire_and_forget_does_not_emit_after_disposal() {
        let emissionsNotReceived = expectation(description: "Emission not received after dispose")
        emissionsNotReceived.isInverted = true
        let callbackFired = expectation(description: "Async callback still fires")
        callbackFired.expectedFulfillmentCount = 3
        let disposable = observable123.callback { number, observer in
            DispatchQueue.main.async {
                observer(number)
                callbackFired.fulfill()
            }
        }.subscribe { _ in
            emissionsNotReceived.fulfill()
        }
        disposable.dispose()
        wait(for: [callbackFired], timeout: Self.defaultTimeout)
        waitForDefaultTimeout()
    }

    /// Exercises `CallbackObserver.onNext` — after delivering the value it must call downstream
    /// `onComplete` so the `flatMap`-wrapped outer observable can track inner completion.
    func test_callback_completes_downstream_after_emitting_value() {
        let emitted = expectation(description: "Value emitted")
        let completed = expectation(description: "Downstream receives onComplete")
        _ = Observables.just(1).callback { number, observer in
            observer(number)
        }.subscribe { _ in
            emitted.fulfill()
        } onComplete: {
            completed.fulfill()
        }
        wait(for: [emitted, completed], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    /// Exercises `CallbackObserver.onComplete` directly from the block side — the public
    /// `Observables.callback` factory only exposes an `onNext` closure, but the internal
    /// `CallbackObservable` block receives an `any Observer<Element>` that can complete
    /// without ever emitting. Downstream must still receive the completion signal.
    func test_CallbackObservable_completes_downstream_when_block_calls_onComplete_without_onNext() {
        let emissionsNotReceived = expectation(description: "No value is received")
        emissionsNotReceived.isInverted = true
        let completed = expectation(description: "Downstream receives onComplete")
        _ = CallbackObservable<Int> { observer in
            observer.onComplete()
            return Disposables.disposed()
        }.subscribe { _ in
            emissionsNotReceived.fulfill()
        } onComplete: {
            completed.fulfill()
        }
        waitForDefaultTimeout()
    }

    /// Exercises `CallbackObserver.onComplete`'s `isStopped` guard — after a successful
    /// `onNext`, the observer has already completed and disposed itself. A subsequent explicit
    /// `onComplete` from the block must not fire downstream a second time.
    func test_CallbackObservable_subsequent_onComplete_from_block_is_ignored_after_onNext() {
        let completed = expectation(description: "onComplete fires exactly once")
        completed.expectedFulfillmentCount = 1
        completed.assertForOverFulfill = true
        _ = CallbackObservable<Int> { observer in
            observer.onNext(1)
            observer.onComplete() // second completion — should be dropped by isStopped
            return Disposables.disposed()
        }.subscribe { _ in } onComplete: {
            completed.fulfill()
        }
        waitForDefaultTimeout()
    }
}
