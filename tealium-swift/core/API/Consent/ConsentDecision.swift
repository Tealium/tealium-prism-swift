//
//  ConsentDecision.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public struct ConsentDecision {
    public enum DecisionType: String {
        case implicit
        case explicit
    }
    public let decisionType: DecisionType
    public let purposes: [String]
    public init(decisionType: DecisionType, purposes: [String]) {
        self.decisionType = decisionType
        self.purposes = purposes
    }

    func isMatchingAllPurposes(in sequence: [String]) -> Bool {
        sequence.allSatisfy(purposes.contains)
    }
}
