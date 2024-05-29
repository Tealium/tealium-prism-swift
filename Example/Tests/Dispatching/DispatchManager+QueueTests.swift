//
//  DispatchManager+QueueTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DispatchManagerQueueTests: DispatchManagerTestCase {

    func test_event_is_dispatched_when_already_present_in_the_queue() {
        let eventIsDispatched = expectation(description: "Event is dispatched")
        queueManager.storeDispatches([TealiumDispatch(name: "someEvent")], enqueueingFor: allDispatchers)
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsDispatched.fulfill()
        }
        _ = dispatchManager
        waitForExpectations(timeout: 1.0)
    }

    func test_events_are_dispatched_in_order() {
        disableModule(module: module2)
        let eventsAreDispatched = expectation(description: "Events are dispatched 30 times")
        eventsAreDispatched.expectedFulfillmentCount = 30
        var count = 1
        queueManager.storeDispatches(createDispatches(amount: 30), enqueueingFor: allDispatchers)
        _ = module1?.onDispatch.subscribe { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "event\(count)")
            count += 1
            eventsAreDispatched.fulfill()
        }
        _ = dispatchManager
        waitForExpectations(timeout: 1.0)
    }

    func test_events_are_dispatched_in_ordered_batches() {
        disableModule(module: module1)
        XCTAssertEqual(modulesManager.modules.value.count, 1)
        let eventsAreDispatched = expectation(description: "Events are dispatched in batches 10 times")
        eventsAreDispatched.expectedFulfillmentCount = 10
        var count = 0
        queueManager.storeDispatches(createDispatches(amount: 30), enqueueingFor: allDispatchers)
        _ = module2?.onDispatch.subscribe { dispatches in
            XCTAssertEqual(dispatches.count, 3)
            for index in 0..<3 {
                XCTAssertEqual(dispatches[index].name, "event\(count * 3 + index + 1)")
            }
            count += 1
            eventsAreDispatched.fulfill()
        }
        _ = dispatchManager
        waitForExpectations(timeout: 1.0)
    }

    func test_pulls_from_the_queue_are_stopped_immediately_when_a_partial_batch_is_returned() {
        disableModule(module: module1)
        let eventsAreDequeued = expectation(description: "Events are dequeued only once in a batch")
        queueManager.storeDispatches(createDispatches(amount: 2), enqueueingFor: allDispatchers)
        _ = queueManager.onDequeueRequest.subscribe {
            eventsAreDequeued.fulfill()
        }
        _ = dispatchManager
        waitForExpectations(timeout: 1.0)
    }

    func test_pulls_from_the_queue_are_stopped_immediately_when_number_of_inflight_reaches_the_maximum() {
        disableModule(module: module2)
        module1?.delay = 2000
        let eventsAreDequeued = expectation(description: "Events are dequeued Maximum number of times, not more")
        eventsAreDequeued.expectedFulfillmentCount = DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER
        queueManager.storeDispatches(createDispatches(amount: DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER + 10), enqueueingFor: allDispatchers)
        _ = queueManager.onDequeueRequest.subscribe {
            eventsAreDequeued.fulfill()
        }
        _ = dispatchManager
        waitForExpectations(timeout: 1.0)
    }
}
