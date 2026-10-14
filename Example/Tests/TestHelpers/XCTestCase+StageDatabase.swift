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
    /// - Parameter userVersion: the `user_version` to stamp on the file afterwards, if not 1.
    /// - Returns: the path of the file.
    @discardableResult
    func stageVersion1Database(config: TealiumConfig, userVersion: Int? = nil) throws -> String {
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
        try staged?.run("PRAGMA user_version = \(userVersion ?? 1)")
        staged = nil
        return databaseUrl.path
    }

    /// Reads the `user_version` and the `module` names of the file at `path` with a fresh connection.
    func storedState(atPath path: String) throws -> (userVersion: Int64?, modules: [String]) {
        let connection = try Connection(path)
        let userVersion = try connection.scalar("PRAGMA user_version") as? Int64
        let modules = try connection.prepare("SELECT name FROM module ORDER BY id").compactMap { $0[0] as? String }
        return (userVersion, modules)
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
