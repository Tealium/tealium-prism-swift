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
#if hasAttribute(nonexhaustive)
@nonexhaustive
#endif
public enum CommandError: ErrorEnum, ErrorWrapping {

    // MARK: - Payload Errors

    /// A payload parameter could not be read. The message is the wrapped error's message.
    case invalidPayload(_ error: ExtractionError)

    // MARK: - Missing Parameters

    /// Required parameter is missing from payload.
    @available(*, deprecated, message: "Deprecated, will be removed in a future version. Use invalidPayload(.missing(key:)) instead.")
    case missingParameter(String)

    /// Required parameter exists but has invalid type.
    @available(*, deprecated, message: "Deprecated, will be removed in a future version. Use invalidPayload(.typeMismatch(key:expectedType:)) instead.")
    case invalidParameterType(parameter: String, expectedType: String)

    /// Required parameter is empty when non-empty value expected.
    @available(*, deprecated, message: "Deprecated, will be removed in a future version. Use invalidPayload(.empty(key:)) instead.")
    case emptyParameter(String)

    // MARK: - Array Parameter Errors

    /// Array parameter is empty when non-empty expected.
    @available(*, deprecated, message: "Deprecated, will be removed in a future version. Use invalidPayload(.empty(key:)) instead.")
    case emptyArray(String)

    /// Multiple arrays have mismatched lengths.
    case arrayLengthMismatch(array1: String, count1: Int, array2: String, count2: Int)

    // MARK: - Validation Errors

    /// None of the payload's parameters were usable by the command.
    ///
    /// When `expected` is not empty, its entries are listed in the message.
    case noValidParameters(expected: [String])

    // MARK: - Command Registry Errors

    /// Command with the specified name was not found in registry.
    case commandNotFound(String)

    // MARK: - Other Errors

    /// Any other error a command fails with, such as an error from a vendor SDK.
    case underlyingError(_ error: Error)

    // MARK: - Error Description

    /// Detailed description of the error for logging purposes.
    public var message: String {
        switch self {
        case .invalidPayload(let error):
            return error.message

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
            guard !expected.isEmpty else {
                return "No valid parameter found."
            }
            return "No valid parameter found. Expected one of: \(expected.map { "'\($0)'" }.joined(separator: ", "))"

        case .commandNotFound(let commandName):
            return "Command '\(commandName)' not found in registry"

        case .underlyingError(let error):
            return "Command failed due to error: \(error)"
        }
    }
}
