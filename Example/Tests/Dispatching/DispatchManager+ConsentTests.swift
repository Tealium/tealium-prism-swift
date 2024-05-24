//
//  DispatchManager+ConsentTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 05/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DispatchManagerConsentTests: DispatchManagerTestCase {

    func test_consent_is_applied_when_consentManager_is_enabled() {
        let consentIsAppliedToDispatch = expectation(description: "Consent is applied to dispatch")
        enableModule(ConsentModule.id)
        _ = consentManager?.onApplyConsent.subscribe { _ in
            consentIsAppliedToDispatch.fulfill()
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForExpectations(timeout: 1.0)
    }

    func test_dispatch_is_not_enqueued_by_the_dispatchManager_when_consentManager_is_enabled() {
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        XCTAssertEqual(queueManager.inflightEvents.value["mockDispatcher1"]?.count, 1, "First event is enqueued because consentManager is disabled")
        enableModule(ConsentModule.id)
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        XCTAssertEqual(queueManager.inflightEvents.value["mockDispatcher1"]?.count, 1, "Second event is not enqueued because consentManager is enabled")
    }

    func test_dispatch_process_is_stopped_before_transformations_for_tealium_purpose_disabled_explicitly() {
        enableModule(ConsentModule.id)
        guard let consentManager = consentManager else {
            XCTFail("ConsentManager not added to the modules list")
            return
        }
        let transformationNotCalled = expectation(description: "The transformation is not called")
        transformationNotCalled.isInverted = true
        consentManager.currentDecision = ConsentDecision(decisionType: .explicit, purposes: [])
        XCTAssertFalse(consentManager.tealiumConsented(forPurposes: consentManager.allPurposes))
        transformer.transformation = { _, _, _ in
            transformationNotCalled.fulfill()
            return nil
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForExpectations(timeout: 1.0)
    }

    func test_dispatch_process_is_NOT_stopped_before_transformations_for_tealium_purpose_disabled_implicitly() {
        enableModule(ConsentModule.id)
        guard let consentManager = consentManager else {
            XCTFail("ConsentManager not added to the modules list")
            return
        }
        let transformationNotCalled = expectation(description: "The transformation is called")
        consentManager.currentDecision = ConsentDecision(decisionType: .implicit, purposes: [])
        XCTAssertFalse(consentManager.tealiumConsented(forPurposes: consentManager.allPurposes))
        transformer.transformation = { _, _, _ in
            transformationNotCalled.fulfill()
            return nil
        }
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        waitForExpectations(timeout: 1.0)
    }
}
