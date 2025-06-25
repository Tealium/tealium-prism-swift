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
        consentManager = MockConsentManager()
        _ = consentManager?.onApplyConsent.subscribe { _ in
            consentIsAppliedToDispatch.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_dispatch_is_not_dequeued_by_the_dispatchManager_when_consentManager_is_enabled_and_doesnt_have_decision() {
        consentManager = MockConsentManager()
        consentManager?.currentDecision = nil
        dispatchManager.track(Dispatch(name: "someEvent"))
        XCTAssertNil(queueManager.inflightEvents.value[MockDispatcher1.id], "Event is not dequeued because consentManager is enabled without consent decision")
    }

    func test_dispatch_process_is_stopped_before_transformations_for_tealium_purpose_disabled_explicitly() {
        consentManager = MockConsentManager()
        guard let consentManager = consentManager else {
            XCTFail("ConsentManager not initialized")
            return
        }
        let transformationNotCalled = expectation(description: "The transformation is not called")
        transformationNotCalled.isInverted = true
        consentManager.currentDecision = ConsentDecision(decisionType: .explicit, purposes: [])
        XCTAssertTrue(consentManager.tealiumPurposeExplicitlyBlocked)
        transformer.transformation = { _, _, _ in
            transformationNotCalled.fulfill()
            return nil
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_dispatch_process_is_NOT_stopped_before_transformations_for_tealium_purpose_disabled_implicitly() {
        consentManager = MockConsentManager()
        guard let consentManager = consentManager else {
            XCTFail("ConsentManager not initialized")
            return
        }
        let transformationNotCalled = expectation(description: "The transformation is not called")
        transformationNotCalled.isInverted = true
        consentManager.currentDecision = ConsentDecision(decisionType: .implicit, purposes: [])
        XCTAssertTrue(consentManager.tealiumPurposeExplicitlyBlocked)
        transformer.transformation = { _, _, _ in
            transformationNotCalled.fulfill()
            return nil
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_track_completion_is_called_when_consent_is_applied() {
        consentManager = MockConsentManager()
        guard let consentManager else {
            XCTFail("ConsentManager not initialized")
            return
        }
        let completionCalled = expectation(description: "Completion was called")
        let consentIsApplied = expectation(description: "Consent is applied")
        consentManager.onApplyConsent.subscribeOnce { _ in
            consentIsApplied.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent")) { _ in
            completionCalled.fulfill()
        }
        waitForDefaultTimeout()
    }
}
