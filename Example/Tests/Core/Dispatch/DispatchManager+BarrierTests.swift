//
//  DispatchManager+BarrierTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DispatchManagerBarrierTests: DispatchManagerTestCase {
    let disposer = AutomaticDisposer()

    override func tearDown() {
        disposer.dispose()
        super.tearDown()
    }

    func test_event_is_not_dispatched_if_a_barrier_is_closed() {
        let eventIsNotDispatched = expectation(description: "Event is NOT dispatched")
        eventIsNotDispatched.isInverted = true
        barrier.setState(.closed)
        module1?.onDispatch.subscribeOnce { _ in
            eventIsNotDispatched.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_events_stop_dispatching_when_a_barrier_closes() {
        disableModule(module: module2)
        let eventIsDispatchedOnlyOnce = expectation(description: "Event is dispatched only once")
        _ = module1?.onDispatch.subscribe { _ in
            eventIsDispatchedOnlyOnce.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        barrier.setState(.closed)
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_event_is_dispatched_after_the_closed_barrier_opens() {
        let eventIsNotDispatched = expectation(description: "Event is NOT dispatched")
        eventIsNotDispatched.isInverted = true
        barrier.setState(.closed)
        let subscription = module1?.onDispatch.subscribeOnce { _ in
            eventIsNotDispatched.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
        subscription?.dispose()
        let eventIsDispatched = expectation(description: "Event is dispatched")
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsDispatched.fulfill()
        }
        barrier.setState(.open)
        waitForDefaultTimeout()
    }

    func test_closing_a_barrier_does_not_cancel_inProgress_dispatches() {
        disableModule(module: module2)
        guard let module = module1 else {
            XCTFail("module1 not found")
            return
        }
        module.delay = 0
        let eventsAreDispatched = expectation(description: "Events are dispatched")
        let eventsAreDequeued = expectation(description: "Events are dequeued")
        dispatchManager.track(Dispatch(name: "someEvent"))
        queueManager.inflightEvents.subscribeOnce { _ in
            self.barrier.setState(.closed)
            eventsAreDequeued.fulfill()
        }
        _ = module.onDispatch.subscribe { _ in
            eventsAreDispatched.fulfill()
        }
        wait(for: [eventsAreDequeued, eventsAreDispatched], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_pulls_from_the_queue_are_stopped_asynchronously_when_a_barrier_closes() throws {
        disableModule(module: module1)
        let eventsAreDequeued = expectation(description: "Events are flushed until queue is empty or limit is reached when a barrier is open. Closing the barrier only stops future flushes")
        eventsAreDequeued.expectedFulfillmentCount = 2
        try queueManager.storeDispatches(createDispatches(amount: 5), enqueueingFor: allDispatchers)
        _ = queueManager.onDequeueRequest.subscribe { _ in
            eventsAreDequeued.fulfill()
        }
        _ = dispatchManager
        barrier.setState(.closed)
        try queueManager.storeDispatches([Dispatch(name: "6")], enqueueingFor: allDispatchers)
        waitForDefaultTimeout()
    }

    // MARK: - Flush restarts

    /// Leaves a closed flushable barrier (like a `BatchingBarrier` below its batch size) holding a backlog
    /// after the launch flush ended, with the barriers re-emittable through the returned subject.
    private func setUpClosedFlushableBarrierWithBacklog() -> StateSubject<[ScopedBarrier]> {
        let barriers = StateSubject<[ScopedBarrier]>([ScopedBarrier(barrier: barrier, scope: .all)])
        onBarriers = barriers.asObservable()
        barrier.setState(.closed)
        _ = dispatchManager
        queueManager.storeDispatches(createDispatches(amount: 5), enqueueingFor: allDispatchers)
        return barriers
    }

    func test_changing_the_dispatchers_list_does_not_dispatch_the_backlog_held_by_a_closed_flushable_barrier() {
        _ = setUpClosedFlushableBarrierWithBacklog()
        let backlogIsNotDispatched = expectation(description: "Backlog is NOT dispatched")
        backlogIsNotDispatched.isInverted = true
        backlogIsNotDispatched.assertForOverFulfill = false
        module1?.onDispatch.subscribe { _ in
            backlogIsNotDispatched.fulfill()
        }.addTo(disposer)

        disableModule(module: module2)
        enableModule(MockDispatcher2.moduleType)
        let readdedModuleDoesNotDispatch = expectation(description: "Re-added module doesn't dispatch the backlog it had when it was disabled")
        readdedModuleDoesNotDispatch.isInverted = true
        readdedModuleDoesNotDispatch.assertForOverFulfill = false
        module2?.onDispatch.subscribe { _ in
            readdedModuleDoesNotDispatch.fulfill()
        }.addTo(disposer)

        waitForDefaultTimeout()
    }

    func test_reemitting_the_barriers_does_not_dispatch_the_backlog_held_by_a_closed_flushable_barrier() {
        let barriers = setUpClosedFlushableBarrierWithBacklog()
        let backlogIsNotDispatched = expectation(description: "Backlog is NOT dispatched")
        backlogIsNotDispatched.isInverted = true
        backlogIsNotDispatched.assertForOverFulfill = false
        module1?.onDispatch.subscribe { _ in
            backlogIsNotDispatched.fulfill()
        }.addTo(disposer)

        barriers.onNext(barriers.value)

        waitForDefaultTimeout()
    }
}
