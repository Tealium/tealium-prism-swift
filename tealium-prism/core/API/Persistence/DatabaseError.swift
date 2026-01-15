//
//  DatabaseError.swift
//  tealium-prism
//
//  Created by Tyler Rister on 14/7/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Errors that can occur during database operations.
public enum DatabaseError: ErrorEnum, ErrorWrapping {
    /// An attempt was made to downgrade the database to an unsupported version.
    case unsupportedDowngrade
    /// A database operation failed due to an underlying error.
    case underlyingError(_ error: Error)
}
