//
//  DatabaseProviderTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 15/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumPrism
import XCTest

final class DatabaseProviderTests: XCTestCase {
    /// The test account's folder. Only this is cleaned up, not the whole `tealium-prism` one, which unsandboxed apps share on macOS.
    var path = ""
    var config = mockConfig
    override func setUp() {
        path = (try? TealiumFileManager.getTealiumApplicationFolder().appendingPathComponent(config.account).path) ?? ""
        try? TealiumFileManager.deleteAtPath(path: path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    override func tearDown() {
        try? TealiumFileManager.deleteAtPath(path: path)
    }

    func test_inMemory_db_is_created() throws {
        let database = XCTAssertNoThrowReturn(try DatabaseProvider.getInMemoryDatabase())
        XCTAssertNotNil(database)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    func test_persistent_db_is_created() throws {
        config.databaseName = "tealium"
        let database = try DatabaseProvider(config: config).database
        XCTAssertFalse(isInMemory(database))
        let suffix = "/tealium-prism/mock_account/mock_profile/tealium.sqlite3"
        XCTAssertTrue(filename(of: database).hasSuffix(suffix), "\(filename(of: database)) should have suffix \(suffix)")
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func test_no_database_name_opens_an_in_memory_db() throws {
        config.databaseName = nil
        let database = try DatabaseProvider.openDatabase(config: config)
        XCTAssertTrue(isInMemory(database))
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    // MARK: - Logging

    /// Opens the database for `config` with `helperFactory`, and returns it with the Persistence errors and warnings logged meanwhile.
    private func open(_ helperFactory: @escaping (URL, LoggerProtocol?) -> DatabaseHelper = { DatabaseHelper(databaseUrl: $0, logger: $1) })
    throws -> (database: Connection, errors: [String], warnings: [String]) {
        let logger = MockLogger()
        var errors = [String]()
        var warnings = [String]()
        let subscription = logger.handler.onLogged.subscribe { event in
            guard event.category == LogCategory.persistence else { return }
            if event.level == .error {
                errors.append(event.message)
            } else if event.level == .warn {
                warnings.append(event.message)
            }
        }
        defer { subscription.dispose() }
        let database = try DatabaseProvider.openDatabase(config: config, logger: logger, helperFactory: helperFactory)
        return (database, errors, warnings)
    }

    private func filename(of connection: Connection) -> String {
        connection.description
    }

    /// SQLite reports an empty file name for an in-memory database.
    private func isInMemory(_ connection: Connection) -> Bool {
        filename(of: connection).isEmpty
    }

    /// The error `DatabaseProvider` logs when it falls back to in-memory storage, ending with `errorDescription`.
    private func fallback(_ reason: String, fileKept: Bool, errorDescription: String) -> String {
        "Using in-memory storage for this session because \(reason)."
            + (fileKept ? " The database file is kept." : "")
            + " Nothing stored will survive this process. Error: \(errorDescription)"
    }

    private func recreateLog(_ reason: String) -> String {
        "Deleting and recreating the database file because \(reason). Data in it is lost."
    }

    private let newerVersionReason = "its version \(DatabaseHelper.DATABASE_VERSION + 1) is newer than this SDK's version \(DatabaseHelper.DATABASE_VERSION)"

    func test_normal_open_logs_nothing() throws {
        config.databaseName = "tealium"
        // A fresh install creates the file, the next launch reopens it.
        for _ in 1...2 {
            let (database, errors, warnings) = try open()
            XCTAssertFalse(isInMemory(database))
            XCTAssertEqual(errors, [])
            XCTAssertEqual(warnings, [])
        }
    }

    func test_failed_backup_exclusion_logs_one_warning_and_the_database_is_still_persistent() throws {
        struct ExcludeError: Error { }
        config.databaseName = "tealium"
        let (database, errors, warnings) = try open { databaseUrl, logger in
            DatabaseHelper(databaseUrl: databaseUrl, logger: logger, excludeFromBackup: { _ in throw ExcludeError() })
        }
        XCTAssertFalse(isInMemory(database))
        let failures = ["tealium.sqlite3", "tealium.sqlite3-wal", "tealium.sqlite3-shm"].map { " \($0): \(ExcludeError())" }
        XCTAssertEqual(warnings, [
            "The database files could not be excluded from backup; they are used anyway and the exclusion is retried on the next launch."
            + failures.joined(separator: ";")
        ])
        XCTAssertEqual(errors, [])
    }

    func test_downgraded_db_is_deleted_recreated_and_logged() throws {
        config.databaseName = "tealium"
        let databasePath = try stageVersion1Database(config: config, userVersion: DatabaseHelper.DATABASE_VERSION + 1)
        var opened = Optional(try open())
        XCTAssertEqual(opened?.errors, [recreateLog(newerVersionReason)])
        XCTAssertEqual(opened?.warnings, [])
        XCTAssertFalse(isInMemory(try XCTUnwrap(opened?.database)))
        XCTAssertEqual(opened?.database.userVersion.map(Int.init), DatabaseHelper.DATABASE_VERSION)
        opened = nil
        let state = try storedState(atPath: databasePath)
        XCTAssertEqual(state.userVersion, Int64(DatabaseHelper.DATABASE_VERSION))
        XCTAssertEqual(state.modules, [])
    }

    func test_failed_delete_uses_memory_keeps_the_file_and_does_not_reopen_it() throws {
        struct RemoveError: Error { }
        config.databaseName = "tealium"
        let mainPath = try stageVersion1Database(config: config, userVersion: DatabaseHelper.DATABASE_VERSION + 1)
        // Every open excludes the main file from backup, so a reopen would show up after the removal.
        var events = [String]()
        let (database, errors, _) = try open { databaseUrl, logger in
            DatabaseHelper(databaseUrl: databaseUrl,
                           logger: logger,
                           excludeFromBackup: { events.append("exclude \($0.lastPathComponent)") },
                           removeFile: { path in
                events.append("remove \(URL(fileURLWithPath: path).lastPathComponent)")
                if path == mainPath { throw RemoveError() }
            })
        }
        XCTAssertTrue(isInMemory(database))
        XCTAssertEqual(errors, [
            recreateLog(newerVersionReason),
            fallback("the database file could not be deleted", fileKept: true, errorDescription: "\(RemoveError())")
        ])
        XCTAssertEqual(events.first, "exclude tealium.sqlite3")
        XCTAssertEqual(events.filter { $0.hasPrefix("remove") }, ["remove tealium.sqlite3"])
        XCTAssertEqual(events.last, "remove tealium.sqlite3")
        XCTAssertEqual(try storedState(atPath: mainPath).modules, ["marker"])
    }

    func test_failed_sidecar_delete_is_a_warning_and_a_failed_reopen_does_not_keep_the_file() throws {
        struct RemoveError: Error { }
        config.databaseName = "tealium"
        let mainPath = try stageVersion1Database(config: config, userVersion: DatabaseHelper.DATABASE_VERSION + 1)
        let (database, errors, warnings) = try open { databaseUrl, logger in
            FailingCreateDatabaseHelper(databaseUrl: databaseUrl, logger: logger, removeFile: { path in
                if path == mainPath + "-wal" { throw RemoveError() }
                try SQLiteOpenHelper.defaultRemoveFile(path)
            })
        }
        XCTAssertTrue(isInMemory(database))
        XCTAssertEqual(warnings, [
            "The database file was deleted, but some of its sidecar files could not be removed; SQLite discards them next to the new file. tealium.sqlite3-wal: RemoveError()"
        ])
        XCTAssertEqual(errors, [
            recreateLog(newerVersionReason),
            fallback("the recreated database file could not be opened", fileKept: false, errorDescription: "\(FailingCreateDatabaseHelper.CreateError())")
        ])
    }

    func test_unavailable_file_location_logs_the_in_memory_fallback() throws {
        config.databaseName = "tealium"
        try blockAccountFolder(config.account)
        let (database, errors, _) = try open()
        XCTAssertTrue(isInMemory(database))
        XCTAssertEqual(errors.count, 1)
        // The error is a real `NSError`, whose description embeds object addresses.
        let prefix = fallback("the database file location could not be created", fileKept: false, errorDescription: "")
        XCTAssertTrueOptional(errors.first?.hasPrefix(prefix))
        XCTAssertGreaterThan(errors.first?.count ?? 0, prefix.count)
        XCTAssertTrueOptional(errors.first?.contains("Domain=NSCocoaErrorDomain Code=512"))
        XCTAssertTrueOptional(errors.first?.contains("Domain=NSPOSIXErrorDomain Code=20"))
    }

    // MARK: - Upgrade failures

    private let upgradeFailure = "the upgrade to version 2 failed"

    func test_failed_upgrade_uses_memory_keeps_the_file_and_logs_the_version() throws {
        config.databaseName = "tealium"
        let databasePath = try stageVersion1Database(config: config)
        let (database, errors, _) = try open { databaseUrl, logger in
            DatabaseHelper(databaseUrl: databaseUrl, logger: logger, version: 2, upgrades: [
                TestUpgrade(targetVersion: 2) { _ in throw StepError() }
            ])
        }
        XCTAssertTrue(isInMemory(database))
        XCTAssertEqual(errors, [fallback(upgradeFailure, fileKept: true, errorDescription: "\(StepError())")])
        let state = try storedState(atPath: databasePath)
        XCTAssertEqual(state.userVersion, 1)
        XCTAssertEqual(state.modules, ["marker"])
    }

    func test_broken_chain_uses_memory_keeps_the_file_and_logs_the_chain() throws {
        config.databaseName = "tealium"
        let databasePath = try stageVersion1Database(config: config)
        let (database, errors, _) = try open { databaseUrl, logger in
            DatabaseHelper(databaseUrl: databaseUrl, logger: logger, version: 2, upgrades: [])
        }
        XCTAssertTrue(isInMemory(database))
        XCTAssertEqual(errors, [
            fallback(upgradeFailure, fileKept: true, errorDescription: "Upgrade chain from 1 to 2 is not contiguous: expected [2], registered []")
        ])
        let state = try storedState(atPath: databasePath)
        XCTAssertEqual(state.userVersion, 1)
        XCTAssertEqual(state.modules, ["marker"])
    }

    func test_open_after_a_failed_upgrade_upgrades_the_same_file() throws {
        config.databaseName = "tealium"
        let databasePath = try stageVersion1Database(config: config)
        let failed = try DatabaseProvider.openDatabase(config: config) { databaseUrl, logger in
            DatabaseHelper(databaseUrl: databaseUrl, logger: logger, version: 2, upgrades: [
                TestUpgrade(targetVersion: 2) { _ in throw StepError() }
            ])
        }
        XCTAssertTrue(isInMemory(failed))
        var upgraded: Connection? = try DatabaseProvider.openDatabase(config: config) { databaseUrl, logger in
            DatabaseHelper(databaseUrl: databaseUrl, logger: logger, version: 2, upgrades: [TestUpgrade(targetVersion: 2)])
        }
        XCTAssertFalse(isInMemory(try XCTUnwrap(upgraded)))
        upgraded = nil
        let state = try storedState(atPath: databasePath)
        XCTAssertEqual(state.userVersion, 2)
        XCTAssertEqual(state.modules, ["marker"])
    }

    func test_garbage_header_fails_the_open_before_any_transaction_keeps_the_file_and_logs_the_cause() throws {
        config.databaseName = "tealium"
        let fileUrl = try XCTUnwrap(config.databaseUrl())
        let garbage = Data(repeating: 0x41, count: 4096)
        XCTAssertTrue(FileManager.default.createFile(atPath: fileUrl.path, contents: garbage))
        // A failed version read used to pass for version 0, and so for a fresh install whose `onCreate` would log `CreateError`.
        let (database, errors, _) = try open { databaseUrl, logger in
            FailingCreateDatabaseHelper(databaseUrl: databaseUrl, logger: logger)
        }
        XCTAssertTrue(isInMemory(database))
        XCTAssertEqual(FileManager.default.contents(atPath: fileUrl.path), garbage)
        XCTAssertEqual(errors.count, 2)
        XCTAssertEqual(errors.first, "Could not enable WAL journal mode (got nil); if the database opens, it uses the rollback journal instead. Error: file is not a database (code: 26)")
        XCTAssertEqual(errors.last, fallback("the database file could not be opened", fileKept: true, errorDescription: "file is not a database (code: 26)"))
    }

    func test_database_below_the_minimum_version_is_deleted_and_recreated() throws {
        config.databaseName = "tealium"
        let databasePath = try stageVersion1Database(config: config, userVersion: -1)
        var opened = Optional(try open())
        XCTAssertEqual(opened?.errors, [
            recreateLog("its version -1 is below the minimum supported version \(DatabaseHelper.MIN_SUPPORTED_VERSION)")
        ])
        XCTAssertFalse(isInMemory(try XCTUnwrap(opened?.database)))
        XCTAssertEqual(opened?.database.userVersion.map(Int.init), DatabaseHelper.DATABASE_VERSION)
        opened = nil
        let state = try storedState(atPath: databasePath)
        XCTAssertEqual(state.userVersion, Int64(DatabaseHelper.DATABASE_VERSION))
        XCTAssertEqual(state.modules, [])
    }
}

/// A `DatabaseHelper` whose `onCreate` fails, to exercise the provider's fallbacks.
private class FailingCreateDatabaseHelper: DatabaseHelper {
    struct CreateError: Error { }

    override func onCreate(database: Connection) throws {
        throw CreateError()
    }
}
