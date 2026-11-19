//
//  DatabaseProvider+DeleteCorruptTests.swift
//  tealium-prism_Tests
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite
import SQLite3
@testable import TealiumPrism
import XCTest

/// What `DatabaseProvider.deleteCorruptDatabase` deletes and logs when called. Detecting corruption, and calling it once, are the connection's job.
final class DatabaseProviderDeleteCorruptTests: XCTestCase {
    func test_delete_corrupt_database_deletes_the_file_and_its_sidecars_and_logs_it() throws {
        for code in [SQLITE_CORRUPT, SQLITE_NOTADB, SQLITE_CORRUPT_INDEX] {
            let config = fileDatabaseConfig()
            try removeAccountFolderNowAndAtTeardown(account: config.account)
            let files = try stageDatabaseFileWithSidecars(config: config)
            let logger = MockLogger()
            let helper = try newHelper(config: config, logger: logger)
            let failure = injectedSQLiteError(code: code)
            let logged = logger.handler.messagesLogged(at: .error, in: LogCategory.persistence) {
                DatabaseProvider.deleteCorruptDatabase(helper: helper, logger: logger, error: failure)
            }
            for file in databaseFiles(atPath: files.database) {
                XCTAssertFalse(FileManager.default.fileExists(atPath: file), "\(file) was not deleted, code \(code)")
            }
            XCTAssertEqual(logged, [DatabaseCorruptionLogs.fileDeleted(path: files.database, error: failure)], "code \(code)")
        }
    }

    func test_delete_corrupt_database_logs_a_failed_delete() throws {
        struct RemoveError: Error { }
        let config = fileDatabaseConfig()
        try removeAccountFolderNowAndAtTeardown(account: config.account)
        let files = try stageDatabaseFileWithSidecars(config: config)
        let logger = MockLogger()
        let helper = try newHelper(config: config, logger: logger) { _ in throw RemoveError() }
        let failure = injectedSQLiteError(code: SQLITE_CORRUPT)
        let logged = logger.handler.messagesLogged(at: .error, in: LogCategory.persistence, whileExecuting: { DatabaseProvider.deleteCorruptDatabase(helper: helper, logger: logger, error: failure) })
        XCTAssertTrue(FileManager.default.fileExists(atPath: files.database))
        XCTAssertEqual(logged, [DatabaseCorruptionLogs.fileDeletionFailed(path: files.database, error: failure, deleteError: RemoveError())])
    }

    func test_delete_corrupt_database_in_memory_logs_it_and_deletes_nothing() {
        let logger = MockLogger()
        let failure = injectedSQLiteError(code: SQLITE_CORRUPT)
        let logged = logger.handler.messagesLogged(at: .error, in: LogCategory.persistence, whileExecuting: { DatabaseProvider.deleteCorruptDatabase(helper: nil, logger: logger, error: failure) })
        XCTAssertEqual(logged, [DatabaseCorruptionLogs.inMemory(error: failure)])
    }
}

// MARK: - Helpers

extension DatabaseProviderDeleteCorruptTests {
    /// A helper for `config`'s file that removes files with `removeFile`.
    private func newHelper(config: TealiumConfig, logger: MockLogger,
                           removeFile: @escaping (String) throws -> Void = SQLiteOpenHelper.defaultRemoveFile) throws -> DatabaseHelper {
        DatabaseHelper(databaseUrl: try XCTUnwrap(config.databaseUrl()), logger: logger, removeFile: removeFile)
    }
}
