//
//  ContextAPIError.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 28/10/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if contextapi
import TealiumPrismCore
#endif

/**
 * Errors that can occur when using the Context API module.
 */
public enum ContextAPIError: Error, ErrorEnum, ErrorWrapping {
    /// The engine ID provided is invalid (empty or malformed). Engine IDs must be non-empty strings that identify a valid Context API engine in your Tealium account.
    case invalidEngineID

    /// A configuration error occurred, such as invalid account settings, malformed URLs, or missing required parameters. The associated string provides specific details about the configuration issue.
    case configurationError(String)

    /// The network request to the Context API failed. This includes HTTP errors, connectivity issues, timeouts, or invalid responses from the server.
    case networkError(NetworkError)

    /// An unexpected error occurred during a Context API operation. This wraps underlying errors from other system components.
    case underlyingError(_ error: Error)

    var localizedDescription: String {
        switch self {
        case .invalidEngineID:
            "Invalid engine ID provided"
        case .configurationError(let message):
            "Configuration error: \(message)"
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"
        case .underlyingError(let error):
            "Fetching engine response failed due to error: \(error)"
        }
    }
}
