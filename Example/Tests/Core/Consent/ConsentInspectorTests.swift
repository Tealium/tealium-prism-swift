//
//  ConsentInspectorTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

private let tealiumPurpose = "tealium_purpose_id"
final class ConsentInspectorTests: XCTestCase {

    var configuration = ConsentConfiguration(tealiumPurposeId: tealiumPurpose,
                                             refireDispatchersIds: [],
                                             purposes: [:])
    var decision = ConsentDecision(decisionType: .implicit, purposes: [])
    var allPurposes: [String] = []
    lazy var consentInspector: ConsentInspector = ConsentInspector(configuration: configuration,
                                                                   decision: decision,
                                                                   allPurposes: allPurposes)

    func test_tealium_consented_when_tealium_purpose_present_in_decision() {
        decision = ConsentDecision(decisionType: .implicit, purposes: [tealiumPurpose])
        XCTAssertTrue(consentInspector.tealiumConsented())
    }

    func test_tealium_not_consented_when_tealium_purpose_not_present_in_decision() {
        decision = ConsentDecision(decisionType: .implicit, purposes: [])
        XCTAssertFalse(consentInspector.tealiumConsented())
    }

    func test_tealium_explicitly_blocked_when_tealium_purpose_not_present_and_decision_explicit() {
        decision = ConsentDecision(decisionType: .explicit, purposes: [])
        XCTAssertTrue(consentInspector.tealiumExplicitlyBlocked())
    }

    func test_tealium_no_explicitly_blocked_when_tealium_purpose_not_present_and_decision_implicit() {
        decision = ConsentDecision(decisionType: .implicit, purposes: [])
        XCTAssertFalse(consentInspector.tealiumExplicitlyBlocked())
    }

    func test_tealium_no_explicitly_blocked_when_tealium_purpose_present() {
        decision = ConsentDecision(decisionType: .implicit, purposes: [tealiumPurpose])
        XCTAssertFalse(consentInspector.tealiumExplicitlyBlocked())
    }

    func test_allows_refire_when_decision_implicit_purposes_not_full_and_refireDispatchers_not_empty() {
        decision = ConsentDecision(decisionType: .implicit, purposes: ["1", "2", "3"])
        allPurposes = ["1", "2", "3", "4"]
        configuration = ConsentConfiguration(tealiumPurposeId: tealiumPurpose,
                                             refireDispatchersIds: ["dispatcher1"],
                                             purposes: [:])
        XCTAssertTrue(consentInspector.allowsRefire())
    }

    func test_doesnt_allow_refire_when_decision_explicit() {
        decision = ConsentDecision(decisionType: .explicit, purposes: ["1", "2", "3"])
        allPurposes = ["1", "2", "3", "4"]
        configuration = ConsentConfiguration(tealiumPurposeId: tealiumPurpose,
                                             refireDispatchersIds: ["dispatcher1"],
                                             purposes: [:])
        XCTAssertFalse(consentInspector.allowsRefire())
    }

    func test_doesnt_allow_refire_when_purposes_full() {
        decision = ConsentDecision(decisionType: .implicit, purposes: ["1", "2", "3"])
        allPurposes = ["1", "2", "3"]
        configuration = ConsentConfiguration(tealiumPurposeId: tealiumPurpose,
                                             refireDispatchersIds: ["dispatcher1"],
                                             purposes: [:])
        XCTAssertFalse(consentInspector.allowsRefire())
    }

    func test_doesnt_allow_refire_when_refireDispatchers_empty() {
        decision = ConsentDecision(decisionType: .explicit, purposes: ["1", "2", "3"])
        allPurposes = ["1", "2", "3", "4"]
        configuration = ConsentConfiguration(tealiumPurposeId: tealiumPurpose,
                                             refireDispatchersIds: [],
                                             purposes: [:])
        XCTAssertFalse(consentInspector.allowsRefire())
    }
}
