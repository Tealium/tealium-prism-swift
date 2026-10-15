//
//  DatabaseHelper.swift
//  tealium-prism
//
//  Created by Tyler Rister on 12/5/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

/**
 * Concrete implementation of the `SQLiteOpenHelper` which implements the onCreate/onConfigure/onUpgrade/onDowngrade methods.
 */
class DatabaseHelper: SQLiteOpenHelper {

    /// The current version of the DB implemented in the codebase
    static let DATABASE_VERSION = 2
    /// The oldest stored version that can still be upgraded. A file below it is deleted and recreated instead.
    static let MIN_SUPPORTED_VERSION = 1

    private let upgrades: [DatabaseUpgrade]

    init(databaseUrl: URL?,
         logger: LoggerProtocol? = nil,
         version: Int = DatabaseHelper.DATABASE_VERSION,
         upgrades: [DatabaseUpgrade] = Upgrades.all,
         excludeFromBackup: @escaping (URL) throws -> Void = SQLiteOpenHelper.defaultExcludeFromBackup,
         removeFile: @escaping (String) throws -> Void = SQLiteOpenHelper.defaultRemoveFile) {
        self.upgrades = upgrades
        super.init(version: version,
                   databaseUrl: databaseUrl,
                   logger: logger,
                   excludeFromBackup: excludeFromBackup,
                   removeFile: removeFile)
    }

    override func onConfigure(database: Connection) throws {
        database.foreignKeys = true

        // Write-ahead logging. deleteDatabase() also removes the -wal, -shm and -journal.
        //
        // Never throws: DatabaseProvider would fall back to an in-memory database and lose unsent
        // events at app exit. Enabling WAL can fail, e.g. creating the -shm under Data Protection
        // before first unlock, and then the database keeps the rollback journal.
        //
        // busy_timeout first, as the WAL conversion briefly takes an exclusive lock.
        _ = try? database.execute("PRAGMA busy_timeout = 3000")
        // Lowercased: the returned casing is not contractual.
        var journalMode: String?
        var journalModeError: Error?
        do {
            journalMode = (try database.scalar("PRAGMA journal_mode = WAL") as? String)?.lowercased()
        } catch {
            journalModeError = error
        }

        if journalMode == "wal" {
            // NORMAL only under WAL: with the rollback journal it can corrupt the database on power loss.
            _ = try? database.execute("PRAGMA synchronous = NORMAL")
            // Android's framework values, for parity: the same log growth and checkpoint cadence.
            _ = try? database.execute("PRAGMA journal_size_limit = 524288")
            _ = try? database.execute("PRAGMA wal_autocheckpoint = 100")
        }

        // "memory" is the expected answer for an in-memory database.
        if journalMode != "wal" && journalMode != "memory" {
            let cause = journalModeError.map { ". Error: \($0)" } ?? ""
            logger?.error(category: LogCategory.persistence,
                          "Could not enable WAL journal mode (got \(journalMode ?? "nil")); if the database opens, it uses the rollback journal instead\(cause)")
        }
    }

    override func onCreate(database: Connection) throws {
        // Create Queue Tables
        try DispatchSchema.createTable(database: database)
        try QueueSchema.createTable(database: database)

        // Create Module Tables
        try ModuleSchema.createTable(database: database)
        try ModuleStorageSchema.createTable(database: database)

        // Create Triggers
        _ = try database.run(QueueSchema.getTriggerToRemoveProcessedDispatches())
    }

    /// Runs every registered step from `oldVersion` to `newVersion`, in order.
    ///
    /// - Throws: `UnsupportedSchemaVersionError` if `oldVersion` is below `MIN_SUPPORTED_VERSION`, or
    /// `DatabaseUpgradeError` if the steps aren't exactly one per version, in order, or if a step fails.
    /// Every error except a step failure is thrown before any step runs.
    override func onUpgrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
        guard oldVersion >= Self.MIN_SUPPORTED_VERSION else {
            throw UnsupportedSchemaVersionError.belowMinimum(stored: oldVersion)
        }
        let steps = Upgrades.since(old: oldVersion, new: newVersion, upgrades: upgrades)
        try Self.requireContiguousChain(steps, oldVersion, newVersion)
        for step in steps {
            do {
                try step.upgrade(database)
            } catch {
                throw DatabaseUpgradeError(targetVersion: step.targetVersion, underlying: error)
            }
        }
    }

    /// Throws unless the versions of `steps` are exactly `old + 1 ... new`, in order.
    ///
    /// Only called by `onUpgrade`, which only runs when `old < new`.
    private static func requireContiguousChain(_ steps: [DatabaseUpgrade], _ old: Int, _ new: Int) throws {
        let expected = old < new ? Array(old + 1 ... new) : []
        let registered = steps.map { $0.targetVersion }
        guard registered != expected else {
            return
        }
        let brokenVersion = expected.first { version in registered.filter { $0 == version }.count != 1 } ?? new
        throw DatabaseUpgradeError(targetVersion: brokenVersion,
                                   underlying: DatabaseUpgradeError.BrokenChain(old: old, new: new, expected: expected, registered: registered))
    }

    /// Rejects the downgrade with the stored and current versions, so the provider can delete and recreate the file.
    override func onDowngrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
        throw UnsupportedSchemaVersionError.newer(stored: oldVersion, current: newVersion)
    }
}
