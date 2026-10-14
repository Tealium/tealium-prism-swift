//
//  DatabaseProvider.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

public protocol DatabaseProviderProtocol {
    var database: Connection { get }

    /// Folds the write-ahead log back into the main database file and waits for readers to leave it,
    /// so the next write starts again from the beginning of the `-wal` file.
    ///
    /// Has a default implementation so existing conformances (including test doubles) need not
    /// implement it, and so it is a harmless no-op when the database is not in WAL mode.
    ///
    /// - Returns: The row `wal_checkpoint` reports: `busy` is `true` when the checkpoint could not
    ///   complete because another connection still held the log, `log` is the number of frames in the
    ///   log and `checkpointed` the number folded back into the database.
    /// - Throws: The SQLite error if the pragma cannot be prepared or run.
    @discardableResult
    func checkpoint() throws -> (busy: Bool, log: Int, checkpointed: Int)
}

public extension DatabaseProviderProtocol {
    /// An optimization: folds the WAL data into the main database file at sensible points, instead of
    /// waiting for the automatic checkpoint or for the next launch to do it on open. The connection is
    /// held for the process lifetime and SQLite.swift only closes it in `deinit`, which does not run
    /// when the app is killed.
    ///
    /// Strictly durability-positive: `RESTART` moves committed frames INTO the main database and
    /// only lets the next writer restart the log once every frame is there, so nothing is discarded.
    ///
    /// `RESTART` rather than `TRUNCATE`, for parity with Android. The `-wal` file is kept at its
    /// working size and overwritten from the start by the next writer, which is cheaper than
    /// growing it again from zero. It stays bounded: `journal_size_limit` cuts it back to the limit
    /// at that next reset.
    @discardableResult
    func checkpoint() throws -> (busy: Bool, log: Int, checkpointed: Int) {
        // Same as SQLite.swift's `walCheckpoint()` helper, which would replace this, but it is only
        // on master; the latest tagged release does not have it and the pod pins ~> 0.15.0.
        let statement = try database.prepare("PRAGMA wal_checkpoint(RESTART)")
        _ = try statement.step()
        let busy: Int64 = statement.row[0]
        let log: Int64 = statement.row[1]
        let checkpointed: Int64 = statement.row[2]
        return (busy != 0, Int(log), Int(checkpointed))
    }
}

public class DatabaseProvider: DatabaseProviderProtocol {
    public let database: Connection

    static let defaultHelperFactory: (URL, LoggerProtocol?) -> DatabaseHelper = { DatabaseHelper(databaseUrl: $0, logger: $1) }

    init(config: TealiumConfig,
         logger: LoggerProtocol? = nil,
         helperFactory: (URL, LoggerProtocol?) -> DatabaseHelper = DatabaseProvider.defaultHelperFactory) throws {
        database = try Self.openDatabase(config: config, logger: logger, helperFactory: helperFactory)
    }

    /// Opens the database file configured in `config`, or an in-memory database when there is no `databaseName`.
    ///
    /// Every failure to use the file is logged and falls back to an in-memory database for this session.
    ///
    /// - Throws: Only if the in-memory database cannot be opened either.
    static func openDatabase(config: TealiumConfig,
                             logger: LoggerProtocol? = nil,
                             helperFactory: (URL, LoggerProtocol?) -> DatabaseHelper = DatabaseProvider.defaultHelperFactory) throws -> Connection {
        guard let databaseName = config.databaseName else {
            return try getInMemoryDatabase(logger: logger)
        }
        let helper: DatabaseHelper
        do {
            helper = helperFactory(try databaseUrl(for: config, databaseName: databaseName), logger)
        } catch {
            return try fallBackToMemory(because: "the database file location could not be created",
                                        fileKept: false, error: error, logger: logger)
        }
        do {
            return try helper.getDatabase()
        } catch let unsupported as UnsupportedSchemaVersionError {
            let reason: String
            switch unsupported {
            case let .newer(stored, current):
                reason = "its version \(stored) is newer than this SDK's version \(current)"
            case let .belowMinimum(stored):
                reason = "its version \(stored) is below the minimum supported version \(DatabaseHelper.MIN_SUPPORTED_VERSION)"
            }
            return try recreateDatabase(helper: helper, logger: logger, reason: reason)
        } catch let upgrade as DatabaseUpgradeError {
            return try fallBackToMemory(because: "the upgrade to version \(upgrade.targetVersion) failed",
                                        fileKept: true, error: upgrade.underlying, logger: logger)
        } catch {
            // Android (Kotlin): an SQLException or an upgrade step's exception falls back to memory, keeping the file; any other exception
            // (e.g. the platform helper's IllegalStateException when misused) propagates and fails init. Here everything an open can throw
            // is a storage error (SQLite.swift's or the SDK's own; programming errors crash), so it falls back to memory, keeping the file.
            return try fallBackToMemory(because: "the database file could not be opened",
                                        fileKept: true, error: error, logger: logger)
        }
    }

    /// The file for `databaseName` in `config`'s account and profile folder, creating the folder if needed.
    static func databaseUrl(for config: TealiumConfig, databaseName: String) throws -> URL {
        try TealiumFileManager.getApplicationFileUrl(for: config.account,
                                                     profile: config.profile,
                                                     fileName: "\(databaseName).sqlite3")
    }

    /// Deletes the database file and opens a new one, falling back to memory if either fails.
    private static func recreateDatabase(helper: DatabaseHelper, logger: LoggerProtocol?, reason: String) throws -> Connection {
        logger?.error(category: LogCategory.persistence,
                      "Deleting and recreating the database file because \(reason). Data in it is lost.")
        do {
            try helper.deleteDatabase()
        } catch {
            // The main file is still there, so a reopen would fail again today, and after MT-2271 could succeed on a corrupt file,
            // since opening only reads the header.
            // Android (Kotlin): reopens instead. There, a delete that finds nothing usually means Android already deleted the corrupt
            // file itself, so the reopen creates a fresh one.
            return try fallBackToMemory(because: "the database file could not be deleted", fileKept: true, error: error, logger: logger)
        }
        do {
            return try helper.getDatabase()
        } catch {
            return try fallBackToMemory(because: "the recreated database file could not be opened", fileKept: false, error: error, logger: logger)
        }
    }

    /// Logs why storage falls back to memory, and returns the in-memory database.
    private static func fallBackToMemory(because reason: String, fileKept: Bool, error: Error, logger: LoggerProtocol?) throws -> Connection {
        logger?.error(category: LogCategory.persistence,
                      "Using in-memory storage for this session because \(reason)."
                      + (fileKept ? " The database file is kept." : "")
                      + " Nothing stored will survive this process. Error: \(error)")
        return try getInMemoryDatabase(logger: logger)
    }

    static func getInMemoryDatabase(logger: LoggerProtocol? = nil) throws -> Connection {
        let helper = DatabaseHelper(databaseUrl: nil, logger: logger)
        return try helper.getDatabase()
    }
}
