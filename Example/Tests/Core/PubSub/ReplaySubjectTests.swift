//
//  ReplaySubjectTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 13/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ReplaySubjectTests: SubjectTests {
    let subject = ReplaySubject<Int>(cacheSize: 5)

    func test_events_are_cached() {
        subject.onNext(0)
        XCTAssertEqual(subject.last(), 0)
    }

    func test_init_with_initialValue_immediately_emits_the_initialValue() {
        let subject = ReplaySubject(1)
        XCTAssertEqual(subject.last(), 1)
    }

    func test_cached_events_are_returned_in_order() {
        let expectations = [
            expectation(description: "Event 0 is emitted"),
            expectation(description: "Event 1 is emitted"),
            expectation(description: "Event 2 is emitted"),
            expectation(description: "Event 3 is emitted"),
            expectation(description: "Event 4 is emitted")
        ]
        subject.onNext(0)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        _ = subject.subscribe { number in
            expectations[number].fulfill()
        }
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_oldest_event_is_the_first_to_be_removed_from_the_cache() {
        let expectation = expectation(description: "Event is emitted")
        subject.onNext(0)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.onNext(5)
        subject.subscribeOnce { number in
            XCTAssertEqual(number, 1)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_clear_removes_all_cached_events() {
        let expectation = expectation(description: "Event is not emitted")
        expectation.isInverted = true
        subject.onNext(0)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.clear()
        subject.subscribeOnce { _ in
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_events_are_directly_sent_to_subscribed_observers() {
        let expectations = [
            expectation(description: "Event 0 is emitted"),
            expectation(description: "Event 1 is emitted"),
            expectation(description: "Event 2 is emitted"),
            expectation(description: "Event 3 is emitted"),
            expectation(description: "Event 4 is emitted")
        ]
        expectations.forEach { $0.expectedFulfillmentCount = 2 }
        _ = subject.subscribe { number in
            expectations[number].fulfill()
        }
        subject.onNext(0)
        subject.onNext(1)
        subject.onNext(2)
        _ = subject.subscribe { number in
            expectations[number].fulfill()
        }
        subject.onNext(3)
        subject.onNext(4)
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_subscribeOnce_ReplaySubject_calls_the_observer_only_once() {
        let subject = ReplaySubject<Int>(cacheSize: 2)
        subscribeOnce_calls_the_observer_only_once(subject)
    }

    func test_resize_to_less_size_leaves_latest_cached_events() {
        var sum = 0
        subject.onNext(0)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.resize(3)
        _ = subject.subscribe { number in
            sum += number
        }
        XCTAssertEqual(sum, 9)
    }

    func test_resize_to_greater_size_leaves_all_cached_events() {
        var sum = 0
        subject.onNext(5)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.resize(10)
        _ = subject.subscribe { number in
            sum += number
        }
        XCTAssertEqual(sum, 15)
    }

    func test_resize_to_negative_size_increases_cache_size() {
        var sum = 0
        subject.onNext(5)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.resize(-3)
        subject.onNext(10)
        _ = subject.subscribe { number in
            sum += number
        }
        XCTAssertEqual(sum, 25)
    }

    func test_resize_to_zero_clears_cache() {
        let cacheNotEmpty = expectation(description: "Cache is not empty")
        cacheNotEmpty.isInverted = true
        subject.onNext(5)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onNext(4)
        subject.resize(0)
        _ = subject.subscribe { _ in
            cacheNotEmpty.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - Emitting from the replay callback

    private func assertNewObserverReceives(_ expected: [Int],
                                           cacheSize: Int?,
                                           cached: [Int],
                                           emittingThreeDuringReplayOf trigger: Int,
                                           file: StaticString = #filePath,
                                           line: UInt = #line) {
        let subject = ReplaySubject<Int>(cacheSize: cacheSize)
        cached.forEach { subject.onNext($0) }
        var received = [Int]()

        let subscription = subject.asObservable().subscribe { value in
            received.append(value)
            if value == trigger {
                subject.onNext(3)
            }
        }
        defer { subscription.dispose() }

        XCTAssertEqual(received, expected, file: file, line: line)
        XCTAssertEqual(subject.last(), 3, file: file, line: line)
        XCTAssertFalse(subscription.isDisposed, file: file, line: line)
    }

    func test_value_emitted_from_first_replayed_value_reaches_new_observer_when_cache_not_full() {
        assertNewObserverReceives([1, 2, 3], cacheSize: 3, cached: [1, 2], emittingThreeDuringReplayOf: 1)
    }

    func test_value_emitted_from_last_replayed_value_reaches_new_observer_when_cache_not_full() {
        assertNewObserverReceives([1, 2, 3], cacheSize: 3, cached: [1, 2], emittingThreeDuringReplayOf: 2)
    }

    func test_value_emitted_from_first_replayed_value_reaches_new_observer_when_cache_full() {
        assertNewObserverReceives([1, 2, 3], cacheSize: 2, cached: [1, 2], emittingThreeDuringReplayOf: 1)
    }

    func test_value_emitted_from_last_replayed_value_reaches_new_observer_when_cache_full() {
        assertNewObserverReceives([1, 2, 3], cacheSize: 2, cached: [1, 2], emittingThreeDuringReplayOf: 2)
    }

    func test_value_emitted_from_first_replayed_value_reaches_new_observer_when_cache_unbounded() {
        assertNewObserverReceives([1, 2, 3], cacheSize: nil, cached: [1, 2], emittingThreeDuringReplayOf: 1)
    }

    func test_value_emitted_from_last_replayed_value_reaches_new_observer_when_cache_unbounded() {
        assertNewObserverReceives([1, 2, 3], cacheSize: nil, cached: [1, 2], emittingThreeDuringReplayOf: 2)
    }

    func test_value_emitted_from_replayed_value_reaches_new_observer_when_cache_size_one() {
        assertNewObserverReceives([1, 3], cacheSize: 1, cached: [1], emittingThreeDuringReplayOf: 1)
    }

    func test_values_emitted_during_replay_and_drain_reach_new_observer_in_emission_order() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        subject.onNext(1)
        subject.onNext(2)
        var received = [Int]()

        let subscription = subject.asObservable().subscribe { value in
            received.append(value)
            if value == 1 {
                subject.onNext(3)
            } else if value == 2 {
                subject.onNext(4)
            } else if value == 3 {
                subject.onNext(5)
            }
        }
        defer { subscription.dispose() }

        XCTAssertEqual(received, [1, 2, 3, 4, 5])
        XCTAssertEqual(subject.last(), 5)
    }

    func test_value_emitted_from_replay_callback_reaches_earlier_observer_nested() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        subject.onNext(1)
        subject.onNext(2)
        var events = [String]()
        _ = subject.asObservable().subscribe { value in
            events.append("earlier \(value)")
        }
        events.removeAll()

        let subscription = subject.asObservable().subscribe { value in
            events.append("new start \(value)")
            if value == 1 {
                subject.onNext(3)
            }
            events.append("new end \(value)")
        }
        defer { subscription.dispose() }

        XCTAssertEqual(events, ["new start 1", "earlier 3", "new end 1",
                                "new start 2", "new end 2",
                                "new start 3", "new end 3"])
    }

    func test_combineLatest_receives_value_emitted_into_last_source_from_first_value() {
        assertCombineLatestReceivesValueEmittedIntoLastSource(makeSubject: { ReplaySubject($0) })
    }

    func test_iterable_combineLatest_receives_value_emitted_into_last_source_from_first_value() {
        assertIterableCombineLatestReceivesValueEmittedIntoLastSource(makeSubject: { ReplaySubject($0) })
    }

    func test_nested_subscription_from_replay_callback_receives_its_replay_and_emitted_value() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        subject.onNext(1)
        subject.onNext(2)
        var outerReceived = [Int]()
        var innerReceived = [Int]()
        var innerSubscription: (any Disposable)?

        let outerSubscription = subject.asObservable().subscribe { value in
            outerReceived.append(value)
            guard value == 1, innerSubscription == nil else { return }
            innerSubscription = subject.asObservable().subscribe { innerValue in
                innerReceived.append(innerValue)
                if innerValue == 1 {
                    subject.onNext(3)
                }
            }
        }
        defer {
            outerSubscription.dispose()
            innerSubscription?.dispose()
        }

        XCTAssertEqual(innerReceived, [1, 2, 3])
        XCTAssertEqual(outerReceived, [1, 2, 3])

        subject.onNext(4)

        XCTAssertEqual(innerReceived, [1, 2, 3, 4])
        XCTAssertEqual(outerReceived, [1, 2, 3, 4])
    }

    // MARK: - Completion

    func test_completion_emitted_from_replay_callback_reaches_new_observer_after_replay() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        subject.onNext(1)
        subject.onNext(2)
        let log = EventLog()
        _ = subject.asObservable().subscribe(RecordingObserver<Int>(log: log, name: "earlier"))
        log.removeAll()

        _ = subject.asObservable().subscribe(RecordingObserver<Int>(log: log, name: "new") { value in
            if value == 1 {
                subject.onComplete()
            }
            log.append("new:end \(value)")
        })
        subject.onNext(3)

        XCTAssertEqual(log.events, ["new:next 1", "earlier:complete", "new:end 1",
                                    "new:next 2", "new:end 2",
                                    "new:complete"])
    }

    func test_value_reaches_new_observer_before_completion_when_earlier_observer_completes_on_value_emitted_from_replay() {
        let subject = ReplaySubject<Int>(cacheSize: 2)
        subject.onNext(1)
        let log = EventLog()
        _ = subject.asObservable().subscribe(RecordingObserver<Int>(log: log, name: "earlier") { value in
            if value == 2 {
                subject.onComplete()
            }
        })
        log.removeAll()

        _ = subject.asObservable().subscribe(RecordingObserver<Int>(log: log, name: "new") { value in
            if value == 1 {
                subject.onNext(2)
            }
        })

        XCTAssertEqual(log.events, ["new:next 1", "earlier:next 2", "earlier:complete", "new:next 2", "new:complete"])
    }

    func test_completion_during_drain_reaches_new_observer_after_buffered_values() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        subject.onNext(1)
        let observer = RecordingObserver<Int> { value in
            if value == 1 {
                subject.onNext(2)
            } else if value == 2 {
                subject.onNext(3)
                subject.onComplete()
            }
        }

        _ = subject.asObservable().subscribe(observer)
        subject.onNext(4)

        XCTAssertEqual(observer.events, ["next 1", "next 2", "next 3", "complete"])
    }

    func test_completed_subject_delivers_replay_then_completion_to_raw_observer() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        subject.onNext(1)
        subject.onNext(2)
        subject.onComplete()
        let observer = RecordingObserver<Int> { _ in subject.onNext(3) }

        _ = subject.asObservable().subscribe(observer)
        subject.onNext(4)

        XCTAssertEqual(observer.events, ["next 1", "next 2", "complete"])
    }

    func test_onNext_after_completion_does_not_change_cache() {
        let subject = ReplaySubject<Int>(cacheSize: 2)
        subject.onNext(1)
        subject.onNext(2)
        subject.onComplete()

        subject.onNext(3)

        XCTAssertEqual(subject.last(), 2)
        let observer = RecordingObserver<Int>()
        _ = subject.asObservable().subscribe(observer)
        XCTAssertEqual(observer.events, ["next 1", "next 2", "complete"])
    }

    // MARK: - Observers that complete during their replay

    func test_first_completing_during_replay_receives_nothing_after_completion() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        subject.onNext(1)
        subject.onNext(2)
        let observer = RecordingObserver<Int> { _ in subject.onNext(3) }

        _ = subject.asObservable().first().subscribe(observer)
        subject.onNext(4)

        XCTAssertEqual(observer.events, ["next 1", "complete"])
        XCTAssertEqual(subject.last(), 4)
    }

    func test_takeWhile_inclusive_completing_during_replay_receives_nothing_after_completion() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        subject.onNext(1)
        subject.onNext(2)
        let observer = RecordingObserver<Int> { _ in subject.onNext(3) }

        _ = subject.asObservable().takeWhile({ _ in false }, inclusive: true).subscribe(observer)
        subject.onNext(4)

        XCTAssertEqual(observer.events, ["next 1", "complete"])
    }

    func test_subscriber_disposed_during_replay_is_unregistered_when_subscribe_returns() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        subject.onNext(1)
        subject.onNext(2)

        assertSelfDisposingSubscriberIsReleased(by: subject)
    }

    func test_subscriber_not_disposed_is_retained_by_the_subject() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        subject.onNext(1)

        assertStayingSubscriberIsRetained(by: subject)
    }

    // MARK: - Changing the cache from the replay callback

    func test_clear_from_replay_callback_does_not_change_the_ongoing_replay_and_empties_the_cache() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        var received = [Int]()

        let subscription = subject.asObservable().subscribe { value in
            received.append(value)
            if value == 1 {
                subject.clear()
            }
        }
        defer { subscription.dispose() }

        XCTAssertEqual(received, [1, 2, 3], "The replay delivers the copy of the cache taken at subscription")
        XCTAssertNil(subject.last())

        var laterReceived = [Int]()
        _ = subject.asObservable().subscribe { laterReceived.append($0) }

        XCTAssertEqual(laterReceived, [])
    }

    func test_resize_from_replay_callback_does_not_change_the_ongoing_replay_and_trims_the_cache() {
        let subject = ReplaySubject<Int>(cacheSize: nil)
        (1...4).forEach { subject.onNext($0) }
        var received = [Int]()

        let subscription = subject.asObservable().subscribe { value in
            received.append(value)
            if value == 1 {
                subject.resize(2)
            }
        }
        defer { subscription.dispose() }

        XCTAssertEqual(received, [1, 2, 3, 4], "The replay delivers the copy of the cache taken at subscription")
        XCTAssertEqual(subject.last(), 4)

        var laterReceived = [Int]()
        _ = subject.asObservable().subscribe { laterReceived.append($0) }

        XCTAssertEqual(laterReceived, [3, 4])
    }
}
