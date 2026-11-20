//
//  XCTestCase+StageDatabase.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 09/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite
import SQLite3
@testable import TealiumPrism
import XCTest

/// Thrown when a test's setup can't be staged: the test fails at its call, with `description`.
struct StagingError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

extension XCTestCase {
    /// Stops staging, failing the test, if a file already exists at `path`.
    func requireNoFile(atPath path: String) throws {
        guard !FileManager.default.fileExists(atPath: path) else {
            throw StagingError("A file already exists at \(path): clean it up before staging")
        }
    }

    /// Stages a version 1 database file for `config` holding one `module` row named "marker", and closes it.
    ///
    /// The file is built from the frozen version-1 DDL (`FrozenSchemas.v1`), as 0.5.0 wrote it (rollback journal; 0.5.0 predates WAL),
    /// so it stays a real version-1 file whatever the live schema becomes. No file may exist at the path yet.
    ///
    /// - Parameters:
    ///   - userVersion: the `user_version` to stamp on the file afterwards, if not 1.
    ///   - rows: `module_storage` rows to add after the "marker" row, each in its module (created if needed), before the `user_version` stamp.
    ///     Values are the stored JSON text: JSON-quoted strings (e.g. `"abc"` with its quotes) and `expiry` -1 for `.forever`, as 0.6.0 wrote them.
    /// - Returns: the path of the file.
    @discardableResult
    func stageVersion1Database(config: TealiumConfig, userVersion: Int? = nil,
                               rows: [StoredRow] = []) throws -> String {
        let databaseUrl = try XCTUnwrap(config.databaseUrl(), "The config needs a databaseName to stage a file")
        let statements = try XCTUnwrap(FrozenSchemas.createStatements(for: 1), "No frozen version-1 schema")
        try requireNoFile(atPath: databaseUrl.path)
        var staged: Connection? = try Connection(databaseUrl.path)
        for statement in statements {
            try staged?.run(statement)
        }
        try staged?.run("INSERT INTO module (name) VALUES ('marker')")
        for row in rows {
            try staged?.run("INSERT OR IGNORE INTO module (name) VALUES (?)", row.module)
            try staged?.run("""
                INSERT INTO module_storage (module_id, key, value, expiry)
                VALUES ((SELECT id FROM module WHERE name = ?), ?, ?, ?)
                """, row.module, row.key, row.value, row.expiry)
        }
        try staged?.run("PRAGMA user_version = \(userVersion ?? 1)")
        staged = nil
        return databaseUrl.path
    }

    /// Overwrites the schema page (page 1) of the database file at `path`, after the 100-byte header, so that the version is still
    /// readable but the schema is not: SQLite reports `SQLITE_CORRUPT` as soon as it loads the schema.
    ///
    /// No connection may be open on the file, and a `-wal` next to it must be empty or absent, or the page would be read from there.
    func corruptSchemaPage(atPath path: String) throws {
        let handle = try XCTUnwrap(FileHandle(forUpdatingAtPath: path), "Could not open \(path) to corrupt it")
        defer { try? handle.close() }
        let pageSize = try Self.pageSize(of: handle)
        try handle.seek(toOffset: 100)
        handle.write(Data(repeating: 0xFF, count: pageSize - 100))
    }

    /// Overwrites the whole page `number` (1-based) of the database file at `path`, to corrupt what is stored in it.
    ///
    /// Same conditions as `corruptSchemaPage(atPath:)`.
    func corruptPage(_ number: Int, atPath path: String) throws {
        let handle = try XCTUnwrap(FileHandle(forUpdatingAtPath: path), "Could not open \(path) to corrupt it")
        defer { try? handle.close() }
        let pageSize = try Self.pageSize(of: handle)
        try handle.seek(toOffset: UInt64((number - 1) * pageSize))
        handle.write(Data(repeating: 0xFF, count: pageSize))
    }

    /// Overwrites the last 4 KB of the database file at `path` with pseudo-random bytes, as damage to the end of the file after the
    /// process is killed. The sequence is fixed, so every run damages the file the same way.
    ///
    /// Same conditions as `corruptSchemaPage(atPath:)`.
    private func overwriteTail(ofDatabaseAt path: String) throws {
        let handle = try XCTUnwrap(FileHandle(forUpdatingAtPath: path), "Could not open \(path) to corrupt it")
        defer { try? handle.close() }
        let size = try handle.seekToEnd()
        let count = min(4096, size)
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        let bytes = (0..<count).map { _ -> UInt8 in
            // xorshift64
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return UInt8(truncatingIfNeeded: state)
        }
        try handle.seek(toOffset: size - count)
        handle.write(Data(bytes))
    }

    /// Creates the database file for `config` through `DatabaseProvider`, lets `write` fill it, then overwrites every page but the
    /// schema page, and returns a provider on the file again, which deletes it when a statement finds it corrupt.
    ///
    /// Statements on the returned provider compile, as the schema is intact, but fail as soon as they read a row. No file may exist
    /// at the path yet.
    func providerWithUnreadableRows(in config: TealiumConfig, writing write: (DatabaseProviderProtocol) throws -> Void) throws -> DatabaseProvider {
        let url = try XCTUnwrap(config.databaseUrl(), "The config needs a databaseName to stage a file")
        try requireNoFile(atPath: url.path)
        do {
            // Released at the end of the scope, so the connection closes and folds the -wal back into the file.
            try write(try DatabaseProvider(config: config))
        }
        let pageCount = try pageCount(ofDatabaseAt: url.path)
        guard pageCount > 1 else {
            throw StagingError("Nothing but the schema was written to \(url.path)")
        }
        for page in stride(from: 2, through: pageCount, by: 1) {
            try corruptPage(page, atPath: url.path)
        }
        return DatabaseProvider(connection: try Connection(url.path), helper: DatabaseHelper(databaseUrl: url, logger: nil), logger: nil)
    }

