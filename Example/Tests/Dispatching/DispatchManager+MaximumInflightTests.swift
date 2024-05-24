//
//  DispatchManager+MaximumInflightTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DispatchManagerMaximumInflightTests: DispatchManagerTestCase {

    func test_event_is_not_dispatched_if_inflight_count_is_too_high() {
        let eventIsNotDispatched = expectation(description: "Event is NOT dispatched")
        eventIsNotDispatched.isInverted = true
        let dispatches = (0..<DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER).map { TealiumDispatch(name: "event\($0)") }
        queueManager.storeDispatches(dispatches, enqueueingFor: ["mockDispatcher1"])
        _ = queueManager.getQueuedDispatches(for: "mockDispatcher1", limit: nil)
        XCTAssertEqual(queueManager.inflightEvents.value["mockDispatcher1"]?.count, DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER)
        module1?.onDispatch.subscribeOnce { _ in
            eventIsNotDispatched.fulfill()
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForExpectations(timeout: 1.0)
    }

    func test_event_is_dispatched_again_after_the_inflight_count_goes_down() {
        let eventIsNotDispatched = expectation(description: "Event is NOT dispatched")
        eventIsNotDispatched.isInverted = true
        let dispatches = (0..<DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER).map { TealiumDispatch(name: "event\($0)") }
        queueManager.storeDispatches(dispatches, enqueueingFor: ["mockDispatcher1"])
        _ = queueManager.getQueuedDispatches(for: "mockDispatcher1", limit: nil)
        XCTAssertEqual(queueManager.inflightEvents.value["mockDispatcher1"]?.count, DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER)
        let subscription = module1?.onDispatch.subscribeOnce { _ in
            eventIsNotDispatched.fulfill()
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForExpectations(timeout: 1.0)
        subscription?.dispose()
        let eventIsDispatched = expectation(description: "Event is dispatched")
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsDispatched.fulfill()
        }
        queueManager.deleteDispatches(dispatches.map { $0.id }, for: "mockDispatcher1")
        waitForExpectations(timeout: 1.0)
    }

    func test_events_are_stopped_after_we_reach_the_maximumInflightLimit() {
        guard let module1 = module1 else { return }
        module1.delay = 500
        disableModule(module: module2)
        XCTAssertEqual(modulesManager.modules.value.count, 1)
        let firstEventIsDispatched = expectation(description: "First event is dispatched")
        let maximumInflightCountReached = expectation(description: "Maximum number of events inflight is reached")
        maximumInflightCountReached.assertForOverFulfill = false
        for index in 0..<DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER + 5 {
            queueManager.storeDispatches([TealiumDispatch(name: "\(index)")], enqueueingFor: allDispatchers)
        }
        _ = queueManager.onInflightDispatchesCount(for: module1.id).subscribe { inflights in
            XCTAssertLessThanOrEqual(inflights, DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER)
            if inflights == DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER {
                maximumInflightCountReached.fulfill()
            }
        }
        _ = module1.onDispatch.subscribeOnce { _ in
            firstEventIsDispatched.fulfill()
        }
        _ = dispatchManager
        wait(for: [maximumInflightCountReached, firstEventIsDispatched], timeout: 1.0, enforceOrder: false)
    }
}
