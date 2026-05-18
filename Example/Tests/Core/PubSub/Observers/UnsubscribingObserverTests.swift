//
//  UnsubscribingObserverTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 20/05/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class UnsubscribingObserverTests: XCTestCase {

    // MARK: - onNext

    func test_onNext_forwards_value_to_delegate() {
        let received = expectation(description: "onNext forwarded")
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { value in
            XCTAssertEqual(value, 42)
            received.fulfill()
        }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)

        observer.onNext(42)

        waitForDefaultTimeout()
    }

    func test_onNext_does_not_forward_after_disposal() {
        let notCalled = expectation(description: "onNext not called after disposal")
        notCalled.isInverted = true
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in notCalled.fulfill() }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)
        observer.dispose()

        observer.onNext(1)

        waitForDefaultTimeout()
    }

    func test_onNext_does_not_forward_after_completion() {
        let notCalled = expectation(description: "onNext not called after completion")
        notCalled.isInverted = true
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in notCalled.fulfill() }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)
        observer.onComplete()

        observer.onNext(1)

        waitForDefaultTimeout()
    }

    // MARK: - onComplete

    func test_onComplete_forwards_to_delegate() {
        let completed = expectation(description: "onComplete forwarded")
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { completed.fulfill() })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)

        observer.onComplete()

        waitForDefaultTimeout()
    }

    func test_onComplete_disposes_observer() {
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)

        observer.onComplete()

        XCTAssertTrue(observer.isDisposed)
    }

    func test_onComplete_removes_self_from_owner() {
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)
        container.add(observer)
        XCTAssertEqual(container.count, 1)

        observer.onComplete()

        XCTAssertEqual(container.count, 0)
    }

    func test_onComplete_disposes_upstream() {
        let upstreamDisposed = expectation(description: "upstream disposed on completion")
        let container = DisposableContainer()
        let upstream = Subscription { upstreamDisposed.fulfill() }
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)
        observer.setUpstream(upstream)

        observer.onComplete()

        waitForDefaultTimeout()
    }

    func test_onComplete_is_idempotent() {
        let completed = expectation(description: "onComplete called once")
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: {
            completed.fulfill()
        })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)

        observer.onComplete()
        observer.onComplete()

        waitForDefaultTimeout()
    }

    func test_onComplete_does_not_forward_when_already_disposed() {
        let notCalled = expectation(description: "onComplete not forwarded after disposal")
        notCalled.isInverted = true
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { notCalled.fulfill() })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)
        observer.dispose()

        observer.onComplete()

        waitForDefaultTimeout()
    }

    // MARK: - dispose

    func test_dispose_removes_self_from_owner() {
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)
        container.add(observer)
        XCTAssertEqual(container.count, 1)

        observer.dispose()

        XCTAssertEqual(container.count, 0)
    }

    func test_dispose_disposes_upstream() {
        let upstreamDisposed = expectation(description: "upstream disposed")
        let container = DisposableContainer()
        let upstream = Subscription { upstreamDisposed.fulfill() }
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)
        observer.setUpstream(upstream)

        observer.dispose()

        waitForDefaultTimeout()
    }

    func test_dispose_is_idempotent() {
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)
        container.add(observer)

        observer.dispose()
        observer.dispose()

        XCTAssertTrue(observer.isDisposed)
        XCTAssertEqual(container.count, 0)
    }

    func test_delegate_is_released_after_dispose() {
        var downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = UnsubscribingObserver(owner: DisposableContainer(), delegate: downstream)
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

    func test_delegate_is_released_after_onComplete() {
        var downstream = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = UnsubscribingObserver(owner: DisposableContainer(), delegate: downstream)
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

    // MARK: - isDisposed

    func test_isDisposed_is_false_initially() {
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)

        XCTAssertFalse(observer.isDisposed)
    }

    func test_isDisposed_is_true_after_dispose() {
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)

        observer.dispose()

        XCTAssertTrue(observer.isDisposed)
    }

    func test_isDisposed_is_true_after_onComplete() {
        let container = DisposableContainer()
        let delegate = AnonymousObserver<Int>(onNext: { _ in }, onComplete: { })
        let observer = UnsubscribingObserver(owner: container, delegate: delegate)

        observer.onComplete()

        XCTAssertTrue(observer.isDisposed)
    }
}
