//
//  DatabaseProvider.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

protocol DatabaseProviderProtocol {
    var database: DatabaseConnection { get }
}

class DatabaseProvider: DatabaseProviderProtocol {
    /// The connection every repository shares. It holds the only reference to the raw `Connection`.
    let database: DatabaseConnection

    static let defaultHelperFactory: (URL, LoggerProtocol?) -> DatabaseHelper = { DatabaseHelper(databaseUrl: $0, logger: $1) }

    convenience init(config: TealiumConfig,
                     logger: LoggerProtocol? = nil,
                     helperFactory: (URL, LoggerProtocol?) -> DatabaseHelper = DatabaseProvider.defaultHelperFactory) throws {
        let (connection, helper) = try Self.openDatabase(config: config, logger: logger, helperFactory: helperFactory)
        self.init(connection: connection, helper: helper, logger: logger)
    }

    /// Wraps a connection `openDatabase` already opened, with the `helper` that deletes its file if it is found corrupt later (`nil` for
    /// an in-memory database).
    init(connection: Connection, helper: SQLiteOpenHelper?, logger: LoggerProtocol?) {
        database = DatabaseConnection(connection: connection,
                                      onCorruption: { DatabaseProvider.deleteCorruptDatabase(helper: helper, logger: logger, error: $0) })
    }

    /// Opens the database file configured in `config`, or an in-memory database when there is no `databaseName`.
    ///
    /// Every failure to use the file is logged. A corrupt or unsupported file is deleted and recreated once; any other failure
    /// falls back to an in-memory database for this session.
    ///
    /// - Returns: The connection, and the helper that opened its file, to delete it if it is found corrupt later. The helper is `nil` for an
    ///   in-memory database, whether asked for or a fallback, as it has no file of its own to delete.
    /// - Throws: Only if the in-memory database cannot be opened either.
    static func openDatabase(config: TealiumConfig,
                             logger: LoggerProtocol? = nil,
                             helperFactory: (URL, LoggerProtocol?) -> DatabaseHelper = DatabaseProvider.defaultHelperFactory) throws -> (connection: Connection, helper: DatabaseHelper?) {
        guard let databaseName = config.databaseName else {
            return (try getInMemoryDatabase(logger: logger), nil)
        }
        let helper: DatabaseHelper
        do {
            helper = helperFactory(try databaseUrl(for: config, databaseName: databaseName), logger)
        } catch {
            return try fallBackToMemory(because: "the database file location could not be created",
                                        fileKept: false, error: error, logger: logger)
        }
        do {
            return (try helper.getDatabase(), helper)
        } catch {
            // Before the failure type: an upgrade step that hit a corrupt page has nothing to upgrade, so the file is recreated, not kept.
            // Nothing here holds the failed connection or statement, so the file can be deleted: `getDatabase()` released the connection
            // when it threw, and the error carries no statement.
            if let code = DatabaseHelper.corruptionCode(error) {
                let reason = if let upgrade = error as? DatabaseUpgradeError {
                    "the upgrade to version \(upgrade.targetVersion) hit a corrupt file (SQLite code \(code))"
                } else {
                    "it is corrupt (SQLite code \(code))"
                }
                return try recreateDatabase(helper: helper, logger: logger, reason: reason)
            }
            switch error {
            case let unsupported as UnsupportedSchemaVersionError:
                let reason = switch unsupported {
                case let .newer(stored, current):
                    "its version \(stored) is newer than this SDK's version \(current)"
                case let .belowMinimum(stored):
                    "its version \(stored) is below the minimum supported version \(DatabaseHelper.MIN_SUPPORTED_VERSION)"
                }
                return try recreateDatabase(helper: helper, logger: logger, reason: reason)
            case let upgrade as DatabaseUpgradeError:
                return try fallBackToMemory(because: "the upgrade to version \(upgrade.targetVersion) failed",
                                            fileKept: true, error: upgrade.underlying, logger: logger)
            default:
                // Every other open failure is a storage error, SQLite.swift's or the SDK's own, as in Kotlin's `SQLException` branch.
                // Android (Kotlin): also rethrows any other exception, e.g. the platform helper's IllegalStateException when misused; Swift
                // has no such errors to rethrow, as programming errors crash instead of throwing.
                return try fallBackToMemory(because: "the database file could not be opened",
                                            fileKept: true, error: error, logger: logger)
            }
        }
    }

