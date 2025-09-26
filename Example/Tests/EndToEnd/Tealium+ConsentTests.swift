//
//  Tealium+ConsentTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 15/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumConsentTests: TealiumBaseTests {
    let cmp = MockCMPAdapter(consentDecision: ConsentDecision(decisionType: .implicit,
                                                              purposes: []))
    override func setUp() {
        super.setUp()
        config.modules = [
            MockDispatcher1.factory(),
            MockDispatcher2.factory(),
        ]
        config.enableConsentIntegration(with: cmp) { enforcedConfiguration in
            enforcedConfiguration.addPurpose("1", dispatcherIds: [MockDispatcher1.moduleType])
                .addPurpose("2", dispatcherIds: [MockDispatcher2.moduleType])
                .setTealiumPurposeId("3")
                .setRefireDispatchersIds([MockDispatcher1.moduleType])
        }
    }

    func test_consent_allows_events_if_consent_is_granted() {
        let dispatchIsSent = expectation(description: "Dispatch is sent to all dispatchers")
        dispatchIsSent.expectedFulfillmentCount = 2
        cmp.applyDecision(ConsentDecision(decisionType: .implicit, purposes: ["1", "2", "3"]))
        let teal = createTealium()
        MockDispatcher.onDispatch.subscribe { _ in
            dispatchIsSent.fulfill()
        }.addTo(disposer)
        teal.track("event")
        waitForLongTimeout()
    }

    func test_consent_blocks_events_if_no_consent_decision() {
        let dispatchIsNotSent = expectation(description: "Dispatch is not sent")
        dispatchIsNotSent.isInverted = true
        let teal = createTealium()
        MockDispatcher.onDispatch.subscribe { _ in
            dispatchIsNotSent.fulfill()
        }.addTo(disposer)
        teal.track("event")
        waitForDefaultTimeout()
    }

    func test_consent_unblocks_events_when_consent_is_given() {
        let dispatchIsNotSent = expectation(description: "Dispatch is not sent")
        dispatchIsNotSent.isInverted = true
        let teal = createTealium()
        let disposable = MockDispatcher.onDispatch.subscribe { _ in
            dispatchIsNotSent.fulfill()
        }
        teal.track("event")
        waitForDefaultTimeout()
        disposable.dispose()

        let dispatchIsSent = expectation(description: "Dispatch is sent to both dispatchers")
        dispatchIsSent.expectedFulfillmentCount = 2
        MockDispatcher.onDispatch.subscribe { _ in
            dispatchIsSent.fulfill()
        }.addTo(disposer)
        cmp.applyDecision(ConsentDecision(decisionType: .implicit, purposes: ["1", "2", "3"]))
        waitForLongTimeout()
    }

    func test_consent_refires_events_for_refire_dispatchers() {
        let dispatchIsSent = expectation(description: "Dispatch is sent to all dispatchers")
        dispatchIsSent.expectedFulfillmentCount = 2
        var purposes = Set(["1", "2", "3"])
        cmp.applyDecision(ConsentDecision(decisionType: .implicit, purposes: purposes))
        let teal = createTealium()
        let disposable = MockDispatcher.onDispatch.subscribe { dispatches in
            guard let consentedPurposes = dispatches.first?.payload.getArray(key: TealiumDataKey.allConsentedPurposes, of: String.self) else {
                XCTFail("No purposes found in first dispatch")
                return
            }
            XCTAssertEqual(Set(consentedPurposes), purposes)
            dispatchIsSent.fulfill()
        }
        teal.track("event")
        waitForLongTimeout()
        disposable.dispose()

        let dispatchIsSentToRefireDispatchers = expectation(description: "Dispatch is sent to refire dispatchers")
        purposes.insert("4")
        cmp.applyDecision(ConsentDecision(decisionType: .implicit, purposes: purposes))
        MockDispatcher.onDispatch.subscribe { dispatches in
            guard let consentedPurposes = dispatches.first?.payload.getArray(key: TealiumDataKey.allConsentedPurposes, of: String.self) else {
                XCTFail("No consented purposes found in first dispatch")
                return
            }
            XCTAssertEqual(Set(consentedPurposes), purposes)
            guard let unprocessedPurposes = dispatches.first?.payload.getArray(key: TealiumDataKey.unprocessedPurposes, of: String.self) else {
                XCTFail("No unprocessed purposes found in first dispatch")
                return
            }
            XCTAssertEqual(unprocessedPurposes, ["4"])
            dispatchIsSentToRefireDispatchers.fulfill()
        }.addTo(disposer)
        waitForLongTimeout()
    }
}
