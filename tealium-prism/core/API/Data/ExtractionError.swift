//
//  ExtractionError.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 16/11/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Errors that can occur when reading a value from a `DataItemExtractor`, such as a command payload.
///
/// `key` is the rendered path of the parameter. Messages never include the received value:
/// they are logged and values can be personal data.
#if hasAttribute(nonexhaustive)
@nonexhaustive
#endif
public enum ExtractionError: ErrorEnum {
    /// No value exists at the parameter's path, or it is an explicit `null`.
    case missing(key: String)

    /// The value exists but can't be converted to `expectedType`.
    case typeMismatch(key: String, expectedType: String)

    /// The value has the right type but is not acceptable.
    ///
    /// `reason` states what is accepted (for example `expected one of granted, denied`) and must not
    /// include the received value.
    case invalidValue(key: String, reason: String)

    /// The value is blank: an empty or whitespace-only string, an empty array or an empty dictionary.
    case empty(key: String)

    /// Detailed description of the error for logging purposes.
    public var message: String {
        switch self {
        case .missing(let key):
            return "Missing required value for '\(key)'"
        case let .typeMismatch(key, expectedType):
            return "Invalid type for '\(key)' - expected \(expectedType)"
        case let .invalidValue(key, reason):
            return "Invalid value for '\(key)' - \(reason)"
        case .empty(let key):
            return "Empty value for '\(key)'"
        }
    }
}
