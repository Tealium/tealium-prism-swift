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
            self._onApplicationStatus.publish(status)
        }
    }
    lazy var coordinator = BarrierCoordinator(onScopedBarriers: barriers,
                                              onApplicationStatus: onApplicationStatus,
                                              queueMetrics: queueMetrics,
                                              debouncer: MockInstantDebouncer(),
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
            ScopedBarrier(barrier: flushableBarrier, scopes: [.all]),
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
            ScopedBarrier(barrier: blockingBarrier, scopes: [.all]),
            ScopedBarrier(barrier: flushableBarrier, scopes: [.all]),
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
            ScopedBarrier(barrier: barrier, scopes: [.all]),
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
            ScopedBarrier(barrier: barrier, scopes: [.all]),
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
            ScopedBarrier(barrier: barrier, scopes: [.all]),
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
            ScopedBarrier(barrier: nonFlushableBarrier, scopes: [.all]),
            ScopedBarrier(barrier: flushableBarrier, scopes: [.all]),
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
            ScopedBarrier(barrier: flushableBarrier, scopes: [.all]),
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
            ScopedBarrier(barrier: flushableBarrier, scopes: [.all]),
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
            ScopedBarrier(barrier: flushableBarrier, scopes: [.all]),
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
            ScopedBarrier(barrier: flushableBarrier, scopes: [.all]),
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
}
