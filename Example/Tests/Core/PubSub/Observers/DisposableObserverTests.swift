//
//  DisposableObserverTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 20/05/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DisposableObserverTests: XCTestCase {

    // MARK: - onNext

    func test_onNext_forwards_value_to_downstream() {
        let received = expectation(description: "onNext forwarded")
        let downstream = AnonymousObserver<Int>(onNext: { value in
            XCTAssertEqual(value, 42)
            received.fulfill()
        }, onComplete: { })
        let observer = DisposableObserver(downstream: downstream)

        observer.onNext(42)

        waitForDefaultTimeout()
    }

    func test_onNext_does_not_forward_after_completion() {
        let notCalled = expectation(description: "onNext not called after completion")
        notCalled.isInverted = true
        let downstream = AnonymousObserver<Int>(onNext: { _ in notCalled.fulfill() }, onComplete: { })
        let observer = DisposableObserver(downstream: downstream)
        observer.onComplete()

        observer.onNext(1)

        waitForDefaultTimeout()
    }

    func test_onNext_does_not_forward_after_disposal() {
        let notCalled = expectation(description: "onNext not called after disposal")
        notCalled.isInverted = true
        let downstream = AnonymousObserver<Int>(onNext: { _ in notCalled.fulfill() }, onComplete: { })
        let observer = DisposableObserver(downstream: downstream)
        observer.dispose()

        observer.onNext(1)

        waitForDefaultTimeout()
    }

    // MARK: - onComplete

    func test_onComplete_forwards_to_downstream() {
        let completed = expectation(description: "onComplete forwarded")
        let downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { completed.fulfill() })
        let observer = DisposableObserver(downstream: downstream)

        observer.onComplete()

        waitForDefaultTimeout()
    }

    func test_onComplete_disposes_observer() {
        let downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = DisposableObserver(downstream: downstream)

        observer.onComplete()

        XCTAssertTrue(observer.isDisposed)
        XCTAssertTrue(observer.isCompleted)
    }

    func test_onComplete_disposes_upstream() {
        let upstreamDisposed = expectation(description: "upstream disposed on completion")
        let upstream = Subscription { upstreamDisposed.fulfill() }
        let downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = DisposableObserver(downstream: downstream)
        observer.link(upstream)

        observer.onComplete()

        waitForDefaultTimeout()
    }

    func test_onComplete_is_idempotent() {
        let completed = expectation(description: "onComplete called once")
        let downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: {
            completed.fulfill()
        })
        let observer = DisposableObserver(downstream: downstream)

        observer.onComplete()
        observer.onComplete()

        waitForDefaultTimeout()
    }

    func test_onComplete_does_not_forward_when_already_disposed() {
        let notCalled = expectation(description: "onComplete not forwarded after disposal")
        notCalled.isInverted = true
        let downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { notCalled.fulfill() })
        let observer = DisposableObserver(downstream: downstream)
        observer.dispose()

        observer.onComplete()

        waitForDefaultTimeout()
    }

    // MARK: - dispose / isDisposed

    func test_isDisposed_is_false_initially() {
        let downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = DisposableObserver(downstream: downstream)

        XCTAssertFalse(observer.isDisposed)
    }

    func test_isDisposed_is_true_after_dispose() {
        let downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = DisposableObserver(downstream: downstream)

        observer.dispose()

        XCTAssertTrue(observer.isDisposed)
    }

    func test_dispose_is_idempotent() {
        let upstreamDisposed = expectation(description: "upstream disposed once")
        let upstream = Subscription { upstreamDisposed.fulfill() }
        let downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = DisposableObserver(downstream: downstream)
        observer.link(upstream)

        observer.dispose()
        observer.dispose()

        waitForDefaultTimeout()
    }

    func test_downstream_is_released_after_dispose() {
        var downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = DisposableObserver(downstream: downstream)
        #if compiler(>=6.2.3)
        weak let weakRef = downstream
        #else
        weak var weakRef = downstream
        #endif

        downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { }) // Replace old one
        XCTAssertNotNil(weakRef, "Observer should still retain the downstream before disposal")

        observer.dispose()

        XCTAssertNil(weakRef, "dispose() must nil downstream")
    }

    func test_downstream_is_released_after_onComplete() {
        var downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = DisposableObserver(downstream: downstream)
        #if compiler(>=6.2.3)
        weak let weakRef = downstream
        #else
        weak var weakRef = downstream
        #endif
        downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { }) // Replace old one
        XCTAssertNotNil(weakRef, "Observer should still retain the downstream before completion")

        observer.onComplete()

        XCTAssertNil(weakRef, "onComplete() must nil downstreal")
    }

    // MARK: - link

    func test_link_disposes_upstream_when_already_disposed() {
        let upstreamDisposed = expectation(description: "upstream disposed immediately")
        let upstream = Subscription { upstreamDisposed.fulfill() }
        let downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = DisposableObserver(downstream: downstream)
        observer.dispose()

        observer.link(upstream)

        waitForDefaultTimeout()
    }
}
