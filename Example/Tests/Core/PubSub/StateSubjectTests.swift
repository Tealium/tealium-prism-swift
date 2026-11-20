//
//  StateSubjectTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class StateSubjectTests: XCTestCase {

    let variableSubject = StateSubject(0)

    func test_value_changes_emit_new_updates() {
        let stateChanged = expectation(description: "State changed")
        stateChanged.expectedFulfillmentCount = 3
        var count = 1
        _ = variableSubject.updates().subscribe { element in
            XCTAssertEqual(count, element)
            count += 1
            stateChanged.fulfill()
        }
        variableSubject.value = 1
        variableSubject.value = 2
        variableSubject.value = 3
        waitForDefaultTimeout()
    }

    func test_value_returns_latest_provided_value() {
        XCTAssertEqual(variableSubject.value, 0)
        variableSubject.value = 1
        variableSubject.value = 2
        variableSubject.value = 3
        XCTAssertEqual(variableSubject.value, 3)
    }

    func test_asObservable_emits_current_value_and_all_updates() {
        let stateChanged = expectation(description: "State changed")
        stateChanged.expectedFulfillmentCount = 4
        var count = 0
        _ = variableSubject.asObservable().subscribe { element in
            XCTAssertEqual(count, element)
            count += 1
            stateChanged.fulfill()
        }
        variableSubject.value = 1
        variableSubject.value = 2
        variableSubject.value = 3
        waitForDefaultTimeout()
    }

    func test_mutateIfChanged_only_emits_new_updates_if_changed() {
        let stateChanged = expectation(description: "State changed")
        stateChanged.expectedFulfillmentCount = 2
        var count = 1
        _ = variableSubject.updates().subscribe { element in
            XCTAssertEqual(count, element)
            count += 1
            stateChanged.fulfill()
        }
        variableSubject.onNextIfChanged(1)
        variableSubject.onNextIfChanged(1)
        variableSubject.onNextIfChanged(1)
        variableSubject.onNextIfChanged(2)
        waitForDefaultTimeout()
    }

    func test_mutate_array_emits_new_update() {
        let variableSubject = StateSubject([1, 2, 3])
        let updated = expectation(description: "Update arrives")
        _ = variableSubject.updates().subscribe { result in
            updated.fulfill()
            XCTAssertEqual(result, [1, 2, 3, 4])
        }
        variableSubject.value.append(4)
        XCTAssertEqual(variableSubject.value, [1, 2, 3, 4])
        waitForDefaultTimeout()
    }

    func test_map_emits_updates() {
        let multipleValuesEmitted = expectation(description: "Multiple values are emitted")
        multipleValuesEmitted.expectedFulfillmentCount = 5
        var count = 0
        _ = variableSubject.asObservableState()
            .map { $0 + 1 }
            .subscribe { value in
                count += 1
                XCTAssertEqual(count, value)
                multipleValuesEmitted.fulfill()
            }
        variableSubject.value = 1
        variableSubject.value = 2
        variableSubject.value = 3
        variableSubject.value = 4
        waitForDefaultTimeout()
    }

    func test_constant_observableState_emits_constant_value() {
        let valueEmitted = expectation(description: "Value is emitted")
        let state = ObservableState.constant(1)
        XCTAssertEqual(state.value, 1)
        state.subscribeOnce { value in
            XCTAssertEqual(value, 1)
            valueEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_asObservable_returns_observableState() {
        let valueEmitted = expectation(description: "Value is emitted")
        let state = StateSubject(1)
        XCTAssertEqual(state.value, 1)
        state.asObservable().subscribeOnce { value in
            XCTAssertEqual(value, 1)
            valueEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_asObservableState_returns_observableState() {
        let valueEmitted = expectation(description: "Value is emitted")
        let state = StateSubject(1)
        XCTAssertEqual(state.value, 1)
        state.asObservableState().subscribeOnce { value in
            XCTAssertEqual(value, 1)
            valueEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_disposed_subscription_does_not_call_observer() {
        let subject = StateSubject<Int>(1)
        let container = Disposables.composite()
        subject.subscribe { number in
            if number == 2 {
                container.dispose()
            }
        }.addTo(container)
        subject.subscribe { number in
            XCTAssertEqual(number, 1, "Number 2 should never reach this observer because it's disposed by a previously subscribed observer")
        }.addTo(container)
        subject.onNext(2)
    }

    // MARK: - Emitting from the replay callback

    func test_value_emitted_from_replay_callback_reaches_new_observer_after_the_callback() {
        let subject = StateSubject(1)
        var events = [String]()

        let subscription = subject.asObservable().subscribe { value in
            events.append("start \(value)")
            if value == 1 {
                subject.onNext(2)
            }
            events.append("end \(value)")
        }
        defer { subscription.dispose() }

        XCTAssertEqual(events, ["start 1", "end 1", "start 2", "end 2"])
        XCTAssertEqual(subject.value, 2)
    }

    func test_value_emitted_from_replay_callback_reaches_earlier_observer_nested() {
        let subject = StateSubject(1)
        var events = [String]()

        _ = subject.asObservable().subscribe { value in
            events.append("earlier \(value)")
        }
        events.removeAll()

        let subscription = subject.asObservable().subscribe { value in
            events.append("new start \(value)")
            if value == 1 {
                subject.onNext(2)
            }
            events.append("new end \(value)")
        }
        defer { subscription.dispose() }

        XCTAssertEqual(events, ["new start 1", "earlier 2", "new end 1", "new start 2", "new end 2"])
    }

    func test_combineLatest_receives_value_emitted_into_last_source_from_first_value() {
        assertCombineLatestReceivesValueEmittedIntoLastSource(makeSubject: { StateSubject($0) })
    }

    func test_iterable_combineLatest_receives_value_emitted_into_last_source_from_first_value() {
        assertIterableCombineLatestReceivesValueEmittedIntoLastSource(makeSubject: { StateSubject($0) })
    }

    // MARK: - Completion

    func test_completed_subject_delivers_value_then_completion_to_raw_observer() {
        let subject = StateSubject(1)
        subject.onComplete()
        let observer = RecordingObserver<Int> { _ in subject.onNext(2) }

        _ = subject.asObservable().subscribe(observer)
        subject.onNext(3)

        XCTAssertEqual(observer.events, ["next 1", "complete"])
    }

    func test_onNext_after_completion_does_not_change_value() {
        let subject = StateSubject(1)
        subject.onComplete()

        subject.onNext(2)

        XCTAssertEqual(subject.value, 1)
        let observer = RecordingObserver<Int>()
        _ = subject.asObservable().subscribe(observer)
        XCTAssertEqual(observer.events, ["next 1", "complete"])
    }

    func test_completion_emitted_from_replay_callback_reaches_new_observer_after_replay() {
        let subject = StateSubject(1)
        let log = EventLog()
        _ = subject.asObservable().subscribe(RecordingObserver<Int>(log: log, name: "earlier"))
        log.removeAll()

        _ = subject.asObservable().subscribe(RecordingObserver<Int>(log: log, name: "new") { value in
            subject.onComplete()
            log.append("new:end \(value)")
        })
        subject.onNext(2)

        XCTAssertEqual(log.events, ["new:next 1", "earlier:complete", "new:end 1", "new:complete"])
    }

    func test_value_reaches_new_observer_before_completion_when_earlier_observer_completes_on_value_emitted_from_replay() {
        let subject = StateSubject(1)
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

    // MARK: - Observers that complete during their replay

    func test_first_completing_during_replay_receives_nothing_after_completion() {
        let subject = StateSubject(1)
        let observer = RecordingObserver<Int> { _ in subject.onNext(2) }

        _ = subject.asObservable().first().subscribe(observer)
        subject.onNext(3)

        XCTAssertEqual(observer.events, ["next 1", "complete"])
        XCTAssertEqual(subject.value, 3)
    }

    func test_takeWhile_inclusive_completing_during_replay_receives_nothing_after_completion() {
        let subject = StateSubject(1)
        let observer = RecordingObserver<Int> { _ in subject.onNext(2) }

        _ = subject.asObservable().takeWhile({ _ in false }, inclusive: true).subscribe(observer)
        subject.onNext(3)

        XCTAssertEqual(observer.events, ["next 1", "complete"])
    }

    func test_subscriber_disposed_during_replay_is_unregistered_when_subscribe_returns() {
        assertSelfDisposingSubscriberIsReleased(by: StateSubject(1))
    }

    func test_subscriber_not_disposed_is_retained_by_the_subject() {
        assertStayingSubscriberIsRetained(by: StateSubject(1))
    }
}