    /// Runs `statement` on a provider over a file staged by `write` whose rows are unreadable, and asserts that it deletes the file.
    /// Each call stages its own file, as after the first corruption every statement fails fast without running.
    func assertStatementDeletesUnreadableFile(writing write: (DatabaseProviderProtocol) throws -> Void,
                                              message: String = "",
                                              _ statement: (DatabaseProviderProtocol) throws -> Void,
                                              file: StaticString = #filePath, line: UInt = #line) throws {
        let config = fileDatabaseConfig()
        try removeAccountFolderNowAndAtTeardown(account: config.account)
        let path = try XCTUnwrap(config.databaseUrl()).path
        let provider = try providerWithUnreadableRows(in: config, writing: write)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path), message, file: file, line: line)
        try statement(provider)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path), "The file was not deleted. \(message)", file: file, line: line)
    }

    /// Stores 500 dispatches in `config`'s database file, then damages its tail, as after the process is killed while writing.
    ///
    /// - Returns: the path of the file.
    @discardableResult
    func stageQueuedDispatchesWithDamagedTail(config: TealiumConfig) throws -> String {
        let path = try XCTUnwrap(config.databaseUrl(), "The config needs a databaseName to stage a file").path
        do {
            // Released at the end of the scope, so the connection closes and folds the -wal back into the file.
            let repository = SQLQueueRepository(dbProvider: try DatabaseProvider(config: config), maxQueueSize: 500, expiration: 1.days)
            try repository.storeDispatches((1...500).map { Dispatch(name: "queued_\($0)") }, enqueueingFor: [MockDispatcher.moduleType])
        }
        try overwriteTail(ofDatabaseAt: path)
        return path
    }

    /// Creates the database file for `config` and leaves a -journal, -wal and -shm next to it, filled with garbage. Returns the paths of
    /// the database file and of the three sidecars.
    func stageDatabaseFileWithSidecars(config: TealiumConfig) throws -> (database: String, sidecars: [String]) {
        _ = try DatabaseProvider.openDatabase(config: config)
        let databasePath = try XCTUnwrap(config.databaseUrl(), "The config needs a databaseName").path
        let sidecars = Array(databaseFiles(atPath: databasePath).dropFirst())
        for sidecar in sidecars {
            guard FileManager.default.createFile(atPath: sidecar, contents: Data(repeating: 0x42, count: 4096)) else {
                throw StagingError("Could not create \(sidecar)")
            }
        }
        return (databasePath, sidecars)
    }

    /// The number of pages in the database file at `path`, from its size and the page size in its header.
    func pageCount(ofDatabaseAt path: String) throws -> Int {
        let handle = try XCTUnwrap(FileHandle(forReadingAtPath: path), "Could not open \(path)")
        defer { try? handle.close() }
        let pageSize = try Self.pageSize(of: handle)
        return Int(try handle.seekToEnd()) / pageSize
    }

    /// The root page of `table` in the database file at `path`, read with a fresh connection.
    func rootPage(of table: String, atPath path: String) throws -> Int {
        let connection = try Connection(path, readonly: true)
        let rootPage = try connection.scalar("SELECT rootpage FROM sqlite_master WHERE name = ?", table) as? Int64
        return Int(try XCTUnwrap(rootPage, "No table \(table) in \(path)"))
    }

    /// The page size stored in the header of the database file: 2 bytes big-endian at offset 16 (1 means 65536).
    private static func pageSize(of handle: FileHandle) throws -> Int {
        try handle.seek(toOffset: 16)
        let bytes = try XCTUnwrap(try handle.read(upToCount: 2), "Could not read the page size")
        let size = Int(bytes[bytes.startIndex]) << 8 | Int(bytes[bytes.startIndex + 1])
        return size == 1 ? 65_536 : size
    }

    /// Reads the `user_version` and the `module` names of the file at `path` with a fresh connection.
    func storedState(atPath path: String) throws -> (userVersion: Int64?, modules: [String]) {
        let connection = try Connection(path, readonly: true)
        let userVersion = try connection.scalar("PRAGMA user_version") as? Int64
        let modules = try connection.prepare("SELECT name FROM module ORDER BY id").compactMap { $0[0] as? String }
        return (userVersion, modules)
    }

    /// A `module_storage` row joined with the name of its module.
    struct StoredRow: Equatable {
        let module: String
        let key: String
        let value: String
        let expiry: Int64
    }

    /// Reads the `module_storage` rows of the file at `path` with a fresh connection, ordered by module name and key.
    /// `value` is the stored JSON text, so a string comes back JSON-quoted (e.g. `"abc"` with its quotes); `expiry` is -1 for `.forever`.
    func storedRows(atPath path: String) throws -> [StoredRow] {
        let connection = try Connection(path, readonly: true)
        let query = "SELECT m.name, s.key, s.value, s.expiry FROM module_storage s JOIN module m ON m.id = s.module_id ORDER BY m.name, s.key"
        return try connection.prepare(query).map { row in
            let module = try XCTUnwrap(row[0] as? String, "module name is not TEXT")
            let key = try XCTUnwrap(row[1] as? String, "key of a \(module) row is not TEXT")
            let value = try XCTUnwrap(row[2] as? String, "value of \(module)/\(key) is not TEXT")
            let expiry = try XCTUnwrap(row[3] as? Int64, "expiry of \(module)/\(key) is not INTEGER")
            return StoredRow(module: module, key: key, value: value, expiry: expiry)
        }
    }
}
