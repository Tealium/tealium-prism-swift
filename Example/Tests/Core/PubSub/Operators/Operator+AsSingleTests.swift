//
//  Operator+AsSingleTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 11/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class OperatorAsSingleTests: XCTestCase {

    let observable123 = Observable.Just(1, 2, 3)

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
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable = observable.asSingle(queue: .main)
        var helper: SubscriptionRetainCycleHelper<Observable<Int>>?
        helper = SubscriptionRetainCycleHelper(publisher: generatedObservable.asObservable(),
                                               onDeinit: { expectation.fulfill() })
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

    func test_asSingle_cleans_retain_cycles_after_first_event() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.asSingle(queue: .main).asObservable()
        _ = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
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
