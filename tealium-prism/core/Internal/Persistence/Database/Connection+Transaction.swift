//
//  Connection+Transaction.swift
//  tealium-prism
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite

protocol SQLExecuting {
    func execute(_ sql: String) throws
}

extension Connection: SQLExecuting { }

extension SQLExecuting {
    /// Runs `block` in a transaction that begins in `mode`, commits when `block` returns, and rolls back if `block` or the commit throws.
    ///
    /// Unlike SQLite.swift's `transaction(_:block:)`, the error thrown is the block's (or the `COMMIT`'s), never the `ROLLBACK`'s.
    /// ROLLBACK usually fails because SQLite already rolled back (after SQLITE_FULL or SQLITE_IOERR), and closing the connection
    /// rolls back anything still open, so its error is dropped.
    ///
    /// - Throws: The error of `block`, or of the `COMMIT`. The error of the `BEGIN` if it fails, before `block` runs.
    func transactionIgnoringRollbackError(_ mode: Connection.TransactionMode, _ block: () throws -> Void) throws {
        try execute("BEGIN \(mode.rawValue) TRANSACTION")
        do {
            try block()
            try execute("COMMIT TRANSACTION")
        } catch {
            _ = try? execute("ROLLBACK TRANSACTION")
            throw error
        }
    }
}
