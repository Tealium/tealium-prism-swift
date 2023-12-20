//
//  DispatchManager+TrackTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 28/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DispatchManagerTrackTests: DispatchManagerTestCase {

    func test_event_is_dispatched() {
        let eventIsDispatched = expectation(description: "Event is dispatched")
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsDispatched.fulfill()
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForExpectations(timeout: 1.0)
    }

    func test_subsequent_events_are_dispatched() {
        let eventAreDispatched = expectation(description: "Events are dispatched")
        eventAreDispatched.expectedFulfillmentCount = 2
        _ = module2?.onDispatch.subscribe { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventAreDispatched.fulfill()
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForExpectations(timeout: 1.0)
    }
}
