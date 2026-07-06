//
//  ThreadSafeAnonymousObserverTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 20/05/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ThreadSafeAnonymousObserverTests: XCTestCase {

    // MARK: - onNext

    func test_onNext_forwards_value_when_not_disposed_or_completed() {
        let received = expectation(description: "onNext forwarded")
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { value in
            XCTAssertEqual(value, 1)
            received.fulfill()
        }, onComplete: { })

        observer.onNext(1)

        waitForDefaultTimeout()
    }

    func test_onNext_does_not_forward_value_when_disposed() {
        let notCalled = expectation(description: "onNext not called")
        notCalled.isInverted = true
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in notCalled.fulfill() }, onComplete: { })
        observer.dispose()

        observer.onNext(1)

        waitForDefaultTimeout()
    }

    func test_onNext_does_not_forward_value_when_completed() {
        let notCalled = expectation(description: "onNext not called after complete")
        notCalled.isInverted = true
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in notCalled.fulfill() }, onComplete: { })
        observer.onComplete()

        observer.onNext(1)

        waitForDefaultTimeout()
    }

    // MARK: - onComplete

    func test_onComplete_invokes_callback() {
        let completed = expectation(description: "onComplete invoked")
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in },
                                                        onComplete: { completed.fulfill() })

        observer.onComplete()

        waitForDefaultTimeout()
    }

    func test_onComplete_disposes_observer_and_upstream() {
        let upstreamDisposed = expectation(description: "upstream disposed")
        let upstream = Subscription { upstreamDisposed.fulfill() }
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        observer.link(upstream)

        observer.onComplete()

        XCTAssertTrue(observer.isDisposed)
        waitForDefaultTimeout()
    }

    func test_onComplete_is_idempotent() {
        let completed = expectation(description: "onComplete called once")
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in },
                                                        onComplete: { completed.fulfill() })

        observer.onComplete()
        observer.onComplete()
        observer.onComplete()

        waitForDefaultTimeout()
    }

    func test_onComplete_does_not_invoke_callback_when_already_disposed() {
        let notCalled = expectation(description: "onComplete not called after dispose")
        notCalled.isInverted = true
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in },
                                                        onComplete: { notCalled.fulfill() })
        observer.dispose()

        observer.onComplete()

        waitForDefaultTimeout()
    }

    // MARK: - dispose / isDisposed

    func test_isDisposed_is_false_before_any_action() {
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in }, onComplete: { })

        XCTAssertFalse(observer.isDisposed)
    }

    func test_isDisposed_is_true_after_dispose() {
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in }, onComplete: { })

        observer.dispose()

        XCTAssertTrue(observer.isDisposed)
    }

    func test_isDisposed_is_true_after_onComplete() {
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in }, onComplete: { })

        observer.onComplete()

        XCTAssertTrue(observer.isDisposed)
    }

    func test_dispose_is_idempotent() {
        let upstreamDisposed = expectation(description: "upstream disposed once")
        let upstream = Subscription { upstreamDisposed.fulfill() }
        let downstream = ThreadSafeAnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        downstream.link(upstream)

        downstream.dispose()
        downstream.dispose()

        waitForDefaultTimeout()
    }

    // MARK: - link

    func test_link_disposes_upstream_when_observer_is_already_disposed() {
        let upstreamDisposed = expectation(description: "upstream disposed immediately")
        let upstream = Subscription { upstreamDisposed.fulfill() }
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        observer.dispose()

        observer.link(upstream)

        waitForDefaultTimeout()
    }

    func test_link_disposes_upstream_on_observer_dispose() {
        let upstreamDisposed = expectation(description: "upstream disposed on observer dispose")
        let upstream = Subscription { upstreamDisposed.fulfill() }
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        observer.link(upstream)

        observer.dispose()

        waitForDefaultTimeout()
    }

    // MARK: - callback release

    func test_callbacks_are_released_after_dispose() {
        var capturedObject: NSObject? = NSObject()
        #if compiler(>=6.2.3)
        weak let weakRef = capturedObject
        #else
        weak var weakRef = capturedObject
        #endif
        let observer = ThreadSafeAnonymousObserver<Int>(
            onNext: { [capturedObject] _ in _ = capturedObject },
            onComplete: { }
        )
        capturedObject = nil
        XCTAssertNotNil(weakRef, "Closure should still retain the object before disposal")

        observer.dispose()

        XCTAssertNil(weakRef, "dispose() must nil callbacks, releasing captured references")
    }

    func test_callbacks_are_released_after_onComplete() {
        var capturedObject: NSObject? = NSObject()
        #if compiler(>=6.2.3)
        weak let weakRef = capturedObject
        #else
        weak var weakRef = capturedObject
        #endif
        let observer = ThreadSafeAnonymousObserver<Int>(
            onNext: { [capturedObject] _ in _ = capturedObject },
            onComplete: { }
        )
        capturedObject = nil
        XCTAssertNotNil(weakRef, "Closure should still retain the object before completion")

        observer.onComplete()

        XCTAssertNil(weakRef, "onComplete() must nil callbacks, releasing captured references")
    }

    // MARK: - thread safety

    func test_thread_safety_concurrent_onNext_and_dispose_does_not_crash() {
        let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        for num in 0..<100 {
            group.enter()
            queue.async {
                if num.isMultiple(of: 2) {
                    observer.onNext(num)
                } else {
                    observer.dispose()
                }
                group.leave()
            }
        }

        group.wait()
        XCTAssertTrue(observer.isDisposed)
    }

    func test_thread_safety_concurrent_link_and_onComplete_always_disposes_upstream() {
        for _ in 0..<50 {
            let upstreamDisposed = expectation(description: "upstream disposed")
            let upstream = Subscription { upstreamDisposed.fulfill() }
            let observer = ThreadSafeAnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
            let group = DispatchGroup()

            group.enter()
            DispatchQueue.global().async {
                observer.link(upstream)
                group.leave()
            }
            group.enter()
            DispatchQueue.global().async {
                observer.onComplete()
                group.leave()
            }

            group.wait()
        }

        waitForDefaultTimeout()
    }
}
