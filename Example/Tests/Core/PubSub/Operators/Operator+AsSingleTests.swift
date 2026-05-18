//
//  Operator+AsSingleTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 11/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class OperatorAsSingleTests: XCTestCase {

    let observable123 = Observables.just(1, 2, 3)

    func test_asSingle_returns_only_first_event() {
        let expectation = expectation(description: "Only first event is reported")
        _ = observable123.asSingle(queue: .main)
            .subscribe { _ in
                expectation.fulfill()
            }

        waitForDefaultTimeout()
    }

    func test_asSingle_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable = observable.asSingle(queue: .main)
        var helper: SubscriptionRetainCycleHelper<Observable<Int>>?
        helper = SubscriptionRetainCycleHelper(subscribable: generatedObservable.asObservable(),
                                               onDeinit: { expectation.fulfill() })
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

    func test_asSingle_cleans_retain_cycles_after_first_event() {
        let expectation = expectation(description: "Retain Cycle removed")
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable: Observable<Int> = observable.asSingle(queue: .main).asObservable()
        _ = SubscriptionRetainCycleHelper(subscribable: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        subject.onNext(1)
        waitForDefaultTimeout()
    }

    func test_asSingle_emits_events_on_given_queue() {
        let expectation = expectation(description: "Event emitted")
        let queue = TealiumQueue.worker
        _ = observable123.asSingle(queue: queue)
            .subscribe { _ in
                dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
                expectation.fulfill()
            }
        queue.dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }
}
