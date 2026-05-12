//
//  BarrierCoordinatorTests.swift
//  tealium-prism_Tests
//
//  Created by Tealium on 24/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class BarrierCoordinatorTests: XCTestCase {
    @StateSubject([])
    var barriers: ObservableState<[ScopedBarrier]>
    let starter = MockBackgroundTaskStarter(queue: .main, backgroundTaskTimeout: .seconds(5))
    let applicationStatus = StateSubject(ApplicationStatus(type: .initialized))
    let queueMetrics = MockQueueMetrics(queueSize: 0)
    lazy var coordinator = BarrierCoordinator(onScopedBarriers: barriers,
                                              onApplicationStatus: applicationStatus.asObservable(),
                                              queueMetrics: queueMetrics,
                                              flushDebounceMilliseconds: 0,
                                              backgroundTaskStarter: starter,
                                              queue: .main)

    func test_onBarriers_for_dispatcher_filters_barriers_by_scope() {
        let allBarrier = MockBarrier()
        let specificBarrier = MockBarrier()
        let otherBarrier = MockBarrier()

        _barriers.value = [
            ScopedBarrier(barrier: allBarrier, scope: .all),
            ScopedBarrier(barrier: specificBarrier, scope: .dispatchers(["test"])),
            ScopedBarrier(barrier: otherBarrier, scope: .dispatchers(["other"]))
        ]

        let barriersEmitted = expectation(description: "Barriers emitted")
        coordinator.onBarriers(for: "test").subscribeOnce { barriers in
            XCTAssertEqual(barriers.count, 2)
            XCTAssertIdentical(barriers[0], allBarrier)
            XCTAssertIdentical(barriers[1], specificBarrier)
            barriersEmitted.fulfill()
        }

        waitForDefaultTimeout()
    }

    func test_onBarriers_for_dispatcher_updates_when_barriers_list_changes() {
        let allBarrier = MockBarrier()
        let specificBarrier = MockBarrier()
        let otherBarrier = MockBarrier()

        _barriers.value = [
            ScopedBarrier(barrier: allBarrier, scope: .all),
            ScopedBarrier(barrier: specificBarrier, scope: .dispatchers(["test"])),
        ]

        let barriersEmitted = expectation(description: "Barriers emitted")
        barriersEmitted.expectedFulfillmentCount = 2
        coordinator.onBarriers(for: "test").subscribeOnce { barriers in
            XCTAssertEqual(barriers.count, 2)
            XCTAssertIdentical(barriers[0], allBarrier)
            XCTAssertIdentical(barriers[1], specificBarrier)
            barriersEmitted.fulfill()
        }

        _barriers.value.append(ScopedBarrier(barrier: otherBarrier, scope: .all))

        coordinator.onBarriers(for: "test").subscribeOnce { barriers in
            XCTAssertEqual(barriers.count, 3)
            XCTAssertIdentical(barriers[0], allBarrier)
            XCTAssertIdentical(barriers[1], specificBarrier)
            XCTAssertIdentical(barriers[2], otherBarrier)
            barriersEmitted.fulfill()
        }

        waitForDefaultTimeout()
    }

    func test_onBarriersState_emits_open_when_all_barriers_are_open() {
        let openBarrier1 = MockBarrier()
        let openBarrier2 = MockBarrier()

        _barriers.value = [
            ScopedBarrier(barrier: openBarrier1, scope: .all),
            ScopedBarrier(barrier: openBarrier2, scope: .dispatchers(["test"]))
        ]

        let stateEmitted = expectation(description: "State emitted")
        coordinator.onBarriersState(for: "test").subscribeOnce { state in
            XCTAssertEqual(state, .open)
            stateEmitted.fulfill()
        }

        waitForDefaultTimeout()
    }

    func test_onBarriersState_emits_closed_when_any_barrier_is_closed() {
        let openBarrier = MockBarrier()
        let closedBarrier = MockBarrier()
        closedBarrier.setState(.closed)

        _barriers.value = [
            ScopedBarrier(barrier: openBarrier, scope: .all),
            ScopedBarrier(barrier: closedBarrier, scope: .dispatchers(["test"]))
        ]

        let stateEmitted = expectation(description: "State emitted")
        coordinator.onBarriersState(for: "test").subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            stateEmitted.fulfill()
        }

        waitForDefaultTimeout()
    }

    func test_onBarriersState_emits_new_state_when_barrier_state_changes() {
        let stateChangingBarrier = MockBarrier()

        _barriers.value = [
            ScopedBarrier(barrier: stateChangingBarrier, scope: .all)
        ]
        let stateEmitted = expectation(description: "State emitted")
        stateEmitted.expectedFulfillmentCount = 2

        var stateChanges = 0
        let disposable = coordinator.onBarriersState(for: "test").subscribe { state in
            if stateChanges % 2 == 0 {
                XCTAssertEqual(state, .open)
            } else {
                XCTAssertEqual(state, .closed)
            }
            stateEmitted.fulfill()
            stateChanges += 1
        }
        stateChangingBarrier.setState(.closed)
        waitForDefaultTimeout()
        disposable.dispose()
    }

    func test_onBarriersState_does_not_emit_duplicate_states() {
        let stateChangingBarrier = MockBarrier()
        let alwaysOpenBarrier = MockBarrier()

        _barriers.value = [
            ScopedBarrier(barrier: stateChangingBarrier, scope: .all),
        ]
        let stateEmitted = expectation(description: "State emitted")

        let disposable = coordinator.onBarriersState(for: "test").subscribe { state in
            XCTAssertEqual(state, .open)
            stateEmitted.fulfill()
        }
        stateChangingBarrier.setState(.open)
        _barriers.value = [
            ScopedBarrier(barrier: alwaysOpenBarrier, scope: .all)
        ]
        waitForDefaultTimeout()
        disposable.dispose()
    }

    func test_onBarriersState_updates_when_barrier_with_different_state_is_added() {
        let openBarrier = MockBarrier()
        let closedBarrier = MockBarrier()
        closedBarrier.setState(.closed)

        _barriers.value = [
            ScopedBarrier(barrier: openBarrier, scope: .all)
        ]

        let stateEmitted = expectation(description: "State emitted")
        stateEmitted.expectedFulfillmentCount = 2

        var stateChanges = 0
        let disposable = coordinator.onBarriersState(for: "test").subscribe { state in
            if stateChanges % 2 == 0 {
                XCTAssertEqual(state, .open)
            } else {
                XCTAssertEqual(state, .closed)
            }
            stateEmitted.fulfill()
            stateChanges += 1
        }

        _barriers.value = [
            ScopedBarrier(barrier: closedBarrier, scope: .all)
        ]
        waitForDefaultTimeout()
        disposable.dispose()
    }

    func test_applicationStatus_backgrounded_does_not_start_background_task_if_queue_is_empty() {
        _barriers.value = [
            ScopedBarrier(barrier: MockBarrier(), scope: .all)
        ]
        queueMetrics.setQueueSize(0)

        _ = coordinator.onBarriersState(for: "dispatcher").subscribe { _ in }
        XCTAssertFalse(starter.backgroundTaskOngoing)
        applicationStatus.publish(ApplicationStatus(type: .backgrounded))
        XCTAssertFalse(starter.backgroundTaskOngoing)
    }

    func test_applicationStatus_backgrounded_starts_background_task_if_queue_is_not_empty() {
        _barriers.value = [
            ScopedBarrier(barrier: MockBarrier(), scope: .all)
        ]
        queueMetrics.setQueueSize(1)

        _ = coordinator.onBarriersState(for: "dispatcher").subscribe { _ in }
        XCTAssertFalse(starter.backgroundTaskOngoing)
        applicationStatus.publish(ApplicationStatus(type: .backgrounded))
        XCTAssertTrue(starter.backgroundTaskOngoing)
    }

    func test_background_stops_immediately_upon_emptying_the_queue() {
        _barriers.value = [
            ScopedBarrier(barrier: MockBarrier(), scope: .all)
        ]
        queueMetrics.setQueueSize(1)

        _ = coordinator.onBarriersState(for: "dispatcher").subscribe { _ in }
        XCTAssertFalse(starter.backgroundTaskOngoing)
        applicationStatus.publish(ApplicationStatus(type: .backgrounded))
        XCTAssertTrue(starter.backgroundTaskOngoing)
        queueMetrics.setQueueSize(0)
        XCTAssertFalse(starter.backgroundTaskOngoing)
    }

    func test_onBarriersState_emits_open_when_no_barriers() {
        _barriers.value = []

        let stateEmitted = expectation(description: "State emitted")
        coordinator.onBarriersState(for: "test").subscribeOnce { state in
            XCTAssertEqual(state, .open)
            stateEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onBarriersState_emits_open_when_barriers_are_scoped_to_empty_dispatchers() {
        let closedBarrier = MockBarrier()
        closedBarrier.setState(.closed)

        _barriers.value = [
            ScopedBarrier(barrier: closedBarrier, scope: .dispatchers([]))
        ]

        let stateEmitted = expectation(description: "State emitted")
        coordinator.onBarriersState(for: "test").subscribeOnce { state in
            XCTAssertEqual(state, .open)
            stateEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onBarriersState_emits_open_when_other_dispatchers_barriers_are_closed() {
        let closedBarrier = MockBarrier()
        closedBarrier.setState(.closed)

        _barriers.value = [
            ScopedBarrier(barrier: closedBarrier, scope: .dispatchers(["other"]))
        ]

        let stateEmitted = expectation(description: "State emitted")
        coordinator.onBarriersState(for: "test").subscribeOnce { state in
            XCTAssertEqual(state, .open)
            stateEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onBarriersState_emits_closed_for_all_dispatchers_when_all_scope_barrier_becomes_closed() {
        let barrier = MockBarrier()

        _barriers.value = [
            ScopedBarrier(barrier: barrier, scope: .all)
        ]

        let dispatcher1Closed = expectation(description: "Dispatcher1 closed")
        let dispatcher2Closed = expectation(description: "Dispatcher2 closed")

        coordinator.onBarriersState(for: "dispatcher1").ignoreFirst().subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            dispatcher1Closed.fulfill()
        }
        coordinator.onBarriersState(for: "dispatcher2").ignoreFirst().subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            dispatcher2Closed.fulfill()
        }
        barrier.setState(.closed)
        waitForDefaultTimeout()
    }
}
