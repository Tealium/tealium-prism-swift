//
//  DatabaseConnection.swift
//  tealium-prism
//
//  Created by Craig Rouse on 26/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite

/// The connection that `DatabaseProvider` hands its repositories. It runs SQL statements and typed queries and returns their results
/// fully read. When a statement finds the database corrupt, it releases the connection, reports the error through `onCorruption`,
/// then fails fast.
///
/// Neither a `Statement` nor the raw `Connection` is ever exposed: SQLite.swift's row iteration crashes on a row that can't be
/// read, and a live `Statement` keeps the connection open. Read the columns of a returned `Row` with `Row.get`, which throws on a
/// value that can't be decoded: the `Row` subscript crashes instead (a `try!` in SQLite.swift).
///
/// Query parameters are `QueryType`, `Insert` and `Delete` values from SQLite.swift's typed API. SQL strings take `?` placeholders
/// filled positionally from `bindings`.
///
/// - The statement that gets `SQLITE_CORRUPT` or `SQLITE_NOTADB` (`DatabaseHelper.corruptionCode(_:)`) throws that error. The
///   connection is released, and `onCorruption` is called once with that error.
/// - Every later operation runs nothing and throws `DatabaseError.connectionClosed(cause:)`, with that error as its cause.
/// - Any other error is rethrown and changes nothing: it can come from a healthy file that is only locked.
/// - Inside `transaction`, the nested calls after the corruption fail fast, and `transaction` throws the block's error, or the
///   error of its `COMMIT`; a failed `ROLLBACK` is ignored. A block that swallows the corruption gets `connectionClosed(cause:)`
///   from the `COMMIT`.
///
/// - Warning: Use it from the Tealium queue only: its state has no lock.
///
/// SQLite.swift has no corruption hook and no `close()`, so the connection is wrapped and closed by releasing it (see `perform`).
final class DatabaseConnection: SQLExecuting {
    private enum State {
        /// Statements run on this connection. `onCorruption` is released with it.
        case open(Connection, onCorruption: (Error) -> Void)
        /// A statement found the database corrupt: the connection is released, and every operation throws `connectionClosed(cause:)`.
        /// Storing the cause keeps nothing open: SQLite.swift's errors carry no `Statement`.
        case closed(cause: Error)
    }

    /// The only strong reference to the connection, until the release.
    private var state: State

    /// - Parameters:
    ///   - connection: Owned from here on: keep no other reference to it, as releasing it is what closes it.
    ///   - onCorruption: Called once, with the first corruption error, after the connection is released. Capture neither the connection,
    ///     which would keep it open, nor this object's owner, which would keep both alive after the owner is released.
    init(connection: Connection, onCorruption: @escaping (Error) -> Void) {
        self.state = .open(connection, onCorruption: onCorruption)
    }

    /// Runs a `SELECT` query and reads all its rows.
    ///
    /// - Throws: The SQLite error if the query fails or a row can't be read.
    func rows(_ query: QueryType) throws -> [Row] {
        try perform { try $0.allRows(query) }
    }

    /// Runs a `SELECT` query for its first row only.
    ///
    /// - Returns: The first row, or `nil` if there is none.
    /// - Throws: The SQLite error if the query fails or the row can't be read.
    func pluck(_ query: QueryType) throws -> Row? {
        try perform { try $0.pluck(query) }
    }

    /// Runs a query that selects a single value, such as a count.
    ///
    /// - Returns: The value of the first row.
    /// - Throws: The SQLite error if the query fails, or `QueryError.unexpectedNullValue` if there is no row or its value is `NULL` or not a `V`.
    func scalar<V: Value>(_ query: ScalarQuery<V>) throws -> V {
        try perform { try $0.checkedScalar(query) }
    }

    /// Runs an `INSERT`.
    ///
    /// - Returns: The rowid of the inserted row.
    /// - Throws: The SQLite error if the insert fails.
    @discardableResult
    func run(_ query: Insert) throws -> Int64 {
        try perform { try $0.run(query) }
    }

    /// Runs a `DELETE`.
    ///
    /// - Returns: The number of rows deleted.
    /// - Throws: The SQLite error if the delete fails.
    @discardableResult
    func run(_ query: Delete) throws -> Int {
        try perform { try $0.run(query) }
    }

