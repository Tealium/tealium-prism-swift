//
//  DatabaseProviderTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 15/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import SQLite
import SQLite3
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
        XCTAssertFalse(try isInMemory(database))
        let suffix = "/tealium-prism/mock_account/mock_profile/tealium.sqlite3"
        let name = try filename(of: database)
        XCTAssertTrue(name.hasSuffix(suffix), "\(name) should have suffix \(suffix)")
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func test_no_database_name_opens_an_in_memory_db() throws {
        config.databaseName = nil
        let database = try DatabaseProvider.openDatabase(config: config).connection
        XCTAssertTrue(isInMemory(database))
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    // MARK: - Logging

    /// Opens the database for `config` with `helperFactory`, and returns it with the Persistence errors and warnings logged meanwhile.
    private func open(_ helperFactory: @escaping (URL, LoggerProtocol?) -> DatabaseHelper = { DatabaseHelper(databaseUrl: $0, logger: $1) })
    throws -> (database: Connection, errors: [String], warnings: [String]) {
        let logger = MockLogger()
        var database: Connection?
        let events = try logger.handler.eventsLoggedWhileExecuting {
            database = try DatabaseProvider.openDatabase(config: config, logger: logger, helperFactory: helperFactory).connection
        }
        return (try XCTUnwrap(database),
                events.messages(at: .error, in: LogCategory.persistence),
                events.messages(at: .warn, in: LogCategory.persistence))
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
        }.connection
        XCTAssertTrue(isInMemory(failed))
        var upgraded: Connection? = try DatabaseProvider.openDatabase(config: config) { databaseUrl, logger in
            DatabaseHelper(databaseUrl: databaseUrl, logger: logger, version: 2, upgrades: [TestUpgrade(targetVersion: 2)])
        }.connection
        XCTAssertFalse(isInMemory(try XCTUnwrap(upgraded)))
        upgraded = nil
        let state = try storedState(atPath: databasePath)
        XCTAssertEqual(state.userVersion, 2)
        XCTAssertEqual(state.modules, ["marker"])
    }

    // MARK: - Corruption

    private let garbage = Data(repeating: 0x41, count: 4096)
    private let notADatabase = "file is not a database (code: 26)"

    /// Checks that `database` is a fresh, current, file-backed database at `databasePath`.
    private func assertRecreated(_ database: Connection,
                                 atPath databasePath: String,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) {
        XCTAssertFalse(isInMemory(database), file: file, line: line)
        XCTAssertEqual(database.userVersion.map(Int.init), DatabaseHelper.DATABASE_VERSION, file: file, line: line)
        for table in ["dispatch", "queue", "module", "module_storage"] {
            XCTAssertTrue(database.tableExists(tableName: table), "\(table) is missing", file: file, line: line)
        }
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM module") as? Int64, 0, file: file, line: line)
        XCTAssertEqual(filename(of: database), databasePath, file: file, line: line)
    }

    /// Checks that the next launch opens the database file on disk without logging anything. The previous connection must be released.
    private func assertNextLaunchOpensSilently(file: StaticString = #filePath, line: UInt = #line) throws {
        let reopened = try open()
        XCTAssertFalse(isInMemory(reopened.database), file: file, line: line)
        XCTAssertEqual(reopened.errors, [], file: file, line: line)
        XCTAssertEqual(reopened.warnings, [], file: file, line: line)
    }

    func test_garbage_header_is_deleted_and_recreated_and_logs_the_code() throws {
        config.databaseName = "tealium"
        let fileUrl = try XCTUnwrap(config.databaseUrl())
        XCTAssertTrue(FileManager.default.createFile(atPath: fileUrl.path, contents: garbage))
        var opened = Optional(try open())
        XCTAssertEqual(opened?.errors, [recreateLog("it is corrupt (SQLite code 26)")])
        assertRecreated(try XCTUnwrap(opened?.database), atPath: fileUrl.path)
        opened = nil
        try assertNextLaunchOpensSilently()
    }

    func test_corrupt_schema_page_at_the_current_version_is_deleted_and_recreated() throws {
        config.databaseName = "tealium"
        // Discarded at once, so the connection closes and the file is left at the current version.
        _ = try DatabaseProvider.openDatabase(config: config)
        let fileUrl = try XCTUnwrap(config.databaseUrl())
        // The version in the header is still readable, so only `PRAGMA journal_mode = WAL`, which loads the schema, notices.
        try corruptSchemaPage(atPath: fileUrl.path)
        var opened = Optional(try open())
        XCTAssertEqual(opened?.errors, [recreateLog("it is corrupt (SQLite code 11)")])
        assertRecreated(try XCTUnwrap(opened?.database), atPath: fileUrl.path)
        opened = nil
        try assertNextLaunchOpensSilently()
    }

    func test_corruption_in_an_upgrade_step_deletes_and_recreates_the_file() throws {
        config.databaseName = "tealium"
        let databasePath = try stageVersion1Database(config: config, rows: [
            StoredRow(module: V1ToV2.sourceModuleName, key: V1ToV2.sourceKeyVisitorId, value: "\"abc\"", expiry: -1)
        ])
        // Only `V1ToV2` reads module_storage, so nothing before the upgrade step touches these pages.
        try corruptPage(try rootPage(of: "module_storage", atPath: databasePath), atPath: databasePath)
        try corruptPage(try rootPage(of: "sqlite_autoindex_module_storage_1", atPath: databasePath), atPath: databasePath)
        var opened = Optional(try open())
        XCTAssertEqual(opened?.errors, [recreateLog("the upgrade to version 2 hit a corrupt file (SQLite code 11)")])
        assertRecreated(try XCTUnwrap(opened?.database), atPath: databasePath)
        opened = nil
        XCTAssertEqual(try storedRows(atPath: databasePath), [])
    }

    func test_leftover_sidecars_of_a_corrupt_file_are_deleted_with_it() throws {
        config.databaseName = "tealium"
        let fileUrl = try XCTUnwrap(config.databaseUrl())
        // Left over from the corrupt file, so they don't belong to the new one: a -journal could be replayed into it.
        // Arbitrary bytes, only to tell them apart from the files SQLite creates for the new file.
        let leftover = Data(repeating: 0x42, count: 4096)
        XCTAssertTrue(FileManager.default.createFile(atPath: fileUrl.path, contents: garbage))
        let sidecars = SQLiteOpenHelper.sidecarSuffixes.map { fileUrl.path + $0 }
        for sidecar in sidecars {
            XCTAssertTrue(FileManager.default.createFile(atPath: sidecar, contents: leftover))
        }
        var opened = Optional(try open())
        XCTAssertEqual(opened?.errors, [recreateLog("it is corrupt (SQLite code 26)")])
        assertRecreated(try XCTUnwrap(opened?.database), atPath: fileUrl.path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileUrl.path + "-journal"))
        for sidecar in sidecars {
            XCTAssertNotEqual(FileManager.default.contents(atPath: sidecar), leftover, "\(sidecar) was not deleted")
        }
        opened = nil
        try assertNextLaunchOpensSilently()
    }

    // MARK: - Never delete on other errors

    func test_open_failures_that_are_not_corruption_use_memory_and_keep_the_file_untouched() throws {
        // What a locked or unreadable, but healthy, file reports.
        for code in [SQLITE_IOERR_READ, SQLITE_AUTH, SQLITE_CANTOPEN] {
            try? TealiumFileManager.deleteAtPath(path: path)
            config.databaseName = "tealium"
            var healthy: Connection? = try DatabaseProvider.openDatabase(config: config).connection
            try healthy?.run("INSERT INTO module (name) VALUES ('marker')")
            healthy = nil
            let fileUrl = try XCTUnwrap(config.databaseUrl())
            let before = try XCTUnwrap(FileManager.default.contents(atPath: fileUrl.path))
            let failure = injectedSQLiteError(code: code)
            let (database, errors, _) = try open { databaseUrl, logger in
                InjectedDatabaseHelper(databaseUrl: databaseUrl, logger: logger) { _ in failure }
            }
            XCTAssertTrue(isInMemory(database), "code \(code)")
            XCTAssertEqual(errors, [fallback("the database file could not be opened", fileKept: true, errorDescription: "\(failure)")], "code \(code)")
            XCTAssertEqual(FileManager.default.contents(atPath: fileUrl.path), before, "code \(code)")
        }
    }

    func test_WAL_failure_that_is_not_corruption_is_logged_and_the_file_is_used() throws {
        // A healthy file that can't switch to WAL, e.g. locked by another process.
        for code in [SQLITE_IOERR_READ, SQLITE_AUTH, SQLITE_CANTOPEN, SQLITE_BUSY] {
            try? TealiumFileManager.deleteAtPath(path: path)
            config.databaseName = "tealium"
            var healthy: Connection? = try DatabaseProvider.openDatabase(config: config).connection
            try healthy?.run("INSERT INTO module (name) VALUES ('marker')")
            healthy = nil
            let fileUrl = try XCTUnwrap(config.databaseUrl())
            let failure = injectedSQLiteError(code: code)
            let (database, errors, _) = try open { databaseUrl, logger in
                FailingWALDatabaseHelper(databaseUrl: databaseUrl, logger: logger, failure: failure)
            }
            XCTAssertFalse(isInMemory(database), "code \(code)")
            XCTAssertEqual(filename(of: database), fileUrl.path, "code \(code)")
            XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM module WHERE name = 'marker'") as? Int64, 1, "code \(code)")
            XCTAssertEqual(errors, ["Could not enable WAL journal mode (got nil); if the database opens, it uses the rollback journal instead. Error: \(failure)"],
                           "code \(code)")
        }
    }

    func test_unreadable_file_is_not_deleted() throws {
        config.databaseName = "tealium"
        var healthy: Connection? = try DatabaseProvider.openDatabase(config: config).connection
        try healthy?.run("INSERT INTO module (name) VALUES ('marker')")
        healthy = nil
        let fileUrl = try XCTUnwrap(config.databaseUrl())
        let before = try XCTUnwrap(FileManager.default.contents(atPath: fileUrl.path))
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: fileUrl.path)
        addTeardownBlock { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: fileUrl.path) }
        guard !FileManager.default.isReadableFile(atPath: fileUrl.path) else {
            throw XCTSkip("This environment still reads a file with no permissions")
        }
        let (database, errors, _) = try open()
        XCTAssertTrue(isInMemory(database))
        XCTAssertTrueOptional(errors.last?.hasPrefix("Using in-memory storage for this session because"))
        XCTAssertTrueOptional(errors.last?.contains("The database file is kept."))
        XCTAssertFalse(errors.contains { $0.hasPrefix("Deleting and recreating") })
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: fileUrl.path)
        XCTAssertEqual(FileManager.default.contents(atPath: fileUrl.path), before)
    }

    // MARK: - Recreate failures

    func test_corrupt_file_whose_recreated_open_fails_uses_memory_without_deleting_again() throws {
        config.databaseName = "tealium"
        let fileUrl = try XCTUnwrap(config.databaseUrl())
        XCTAssertTrue(FileManager.default.createFile(atPath: fileUrl.path, contents: garbage))
        let reopenFailure = SQLite.Result.error(message: "still corrupt", code: SQLITE_CORRUPT, statement: nil)
        var removed = [String]()
        let (database, errors, _) = try open { databaseUrl, logger in
            InjectedDatabaseHelper(databaseUrl: databaseUrl, logger: logger,
                                   removeFile: { path in
                removed.append(path)
                try SQLiteOpenHelper.defaultRemoveFile(path)
            }, failure: { $0 == 2 ? reopenFailure : nil })
        }
        XCTAssertTrue(isInMemory(database))
        XCTAssertEqual(errors.suffix(2), [
            recreateLog("it is corrupt (SQLite code 26)"),
            fallback("the recreated database file could not be opened", fileKept: false, errorDescription: "\(reopenFailure)")
        ])
        XCTAssertEqual(removed.filter { $0 == fileUrl.path }.count, 1)
    }

    func test_corrupt_file_that_cannot_be_deleted_uses_memory_keeps_the_file_and_does_not_reopen() throws {
        struct RemoveError: Error { }
        config.databaseName = "tealium"
        let fileUrl = try XCTUnwrap(config.databaseUrl())
        XCTAssertTrue(FileManager.default.createFile(atPath: fileUrl.path, contents: garbage))
        var helper: InjectedDatabaseHelper?
        let (database, errors, _) = try open { databaseUrl, logger in
            let created = InjectedDatabaseHelper(databaseUrl: databaseUrl, logger: logger, removeFile: { _ in throw RemoveError() }, failure: { _ in nil })
            helper = created
            return created
        }
        XCTAssertTrue(isInMemory(database))
        XCTAssertEqual(errors.suffix(2), [
            recreateLog("it is corrupt (SQLite code 26)"),
            fallback("the database file could not be deleted", fileKept: true, errorDescription: "\(RemoveError())")
        ])
        XCTAssertEqual(FileManager.default.contents(atPath: fileUrl.path), garbage)
        XCTAssertEqual(helper?.configureCalls, 1)
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

// MARK: - Corruption found by a statement

// An extension only to keep the class body within the lint limit.
extension DatabaseProviderTests {
    func test_openDatabase_returns_no_helper_for_an_in_memory_database() throws {
        config.databaseName = nil
        XCTAssertNil(try DatabaseProvider.openDatabase(config: config).helper)
    }

    func test_openDatabase_returns_the_helper_of_the_file_it_opened() throws {
        config.databaseName = "tealium"
        let opened = try DatabaseProvider.openDatabase(config: config)
        let expected = try XCTUnwrap(config.databaseUrl())
        XCTAssertEqual(try XCTUnwrap(opened.helper?.databaseUrl), expected)
    }

    func test_openDatabase_returns_the_helper_of_the_file_it_recreated() throws {
        config.databaseName = "tealium"
        let fileUrl = try XCTUnwrap(config.databaseUrl())
        XCTAssertTrue(FileManager.default.createFile(atPath: fileUrl.path, contents: garbage))
        let opened = try DatabaseProvider.openDatabase(config: config)
        XCTAssertFalse(isInMemory(opened.connection))
        XCTAssertEqual(try XCTUnwrap(opened.helper?.databaseUrl), fileUrl)
    }

    func test_openDatabase_returns_no_helper_when_the_file_fails_to_open_and_storage_falls_back_to_memory() throws {
        config.databaseName = "tealium"
        _ = try DatabaseProvider.openDatabase(config: config).connection
        let failure = injectedSQLiteError(code: SQLITE_IOERR_READ)
        let opened = try DatabaseProvider.openDatabase(config: config) { databaseUrl, logger in
            InjectedDatabaseHelper(databaseUrl: databaseUrl, logger: logger) { _ in failure }
        }
        XCTAssertTrue(isInMemory(opened.connection))
        XCTAssertNil(opened.helper)
    }

    func test_corruption_after_the_fallback_to_memory_does_not_delete_the_kept_file() throws {
        config.databaseName = "tealium"
        _ = try DatabaseProvider.openDatabase(config: config).connection
        let fileUrl = try XCTUnwrap(config.databaseUrl())
        let failure = injectedSQLiteError(code: SQLITE_IOERR_READ)
        let provider = try providerWithFailFunction { databaseUrl, logger in
            InjectedDatabaseHelper(databaseUrl: databaseUrl, logger: logger) { _ in failure }
        }
        XCTAssertTrue(try isInMemory(provider.database))
        XCTAssertThrowsError(try provider.database.execute("SELECT fail(\(SQLITE_CORRUPT))"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileUrl.path))
    }

    func test_provider_deletes_its_own_file_and_not_another_database_file() throws {
        config.databaseName = "other"
        let otherPath = try XCTUnwrap(config.databaseUrl()).path
        _ = try DatabaseProvider.openDatabase(config: config)
        config.databaseName = "tealium"
        let provider = try providerWithFailFunction()
        let ownPath = try XCTUnwrap(config.databaseUrl()).path
        XCTAssertTrue(FileManager.default.fileExists(atPath: ownPath))
        XCTAssertThrowsError(try provider.database.execute("SELECT fail(\(SQLITE_CORRUPT))"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: ownPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: otherPath))
    }

    func test_after_the_delete_the_old_connection_fails_and_a_new_provider_opens_a_new_file() throws {
        config.databaseName = "tealium"
        let databasePath = try XCTUnwrap(config.databaseUrl()).path
        let provider = try providerWithFailFunction()
        try provider.database.run("INSERT INTO module (name) VALUES ('old')")
        let corruption = try XCTUnwrapThrownError { try provider.database.execute("SELECT fail(\(SQLITE_CORRUPT))") }
        XCTAssertFalse(FileManager.default.fileExists(atPath: databasePath))
        // The connection is closed: a write on it throws the closed error, whose cause is the corruption, and leaves no file behind.
        XCTAssertConnectionClosed(try XCTUnwrapThrownError { try provider.database.run("INSERT INTO module (name) VALUES ('after')") }, causedBy: corruption)
        for file in databaseFiles(atPath: databasePath) {
            XCTAssertFalse(FileManager.default.fileExists(atPath: file), "\(file) reappeared")
        }
        let reopened = try open()
        assertRecreated(reopened.database, atPath: databasePath)
        XCTAssertEqual(reopened.errors, [])
        XCTAssertEqual(reopened.warnings, [])
    }

    func test_leftover_sidecars_without_a_database_file_are_discarded_at_open() throws {
        config.databaseName = "tealium"
        let fileUrl = try XCTUnwrap(config.databaseUrl())
        // A -wal and -shm with frames that were never checkpointed, from another database with a table of its own.
        let otherPath = fileUrl.deletingLastPathComponent().appendingPathComponent("other.sqlite3").path
        var other: Connection? = try Connection(otherPath)
        try other?.execute("PRAGMA journal_mode = WAL; CREATE TABLE leftover (value TEXT); INSERT INTO leftover VALUES ('old');")
        for suffix in ["-wal", "-shm"] {
            try FileManager.default.copyItem(atPath: otherPath + suffix, toPath: fileUrl.path + suffix)
        }
        other = nil
        XCTAssertTrue(FileManager.default.createFile(atPath: fileUrl.path + "-journal", contents: Data(repeating: 0x42, count: 4096)))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileUrl.path))
        let opened = try open()
        XCTAssertEqual(opened.errors, [])
        XCTAssertEqual(opened.warnings, [])
        assertRecreated(opened.database, atPath: fileUrl.path)
        XCTAssertFalse(opened.database.tableExists(tableName: "leftover"))
        XCTAssertEqual(try integrityCheck(ofDatabaseAt: fileUrl.path), "ok")
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileUrl.path + "-journal"))
        try opened.database.run("INSERT INTO module (name) VALUES ('new')")
        XCTAssertEqual(try opened.database.scalar("SELECT COUNT(*) FROM module") as? Int64, 1)
    }
}

