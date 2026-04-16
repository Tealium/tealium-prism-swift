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
        Observable { observer in
            block()
            return self.subscribe(observer)
        }
    }
}

final class OperatorsQueuesTests: XCTestCase {
    let observable123 = Observables.just(1, 2, 3)
    let queue = TealiumQueue(label: "ObservableTestQueue")

    func test_subscribeOn_subscribes_on_provided_queue() {
        let expectation = expectation(description: "Subscribe handler is called")
        let observable = Observable<Void> { [queue] _ in
            dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
            expectation.fulfill()
            return Disposables.disposed()
        }
        _ = observable.subscribeOn(queue)
            .subscribe { }
        waitOnQueue(queue: queue)
    }

    func test_subscribeOn_only_subscribes_prior_operators_on_provided_queue() {
        let expectation = expectation(description: "Subscribe handler is called")
        let replaySubject = ReplaySubject<Void>(())
        let observable = replaySubject.asObservable()

        _ = observable
            .onSubscription { [queue] in
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
        _ = observable123.observeOn(queue)
            .subscribe { [queue] _ in
                dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
                expectation.fulfill()
            }
        waitOnQueue(queue: queue)
    }

    func test_observeOn_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
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

    func test_observeOn_disposes_subscription_when_upstream_is_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")

        let observable = subject.asObservable()
            .first()
            .observeOn(.main)

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 1)
        }
        subject.publish(1)
        subject.publish(2)

        waitForDefaultTimeout()
        XCTAssertTrue(disposable.isDisposed, "ObserveOn should dispose downstream if upstream disposes")
    }

    func test_subscribeOn_disposes_subscription_when_upstream_is_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")

        let observable = subject.asObservable()
            .first()
            .subscribeOn(.main)

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 1)
        }
        subject.publish(1)
        subject.publish(2)

        waitForDefaultTimeout()
        XCTAssertTrue(disposable.isDisposed, "SubscribeOn should dispose downstream if upstream disposes")
    }

    func test_delay_notifies_on_provided_queue() {
        let expectation = expectation(description: "Observer is called")
        expectation.assertForOverFulfill = false
        _ = observable123.delay(1, on: queue)
            .subscribeOn(queue) // For thread safety
            .subscribe { [queue] _ in
                dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
                expectation.fulfill()
            }
        waitForLongTimeout()
    }

    func test_delay_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.delay(0, on: queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        queue.ensureOnQueue {
            pub.publish(1)
        }
        queue.dispatchQueue.sync {
            helper?.subscription?.dispose()
            helper = nil
            waitForDefaultTimeout()
        }
    }

    func test_delay_disposes_subscription_when_upstream_is_disposed() {
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 3
        let observable = observable123
            .delay(0, on: .main)
        var count = 1
        let disposable = observable.subscribe { res in
            print("res", res)
            eventEmitted.fulfill()
            XCTAssertEqual(res, count)
            count += 1
        }

        waitForDefaultTimeout()
        XCTAssertTrue(disposable.isDisposed, "Delay should dispose downstream if upstream disposes")
    }

    func test_delay_does_not_dispose_subscription_when_upstream_is_not_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let observable = subject.asObservable()
            .delay(0, on: .main)

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 1)
        }
        subject.publish(1)

        waitForDefaultTimeout()
        XCTAssertFalse(disposable.isDisposed, "Delay should NOT dispose downstream if upstream does NOT dispose")
    }

    func test_debounce_observes_on_provided_queue() {
        let expectation = expectation(description: "Observer is called")
        expectation.assertForOverFulfill = false
        _ = observable123.debounce(1, on: queue)
            .subscribeOn(queue) // For thread safety
            .subscribe { [queue] _ in
                dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
                expectation.fulfill()
            }
        waitForLongTimeout()
    }

    func test_debounce_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = BasePublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: Observable<Int> = observable.debounce(0, on: queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        queue.ensureOnQueue {
            pub.publish(1)
        }
        queue.dispatchQueue.sync {
            helper?.subscription?.dispose()
            helper = nil
            waitForDefaultTimeout()
        }
    }

    func test_debounce_disposes_subscription_when_upstream_is_disposed() {
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 3
        let observable = observable123
            .debounce(0, on: .main)
        var count = 1
        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, count)
            count += 1
        }

        waitForDefaultTimeout()
        XCTAssertTrue(disposable.isDisposed, "Delay should dispose downstream if upstream disposes")
    }

    func test_debounce_does_not_dispose_subscription_when_upstream_is_not_disposed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let observable = subject.asObservable()
            .debounce(0, on: .main)

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 1)
        }
        subject.publish(1)

        waitOnQueue(queue: queue)
        XCTAssertFalse(disposable.isDisposed, "Delay should NOT dispose downstream if upstream does NOT dispose")
    }

    func test_observeOn_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal { $0.observeOn(.main) }
    }

    func test_subscribeOn_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        let disposable = Disposables.composite()
        let observerCalled = expectation(description: "Observer is called once")
        let observable = NonDisposalCheckingObservable<Int> { observer in
            DispatchQueue.main.async {
                observer(1)
                // The following is a synchronous observer call,
                // done without checking if disposable is already disposed.
                observer(2)
            }
            return Disposables.composite()
        }

        observable.subscribeOn(.main)
            .subscribe { elements in
                if elements == 1 {
                    disposable.dispose()
                }
                observerCalled.fulfill()
            }.addTo(disposable)
        waitForDefaultTimeout()
    }

    func test_debounce_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal { $0.debounce(0, on: .main) }
    }
}
