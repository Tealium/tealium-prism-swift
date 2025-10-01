//
//  DispatchManager+DispatchersListTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DispatchManagerDispatchersListTests: DispatchManagerTestCase {

    func test_event_is_dispatched_to_all_modules() {
        let eventIsDispatchedToModule1 = expectation(description: "Event is dispatched to module1")
        let eventIsDispatchedToModule2 = expectation(description: "Event is dispatched to module2")
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsDispatchedToModule1.fulfill()
        }
        module2?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsDispatchedToModule2.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_event_is_not_dispatched_to_old_modules_when_they_get_disabled() {
        let eventIsDispatchedToModule1 = expectation(description: "Event is dispatched to module1")
        let eventIsNotDispatchedToModule2 = expectation(description: "Event is NOT dispatched to module2")
        eventIsNotDispatchedToModule2.isInverted = true
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsDispatchedToModule1.fulfill()
        }
        module2?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsNotDispatchedToModule2.fulfill()
        }
        disableModule(module: module2)
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_disabling_a_module_doesnt_cancel_inProgress_dispatches() {
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
            self.disableModule(module: module)
            eventsAreDequeued.fulfill()
        }
        _ = module.onDispatch.subscribe { _ in
            eventsAreDispatched.fulfill()
        }
        wait(for: [eventsAreDequeued, eventsAreDispatched], timeout: Self.defaultTimeout, enforceOrder: true)
    }

}