// MARK: - Helpers

extension DatabaseProviderTests {
    /// The file of the `main` database, through SQL: empty for an in-memory database.
    private func filename(of database: DatabaseConnection) throws -> String {
        try XCTUnwrap(database.scalar("SELECT file FROM pragma_database_list WHERE name = 'main'") as? String)
    }

    private func isInMemory(_ database: DatabaseConnection) throws -> Bool {
        try filename(of: database).isEmpty
    }

    /// A provider opened as `init(config:helperFactory:)` does. The raw connection is not kept: the provider is its only owner.
    private func providerWithFailFunction(helperFactory: (URL, LoggerProtocol?) -> DatabaseHelper = DatabaseProvider.defaultHelperFactory) throws -> DatabaseProvider {
        let opened = try DatabaseProvider.openDatabase(config: config, helperFactory: helperFactory)
        return DatabaseProvider(connection: opened.connection.addingFailFunction(), helper: opened.helper, logger: nil)
    }
}

/// A `DatabaseHelper` whose `onCreate` fails, to exercise the provider's fallbacks.
private class FailingCreateDatabaseHelper: DatabaseHelper {
    struct CreateError: Error { }

    override func onCreate(database: Connection) throws {
        throw CreateError()
    }
}

/// A `DatabaseHelper` whose attempt to enable WAL fails with `failure`.
private class FailingWALDatabaseHelper: DatabaseHelper {
    private let failure: Error

    init(databaseUrl: URL?, logger: LoggerProtocol?, failure: Error) {
        self.failure = failure
        super.init(databaseUrl: databaseUrl, logger: logger)
    }

    override func enableWriteAheadLog(database: Connection) throws -> String? {
        throw failure
    }
}

/// A `DatabaseHelper` that fails the `onConfigure` calls `failure` picks, by their 1-based number, and counts them.
private class InjectedDatabaseHelper: DatabaseHelper {
    private(set) var configureCalls = 0
    private let failure: (Int) -> Error?

    init(databaseUrl: URL?,
         logger: LoggerProtocol?,
         removeFile: @escaping (String) throws -> Void = SQLiteOpenHelper.defaultRemoveFile,
         failure: @escaping (Int) -> Error?) {
        self.failure = failure
        super.init(databaseUrl: databaseUrl, logger: logger, removeFile: removeFile)
    }

    override func onConfigure(database: Connection) throws {
        configureCalls += 1
        if let error = failure(configureCalls) {
            throw error
        }
        try super.onConfigure(database: database)
    }
}
