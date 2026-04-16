//
//  CommandError.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 18/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Errors that can occur during remote command execution.
///
/// These errors represent validation failures and missing required parameters.
/// All errors provide descriptive messages for centralized logging in dispatchers.
public enum CommandError: ErrorEnum, ErrorWrapping {

    // MARK: - Missing Parameters

    /// Required parameter is missing from payload.
    case missingParameter(String)

    /// Required parameter exists but has invalid type.
    case invalidParameterType(parameter: String, expectedType: String)

    /// Required parameter is empty when non-empty value expected.
    case emptyParameter(String)

    // MARK: - Array Parameter Errors

    /// Array parameter is empty when non-empty expected.
    case emptyArray(String)

    /// Multiple arrays have mismatched lengths.
    case arrayLengthMismatch(array1: String, count1: Int, array2: String, count2: Int)

    // MARK: - Validation Errors

    /// No valid parameters found when at least one expected.
    case noValidParameters(expected: [String])

    // MARK: - Command Registry Errors

    /// Command with the specified name was not found in registry.
    case commandNotFound(String)

    // MARK: - Vendor-Specific Errors

    /// A vendor-specific command error that doesn't fit the generic cases above.
    case underlyingError(_ error: Error)

    // MARK: - Error Description

    /// Detailed description of the error for logging purposes.
    public var message: String {
        switch self {
        case .missingParameter(let param):
            return "Missing required parameter '\(param)'"

        case let .invalidParameterType(parameter, expectedType):
            return "Invalid type for '\(parameter)' - expected \(expectedType)"

        case .emptyParameter(let param):
            return "Parameter '\(param)' is empty"

        case .emptyArray(let param):
            return "Array '\(param)' is empty"

        case let .arrayLengthMismatch(array1, count1, array2, count2):
            return "Array length mismatch: '\(array1)' has \(count1) items, '\(array2)' has \(count2) items"

        case .noValidParameters(let expected):
            return "No valid parameter found. Expected one of: \(expected.map { "'\($0)'" }.joined(separator: ", "))"

        case .commandNotFound(let commandName):
            return "Command '\(commandName)' not found in registry"

        case .underlyingError(let error):
            return "Command failed due to error: \(error)"
        }
    }
}
