//
//  DatabaseConnectionTests.swift
//  tealium-prism_Tests
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite
import SQLite3
@testable import TealiumPrism
import XCTest

/// `DatabaseConnection`: its operations, and how it deletes a corrupt database and then fails fast.
final class DatabaseConnectionTests: XCTestCase {
    func test_raw_sql_runs_on_the_connection() throws {
        let connection = healthyConnection()
        try connection.execute("CREATE TABLE sample (a INTEGER, b TEXT)")
        try connection.run("INSERT INTO sample VALUES (?, ?)", 1, "x")
        try connection.run("INSERT INTO sample VALUES (?, ?)", 2, nil)
        XCTAssertEqual(try connection.scalar("SELECT COUNT(*) FROM sample WHERE a > ?", 0) as? Int64, 2)
        let rows = try connection.rows("SELECT a, b FROM sample ORDER BY a")
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0][0] as? Int64, 1)
        XCTAssertEqual(rows[0][1] as? String, "x")
        XCTAssertNil(rows[1][1])
        XCTAssertEqual(try connection.rows("SELECT a FROM sample WHERE a = ?", 2).count, 1)
    }

    func test_scalar_query_returns_the_value() throws {
        let connection = healthyConnection()
        try connection.run("INSERT INTO module (name) VALUES (?)", "a")
        XCTAssertEqual(try connection.scalar(SQLite.Table("module").count), 1)
    }

    func test_scalar_query_throws_on_a_null_value() throws {
        let connection = healthyConnection()
        try connection.execute("CREATE TABLE sample (a INTEGER)")
        try connection.run("INSERT INTO sample VALUES (NULL)")
        XCTAssertThrowsError(try connection.scalar(SQLite.Table("sample").select(SQLite.Expression<Int64>("a")))) {
            XCTAssertTrue($0 is QueryError, "\($0)")
        }
    }

    func test_scalar_query_throws_on_no_row() throws {
        let connection = healthyConnection()
        try connection.execute("CREATE TABLE sample (a INTEGER)")
        XCTAssertThrowsError(try connection.scalar(SQLite.Table("sample").select(SQLite.Expression<Int64>("a")))) {
            XCTAssertTrue($0 is QueryError, "\($0)")
        }
    }

    func test_execute_reports_corruption() throws {
        try assertStatementDeletesUnreadableFile(writing: writeThreeModules) {
            XCTAssertThrowsError(try $0.database.execute("SELECT * FROM module"))
        }
    }

    func test_run_reports_corruption() throws {
        try assertStatementDeletesUnreadableFile(writing: writeThreeModules) {
            XCTAssertThrowsError(try $0.database.run("DELETE FROM module WHERE name = ?", "b"))
        }
    }

    func test_scalar_reports_corruption() throws {
        try assertStatementDeletesUnreadableFile(writing: writeThreeModules) {
            XCTAssertThrowsError(try $0.database.scalar("SELECT name FROM module WHERE name = ?", "b"))
        }
    }

    func test_rows_reports_an_unreadable_row() throws {
        try assertStatementDeletesUnreadableFile(writing: writeThreeModules) {
            XCTAssertThrowsError(try $0.database.rows("SELECT * FROM module"))
        }
    }

    // MARK: - Checkpoint

    func test_checkpoint_reports_corruption() throws {
        // The schema page is unreadable, so SQLite reports SQLITE_CORRUPT as soon as the pragma loads the schema.
        let (connection, path) = try connectionToFileWithCorruptSchemaPage()
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        XCTAssertThrowsError(try connection.checkpoint())
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    func test_checkpoint_error_that_is_not_corruption_does_not_report_corruption() throws {
        // A read-only connection can't checkpoint: SQLITE_READONLY.
        let (connection, path) = try readOnlyConnectionToNewFile()
        XCTAssertThrowsError(try connection.checkpoint())
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func test_corruption_closes_the_connection_then_deletes_the_file_and_logs_once() throws {
        for code in [SQLITE_CORRUPT, SQLITE_NOTADB, SQLITE_CORRUPT_INDEX] {
            let (connection, trace, path) = try fileConnectionWithFailFunction()
            let error = try XCTUnwrapThrownError { try connection.execute("SELECT fail(\(code))") }
            XCTAssertEqual(DatabaseHelper.corruptionCode(error), code)
            XCTAssertTrue("\(error)".hasPrefix("injected"), "\(error)")
            // Closed now; `removals(of:whileConnectionIs: .closed)` below shows it was closed at each removal.
            XCTAssertNil(trace.openConnection, "code \(code)")
            XCTAssertConnectionClosed(try XCTUnwrapThrownError { try connection.execute("SELECT 1") }, causedBy: error)
            XCTAssertEqual(trace.events, removals(of: path, whileConnectionIs: .closed) + ["log: " + DatabaseCorruptionLogs.fileDeleted(path: path, error: error)], "code \(code)")
            XCTAssertFalse(FileManager.default.fileExists(atPath: path), "code \(code)")
        }
    }

    func test_later_calls_throw_the_closed_error_with_the_original_cause_and_do_not_report_again() throws {
        let (connection, trace, _) = try fileConnectionWithFailFunction()
        let original = try XCTUnwrapThrownError { try connection.execute("SELECT fail(\(SQLITE_CORRUPT))") }
        let handled = trace.events
        XCTAssertConnectionClosed(try XCTUnwrapThrownError { try connection.execute("SELECT fail(\(SQLITE_CORRUPT))") }, causedBy: original)
        for operation in everyOperation {
            XCTAssertConnectionClosed(try XCTUnwrapThrownError { try operation.run(connection) }, causedBy: original)
        }
        XCTAssertEqual(trace.events, handled, "A closed connection must not report again")
    }

    func test_every_row_operation_reports_corruption() throws {
        // The statements on `module` read unreadable pages. `transaction` and `checkpoint` have their own tests.
        for operation in rowOperations {
            try assertStatementDeletesUnreadableFile(writing: writeThreeModules, message: operation.name) {
                XCTAssertThrowsError(try operation.run($0.database), operation.name)
            }
        }
    }

    func test_a_transaction_takes_the_write_lock_when_it_begins() throws {
        let (connection, _, path) = try fileConnectionWithFailFunction()
        try connection.transaction {
            // Nothing was written yet in the block, but another connection already can't start a write.
            let other = try Connection(path)
            other.busyTimeout = 0
            XCTAssertThrowsError(try other.execute("BEGIN IMMEDIATE")) { error in
                XCTAssertEqual((error as? SQLite.Result)?.resultCode, SQLITE_BUSY)
            }
        }
        // The lock is released with the transaction.
        let other = try Connection(path)
        other.busyTimeout = 0
        try other.execute("BEGIN IMMEDIATE; ROLLBACK")
    }

    func test_errors_that_are_not_corruption_do_not_delete() throws {
        struct OtherError: Error { }
        let (connection, trace, path) = try fileConnectionWithFailFunction()
        let codes = [SQLITE_IOERR, SQLITE_IOERR_READ, SQLITE_BUSY, SQLITE_LOCKED, SQLITE_AUTH, SQLITE_CANTOPEN, SQLITE_PERM, SQLITE_FULL,
                     SQLITE_READONLY, SQLITE_READONLY_DBMOVED, SQLITE_ERROR]
        for code in codes {
            let error = try XCTUnwrapThrownError { try connection.execute("SELECT fail(\(code))") }
            XCTAssertEqual((error as? SQLite.Result)?.resultCode, code)
        }
        let rawSQL: [(DatabaseConnection) throws -> Void] = [
            { try $0.execute("NOT SQL") }, { try $0.run("NOT SQL") }, { _ = try $0.scalar("NOT SQL") }, { _ = try $0.rows("NOT SQL") }
        ]
        for operation in rawSQL {
            XCTAssertThrowsError(try operation(connection))
        }
        XCTAssertThrowsError(try connection.transaction { throw OtherError() }) { XCTAssertTrue($0 is OtherError, "\($0)") }
        XCTAssertEqual(trace.events, ["BEGIN IMMEDIATE TRANSACTION", "ROLLBACK TRANSACTION"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        try connection.run("INSERT INTO module (name) VALUES (?)", "still works")
        XCTAssertEqual(try connection.scalar("SELECT COUNT(*) FROM module") as? Int64, 1)
    }

    func test_in_memory_database_is_logged_not_deleted_and_fails_fast() throws {
        let trace = ConnectionTrace()
        let logger = recordingLogger(trace)
        let connection = DatabaseConnection(connection: trace.watch(try DatabaseProvider.getInMemoryDatabase().addingFailFunction()),
                                            onCorruption: { DatabaseProvider.deleteCorruptDatabase(helper: nil, logger: logger, error: $0) })
        let original = try XCTUnwrapThrownError { try connection.execute("SELECT fail(\(SQLITE_CORRUPT))") }
        let logged = ["log: " + DatabaseCorruptionLogs.inMemory(error: original)]
        XCTAssertEqual(trace.events, logged)
        XCTAssertConnectionClosed(try XCTUnwrapThrownError { try connection.execute("SELECT 1") }, causedBy: original)
        XCTAssertEqual(trace.events, logged, "Logged once")
    }

    func test_corruption_in_a_transaction_closes_then_deletes_and_nested_calls_fail_fast() throws {
        let (connection, trace, path) = try fileConnectionWithFailFunction()
        var original: Error?
        let thrown = try XCTUnwrapThrownError {
            try connection.transaction {
                try connection.run("INSERT INTO module (name) VALUES (?)", "rolled back")
                original = try XCTUnwrapThrownError { try connection.rows("SELECT fail(\(SQLITE_CORRUPT))") }
                // Closed and deleted mid-transaction.
                XCTAssertNil(trace.openConnection)
                XCTAssertFalse(FileManager.default.fileExists(atPath: path))
                // Nested calls fail fast.
                XCTAssertConnectionClosed(try XCTUnwrapThrownError { try connection.rows("SELECT name FROM module") }, causedBy: try XCTUnwrap(original))
                trace.append("block ends")
                throw try XCTUnwrap(original)
            }
        }
        let corruption = try XCTUnwrap(original)
        // The block's error; the `ROLLBACK` didn't run on the closed connection.
        XCTAssertEqual("\(thrown)", "\(corruption)")
        XCTAssertEqual(DatabaseHelper.corruptionCode(thrown), SQLITE_CORRUPT)
        XCTAssertEqual(trace.events, ["BEGIN IMMEDIATE TRANSACTION"] + removals(of: path, whileConnectionIs: .closed) + ["log: " + DatabaseCorruptionLogs.fileDeleted(path: path, error: corruption)]
                       + ["block ends"])
        XCTAssertConnectionClosed(try XCTUnwrapThrownError { try connection.transaction { } }, causedBy: corruption)
    }

    func test_a_transaction_whose_block_catches_the_corruption_throws_and_deletes_once() throws {
        let (connection, trace, path) = try fileConnectionWithFailFunction()
        var original: Error?
        XCTAssertThrowsError(try connection.transaction {
            original = try XCTUnwrapThrownError { try connection.execute("SELECT fail(\(SQLITE_CORRUPT))") }
        })
        let corruption = try XCTUnwrap(original)
        XCTAssertNil(trace.openConnection)
        // Whatever `transaction` throws at its end passes through, and is not handled again.
        let handled = trace.events.filter { !$0.hasSuffix("TRANSACTION") }
        XCTAssertEqual(handled, removals(of: path, whileConnectionIs: .closed) + ["log: " + DatabaseCorruptionLogs.fileDeleted(path: path, error: corruption)])
    }

    func test_a_transaction_whose_block_swallows_a_notadb_error_throws_the_closed_error_and_deletes_once() throws {
        let (connection, trace, path) = try fileConnectionWithFailFunction()
        var original: Error?
        // SQLite ends the transaction itself, so what follows the swallowed `SQLITE_NOTADB` is a different error, or none: only the connection state shows it.
        let thrown = try XCTUnwrapThrownError {
            try connection.transaction {
                original = try XCTUnwrapThrownError { try connection.execute("SELECT fail(\(SQLITE_NOTADB))") }
            }
        }
        let corruption = try XCTUnwrap(original)
        XCTAssertConnectionClosed(thrown, causedBy: corruption)
        XCTAssertNil(trace.openConnection)
        XCTAssertEqual(trace.events.filter { !$0.hasSuffix("TRANSACTION") },
                       removals(of: path, whileConnectionIs: .closed) + ["log: " + DatabaseCorruptionLogs.fileDeleted(path: path, error: corruption)])
    }

    func test_corrupt_pages_read_in_a_transaction_delete_the_file() throws {
        try assertStatementDeletesUnreadableFile(writing: writeThreeModules) { provider in
            let connection = provider.database
            XCTAssertThrowsError(try connection.transaction { _ = try connection.rows("SELECT * FROM module") })
        }
    }

    // MARK: - Corruption partway through the rows

    func test_corruption_partway_through_raw_rows_deletes_and_a_new_provider_works() throws {
        try assertCorruptionPartwayThroughTheRowsDeletes { _ = try $0.rows("SELECT * FROM sample") }
    }

    func test_corruption_partway_through_typed_rows_deletes_and_a_new_provider_works() throws {
        try assertCorruptionPartwayThroughTheRowsDeletes { _ = try $0.rows(SQLite.Table("sample")) }
    }

    // MARK: - Same path

    func test_a_new_provider_at_the_same_path_keeps_its_uncheckpointed_writes_after_the_old_connection_closed_before_the_delete() throws {
        let (old, trace, path) = try fileConnectionWithFailFunction()
        // The same account and profile as the connection's: the same file.
        let config = fileDatabaseConfig()
        try old.run("INSERT INTO module (name) VALUES (?)", "old")
        XCTAssertThrowsError(try old.execute("SELECT fail(\(SQLITE_CORRUPT))"))
        XCTAssertNil(trace.openConnection, "The old connection closed before the delete")
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
        var provider: DatabaseProvider? = try DatabaseProvider(config: config)
        try provider?.database.run("INSERT INTO module (name) VALUES (?)", "new")
        // Not checkpointed: the row is only in the new -wal.
        XCTAssertTrue(FileManager.default.fileExists(atPath: path + "-wal"))
        provider = nil
        let reopened = try Connection(path)
        XCTAssertEqual(try reopened.prepareRowIterator("SELECT name FROM module ORDER BY name").map { $0[SQLite.Expression<String>("name")] }, ["new"])
        XCTAssertEqual(try integrityCheck(ofDatabaseAt: path), "ok")
    }
}

// MARK: - Helpers

extension DatabaseConnectionTests {
    private func healthyConnection() -> DatabaseConnection {
        MockDatabaseProvider().database
    }

    /// Writes three modules, so that the file has rows to make unreadable.
    private func writeThreeModules(to provider: DatabaseProviderProtocol) throws {
        for name in ["a", "b", "c"] {
            try provider.database.run("INSERT INTO module (name) VALUES (?)", name)
        }
    }

    /// A connection to a new database file, opened with `readonly`, whose corruption deletes the file.
    private func connectionToNewFile(readonly: Bool = false, beforeConnecting: (String) throws -> Void = { _ in }) throws
    -> (connection: DatabaseConnection, path: String) {
        let fileConfig = fileDatabaseConfig()
        try removeAccountFolderNowAndAtTeardown(account: fileConfig.account)
        _ = try DatabaseProvider.openDatabase(config: fileConfig)
        let path = try XCTUnwrap(fileConfig.databaseUrl()).path
        try beforeConnecting(path)
        let raw = try Connection(path, readonly: readonly)
        let helper = DatabaseHelper(databaseUrl: URL(fileURLWithPath: path), logger: nil)
        return (DatabaseConnection(connection: raw, onCorruption: { DatabaseProvider.deleteCorruptDatabase(helper: helper, logger: nil, error: $0) }), path)
    }

    /// While the file is closed: an open connection would serve the page from its cache.
    private func connectionToFileWithCorruptSchemaPage() throws -> (connection: DatabaseConnection, path: String) {
        try connectionToNewFile(beforeConnecting: { try corruptSchemaPage(atPath: $0) })
    }

    private func readOnlyConnectionToNewFile() throws -> (connection: DatabaseConnection, path: String) {
        try connectionToNewFile(readonly: true)
    }

    /// A connection on a new database file. Its corruption callback logs and removes files; `trace` records both, and whether the connection was
    /// open at each removal.
    private func fileConnectionWithFailFunction()
    throws -> (connection: DatabaseConnection, trace: ConnectionTrace, path: String) {
        let config = fileDatabaseConfig()
        try removeAccountFolderNowAndAtTeardown(account: config.account)
        let url = try XCTUnwrap(config.databaseUrl())
        do {
            // Creates the file, and closes it at the end of the scope.
            _ = try DatabaseProvider.openDatabase(config: config)
        }
        let trace = ConnectionTrace()
        let logger = recordingLogger(trace)
        let helper = DatabaseHelper(databaseUrl: url, logger: logger, removeFile: trace.recordedRemoveFile())
        let connection = DatabaseConnection(connection: trace.watch(try Connection(url.path).addingFailFunction()),
                                            onCorruption: { DatabaseProvider.deleteCorruptDatabase(helper: helper, logger: logger, error: $0) })
        return (connection, trace, url.path)
    }

    /// A logger that records every Persistence error in `trace`.
    private func recordingLogger(_ trace: ConnectionTrace) -> MockLogger {
        let logger = MockLogger()
        let subscription = logger.handler.onLogged.subscribe { [weak trace] event in
            if event.category == LogCategory.persistence && event.level == .error {
                trace?.append("log: \(event.message)")
            }
        }
        addTeardownBlock { subscription.dispose() }
        return logger
    }

    /// The removals of the database file at `path` and its sidecars.
    private func removals(of path: String, whileConnectionIs state: ConnectionState) -> [String] {
        let file = URL(fileURLWithPath: path).lastPathComponent
        return ([""] + SQLiteOpenHelper.sidecarSuffixes).map { "remove \(file)\($0), connection \(state.rawValue)" }
    }

    /// The `DatabaseConnection` methods that read or write rows of `module`, each as a statement that fails on unreadable pages.
    private var rowOperations: [(name: String, run: (DatabaseConnection) throws -> Void)] {
        let module = SQLite.Table("module")
        let name = SQLite.Expression<String>("name")
        return [
            ("rows(query)", { _ = try $0.rows(module) }),
            ("pluck", { _ = try $0.pluck(module) }),
            ("scalar(query)", { _ = try $0.scalar(module.count) }),
            ("run(insert)", { _ = try $0.run(module.insert(name <- "after")) }),
            ("run(delete)", { _ = try $0.run(module.delete()) })
        ]
    }

    /// The other `DatabaseConnection` methods, each as a statement that a closed connection must not run.
    private var nonRowOperations: [(name: String, run: (DatabaseConnection) throws -> Void)] {
        return [
            ("transaction", { try $0.transaction { } }),
            ("execute", { try $0.execute("SELECT 1") }),
            ("run(sql)", { try $0.run("INSERT INTO module (name) VALUES (?)", "after") }),
            ("scalar(sql)", { _ = try $0.scalar("SELECT 1") }),
            ("rows(sql)", { _ = try $0.rows("SELECT 1") }),
            ("checkpoint", { _ = try $0.checkpoint() })
        ]
    }

    private var everyOperation: [(name: String, run: (DatabaseConnection) throws -> Void)] {
        rowOperations + nonRowOperations
    }

    /// Stages `config`'s file with a `sample` table over several pages, then overwrites its last page, so that a scan of `sample` reads
    /// the first rows and fails on the last ones.
    private func stageTableWithUnreadableLastPage(config: TealiumConfig) throws -> String {
        let path = try XCTUnwrap(config.databaseUrl()).path
        do {
            let raw = try DatabaseProvider.openDatabase(config: config).connection
            try raw.execute("CREATE TABLE sample (value TEXT)")
            try raw.transaction {
                for index in 0..<500 {
                    try raw.run("INSERT INTO sample VALUES (?)", String(repeating: "x", count: 50) + "\(index)")
                }
            }
        }
        try corruptPage(try pageCount(ofDatabaseAt: path), atPath: path)
        do {
            let check = try Connection(path, readonly: true)
            XCTAssertNotNil(try check.scalar("SELECT value FROM sample WHERE rowid = 1"), "The first row should be readable")
            XCTAssertThrowsError(try Array(check.prepareRowIterator("SELECT * FROM sample")), "The last rows should be unreadable")
        }
        return path
    }

    private func assertCorruptionPartwayThroughTheRowsDeletes(_ read: (DatabaseConnection) throws -> Void,
                                                              file: StaticString = #filePath, line: UInt = #line) throws {
        let config = fileDatabaseConfig()
        try removeAccountFolderNowAndAtTeardown(account: config.account)
        let path = try stageTableWithUnreadableLastPage(config: config)
        let trace = ConnectionTrace()
        let helper = DatabaseHelper(databaseUrl: try XCTUnwrap(config.databaseUrl()), logger: nil, removeFile: trace.recordedRemoveFile())
        let logger = recordingLogger(trace)
        let connection = DatabaseConnection(connection: trace.watch(try Connection(path)),
                                            onCorruption: { DatabaseProvider.deleteCorruptDatabase(helper: helper, logger: logger, error: $0) })
        let error = try XCTUnwrapThrownError({ try read(connection) }, file: file, line: line)
        XCTAssertEqual(DatabaseHelper.corruptionCode(error), SQLITE_CORRUPT, file: file, line: line)
        // The statement is finished, so nothing holds the connection: it closed before the delete.
        XCTAssertNil(trace.openConnection, file: file, line: line)
        XCTAssertEqual(trace.events, removals(of: path, whileConnectionIs: .closed) + ["log: " + DatabaseCorruptionLogs.fileDeleted(path: path, error: error)], file: file, line: line)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path), file: file, line: line)
        let provider = try DatabaseProvider(config: config)
        try provider.database.run("INSERT INTO module (name) VALUES (?)", "new")
        XCTAssertEqual(try provider.database.scalar("SELECT COUNT(*) FROM module") as? Int64, 1, file: file, line: line)
        XCTAssertEqual(try provider.database.scalar("SELECT COUNT(*) FROM sqlite_master WHERE name = 'sample'") as? Int64, 0,
                       file: file, line: line)
    }
}

/// Whether the connection under test was open when a file was removed.
private enum ConnectionState: String {
    case open, closed
}

/// What a connection under test did, in order: transaction statements, file removals and Persistence errors logged.
private final class ConnectionTrace {
    private(set) var events = [String]()
    /// Weak: deallocating the connection under test closes it.
    weak var openConnection: Connection?

    func append(_ event: String) {
        events.append(event)
    }

    /// A `removeFile` that records the removal and whether the connection was open at that point, then removes the file.
    func recordedRemoveFile() -> (String) throws -> Void {
        return { [weak self] path in
            let file = URL(fileURLWithPath: path).lastPathComponent
            self?.append("remove \(file), connection \(self?.openConnection == nil ? "closed" : "open")")
            try SQLiteOpenHelper.defaultRemoveFile(path)
        }
    }

    /// Records `connection` and its transaction statements, and returns it.
    func watch(_ connection: Connection) -> Connection {
        openConnection = connection
        connection.trace { [weak self] sql in
            if ["BEGIN", "COMMIT", "ROLLBACK"].contains(where: sql.hasPrefix) {
                self?.append(sql)
            }
        }
        return connection
    }
}
