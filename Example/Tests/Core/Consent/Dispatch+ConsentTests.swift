//
//  Dispatch+ConsentTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 25/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DispatchConsentTests: XCTestCase {
    let dispatch = Dispatch(name: "event")
    func test_applyConsentDecision_returns_nil_when_no_purposes_provided() {
        XCTAssertNil(dispatch.applyConsentDecision(ConsentDecision(decisionType: .explicit, purposes: [])))
    }

    func test_applyConsentDecision_returns_nil_if_previously_processed_purposes_contain_all_consented_purposes() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.allConsentedPurposes: ["1", "2", "3"]
        ])
        XCTAssertNil(dispatch.applyConsentDecision(ConsentDecision(decisionType: .explicit, purposes: ["1", "2"])))
    }

    func test_applyConsentDecision_returns_dispatch_if_consented_purposes_contain_some_new_unprocessed_purposes() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.allConsentedPurposes: ["1", "2"]
        ])
        XCTAssertNotNil(dispatch.applyConsentDecision(ConsentDecision(decisionType: .explicit, purposes: ["1", "3"])))
    }

    func test_applyConsentDecision_returns_dispatch_with_allPurposes_being_the_newly_consented_list_of_purposes() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.allConsentedPurposes: ["1", "2"]
        ])
        guard let consentedDispatch = dispatch.applyConsentDecision(ConsentDecision(decisionType: .explicit, purposes: ["1", "3"])) else {
            XCTFail("Dispatch unexpectedly returned nil")
            return
        }
        let allPurposes = consentedDispatch.payload.getArray(key: TealiumDataKey.allConsentedPurposes, of: String.self) ?? []
        XCTAssertEqual(Set(allPurposes), ["1", "3"])
    }

    func test_applyConsentDecision_returns_dispatch_with_processedPurposes_being_the_old_consented_list_of_allPurposes() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.allConsentedPurposes: ["1", "2"]
        ])
        guard let consentedDispatch = dispatch.applyConsentDecision(ConsentDecision(decisionType: .explicit, purposes: ["1", "3"])) else {
            XCTFail("Dispatch unexpectedly returned nil")
            return
        }
        let processedPurposes = consentedDispatch.payload.getArray(key: TealiumDataKey.processedPurposes, of: String.self) ?? []
        XCTAssertEqual(Set(processedPurposes), ["1", "2"])
    }

    func test_applyConsentDecision_returns_dispatch_with_unprocessedPurposes_being_the_newly_consented_list_of_purposes_minus_the_old_consented_purposes() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.allConsentedPurposes: ["1", "2"]
        ])
        guard let consentedDispatch = dispatch.applyConsentDecision(ConsentDecision(decisionType: .explicit, purposes: ["1", "3"])) else {
            XCTFail("Dispatch unexpectedly returned nil")
            return
        }
        let unprocessedPurposes = consentedDispatch.payload.getArray(key: TealiumDataKey.unprocessedPurposes, of: String.self) ?? []
        XCTAssertEqual(Set(unprocessedPurposes), ["3"])
    }

    func test_applyConsentDecision_returns_dispatch_with_decisionType_explicit() {
        guard let consentedDispatch = dispatch.applyConsentDecision(ConsentDecision(decisionType: .explicit, purposes: ["1", "3"])) else {
            XCTFail("Dispatch unexpectedly returned nil")
            return
        }
        let consentType = consentedDispatch.payload.get(key: TealiumDataKey.consentType, as: String.self)
        XCTAssertEqual(consentType, "explicit")
    }

    func test_applyConsentDecision_returns_dispatch_with_decisionType_implicit() {
        guard let consentedDispatch = dispatch.applyConsentDecision(ConsentDecision(decisionType: .implicit, purposes: ["1", "3"])) else {
            XCTFail("Dispatch unexpectedly returned nil")
            return
        }
        let consentType = consentedDispatch.payload.get(key: TealiumDataKey.consentType, as: String.self)
        XCTAssertEqual(consentType, "implicit")
    }

    func test_hasAlreadyProcessedPurposes_returns_false_for_dispatches_without_processed_purposes() {
        XCTAssertFalse(dispatch.hasAlreadyProcessedPurposes())
    }

    func test_hasAlreadyProcessedPurposes_returns_true_for_dispatches_with_processed_purposes() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.processedPurposes: ["1", "2"]
        ])
        XCTAssertTrue(dispatch.hasAlreadyProcessedPurposes())
    }

    func test_matchesConfiguration_returns_true_when_allPurposes_required_by_dispatcher_are_granted() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.allConsentedPurposes: ["1", "2"]
        ])
        let purposeSettings = [
            "1": ConsentPurpose(purposeId: "1", dispatcherIds: ["dispatcher"]),
            "2": ConsentPurpose(purposeId: "2", dispatcherIds: ["dispatcher"]),
            "3": ConsentPurpose(purposeId: "3", dispatcherIds: ["other_dispatcher"])
        ]
        let configuration = ConsentConfiguration(tealiumPurposeId: "",
                                                 refireDispatchersIds: [],
                                                 purposes: purposeSettings)
        XCTAssertTrue(dispatch.matchesConfiguration(configuration, forDispatcher: "dispatcher"))
    }

    func test_matchesConfiguration_returns_false_when_at_least_one_purpose_required_by_dispatcher_is_not_granted() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.allConsentedPurposes: ["1", "2"]
        ])
        let purposeSettings = [
            "1": ConsentPurpose(purposeId: "1", dispatcherIds: ["dispatcher"]),
            "2": ConsentPurpose(purposeId: "2", dispatcherIds: ["dispatcher"]),
            "3": ConsentPurpose(purposeId: "3", dispatcherIds: ["dispatcher"])
        ]
        let configuration = ConsentConfiguration(tealiumPurposeId: "",
                                                 refireDispatchersIds: [],
                                                 purposes: purposeSettings)
        XCTAssertFalse(dispatch.matchesConfiguration(configuration, forDispatcher: "dispatcher"))
    }

    func test_matchesConfiguration_returns_false_when_allPurposes_are_not_present_in_payload() {
        let purposeSettings = [
            "1": ConsentPurpose(purposeId: "1", dispatcherIds: ["dispatcher"]),
            "2": ConsentPurpose(purposeId: "2", dispatcherIds: ["dispatcher"]),
            "3": ConsentPurpose(purposeId: "3", dispatcherIds: ["dispatcher"])
        ]
        let configuration = ConsentConfiguration(tealiumPurposeId: "",
                                                 refireDispatchersIds: [],
                                                 purposes: purposeSettings)
        XCTAssertFalse(dispatch.matchesConfiguration(configuration, forDispatcher: "dispatcher"))
    }

    func test_matchesConfiguration_returns_false_when_allPurposes_are_empty_even_if_dispatcher_needs_no_purposes() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.allConsentedPurposes: [String]()
        ])
        let configuration = ConsentConfiguration(tealiumPurposeId: "",
                                                 refireDispatchersIds: [],
                                                 purposes: [:])
        XCTAssertFalse(dispatch.matchesConfiguration(configuration, forDispatcher: "dispatcher"))
    }

    func test_matchesConfiguration_returns_false_when_dispatcher_has_no_required_purpose() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.allConsentedPurposes: ["1"]
        ])
        let purposeSettings = [
            "1": ConsentPurpose(purposeId: "1", dispatcherIds: ["dispatcher"]),
            "2": ConsentPurpose(purposeId: "2", dispatcherIds: ["dispatcher"]),
            "3": ConsentPurpose(purposeId: "3", dispatcherIds: ["dispatcher"])
        ]
        let configuration = ConsentConfiguration(tealiumPurposeId: "",
                                                 refireDispatchersIds: [],
                                                 purposes: purposeSettings)
        XCTAssertFalse(dispatch.matchesConfiguration(configuration, forDispatcher: "other_dispatcher"))
    }
}
