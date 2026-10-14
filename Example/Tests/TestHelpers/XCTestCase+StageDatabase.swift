//
//  XCTestCase+StageDatabase.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 09/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumPrism
import XCTest

extension XCTestCase {
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
        guard !FileManager.default.fileExists(atPath: databaseUrl.path) else {
            struct StagingError: Error, CustomStringConvertible {
                let description: String
            }
            let error = StagingError(description: "A database file already exists at \(databaseUrl.path): clean it up before staging")
            XCTFail("\(error)")
            throw error
        }
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

    /// Puts a regular file where `account`'s folder goes, so that creating the folder fails, and removes it at teardown.
    func blockAccountFolder(_ account: String) throws {
        let tealiumFolder = try TealiumFileManager.getTealiumApplicationFolder()
        let accountPath = tealiumFolder.appendingPathComponent(account).path
        try FileManager.default.createDirectory(at: tealiumFolder, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(atPath: accountPath)
        XCTAssertTrue(FileManager.default.createFile(atPath: accountPath, contents: Data()))
        addTeardownBlock { try? FileManager.default.removeItem(atPath: accountPath) }
    }
}
