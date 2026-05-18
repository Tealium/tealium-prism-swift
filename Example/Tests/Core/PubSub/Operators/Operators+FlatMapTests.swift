//
//  Operators+FlatMapTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

struct EmptyObserver<Element>: Observer {
    func onNext(_ element: Element) { }

    func onComplete() { }
}

final class OperatorsFlatMapTests: XCTestCase {
    let observable123 = Observables.just(1, 2, 3)

    func test_flatMap_returns_new_observables_flattening_it() {
        let flatMappedEventIsCalled = expectation(description: "FlatMapped event is called 3 times")
        flatMappedEventIsCalled.expectedFulfillmentCount = 3
        _ = observable123.flatMap { _ in
            Observables.just("flatMapped")
        }.subscribe { event in
            XCTAssertEqual(event, "flatMapped")
            flatMappedEventIsCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_flatMap_emits_events_form_all_returned_observables() {
        let flatMappedEventIsCalled = expectation(description: "FlatMapped event is called 3 times")
        flatMappedEventIsCalled.expectedFulfillmentCount = 3
        _ = observable123.flatMap { element in
            Observables.callback { completion in
                DispatchQueue.main.async {
                    completion(element)
                }
            }
        }.subscribe { _ in
            flatMappedEventIsCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_only_emits_events_from_latest_returned_observable() {
        let flatMappedEventIsCalled = expectation(description: "FlatMapped event is called only once")
        _ = observable123.flatMapLatest { element in
            Observables.callback { observer in
                DispatchQueue.main.async {
                    observer(element)
                }
            }
        }.subscribe { element in
            XCTAssertEqual(element, 3)
            flatMappedEventIsCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_flatMap_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let subject = Subject<Int>()
        let observable = subject.asObservable()
        let generatedObservable: Observable<Int> = observable.flatMap { _ in Observables.just(2) }
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(subscribable: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        subject.onNext(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_disposes_previous_subscriptions_when_reentrant_emission_occurs() {
        let observerCalled = expectation(description: "Observer called")
        let subject = Subject<Int>()
        let innerSubject1 = Subject<Int>()
        let innerSubject2 = Subject<Int>()
        _ = subject.asObservable().flatMapLatest { value in
            if value == 1 {
                subject.onNext(2)
                subject.onNext(3)
                subject.onNext(4)
                return innerSubject1.asObservable()
            } else {
                return innerSubject2.asObservable()
            }
        }.subscribe { value in
            XCTAssertEqual(value, 200)
            observerCalled.fulfill()
        }
        subject.onNext(1)
        innerSubject1.onNext(100)
        innerSubject2.onNext(200)
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_doesnt_drop_legitimate_nil_values() {
        let observerCalled = expectation(description: "Observer called")
        let subject = Subject<Int?>()
        _ = subject.asObservable().flatMapLatest { _ in
            Observables.just(200)
        }.subscribe { value in
            XCTAssertEqual(value, 200)
            observerCalled.fulfill()
        }
        subject.onNext(nil)
        waitForDefaultTimeout()
    }

    func test_flatMap_does_not_dispose_subscription_when_upstream_is_disposed_but_downstream_is_not() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let other = StateSubject<Int>(5)
        let observable = subject.asObservable()
            .first()
            .flatMap { _ in other.asObservable() }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 5)
        }
        subject.onNext(1)
        subject.onNext(2)

        XCTAssertFalse(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMap_does_not_dispose_subscription_when_downstream_is_disposed_but_upstream_is_not() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 2
        let observable = subject.asObservable()
            .flatMap { Observables.just($0 + $0) }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 2)
        }
        subject.onNext(1)
        subject.onNext(1)

        XCTAssertFalse(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMap_completes_after_upstream_and_all_of_downstreams_have_completed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 2
        let completed = expectation(description: "FlatMap completed")
        let observable0 = subject.asObservable()
        let observable1 = subject.asObservable().first(where: { $0 == 3 })
        let observable2 = subject.asObservable().first()

        let observable = observable0
            .takeWhile({ $0 < 3 }, inclusive: false)
            .flatMap {
                if $0 == 1 {
                    observable1
                } else {
                    observable2
                }
            }

        _ = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 3)
        } onComplete: {
            completed.fulfill()
        }
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        waitForDefaultTimeout()
    }

    func test_flatMap_completes_when_upstream_and_downstream_have_completed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let completed = expectation(description: "Observable completed")
        let observable = subject.asObservable()
            .first()
            .flatMap { Observables.just($0 + $0) }

        _ = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 2)
        } onComplete: {
            completed.fulfill()
        }
        subject.onNext(1)
        subject.onNext(5)

        waitForDefaultTimeout()
    }

    func test_flatMap_completes_when_upstream_completes_without_emitting() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is not emitted")
        eventEmitted.isInverted = true
        let completed = expectation(description: "Observable completed")
        let observable = subject.asObservable()
            .flatMap { _ in subject.asObservable() }
        _ = observable.subscribe { _ in
            eventEmitted.fulfill()
        } onComplete: {
            completed.fulfill()
        }
        subject.onComplete()

        waitForDefaultTimeout()
    }

    func test_flatMap_inner_subscription_is_removed_from_container_on_completion() {
        let outer = Subject<Int>()
        let inner = Subject<Int>()
        let observable = outer.asObservable().flatMap { _ in inner.asObservable() }
        guard let container = observable.subscribe(EmptyObserver()) as? DisposableContainer else {
            XCTFail("flatMap is expected to return a DisposableContainer as its subscription Disposable")
            return
        }
        // 1 entry: the upstream subscription (FlatMapObserver)
        XCTAssertEqual(container.count, 1)
        outer.onNext(1)
        // 2 entries: upstream + inner UnsubscribingObserver
        XCTAssertEqual(container.count, 2)
        inner.onComplete()
        // Back to 1: inner removed itself
        XCTAssertEqual(container.count, 1)
    }

