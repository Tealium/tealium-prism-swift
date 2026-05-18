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
        Observables.create { observer in
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
        let observable: Observable<Void> = Observables.create { [queue] _ in
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
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable: any Subscribable<Int> = observable.subscribeOn(queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(subscribable: generatedObservable.asObservable(), onDeinit: {
            expectation.fulfill()
        })
        queue.dispatchQueue.sync {
            subject.onNext(1)
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
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable: Observable<Int> = observable.observeOn(queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(subscribable: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        subject.onNext(1)
        queue.dispatchQueue.sync {
            helper?.subscription?.dispose()
            helper = nil
            waitForDefaultTimeout()
        }
    }

    func test_observeOn_completes_when_upstream_is_completed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let completed = expectation(description: "Observable completed")

        let observable = subject.asObservable()
            .first()
            .observeOn(.main)

        _ = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 1)
        } onComplete: {
            completed.fulfill()
        }
        subject.onNext(1)
        subject.onNext(2)

        waitForDefaultTimeout()
    }

    func test_subscribeOn_completes_subscription_when_upstream_is_completed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let completed = expectation(description: "Observable completed")
        let observable = subject.asObservable()
            .first()
            .subscribeOn(.main)

        _ = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 1)
        } onComplete: {
            completed.fulfill()
        }
        subject.onNext(1)
        subject.onNext(2)

        waitForDefaultTimeout()
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
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable: Observable<Int> = observable.delay(0, on: queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(subscribable: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        queue.ensureOnQueue {
            subject.onNext(1)
        }
        queue.dispatchQueue.sync {
            helper?.subscription?.dispose()
            helper = nil
            waitForDefaultTimeout()
        }
    }

    func test_delay_completes_subscription_when_upstream_is_completed() {
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 3
        let completed = expectation(description: "Observable completed")
        let observable = observable123
            .delay(0, on: .main)
        var count = 1
        _ = observable.subscribe { res in
            print(res)
            eventEmitted.fulfill()
            XCTAssertEqual(res, count)
            count += 1
        } onComplete: {
            completed.fulfill()
        }
        waitForLongTimeout()
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
        subject.onNext(1)

        waitForDefaultTimeout()
        XCTAssertFalse(disposable.isDisposed, "Delay should NOT dispose downstream if upstream does NOT dispose")
    }

    func test_debounce_emits_only_last_element_of_a_quick_sequence_when_there_is_a_delay() {
        let expectation = expectation(description: "Observer is called")
        _ = observable123.debounce(10, on: queue)
            .subscribeOn(queue) // For thread safety
            .subscribe { element in
                XCTAssertEqual(element, 3)
                expectation.fulfill()
            }
        waitForLongTimeout()
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
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable: Observable<Int> = observable.debounce(0, on: queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(subscribable: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        queue.ensureOnQueue {
            subject.onNext(1)
        }
        queue.dispatchQueue.sync {
            helper?.subscription?.dispose()
            helper = nil
            waitForDefaultTimeout()
        }
    }

    func test_debounce_completes_when_upstream_has_completed() {
        let eventEmitted = expectation(description: "Event is emitted")
        let completed = expectation(description: "Observable completed")
        eventEmitted.expectedFulfillmentCount = 3
        let observable = observable123
            .debounce(0, on: .main)
        var count = 1
        _ = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, count)
            count += 1
        } onComplete: {
            completed.fulfill()
        }

        waitForDefaultTimeout()
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
        subject.onNext(1)

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
                observer.onNext(1)
                // The following is a synchronous observer call,
                // done without checking if disposable is already disposed.
                observer.onNext(2)
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
