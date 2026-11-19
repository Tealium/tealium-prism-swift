//
//  DatabaseError.swift
//  tealium-prism
//
//  Created by Tyler Rister on 14/7/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Errors that can occur during database operations.
#if hasAttribute(nonexhaustive)
@nonexhaustive
#endif
public enum DatabaseError: ErrorEnum, ErrorWrapping {
    /// A database was created with version lower than 1
    case invalidDatabaseVersion(_ version: Int)
    /// An attempt was made to downgrade the database to an unsupported version.
    case unsupportedDowngrade
    /// A database operation failed due to an underlying error.
    case underlyingError(_ error: Error)
    /// The connection was closed because a statement found the database corrupt, and this operation ran nothing. `cause` is the
    /// error that statement threw, for diagnostics only: its type is not API.
    ///
    /// Storage stays unavailable for this `Tealium` instance. Once it is shut down, a new instance opens a new database file.
    ///
    /// [`Tealium.create(config:completion:)`](doc:Tealium/create(config:completion:)) fails with the corruption error itself, not with this one, when the statement that finds the corruption is
    /// one it throws from (for example, while registering a module's store).
    case connectionClosed(cause: Error)
}
