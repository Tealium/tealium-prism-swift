//
//  Operators+QueuesTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

private extension Observable {
    func onSubscription(block: @escaping () -> Void) -> Observable<Element> {
        CustomObservable { observer in
            block()
            return self.subscribe(observer)
        }
    }
}

final class OperatorsQueuesTests: XCTestCase {
    let observable123 = Observable.Just(1, 2, 3)

    func test_subscribeOn_subscribes_on_provided_queue() {
        let expectation = expectation(description: "Subscribe handler is called")
        let queue = TealiumQueue(label: "ObservableTestQueue")
        let observable = CustomObservable<Void> { _ in
            dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
            expectation.fulfill()
            return Subscription { }
        }
        _ = observable.subscribeOn(queue)
            .subscribe { }
        waitOnQueue(queue: queue)
    }

    func test_subscribeOn_only_subscribes_prior_operators_on_provided_queue() {
        let expectation = expectation(description: "Subscribe handler is called")
        let queue = TealiumQueue(label: "ObservableTestQueue")
        let replaySubject = ReplaySubject<Void>(initialValue: ())
        let observable = replaySubject.asObservable()

        _ = observable
            .onSubscription {
                dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
            }
            .subscribeOn(queue)
            .subscribe {
                expectation.fulfill()
            }
        waitOnQueue(queue: queue)
    }

    func test_subscribeOn_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let queue = TealiumQueue(label: "ObservableTestQueue")
        let generatedObservable: any Subscribable<Int> = observable.subscribeOn(queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable.asObservable(), onDeinit: {
            expectation.fulfill()
        })
        queue.dispatchQueue.sync {
            pub.publish(1)
        }
        helper?.subscription?.dispose()
        helper = nil
        waitOnQueue(queue: queue)
    }

    func test_observeOn_observes_on_provided_queue() {
        let expectation = expectation(description: "Observer is called")
        expectation.assertForOverFulfill = false
        let queue = TealiumQueue(label: "ObservableTestQueue")
        _ = observable123.observeOn(queue)
            .subscribe { _ in
                dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
                expectation.fulfill()
            }
        waitOnQueue(queue: queue)
    }

    func test_observeOn_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let queue = TealiumQueue(label: "ObservableTestQueue")
        let generatedObservable: Observable<Int> = observable.observeOn(queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        queue.dispatchQueue.sync {
            helper?.subscription?.dispose()
            helper = nil
            waitForDefaultTimeout()
        }
    }
}
