//
//  DatabaseCorruptionLogs.swift
//  tealium-prism_Tests
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

/// The messages `DatabaseProvider.deleteCorruptDatabase` logs when it finds a database corrupt.
enum DatabaseCorruptionLogs {
    /// The error `DatabaseProvider.deleteCorruptDatabase` logs when it deletes the corrupt file at `path`, with `error`.
    static func fileDeleted(path: String, error: Error) -> String {
        return "Database corruption detected in '\(path)'. The file was deleted; data in it is lost. "
            + "Storage is unavailable for this Tealium instance; a new instance creates a new file. Error: \(error)"
    }

    /// The error `DatabaseProvider.deleteCorruptDatabase` logs when deleting the corrupt file at `path` throws `deleteError`, with `error`.
    static func fileDeletionFailed(path: String, error: Error, deleteError: Error) -> String {
        return "Database corruption detected in '\(path)'. The file could not be deleted, so it stays as it is. "
            + "Storage is unavailable for this Tealium instance; a new instance opens the same file, and deletes it if a statement "
            + "finds it corrupt again. Error: \(error). Delete error: \(deleteError)"
    }

    /// The error `DatabaseProvider.deleteCorruptDatabase` logs when it finds an in-memory database corrupt, with `error`.
    static func inMemory(error: Error) -> String {
        return "Database corruption detected in ':memory:'. There is no file to delete; data in it is lost. "
            + "Storage is unavailable for this Tealium instance. Error: \(error)"
    }
}
