//
//  ConsentInspector.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// Utility to provide information based upon the data provided by the `CMPAdapter` (decision and allPurposes) and the `ConsentConfiguration`.
struct ConsentInspector {
    let configuration: ConsentConfiguration
    let decision: ConsentDecision
    let allPurposes: [String]

    func tealiumConsented() -> Bool {
        decision.purposes.contains(configuration.tealiumPurposeId)
    }

    func tealiumExplicitlyBlocked() -> Bool {
        decision.decisionType == .explicit && !tealiumConsented()
    }

    func allowsRefire() -> Bool {
        decision.decisionType == .implicit &&
        !decision.isMatchingAllPurposes(in: allPurposes) &&
        !configuration.refireDispatchersIds.isEmpty
    }
}
