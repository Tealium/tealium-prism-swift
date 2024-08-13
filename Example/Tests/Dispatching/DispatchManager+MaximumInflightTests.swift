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
        let dispatches = createDispatches(amount: DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER)
        queueManager.storeDispatches(dispatches, enqueueingFor: [MockDispatcher1.id])
        _ = queueManager.getQueuedDispatches(for: MockDispatcher1.id, limit: nil)
        XCTAssertEqual(queueManager.inflightEvents.value[MockDispatcher1.id]?.count, DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER)
        module1?.onDispatch.subscribeOnce { _ in
            eventIsNotDispatched.fulfill()
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForExpectations(timeout: 1.0)
    }

    func test_event_is_dispatched_again_after_the_inflight_count_goes_down() {
        let eventIsNotDispatched = expectation(description: "Event is NOT dispatched")
        eventIsNotDispatched.isInverted = true
        let dispatches = createDispatches(amount: DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER)
        queueManager.storeDispatches(dispatches, enqueueingFor: [MockDispatcher1.id])
        _ = queueManager.getQueuedDispatches(for: MockDispatcher1.id, limit: nil)
        XCTAssertEqual(queueManager.inflightEvents.value[MockDispatcher1.id]?.count, DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER)
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
        queueManager.deleteDispatches(dispatches.map { $0.id }, for: MockDispatcher1.id)
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
        queueManager.storeDispatches(createDispatches(amount: DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER + 5), enqueueingFor: allDispatchers)
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
        wait(for: [maximumInflightCountReached, firstEventIsDispatched], timeout: 1.0, enforceOrder: true)
    }

    func test_events_are_limited_by_maximumInflightLimit_when_dispatchLimit_is_higher() {
        guard let module1 = module1 else { return }
        module1.dispatchLimit = DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER + 10
        disableModule(module: module2)
        XCTAssertEqual(modulesManager.modules.value.count, 1)
        let firstEventIsDispatched = expectation(description: "First event is dispatched")
        queueManager.storeDispatches(createDispatches(amount: DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER + 10), enqueueingFor: allDispatchers)
        _ = module1.onDispatch.subscribeOnce { dispatches in
            firstEventIsDispatched.fulfill()
            XCTAssertEqual(dispatches.count, DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER)
        }
        _ = dispatchManager
        waitForExpectations(timeout: 1.0)
    }
}
