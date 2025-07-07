//
//  ConsentDecision.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A representation of a user's consent decision.
public struct ConsentDecision {
    public enum DecisionType: String {
        /// A decision that was derived implicitly by the user action (e.g. by opening the application).
        case implicit
        /// An explicit decision that the user purposefully gave (e.g. by accepting the consent policy).
        case explicit
    }
    /// The type of decision.
    public let decisionType: DecisionType
    /// The purposes that were accepted by the user, either explicitly or implicitly.
    public let purposes: [String]
    public init(decisionType: DecisionType, purposes: [String]) {
        self.decisionType = decisionType
        self.purposes = purposes
    }

    func isMatchingAllPurposes(in sequence: [String]) -> Bool {
        return sequence.allSatisfy(purposes.contains)
    }
}
