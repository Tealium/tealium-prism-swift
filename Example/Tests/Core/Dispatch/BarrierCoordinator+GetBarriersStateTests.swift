//
//  BarrierCoordinator+GetBarriersStateTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class BarrierCoordinatorGetBarriersStateTests: XCTestCase {
    let registeredBarriers = [MockBarrier(id: "mock1"), MockBarrier(id: "mock2"), MockBarrier(id: "mock3")]
    @StateSubject([])
    var onScopedBarriers: ObservableState<[ScopedBarrier]>
    lazy var barrierCoordinator = BarrierCoordinator(registeredBarriers: registeredBarriers, onScopedBarriers: onScopedBarriers)

    func test_getBarriersState_returns_open_if_all_barriers_are_open() {
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")]),
                ScopedBarrier(barrierId: "mock2", scopes: [.dispatcher("dispatcher1")]),
                ScopedBarrier(barrierId: "mock3", scopes: [.all])
            ]
            let barrierStateReported = expectation(description: "BarrierState is reported")
            barrierCoordinator.onBarrierState(for: "dispatcher1")
                .subscribeOnce { state in
                    XCTAssertEqual(state, .open)
                    barrierStateReported.fulfill()
                }
            waitForDefaultTimeout()
        }

        func test_getBarriersState_returns_closed_if_at_least_one_barrier_is_closed() {
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")]),
                ScopedBarrier(barrierId: "mock2", scopes: [.dispatcher("dispatcher1")]),
                ScopedBarrier(barrierId: "mock3", scopes: [.all])
            ]
            let barrierStateReported = expectation(description: "BarrierState is reported")
            registeredBarriers[0].setState(.closed)
            barrierCoordinator.onBarrierState(for: "dispatcher1")
                .subscribeOnce { state in
                    XCTAssertEqual(state, .closed)
                    barrierStateReported.fulfill()
                }
            waitForDefaultTimeout()
        }

        func test_getBarriersState_returns_open_if_a_closed_barrier_is_scoped_to_a_different_dispatcher() {
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")]),
                ScopedBarrier(barrierId: "mock2", scopes: [.dispatcher("dispatcher2")]),
                ScopedBarrier(barrierId: "mock3", scopes: [.all])
            ]
            let barrierStateReported = expectation(description: "BarrierState is reported")
            registeredBarriers[1].setState(.closed)
            barrierCoordinator.onBarrierState(for: "dispatcher1")
                .subscribeOnce { state in
                    XCTAssertEqual(state, .open)
                    barrierStateReported.fulfill()
                }
            waitForDefaultTimeout()
        }

        func test_getBarriersState_closes_when_a_barrier_closes() {
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")]),
                ScopedBarrier(barrierId: "mock2", scopes: [.dispatcher("dispatcher1")]),
                ScopedBarrier(barrierId: "mock3", scopes: [.all])
            ]
            let barrierStateReported = expectation(description: "BarrierState is reported")
            barrierStateReported.expectedFulfillmentCount = 2
            var count = 0
            _ = barrierCoordinator.onBarrierState(for: "dispatcher1")
                .subscribe { state in
                    if count == 0 {
                        XCTAssertEqual(state, .open)
                    } else {
                        XCTAssertEqual(state, .closed)
                    }
                    count += 1
                    barrierStateReported.fulfill()
                }
            registeredBarriers[1].setState(.closed)
            waitForDefaultTimeout()
        }

        func test_getBarriersState_opens_when_the_last_closed_barrier_opens() {
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")]),
                ScopedBarrier(barrierId: "mock2", scopes: [.dispatcher("dispatcher1")]),
                ScopedBarrier(barrierId: "mock3", scopes: [.all])
            ]
            let barrierStateReported = expectation(description: "BarrierState is reported")
            barrierStateReported.expectedFulfillmentCount = 2
            registeredBarriers[1].setState(.closed)
            var count = 0
            _ = barrierCoordinator.onBarrierState(for: "dispatcher1")
                .subscribe { state in
                    if count == 0 {
                        XCTAssertEqual(state, .closed)
                    } else {
                        XCTAssertEqual(state, .open)
                    }
                    count += 1
                    barrierStateReported.fulfill()
                }
            registeredBarriers[1].setState(.open)
            waitForDefaultTimeout()
        }

        func test_getBarriersState_doesnt_emit_state_changes_for_the_old_scopedBarriers() {
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")])
            ]
            let barrierStateReported = expectation(description: "BarrierState is reported")
            let barrierStateChangedForOldBarrier = expectation(description: "Barrier state is reported for old barrier")
            barrierStateChangedForOldBarrier.isInverted = true
            var count = 0
            _ = barrierCoordinator.onBarrierState(for: "dispatcher1")
                .subscribe { state in
                    if count == 0 {
                        XCTAssertEqual(state, .open)
                        barrierStateReported.fulfill()
                    } else {
                        barrierStateChangedForOldBarrier.fulfill()
                    }
                    count += 1
                }
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock2", scopes: [.dispatcher("dispatcher1")])
            ]
            registeredBarriers[0].setState(.closed)
            waitForDefaultTimeout()
        }

        func test_getBarriersState_emits_state_changes_for_the_new_scopedBarriers() {
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")])
            ]
            let barrierStateReported = expectation(description: "BarrierState is reported")
            barrierStateReported.expectedFulfillmentCount = 2
            var count = 0
            _ = barrierCoordinator.onBarrierState(for: "dispatcher1")
                .subscribe { state in
                    if count == 0 {
                        XCTAssertEqual(state, .open)
                        barrierStateReported.fulfill()
                    } else {
                        XCTAssertEqual(state, .closed)
                        barrierStateReported.fulfill()
                    }
                    count += 1
                }
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock2", scopes: [.dispatcher("dispatcher1")])
            ]
            registeredBarriers[1].setState(.closed)
            waitForDefaultTimeout()
        }

        func test_getBarriersState_emits_closed_when_adding_a_closed_barrier() {
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")])
            ]
            let barrierStateReported = expectation(description: "BarrierState is reported")
            barrierStateReported.expectedFulfillmentCount = 2
            var count = 0
            _ = barrierCoordinator.onBarrierState(for: "dispatcher1")
                .subscribe { state in
                    if count == 0 {
                        XCTAssertEqual(state, .open)
                        barrierStateReported.fulfill()
                    } else {
                        XCTAssertEqual(state, .closed)
                        barrierStateReported.fulfill()
                    }
                    count += 1
                }
            registeredBarriers[1].setState(.closed)
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")]),
                ScopedBarrier(barrierId: "mock2", scopes: [.dispatcher("dispatcher1")])
            ]
            waitForDefaultTimeout()
        }

        func test_getBarriersState_emits_open_when_removing_the_only_closed_barrier() {
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")]),
                ScopedBarrier(barrierId: "mock2", scopes: [.dispatcher("dispatcher1")])
            ]
            registeredBarriers[1].setState(.closed)
            let barrierStateReported = expectation(description: "BarrierState is reported")
            barrierStateReported.expectedFulfillmentCount = 2
            var count = 0
            _ = barrierCoordinator.onBarrierState(for: "dispatcher1")
                .subscribe { state in
                    if count == 0 {
                        XCTAssertEqual(state, .closed)
                        barrierStateReported.fulfill()
                    } else {
                        XCTAssertEqual(state, .open)
                        barrierStateReported.fulfill()
                    }
                    count += 1
                }
            _onScopedBarriers.value = [
                ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")])
            ]
            waitForDefaultTimeout()
        }

        func test_getBarriersState_emits_open_when_scopedBarriers_is_empty() {
            _onScopedBarriers.value = [
            ]
            let barrierStateReported = expectation(description: "BarrierState is reported")
            _ = barrierCoordinator.onBarrierState(for: "dispatcher1")
                .subscribe { state in
                    XCTAssertEqual(state, .open)
                    barrierStateReported.fulfill()
                }
            waitForDefaultTimeout()
        }
}