    /// The file for `databaseName` in `config`'s account and profile folder, creating the folder if needed.
    static func databaseUrl(for config: TealiumConfig, databaseName: String) throws -> URL {
        try TealiumFileManager.getApplicationFileUrl(for: config.account,
                                                     profile: config.profile,
                                                     fileName: "\(databaseName).sqlite3")
    }

    /// Deletes the database file and opens a new one, falling back to memory if either fails.
    private static func recreateDatabase(helper: DatabaseHelper, logger: LoggerProtocol?, reason: String) throws -> (connection: Connection, helper: DatabaseHelper?) {
        logger?.error(category: LogCategory.persistence,
                      "Deleting and recreating the database file because \(reason). Data in it is lost.")
        do {
            try helper.deleteDatabase()
        } catch {
            // The main file is still there, so a reopen would fail again, or succeed on a corrupt file, since the open reads only
            // the header and the schema.
            // Android (Kotlin): reopens instead. There, a delete that finds nothing usually means Android already deleted the corrupt
            // file itself, so the reopen creates a fresh one.
            return try fallBackToMemory(because: "the database file could not be deleted", fileKept: true, error: error, logger: logger)
        }
        do {
            return (try helper.getDatabase(), helper)
        } catch {
            return try fallBackToMemory(because: "the recreated database file could not be opened", fileKept: false, error: error, logger: logger)
        }
    }

    /// Deletes the database file and its sidecars, and logs the outcome. An in-memory database (no `helper`, or one without `databaseUrl`) has no file: it is only logged.
    /// `DatabaseConnection` calls it once, after it released the connection.
    ///
    /// - Parameter error: The first corruption error a statement threw, for the log.
    static func deleteCorruptDatabase(helper: SQLiteOpenHelper?, logger: LoggerProtocol?, error: Error) {
        guard let helper, let path = helper.databaseUrl?.path else {
            logger?.error(category: LogCategory.persistence,
                          "Database corruption detected in ':memory:'. There is no file to delete; data in it is lost. "
                          + "Storage is unavailable for this Tealium instance. Error: \(error)")
            return
        }
        do {
            try helper.deleteDatabase()
        } catch let deleteError {
            logger?.error(category: LogCategory.persistence,
                          "Database corruption detected in '\(path)'. The file could not be deleted, so it stays as it is. "
                          + "Storage is unavailable for this Tealium instance; a new instance opens the same file, and deletes it if a statement "
                          + "finds it corrupt again. Error: \(error). Delete error: \(deleteError)")
            return
        }
        logger?.error(category: LogCategory.persistence,
                      "Database corruption detected in '\(path)'. The file was deleted; data in it is lost. "
                      + "Storage is unavailable for this Tealium instance; a new instance creates a new file. Error: \(error)")
    }

    /// Logs why storage falls back to memory, and returns the in-memory database.
    private static func fallBackToMemory(because reason: String, fileKept: Bool, error: Error, logger: LoggerProtocol?) throws -> (connection: Connection, helper: DatabaseHelper?) {
        logger?.error(category: LogCategory.persistence,
                      "Using in-memory storage for this session because \(reason)."
                      + (fileKept ? " The database file is kept." : "")
                      + " Nothing stored will survive this process. Error: \(error)")
        return (try getInMemoryDatabase(logger: logger), nil)
    }

    static func getInMemoryDatabase(logger: LoggerProtocol? = nil) throws -> Connection {
        let helper = DatabaseHelper(databaseUrl: nil, logger: logger)
        return try helper.getDatabase()
    }
}
