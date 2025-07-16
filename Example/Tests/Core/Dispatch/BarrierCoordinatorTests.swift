//
//  BarrierCoordinatorTests.swift
//  tealium-swift_Tests
//
//  Created by Tealium on 24/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class BarrierCoordinatorTests: XCTestCase {
    @StateSubject([])
    var barriers: ObservableState<[ScopedBarrier]>
    lazy var coordinator = BarrierCoordinator(onScopedBarriers: barriers,
                                              onApplicationStatus: ApplicationStatusListener.shared.onApplicationStatus,
                                              queueMetrics: MockQueueMetrics(queueSize: 0))

    func test_onBarriers_for_dispatcher_filters_barriers_by_scope() {
        let allBarrier = MockBarrier()
        let specificBarrier = MockBarrier()
        let otherBarrier = MockBarrier()

        _barriers.value = [
            ScopedBarrier(barrier: allBarrier, scopes: [.all]),
            ScopedBarrier(barrier: specificBarrier, scopes: [.dispatcher("test")]),
            ScopedBarrier(barrier: otherBarrier, scopes: [.dispatcher("other")])
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
            ScopedBarrier(barrier: allBarrier, scopes: [.all]),
            ScopedBarrier(barrier: specificBarrier, scopes: [.dispatcher("test")]),
        ]

        let barriersEmitted = expectation(description: "Barriers emitted")
        barriersEmitted.expectedFulfillmentCount = 2
        coordinator.onBarriers(for: "test").subscribeOnce { barriers in
            XCTAssertEqual(barriers.count, 2)
            XCTAssertIdentical(barriers[0], allBarrier)
            XCTAssertIdentical(barriers[1], specificBarrier)
            barriersEmitted.fulfill()
        }

        _barriers.value.append(ScopedBarrier(barrier: otherBarrier, scopes: [.all]))

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
            ScopedBarrier(barrier: openBarrier1, scopes: [.all]),
            ScopedBarrier(barrier: openBarrier2, scopes: [.dispatcher("test")])
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
            ScopedBarrier(barrier: openBarrier, scopes: [.all]),
            ScopedBarrier(barrier: closedBarrier, scopes: [.dispatcher("test")])
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
            ScopedBarrier(barrier: stateChangingBarrier, scopes: [.all])
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
            ScopedBarrier(barrier: stateChangingBarrier, scopes: [.all]),
        ]
        let stateEmitted = expectation(description: "State emitted")

        let disposable = coordinator.onBarriersState(for: "test").subscribe { state in
            XCTAssertEqual(state, .open)
            stateEmitted.fulfill()
        }
        stateChangingBarrier.setState(.open)
        _barriers.value = [
            ScopedBarrier(barrier: alwaysOpenBarrier, scopes: [.all])
        ]
        waitForDefaultTimeout()
        disposable.dispose()
    }

    func test_onBarriersState_updates_when_barrier_with_different_state_is_added() {
        let openBarrier = MockBarrier()
        let closedBarrier = MockBarrier()
        closedBarrier.setState(.closed)

        _barriers.value = [
            ScopedBarrier(barrier: openBarrier, scopes: [.all])
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
            ScopedBarrier(barrier: closedBarrier, scopes: [.all])
        ]
        waitForDefaultTimeout()
        disposable.dispose()
    }
}
