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

        // Write-ahead logging instead of SQLite's default rollback journal.
        //
        // In the default DELETE/FULL configuration every commit costs a flat ~45KB of disk
        // writes regardless of payload — journal create, journal write, journal fsync, db
        // write, db fsync, journal unlink — so writing a few hundred bytes of module names
        // still costs 45KB. WAL appends to a log and, with synchronous=NORMAL, skips the
        // per-commit fsync.
        //
        // `synchronous=NORMAL` under WAL can only lose the most recent commit(s) on an OS
        // crash or power loss — never on app termination, where the WAL survives and is
        // replayed on next open. That is a strictly smaller exposure than the queue already
        // has when the process is killed with events in flight.
        //
        // NOTE: `deleteDatabase()` also removes the -wal, -shm and -journal sidecars; see the comment there.
        //
        // NON-THROWING BY DESIGN. A throw out of onConfigure propagates through
        // SQLiteOpenHelper.prepare() to DatabaseProvider.openDatabase, whose
        // catch-all then makes init fall back to an IN-MEMORY database. The fallback is logged, but
        // the SDK would keep running on a process-lifetime queue and lose every unsent event at app exit.
        //
        // That is reachable in production: enabling WAL must create the -shm file, which can fail
        // with SQLITE_CANTOPEN under Data Protection on a background launch before first unlock.
        // Failing to enable WAL costs us a disk optimisation; losing the queue breaks the
        // delivery guarantee. So degrade to the rollback journal rather than propagate.
        //
        // busy_timeout is set FIRST because the WAL conversion briefly takes an exclusive lock and
        // can return SQLITE_BUSY — it should benefit from the timeout rather than precede it.
        _ = try? database.execute("PRAGMA busy_timeout = 3000")
        // Lowercased defensively: the returned casing is not contractual, and a mismatch here
        // would silently disable WAL's pragmas while logging a spurious error.
        var journalMode: String?
        var journalModeError: Error?
        do {
            journalMode = (try database.scalar("PRAGMA journal_mode = WAL") as? String)?.lowercased()
        } catch {
            journalModeError = error
        }

        if journalMode == "wal" {
            // ONLY under WAL. `synchronous=NORMAL` is safe here because the log is append-only and
            // committed frames survive a process kill. In the rollback journal it is NOT equivalent:
            // the journal may not be fully synced before the database pages are overwritten, which
            // risks a CORRUPT database on power loss, not merely a lost commit. So if the WAL
            // conversion failed we must leave `synchronous` at its default FULL — degrading to a
            // slower journal is the intended fallback; degrading durability is not.
            _ = try? database.execute("PRAGMA synchronous = NORMAL")
            // Android's framework values, adopted here for parity: AOSP applies a 512KB
            // journal_size_limit and a 100-page wal_autocheckpoint to every connection it opens, so
            // matching them gives the same log growth and the same checkpoint cadence on both SDKs
            // for the same event stream.
            //
            // They replace numbers that only restated Apple's compiled defaults. libsqlite3 is
            // built with SQLITE_DEFAULT_JOURNAL_SIZE_LIMIT=32768 and SQLITE_DEFAULT_WAL_SYNCHRONOUS=1,
            // so the previous 32768 limit and the NORMAL line above are what a fresh connection
            // already reads. The branch still matters: it keeps NORMAL off a rollback journal.
            //
            // The two work as a pair. journal_size_limit does not bound growth, it truncates the
            // file back to the limit at the next WAL reset; wal_autocheckpoint is what bounds growth
            // in between. 100 pages of frames is ~412KB, just under the 512KB limit, so the log
            // settles around there instead of the 4MB a 100-event burst reached under Apple's
            // 1000-page default.
            //
            // Both are meaningless outside WAL, so they belong in this branch too.
            _ = try? database.execute("PRAGMA journal_size_limit = 524288")
            _ = try? database.execute("PRAGMA wal_autocheckpoint = 100")
        }

        // "memory" is the expected answer for an in-memory database, so both are healthy.
        //
        // Silent degradation is the thing worth avoiding: the SDK keeps working correctly, just
        // with slower writes.
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
