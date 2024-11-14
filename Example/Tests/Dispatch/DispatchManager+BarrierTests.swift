//
//  DispatchManager+BarrierTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DispatchManagerBarrierTests: DispatchManagerTestCase {

    func test_event_is_not_dispatched_if_a_barrier_is_closed() {
        let eventIsNotDispatched = expectation(description: "Event is NOT dispatched")
        eventIsNotDispatched.isInverted = true
        barrier.setState(.closed)
        module1?.onDispatch.subscribeOnce { _ in
            eventIsNotDispatched.fulfill()
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_events_stop_dispatching_when_a_barrier_closes() {
        disableModule(module: module2)
        let eventIsDispatchedOnlyOnce = expectation(description: "Event is dispatched only once")
        _ = module1?.onDispatch.subscribe { _ in
            eventIsDispatchedOnlyOnce.fulfill()
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        barrier.setState(.closed)
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_event_is_dispatched_after_the_closed_barrier_opens() {
        let eventIsNotDispatched = expectation(description: "Event is NOT dispatched")
        eventIsNotDispatched.isInverted = true
        barrier.setState(.closed)
        let subscription = module1?.onDispatch.subscribeOnce { _ in
            eventIsNotDispatched.fulfill()
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
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

    func test_closing_a_barrier_doesnt_cancel_inProgress_dispatches() {
        disableModule(module: module2)
        guard let module = module1 else {
            XCTFail("module1 not found")
            return
        }
        module.delay = 0
        let eventsAreDispatched = expectation(description: "Events are dispatched")
        let eventsAreDequeued = expectation(description: "Events are dequeued")
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        queueManager.inflightEvents.subscribeOnce { _ in
            self.barrier.setState(.closed)
            eventsAreDequeued.fulfill()
        }
        _ = module.onDispatch.subscribe { _ in
            eventsAreDispatched.fulfill()
        }
        wait(for: [eventsAreDequeued, eventsAreDispatched], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_pulls_from_the_queue_are_stopped_asynchronously_when_a_barrier_closes() {
        disableModule(module: module1)
        let eventsAreDequeued = expectation(description: "Events are flushed until queue is empty or limit is reached when a barrier is open. Closing the barrier only stops future flushes")
        eventsAreDequeued.expectedFulfillmentCount = 2
        queueManager.storeDispatches(createDispatches(amount: 5), enqueueingFor: allDispatchers)
        _ = queueManager.onDequeueRequest.subscribe {
            eventsAreDequeued.fulfill()
        }
        _ = dispatchManager
        barrier.setState(.closed)
        queueManager.storeDispatches([TealiumDispatch(name: "6")], enqueueingFor: allDispatchers)
        waitForDefaultTimeout()
    }
}
