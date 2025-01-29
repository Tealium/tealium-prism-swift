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
    let completionCalledDescription = "Completion was called"

    func test_event_is_dispatched() {
        let eventIsDispatched = expectation(description: "Event is dispatched")
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsDispatched.fulfill()
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_subsequent_events_are_dispatched() {
        let eventAreDispatched = expectation(description: "Events are dispatched")
        eventAreDispatched.expectedFulfillmentCount = 2
        _ = module2?.onDispatch.subscribe { dispatches in
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            for _ in dispatches {
                eventAreDispatched.fulfill()
            }
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_track_completion_block_is_run_with_accepted_result_and_transformed_dispatch_when_consent_not_enabled() {
        let completionCalled = expectation(description: completionCalledDescription)
        dispatchManager.track(TealiumDispatch(name: "someEvent")) { dispatch, result in
            completionCalled.fulfill()
            XCTAssertEqual(result, .accepted)
            XCTAssertNotEqual(dispatch.eventData.count, 2)
            XCTAssertNotNil(dispatch.eventData.getDataItem(key: "transformation-afterCollectors"))
        }
        waitForDefaultTimeout()
    }

    func test_track_completion_block_is_run_with_dropped_result_and_original_dispatch_when_tealium_purpose_explicitly_blocked() {
        enableModule(ConsentModule.id)
        guard let consentManager else {
            XCTFail("ConsentManager not added to the modules list")
            return
        }
        consentManager.currentDecision = ConsentDecision(decisionType: .explicit, purposes: [])
        XCTAssertFalse(consentManager.tealiumConsented(forPurposes: consentManager.allPurposes))
        let completionCalled = expectation(description: completionCalledDescription)
        dispatchManager.track(TealiumDispatch(name: "someEvent")) { dispatch, result in
            completionCalled.fulfill()
            XCTAssertEqual(result, .dropped)
            XCTAssertEqual(dispatch.eventData.count, 3)
        }
        waitForDefaultTimeout()
    }

    func test_track_completion_block_is_run_with_dropped_result_and_original_dispatch_when_event_dropped_by_transformer() {
        transformer.transformation = { _, _, _ in
            return nil
        }
        let completionCalled = expectation(description: completionCalledDescription)
        dispatchManager.track(TealiumDispatch(name: "someEvent")) { dispatch, result in
            completionCalled.fulfill()
            XCTAssertEqual(result, .dropped)
            XCTAssertEqual(dispatch.eventData.count, 3)
        }
        waitForDefaultTimeout()
    }
}
