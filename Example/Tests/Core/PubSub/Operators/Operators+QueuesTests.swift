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

    struct MyObserver: Observer {
        typealias Element = Int
        let completed: XCTestExpectation?
        func onNext(_ element: Int) { }
        func onComplete() {
            completed?.fulfill()
        }
    }

    /// This test is added to verify that ThreadSanitizer won't report a race condition
    /// It should never fail, but will report a race in case observeOn is not thread safe.
    func test_subscribeOn_plus_observeOn_does_not_cause_race_conditions() {
        let subj = StateSubject<Int>(1)
        let completed = expectation(description: "completed")
        _ = subj.asObservable()
            .first()
            .subscribeOn(.worker)
            .observeOn(queue)
            .subscribe(MyObserver(completed: completed))
        waitForLongTimeout()
    }

    /// This test is added to verify that ThreadSanitizer won't report a race condition
    /// It should never fail, but will report a race in case observeOn is not thread safe.
    func test_subscribeOn_plus_observeOn_plus_first_does_not_cause_race_conditions() {
        let subj = StateSubject<Int>(1)
        let completed = expectation(description: "completed")
        _ = subj.asObservable()
            .subscribeOn(.worker)
            .observeOn(queue)
            .first()
            .subscribe(MyObserver(completed: completed))
        waitForLongTimeout()
    }

    /// This test is added to verify that ThreadSanitizer won't report a race condition
    /// It should never fail, but will report a race in case observeOn is not thread safe.
    func test_subscribeOn_plus_observeOn_plus_operators_plus_dispose_on_observedOn_queue_does_not_cause_race_conditions() {
        // This test simulates the common behavior of receiving an observable from a system
        // that works on a different queue (main) and then it's used from within tealium subsystem
        // which observes on it's queue and then later disposes from that same queue.
        let subj = StateSubject<Int>(1)
        let completed = expectation(description: "completed")
        queue.ensureOnQueue { [queue] in
            let disposable = subj.asObservable()
                .first()
                .subscribeOn(.main)
                .observeOn(queue)
                .map { $0 * 10 }
                .subscribe(MyObserver(completed: nil))
            disposable.dispose()
            queue.dispatchQueue.async {
                completed.fulfill()
            }
        }

        waitForLongTimeout()
    }

    /// This test is added to verify that ThreadSanitizer won't report a race condition
    /// It should never fail, but will report a race in case observeOn is not thread safe.
    func test_subscribeOn_plus_observeOn_plus_dispose_on_consumer_queue_does_not_cause_race_conditions() {
        // This test simulates the common behavior of receiving an observable from a system
        // that works on a different queue and then it's used from within tealium subsystem
        // which observes on it's queue and then later disposes from that same queue.
        let subj = StateSubject<Int>(1)
        let completed = expectation(description: "completed")
        queue.ensureOnQueue { [queue] in
            let disposable = subj.asObservable()
                .subscribeOn(.main)
                .observeOn(queue)
                .subscribe(MyObserver(completed: nil))
            disposable.dispose()
            queue.dispatchQueue.async {
                completed.fulfill()
            }
        }
        waitForLongTimeout()
    }

    /// This test is added to verify that ThreadSanitizer won't report a race condition
    /// It should never fail, but will report a race in case observeOn is not thread safe.
    func test_subscribeOn_plus_observeOn_plus_subscribeOn_from_third_queue_does_not_cause_race_conditions() {
        // Simulates the full SDK pattern: some source emits on main (like ApplicationStatusListener), we observe on our queue,
        // then we re-wrap with subscribeOn(queue) before handing to a customer who
        // subscribes and disposes from a third queue using ThreadSafeAnonymousObserver.
        let subj = StateSubject<Int>(1)
        let eventReceived = expectation(description: "event received")
        let completed = expectation(description: "completed")
        let emptied = expectation(description: "Queue was emptied")
        let thirdQueue = DispatchQueue(label: "customer.queue")

        let subscribed = expectation(description: "subscribed")
        let observable = subj.asObservable()
            .first()
            .onSubscription {
                dispatchPrecondition(condition: .onQueue(.main))
                subscribed.fulfill()
            }
            .subscribeOn(.main)
            .observeOn(queue)
            .subscribeOn(queue)

        thirdQueue.async { [queue] in
            observable.subscribe { _ in
                dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
                eventReceived.fulfill()
            } onComplete: {
                dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
                completed.fulfill()
            }
        }
        wait(for: [subscribed], timeout: Self.longTimeout)
        queue.dispatchQueue.async {
            emptied.fulfill()
        }
        wait(for: [eventReceived, completed, emptied], timeout: Self.longTimeout)
    }

    func test_subscribeOn_plus_observeOn_plus_first_does_not_crash() throws {
        try skip("This test succeeds but takes too long. Skipping for reducing test duration.")
        let iterations = 1_000_000
        let completed = expectation(description: "completed")
        completed.expectedFulfillmentCount = iterations
        let deallocated = expectation(description: "deallocated")
        deallocated.expectedFulfillmentCount = iterations
        DispatchQueue.concurrentPerform(iterations: iterations) { number in
            let subj = StateSubject<Int>(1)
            let queue = TealiumQueue(label: "queue_\(number)")
            let otherQueue = TealiumQueue(label: "other_queue_\(number)")
            otherQueue.dispatchQueue.sync {
                let deinitTester = DeinitTester {
                    deallocated.fulfill()
                }
                _ = subj.asObservable()
                    .subscribeOn(queue)
                    .observeOn(otherQueue)
                    .first()
                    .map { [deinitTester] number in
                        _ = deinitTester
                        return number
                    }
                    .subscribe(MyObserver(completed: completed))
            }
        }
        waitForExpectations(timeout: 100)
    }

    func test_subscribeOn_plus_first_does_not_crash() throws {
        try skip("""
This test sporadically crashes. The behavior is not currently supported anyway.
After sub_consentDecisionscribeOn you can only subscribe or you must add an observeOn operator
before appending any sort of additional operators.
""")
        let iterations = 1_000_000
        let completed = expectation(description: "completed")
        completed.expectedFulfillmentCount = iterations
        let deallocated = expectation(description: "deallocated")
        deallocated.expectedFulfillmentCount = iterations
        DispatchQueue.concurrentPerform(iterations: iterations) { number in
            let subj = StateSubject<Int>(1)
            let queue = TealiumQueue(label: "queue_\(number)")
            let deinitTester = DeinitTester {
                deallocated.fulfill()
            }
            _ = subj.asObservable()
                .subscribeOn(queue)
                .first()
                .map { [deinitTester] number in
                    _ = deinitTester
                    return number
                }
                .subscribe(MyObserver(completed: completed))
        }
        waitForExpectations(timeout: 100)
    }
}