    /// Runs `block` in a transaction, which begins with `BEGIN IMMEDIATE`, taking the write lock at the start, so a transaction that
    /// reads before it writes can't get `SQLITE_BUSY` when it writes.
    ///
    /// The transaction is committed when `block` returns. If `block` or the `COMMIT` throws, it is rolled back.
    ///
    /// - Throws: The error of `block` or of the `COMMIT`; a failed `ROLLBACK` is ignored. If the block swallowed a corruption,
    ///   `connectionClosed(cause:)`.
    func transaction(_ block: () throws -> Void) throws {
        do {
            try transactionIgnoringRollbackError(.immediate, block)
        } catch {
            // A block that swallows the corruption leaves a `COMMIT` that fails with `connectionClosed`; a block that then throws another error gets the same.
            if case let .closed(cause) = state, DatabaseHelper.corruptionCode(error) == nil, !(error is DatabaseError) {
                throw DatabaseError.connectionClosed(cause: cause)
            }
            throw error
        }
    }

    /// Runs a batch of SQL statements separated by `;`, without bindings.
    ///
    /// - Throws: The SQLite error if a statement fails.
    func execute(_ sql: String) throws {
        try perform { try $0.execute(sql) }
    }

    /// Runs a single SQL statement.
    ///
    /// Returns nothing, unlike SQLite.swift's `run`, which returns the `Statement`.
    ///
    /// - Parameters:
    ///   - sql: The statement, with `?` placeholders.
    ///   - bindings: The values for the placeholders, in order.
    /// - Throws: The SQLite error if the statement fails.
    func run(_ sql: String, _ bindings: Binding?...) throws {
        try perform { _ = try $0.run(sql, bindings) }
    }

    /// Runs a single SQL statement for the first value of its first row.
    ///
    /// - Parameters:
    ///   - sql: The statement, with `?` placeholders.
    ///   - bindings: The values for the placeholders, in order.
    /// - Returns: The first value of the first row, `nil` if it is `NULL`.
    /// - Throws: The SQLite error if the statement fails.
    func scalar(_ sql: String, _ bindings: Binding?...) throws -> Binding? {
        try perform { try $0.scalar(sql, bindings) }
    }

    /// Runs a single SQL statement and reads all its rows at once.
    ///
    /// - Parameters:
    ///   - sql: The statement, with `?` placeholders.
    ///   - bindings: The values for the placeholders, in order.
    /// - Returns: Every row, as its column values in order, `nil` for `NULL`.
    /// - Throws: The SQLite error if the statement fails or a row can't be read.
    func rows(_ sql: String, _ bindings: Binding?...) throws -> [[Binding?]] {
        try perform { try $0.allRows(sql, bindings) }
    }

    /// Folds the write-ahead log back into the main database file. A no-op when the database is not in WAL mode.
    ///
    /// - Returns: The row `wal_checkpoint` reports: `busy` is `true` when another connection held the log, so the checkpoint did not
    ///   complete; `log` is the number of frames in the log, or -1 when the database is not in WAL mode; `checkpointed` is the number
    ///   folded back into the database.
    /// - Throws: The SQLite error if the pragma cannot be prepared or run.
    @discardableResult
    func checkpoint() throws -> (busy: Bool, log: Int, checkpointed: Int) {
        try perform { try $0.walCheckpointRestart() }
    }

    // MARK: - Corruption handling

    /// Runs `operation` on the open connection. On the first corruption error, it releases the connection and calls `onCorruption`,
    /// then rethrows the error.
    ///
    /// - Throws: `DatabaseError.connectionClosed(cause:)`, without running `operation`, once closed.
    private func perform<T>(_ operation: (Connection) throws -> T) throws -> T {
        do {
            switch state {
            case let .closed(cause):
                throw DatabaseError.connectionClosed(cause: cause)
            case let .open(connection, _):
                // Keep this binding inside the `case`: it ends inside the `do` block, so in the `catch` below only `state` holds the
                // connection, and replacing it closes the connection before `onCorruption` runs. Guarded by
                // `test_corruption_closes_the_connection_then_deletes_the_file_and_logs_once`.
                return try operation(connection)
            }
        } catch {
            // Only an open connection closes: the `connectionClosed` thrown above, or an error that isn't a corruption, is rethrown as is.
            if case let .open(_, onCorruption) = state, DatabaseHelper.corruptionCode(error) != nil {
                state = .closed(cause: error)
                onCorruption(error)
            }
            throw error
        }
    }
}
