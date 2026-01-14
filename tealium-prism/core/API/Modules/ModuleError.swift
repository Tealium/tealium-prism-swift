//
//  ModuleError.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// An error caused when trying to use a `Module`.
public enum ModuleError<SomeError: Error>: ErrorEnum, ErrorWrapping {
    /// A required object was not found.
    case objectNotFound(_ object: String)
    /// The requested module is not enabled.
    case moduleNotEnabled(_ module: String)
    /// The module failed to perform a specific operation.
    case underlyingError(_ error: SomeError)
}
