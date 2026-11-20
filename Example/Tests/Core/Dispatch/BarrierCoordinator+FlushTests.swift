//
//  BarrierCoordinator+FlushTests.swift
//  tealium-prism_Tests
//
//  Created by Den Guzov on 14/07/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class BarrierCoordinatorFlushTests: XCTestCase {
    @StateSubject([])
    var barriers: ObservableState<[ScopedBarrier]>
    let queueMetrics = MockQueueMetrics(queueSize: 0)
    let queue = TealiumQueue.main
    @StateSubject(ApplicationStatus(type: .initialized))
    var onApplicationStatus

    func publishStatus(_ status: ApplicationStatus) {
        queue.ensureOnQueue {
            self._onApplicationStatus.onNext(status)
        }
    }
    let starter = MockBackgroundTaskStarter(queue: .main, backgroundTaskTimeout: .seconds(5))
    lazy var coordinator = BarrierCoordinator(onScopedBarriers: barriers,
                                              onApplicationStatus: onApplicationStatus,
                                              queueMetrics: queueMetrics,
                                              flushDebounceMilliseconds: 0,
                                              backgroundTaskStarter: starter,
                                              queue: queue)
    let disposer = AutomaticDisposer()

    override func tearDown() {
        super.tearDown()
        disposer.dispose()
    }

    func test_flush_opens_flushable_barriers() {
        let flushableBarrier = MockBarrier1()
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        let barriersClosed = expectation(description: "Barriers closed")
        let barriersOpen = expectation(description: "Barriers open")

        coordinator.onBarriersState(for: "dispatcher1").subscribe { state in
            if state == .closed {
                barriersClosed.fulfill()
            } else {
                barriersOpen.fulfill()
            }
        }.addTo(disposer)
        queueMetrics.setQueueSize(1)
        coordinator.flush()

        wait(for: [barriersClosed, barriersOpen], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_flush_doesnt_open_non_flushable_barriers() {
        let blockingBarrier = MockBarrier1()
        let flushableBarrier = MockBarrier2()
        blockingBarrier.setState(.closed)
        blockingBarrier.setFlushable(false)
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: blockingBarrier, scope: .all),
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        let barriersClosed = expectation(description: "Barriers closed")

        coordinator.onBarriersState(for: "dispatcher1").subscribe { state in
            XCTAssertEqual(state, .closed)
            barriersClosed.fulfill()
        }.addTo(disposer)
        queueMetrics.setQueueSize(1)
        coordinator.flush()

        waitForDefaultTimeout()
    }

    func test_flush_opens_if_barrier_becomes_flushable() {
        let barrier = MockBarrier1()
        barrier.setState(.closed)
        barrier.setFlushable(false)
        _barriers.value = [
            ScopedBarrier(barrier: barrier, scope: .all),
        ]
        let barriersClosed = expectation(description: "Barriers closed")
        let barriersOpen = expectation(description: "Barriers open")

        coordinator.onBarriersState(for: "dispatcher1").subscribe { state in
            if state == .closed {
                barriersClosed.fulfill()
            } else {
                barriersOpen.fulfill()
            }
        }.addTo(disposer)
        queueMetrics.setQueueSize(1)
        coordinator.flush()
        barrier.setFlushable(true)

        wait(for: [barriersClosed, barriersOpen], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_flush_closes_if_barrier_becomes_non_flushable() {
        let barrier = MockBarrier1()
        barrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: barrier, scope: .all),
        ]
        let barriersClosed = expectation(description: "Barriers closed")
        barriersClosed.expectedFulfillmentCount = 2
        let barriersOpen = expectation(description: "Barriers open")

        coordinator.onBarriersState(for: "dispatcher1").subscribe { state in
            if state == .closed {
                barriersClosed.fulfill()
            } else {
                barriersOpen.fulfill()
            }
        }.addTo(disposer)
        queueMetrics.setQueueSize(1)
        coordinator.flush()
        barrier.setFlushable(false)

        waitForDefaultTimeout()
    }

    func test_flush_keeps_open_if_open_barrier_becomes_non_flushable() {
        let barrier = MockBarrier1()
        barrier.setState(.open)
        _barriers.value = [
            ScopedBarrier(barrier: barrier, scope: .all),
        ]
        let barriersOpen = expectation(description: "Barriers open")

        coordinator.onBarriersState(for: "dispatcher1").subscribe { state in
            XCTAssertEqual(state, .open)
            barriersOpen.fulfill()
        }.addTo(disposer)
        queueMetrics.setQueueSize(1)
        coordinator.flush()
        barrier.setFlushable(false)

        waitForDefaultTimeout()
    }

    func test_flush_resumes_after_non_flushable_barrier_reopens() {
        let nonFlushableBarrier = MockBarrier1()
        let flushableBarrier = MockBarrier2()
        nonFlushableBarrier.setState(.open)
        nonFlushableBarrier.setFlushable(false)
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: nonFlushableBarrier, scope: .all),
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        let barriersClosed = expectation(description: "Barriers closed")
        barriersClosed.expectedFulfillmentCount = 2
        let barriersOpen = expectation(description: "Barriers open")
        barriersOpen.expectedFulfillmentCount = 2

        coordinator.onBarriersState(for: "dispatcher1").subscribe { state in
            if state == .closed {
                barriersClosed.fulfill()
            } else {
                barriersOpen.fulfill()
            }
        }.addTo(disposer)
        queueMetrics.setQueueSize(1)
        coordinator.flush()
        nonFlushableBarrier.setState(.closed)
        nonFlushableBarrier.setState(.open)

        waitForDefaultTimeout()
    }

    func test_flush_closes_when_queue_size_reaches_zero() {
        let flushableBarrier = MockBarrier1()
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        let barriersClosed = expectation(description: "Barriers closed")
        barriersClosed.expectedFulfillmentCount = 2
        let barriersOpen = expectation(description: "Barriers open")

        coordinator.onBarriersState(for: "dispatcher1").subscribe { state in
            if state == .closed {
                barriersClosed.fulfill()
            } else {
                barriersOpen.fulfill()
            }
        }.addTo(disposer)
        queueMetrics.setQueueSize(1)
        coordinator.flush()
        queueMetrics.setQueueSize(0)

        waitForDefaultTimeout()
    }

    func test_changing_app_status_to_backgrounded_causes_flush() {
        let flushableBarrier = MockBarrier1()
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        let barriersClosed = expectation(description: "Barriers closed")
        let barriersOpen = expectation(description: "Barriers open")

        coordinator.onBarriersState(for: "dispatcher1").subscribe { state in
            if state == .closed {
                barriersClosed.fulfill()
            } else {
                barriersOpen.fulfill()
            }
        }.addTo(disposer)
        queueMetrics.setQueueSize(1)
        publishStatus(ApplicationStatus(type: .backgrounded))

        wait(for: [barriersClosed, barriersOpen], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_changing_app_status_to_foregrounded_causes_flush() {
        let flushableBarrier = MockBarrier1()
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        let barriersClosed = expectation(description: "Barriers closed")
        let barriersOpen = expectation(description: "Barriers open")

        coordinator.onBarriersState(for: "dispatcher1").subscribe { state in
            if state == .closed {
                barriersClosed.fulfill()
            } else {
                barriersOpen.fulfill()
            }
        }.addTo(disposer)
        queueMetrics.setQueueSize(1)
        publishStatus(ApplicationStatus(type: .foregrounded))

        wait(for: [barriersClosed, barriersOpen], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_changing_app_status_to_initialized_causes_flush() {
        let flushableBarrier = MockBarrier1()
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        let barriersClosed = expectation(description: "Barriers closed")
        let barriersOpen = expectation(description: "Barriers open")

        coordinator.onBarriersState(for: "dispatcher1").subscribe { state in
            if state == .closed {
                barriersClosed.fulfill()
            } else {
                barriersOpen.fulfill()
            }
        }.addTo(disposer)
        queueMetrics.setQueueSize(1)
        publishStatus(ApplicationStatus(type: .initialized))

        wait(for: [barriersClosed, barriersOpen], timeout: Self.longTimeout, enforceOrder: false)
    }

    func test_closes_after_flush_ends() {
        // In case of observers non disposing properly, an array of just [ConnectivityBarrier]
        // is erroneously used by the coordinator to determine the coordinator state,
        // even if that array is already stale and should be disposed, as it was replaced by an empty array []
        // due to the ConnectivityBarrier becoming flushable at the same time of it opening as well.
        queueMetrics.setQueueSize(2)
        let dispatcher = MockDispatcher2()
        let batchingBarrier = BatchingBarrier(queueMetrics: queueMetrics,
                                              onDispatchers: Observables.just([dispatcher]), configuration: BatchingBarrierSettingsBuilder().setBatchSize(10)._configurationObject)
        let connectivityBarrier = MockConnectivityBarrier()

        _barriers.value = [
            ScopedBarrier(barrier: batchingBarrier, scope: .all),
            ScopedBarrier(barrier: connectivityBarrier, scope: .all)
        ]

        let batchingCloses = expectation(description: "BatchingBarrier closed")

        let coordinatorCloses = expectation(description: "BarrierCoordinator closed")
        coordinatorCloses.expectedFulfillmentCount = 2
        let coordinatorOpens = expectation(description: "BarrierCoordinator opens when connectivity opens and we are flushing, but not again after flushing is over.")

        _ = batchingBarrier.onState(for: dispatcher.id).subscribe { state in
            XCTAssertEqual(state, .closed)
            batchingCloses.fulfill()
        }

        _ = coordinator.onBarriersState(for: dispatcher.id).subscribe { state in
            switch state {
            case .closed:
                coordinatorCloses.fulfill()
            case .open:
                coordinatorOpens.fulfill()
                // End the flush
                self.queueMetrics.setQueueSize(0)
            }
        }

        // Start the flush
        coordinator.flush()
        // ConnectivityBarrier: Allow flushing and open at the same time.
        connectivityBarrier.setConnection(.connected(.wifi))

        let expectations = [
            batchingCloses,
            coordinatorOpens,
            coordinatorCloses
            // Coordinator does not open again
        ]
        wait(for: expectations, timeout: Self.defaultTimeout, enforceOrder: false)
    }

    // MARK: - Shared flush state

    func test_reemitting_the_barriers_after_the_flush_ended_does_not_start_a_new_flush() {
        var states = [BarrierState]()
        subscribeToClosedFlushableBarrierAfterLaunchFlush { states.append($0) }
        queueMetrics.setQueueSize(1)

        reemitBarriers()

        XCTAssertEqual(states, [.closed], "Re-emitting the barriers must not flush the pending dispatches")
    }

    func test_a_second_barriers_state_subscription_after_the_flush_ended_does_not_start_a_flush() {
        subscribeToClosedFlushableBarrierAfterLaunchFlush { _ in }
        queueMetrics.setQueueSize(1)

        var states = [BarrierState]()
        coordinator.onBarriersState(for: "dispatcher1").subscribe { states.append($0) }.addTo(disposer)

        XCTAssertEqual(states, [.closed], "A new subscriber must not flush the pending dispatches")
    }

    func test_the_flush_state_is_per_dispatcher() {
        let flushableBarrier = MockBarrier1()
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        var dispatcher1States = [BarrierState]()
        var dispatcher2States = [BarrierState]()
        coordinator.onBarriersState(for: "dispatcher1").subscribe { dispatcher1States.append($0) }.addTo(disposer)
        coordinator.onBarriersState(for: "dispatcher2").subscribe { dispatcher2States.append($0) }.addTo(disposer)
        queueMetrics.setQueueSize(1, for: "dispatcher1")

        publishStatus(ApplicationStatus(type: .foregrounded))

        XCTAssertEqual(dispatcher1States, [.closed, .open], "The dispatcher with pending dispatches flushes")
        XCTAssertEqual(dispatcher2States, [.closed], "The other dispatcher's flushable barrier stays closed")
    }

    func test_resubscribing_during_a_flush_keeps_the_flush_state_without_closing_the_barriers() {
        let flushableBarrier = MockBarrier1()
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        queueMetrics.setQueueSize(1)
        var firstStates = [BarrierState]()
        coordinator.onBarriersState(for: "dispatcher1").subscribe { firstStates.append($0) }.addTo(disposer)
        XCTAssertEqual(firstStates, [.open], "The launch flush is in progress")

        var secondStates = [BarrierState]()
        coordinator.onBarriersState(for: "dispatcher1").subscribe { secondStates.append($0) }.addTo(disposer)
        reemitBarriers()

        XCTAssertEqual(secondStates, [.open], "A new subscriber receives the flushing state, without closing the barriers first")
        XCTAssertEqual(firstStates, [.open], "Re-emitting the barriers must not close them again")
    }

    func test_resubscribing_during_a_background_flush_starts_only_one_background_task() {
        let flushableBarrier = MockBarrier1()
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        queueMetrics.setQueueSize(1)
        var backgroundTasksStarted = 0
        starter.onBackgroundTaskStarted.subscribe { ongoing in
            if ongoing {
                backgroundTasksStarted += 1
            }
        }.addTo(disposer)
        coordinator.onBarriersState(for: "dispatcher1").subscribe { _ in }.addTo(disposer)
        publishStatus(ApplicationStatus(type: .backgrounded))
        XCTAssertTrue(starter.backgroundTaskOngoing)

        coordinator.onBarriersState(for: "dispatcher1").subscribe { _ in }.addTo(disposer)
        reemitBarriers()

        XCTAssertEqual(backgroundTasksStarted, 1)
        XCTAssertTrue(starter.backgroundTaskOngoing)
    }

    func test_the_initialized_status_flushes_on_launch_without_publishing_a_new_status() {
        let flushableBarrier = MockBarrier1()
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        queueMetrics.setQueueSize(1)
        var states = [BarrierState]()

        coordinator.onBarriersState(for: "dispatcher1").subscribe { states.append($0) }.addTo(disposer)

        // With a 0 ms debounce the flush detection runs synchronously, so the shared state is already true when the first subscriber attaches and closed is never emitted. With a real debounce the first subscriber sees closed, then open.
        XCTAssertEqual(states, [.open])
    }

    func test_a_new_status_after_resubscribing_still_causes_a_flush() {
        var states = [BarrierState]()
        subscribeToClosedFlushableBarrierAfterLaunchFlush { states.append($0) }
        queueMetrics.setQueueSize(1)
        reemitBarriers()
        XCTAssertEqual(states, [.closed], "No flush without a new status")

        publishStatus(ApplicationStatus(type: .foregrounded))

        XCTAssertEqual(states, [.closed, .open])
    }

    func test_a_manual_flush_after_resubscribing_still_causes_a_flush() {
        var states = [BarrierState]()
        subscribeToClosedFlushableBarrierAfterLaunchFlush { states.append($0) }
        queueMetrics.setQueueSize(1)
        reemitBarriers()
        XCTAssertEqual(states, [.closed], "No flush without a new status or manual flush")

        coordinator.flush()

        XCTAssertEqual(states, [.closed, .open])
    }

    // MARK: - Timeout and debounce

    // The checks below only assert that the flush doesn't end before its deadline, which a timer can never do,
    // and wait for the end with a generous timeout, so they don't depend on how fast the machine is.

    func test_flush_ends_after_timeout_when_queue_size_never_reaches_zero() {
        let timeoutMilliseconds = 100
        let opened = expectation(description: "Barriers open")
        let closedAgain = expectation(description: "Barriers closed again by the timeout")
        var states = [BarrierState]()
        let flushStartedAt = ProcessInfo.processInfo.systemUptime

        subscribeWithRealTimes(debounceMilliseconds: 20, timeoutMilliseconds: timeoutMilliseconds) { state in
            states.append(state)
            switch states.count {
            case 2:
                XCTAssertEqual(state, .open)
                opened.fulfill()
            case 3:
                XCTAssertEqual(state, .closed)
                XCTAssertGreaterThanOrEqual(ProcessInfo.processInfo.systemUptime - flushStartedAt,
                                            Double(timeoutMilliseconds) / 1000 - 0.01,
                                            "The flush must last until the timeout")
                closedAgain.fulfill()
            default:
                break
            }
        }

        wait(for: [opened, closedAgain], timeout: Self.longTimeout, enforceOrder: true)
        XCTAssertEqual(states, [.closed, .open, .closed])
    }

    func test_flush_does_not_end_when_queue_size_changes_within_debounce() {
        let opened = expectation(description: "Barriers open")
        let closedAgain = expectation(description: "Barriers closed again")
        closedAgain.isInverted = true
        var states = [BarrierState]()

        subscribeWithRealTimes(debounceMilliseconds: 20) { state in
            states.append(state)
            if state == .open {
                opened.fulfill()
            } else if states.count > 1 {
                closedAgain.fulfill()
            }
        }
        wait(for: [opened], timeout: Self.longTimeout)

        // The queue empties and fills up again synchronously, well within the debounce time.
        queueMetrics.setQueueSize(0)
        queueMetrics.setQueueSize(1)

        wait(for: [closedAgain], timeout: 0.1)
        XCTAssertEqual(states, [.closed, .open])
    }

    func test_flush_ends_when_queue_size_stays_zero_for_the_debounce_time() {
        let debounceMilliseconds = 20
        let opened = expectation(description: "Barriers open")
        let closedAgain = expectation(description: "Barriers closed again")
        var states = [BarrierState]()
        var emptiedAt: TimeInterval = 0

        subscribeWithRealTimes(debounceMilliseconds: debounceMilliseconds) { state in
            states.append(state)
            if state == .open {
                opened.fulfill()
            } else if states.count > 1 {
                XCTAssertGreaterThanOrEqual(ProcessInfo.processInfo.systemUptime - emptiedAt,
                                            Double(debounceMilliseconds) / 1000 - 0.01,
                                            "The flush must wait for the queue to stay empty for the debounce time")
                closedAgain.fulfill()
            }
        }
        wait(for: [opened], timeout: Self.longTimeout)

        emptiedAt = ProcessInfo.processInfo.systemUptime
        queueMetrics.setQueueSize(0)

        wait(for: [closedAgain], timeout: Self.longTimeout)
        XCTAssertEqual(states, [.closed, .open, .closed])
    }

    func test_flush_starts_when_queue_size_keeps_changing_within_debounce() {
        let changes = 8
        let opened = expectation(description: "Barriers open")
        let allChangesApplied = expectation(description: "All the pending count changes are applied")
        var changesApplied = 0
        var changesAppliedWhenOpened = Int.max
        var states = [BarrierState]()

        subscribeWithRealTimes(debounceMilliseconds: 20) { state in
            states.append(state)
            if state == .open {
                changesAppliedWhenOpened = changesApplied
                opened.fulfill()
            }
        }
        // The pending count keeps growing more often than the debounce time, but it never goes back to empty.
        for change in 1...changes {
            queue.dispatchQueue.asyncAfter(deadline: .now() + .milliseconds(10 * change)) { [queueMetrics] in
                changesApplied += 1
                queueMetrics.setQueueSize(change + 1)
                if change == changes {
                    allChangesApplied.fulfill()
                }
            }
        }

        wait(for: [opened, allChangesApplied], timeout: Self.longTimeout)
        XCTAssertLessThan(changesAppliedWhenOpened, 4, "The flush must start soon after the first change, not after the pending count stops changing")
        XCTAssertEqual(states, [.closed, .open], "The flush must keep going while the pending count changes")
    }

    // MARK: - Shutdown

    func test_shutdown_stops_flushing_on_new_status() {
        var states = [BarrierState]()
        subscribeToClosedFlushableBarrierAfterLaunchFlush { states.append($0) }
        queueMetrics.setQueueSize(1)
        coordinator.shutdown()

        publishStatus(ApplicationStatus(type: .foregrounded))
        publishStatus(ApplicationStatus(type: .backgrounded))

        XCTAssertEqual(states, [.closed], "No flush after shutdown")
        XCTAssertFalse(starter.backgroundTaskOngoing, "No background task after shutdown")
    }

    /// Subscribes to a closed flushable barrier, after a launch flush that ended immediately because the queue was empty.
    private func subscribeToClosedFlushableBarrierAfterLaunchFlush(onState: @escaping (BarrierState) -> Void) {
        let flushableBarrier = MockBarrier1()
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        coordinator.onBarriersState(for: "dispatcher1").subscribe(onState).addTo(disposer)
    }

    /// Emits the same barriers again, as a settings refresh does even when nothing changed.
    private func reemitBarriers() {
        _barriers.value = barriers.value
    }

    /// Builds a coordinator with real, small times, and subscribes to a closed flushable barrier while the queue is not empty, so the launch status starts a flush.
    private func subscribeWithRealTimes(debounceMilliseconds: Int,
                                        timeoutMilliseconds: Int = 5000,
                                        onState: @escaping (BarrierState) -> Void) {
        let realTimeCoordinator = BarrierCoordinator(onScopedBarriers: barriers,
                                                     onApplicationStatus: onApplicationStatus,
                                                     queueMetrics: queueMetrics,
                                                     flushDebounceMilliseconds: debounceMilliseconds,
                                                     flushTimeoutMilliseconds: timeoutMilliseconds,
                                                     backgroundTaskStarter: starter,
                                                     queue: queue)
        let flushableBarrier = MockBarrier1()
        flushableBarrier.setState(.closed)
        _barriers.value = [
            ScopedBarrier(barrier: flushableBarrier, scope: .all),
        ]
        queueMetrics.setQueueSize(1)
        realTimeCoordinator.onBarriersState(for: "dispatcher1").subscribe(onState).addTo(disposer)
    }
}
