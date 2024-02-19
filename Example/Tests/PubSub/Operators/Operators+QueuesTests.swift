//
//  Operators+QueuesTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

final class OperatorsQueuesTests: XCTestCase {
    let observable123 = TealiumObservable.Just(1, 2, 3)

    func test_subscribeOn_subscribes_on_provided_queue() {
        let expectation = expectation(description: "Subscribe handler is called")
        let queue = DispatchQueue(label: "ObservableTestQueue")
        let observable = TealiumObservableCreate<Void> { _ in
            dispatchPrecondition(condition: .onQueue(queue))
            expectation.fulfill()
            return TealiumSubscription { }
        }
        _ = observable.subscribeOn(queue)
            .subscribe { }
        queue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }

    func test_subscribeOn_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let queue = DispatchQueue(label: "ObservableTestQueue")
        let generatedObservable: TealiumObservable<Int> = observable.subscribeOn(queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        queue.sync {
            pub.publish(1)
        }
        helper?.subscription?.dispose()
        helper = nil
        queue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }

    func test_subscribeOn_subscription_dispose_immediately_disposes_underlying_subscription() {
        let notPublished = expectation(description: "Even not published to the observer")
        notPublished.isInverted = true
        let pub = TealiumReplaySubject<Int>(initialValue: 1)
        let observable = pub.asObservable()
        let queue = DispatchQueue.main // So that the subscription is delayed after the end of this function
        let generatedObservable: TealiumObservable<Int> = observable.subscribeOn(queue)
        let subscription = generatedObservable.subscribe { _ in
            notPublished.fulfill()
        }
        subscription.dispose()
        waitForExpectations(timeout: 1.0)
    }

    func test_observeOn_observes_on_provided_queue() {
        let expectation = expectation(description: "Observer is called")
        expectation.assertForOverFulfill = false
        let queue = DispatchQueue(label: "ObservableTestQueue")
        _ = observable123.observeOn(queue)
            .subscribe { _ in
                dispatchPrecondition(condition: .onQueue(queue))
                expectation.fulfill()
            }
        queue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }

    func test_observeOn_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let queue = DispatchQueue(label: "ObservableTestQueue")
        let generatedObservable: TealiumObservable<Int> = observable.observeOn(queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        queue.sync {
            helper?.subscription?.dispose()
            helper = nil
            waitForExpectations(timeout: 1.0)
        }
    }

    func test_observeOn_subscription_dispose_immediately_disposes_underlying_subscription() {
        let notPublished = expectation(description: "Even not published to the observer")
        notPublished.isInverted = true
        let pub = TealiumReplaySubject<Int>(initialValue: 1)
        let observable = pub.asObservable()
        let queue = DispatchQueue.main // So that the subscription is delayed after the end of this function
        let generatedObservable: TealiumObservable<Int> = observable.observeOn(queue)
        let subscription = generatedObservable.subscribe { _ in
            notPublished.fulfill()
        }
        subscription.dispose()
        waitForExpectations(timeout: 1.0)
    }
}
