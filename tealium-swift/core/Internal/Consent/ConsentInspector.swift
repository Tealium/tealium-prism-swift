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
    let allPurposes: [String]?

    func tealiumConsented() -> Bool {
        decision.purposes.contains(configuration.tealiumPurposeId)
    }

    func tealiumExplicitlyBlocked() -> Bool {
        decision.decisionType == .explicit && !tealiumConsented()
    }

    func allowsRefire() -> Bool {
        decision.decisionType == .implicit &&
        !allPurposesAreMatched() &&
        !configuration.refireDispatchersIds.isEmpty
    }

    func allPurposesAreMatched() -> Bool {
        guard let allPurposes else {
            // We don't know what all the purposes are
            // So we can't know if they are all matched
            // Therefore we need to assume they are not matched.
            return false
        }
        return decision.isMatchingAllPurposes(in: allPurposes)
    }
}
