//
//  RuleNotFoundError.swift
//  tealium-swift-Core-iOS
//
//  Created by Den Guzov on 09/09/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A `LoadRule` was configured for a `Module`, but was not found. This will cause the module feature
/// (collection/dispatching etc) not to happen. Contains rule ID and module ID strings.
public struct RuleNotFoundError: Error, InvalidMatchError {
    let ruleId: String
    let moduleId: String

    public var description: String {
        "Matching operation failed: RuleNotFoundError. LoadRule(\(ruleId)) not found for Module(\(moduleId))."
    }
}