    func test_flatMapLatest_does_not_dispose_subscription_when_upstream_is_disposed_but_downstream_is_not() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let other = StateSubject<Int>(5)
        let observable = subject.asObservable()
            .first()
            .flatMapLatest { _ in other.asObservable() }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 5)
        }
        subject.onNext(1)
        subject.onNext(2)

        XCTAssertFalse(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_does_not_dispose_subscription_when_downstream_is_disposed_but_upstream_is_not() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        eventEmitted.expectedFulfillmentCount = 2
        let observable = subject.asObservable()
            .flatMapLatest { Observables.just($0 + $0) }

        let disposable = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 2)
        }
        subject.onNext(1)
        subject.onNext(1)

        XCTAssertFalse(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_completes_after_upstream_and_all_of_downstreams_have_completed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let completed = expectation(description: "Observable completed")
        let observable0 = subject.asObservable()
        let observable1 = subject.asObservable().first(where: { $0 == 3 })
        let observable2 = subject.asObservable().first()

        let observable = observable0
            .takeWhile({ $0 < 3 }, inclusive: false)
            .flatMapLatest {
                if $0 == 1 {
                    observable1
                } else {
                    observable2
                }
            }

        _ = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 3)
        } onComplete: {
            completed.fulfill()
        }
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        waitForDefaultTimeout()
    }

    func test_flatMapLatest_completes_when_upstream_and_downstream_have_completed() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is emitted")
        let completed = expectation(description: "Observable completed")
        let observable = subject.asObservable()
            .first()
            .flatMapLatest { Observables.just($0 + $0) }

        _ = observable.subscribe { res in
            eventEmitted.fulfill()
            XCTAssertEqual(res, 2)
        } onComplete: {
            completed.fulfill()
        }
        subject.onNext(1)
        subject.onNext(2)
        waitForDefaultTimeout()
    }

    func test_flatMap_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal { $0.flatMap { Observables.just($0) } }
    }

    func test_flatMapLatest_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal { $0.flatMapLatest { Observables.just($0) } }
    }

    func test_flatMapLatest_completes_when_upstream_completes_without_emitting() {
        let subject = Subject<Int>()
        let eventEmitted = expectation(description: "Event is not emitted")
        eventEmitted.isInverted = true
        let completed = expectation(description: "Observable completed")
        let observable = subject.asObservable()
            .flatMapLatest { _ in subject.asObservable() }
        _ = observable.subscribe { _ in
            eventEmitted.fulfill()
        } onComplete: {
            completed.fulfill()
        }
        subject.onComplete()

        waitForDefaultTimeout()
    }

    /// Exercises the while-loop in `FlatMapLatestObserver.onNext`: each inner observable,
    /// on subscribe, synchronously re-emits upstream before emitting. The loop must
    /// drain `latestElement` across every re-entry so all three inner subscriptions run
    /// in sequence without the operator losing or duplicating events.
    func test_flatMapLatest_handles_reentrant_synchronous_reemits_from_inner_subscription() {
        let emitted = expectation(description: "Each inner subscription emits once")
        emitted.expectedFulfillmentCount = 3
        let completed = expectation(description: "Observable completed")
        let subject = Subject<Int>()
        var received = [Int]()
        _ = subject.asObservable().flatMapLatest { value -> Observable<Int> in
            Observables.create { observer in
                if value < 3 {
                    subject.onNext(value + 1)
                }
                observer.onNext(value * 10)
                observer.onComplete()
                return Disposables.disposed()
            }
        }.subscribe { value in
            received.append(value)
            emitted.fulfill()
        } onComplete: {
            completed.fulfill()
        }
        subject.onNext(1)
        subject.onComplete()
        waitForDefaultTimeout()
        XCTAssertEqual(received, [10, 20, 30])
    }

    /// Verifies that the container never accumulates more than one inner entry during reentrant
    /// synchronous re-emission: each inner observable completes synchronously before the next
    /// `subscribe(composite:observer:)` call registers it, so the container stays at count 1.
    func test_flatMapLatest_container_count_stays_at_one_during_reentrant_synchronous_reemit() {
        let subject = Subject<Int>()
        let observable = subject.asObservable().flatMapLatest { value -> Observable<Int> in
            Observables.create { observer in
                if value < 3 {
                    subject.onNext(value + 1)
                }
                observer.onNext(value * 10)
                observer.onComplete()
                return Disposables.disposed()
            }
        }
        guard let container = observable.subscribe(EmptyObserver()) as? DisposableContainer else {
            XCTFail("flatMapLatest is expected to return a DisposableContainer as its subscription Disposable")
            return
        }
        // 1 entry: upstream FlatMapLatestObserver
        XCTAssertEqual(container.count, 1)
        subject.onNext(1)
        // All three inner observables completed synchronously and self-removed; back to 1
        XCTAssertEqual(container.count, 1)
    }

    func test_flatMapLatest_inner_subscription_is_removed_from_container_on_completion() {
        let outer = Subject<Int>()
        let inner = Subject<Int>()
        let observable = outer.asObservable().flatMapLatest { _ in inner.asObservable() }
        guard let container = observable.subscribe(EmptyObserver()) as? DisposableContainer else {
            XCTFail("flatMapLatest is expected to return a DisposableContainer as its subscription Disposable")
            return
        }
        XCTAssertEqual(container.count, 1)
        outer.onNext(1)
        // 2 entries: upstream + inner UnsubscribingObserver
        XCTAssertEqual(container.count, 2)
        inner.onComplete()
        // Back to 1: inner removed itself
        XCTAssertEqual(container.count, 1)
    }
}
