//
//  SQLiteOpenHelper.swift
//  tealium-prism
//
//  Created by Tyler Rister on 12/5/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

/**
 * A helper class to manage database creation and version management.
 *
 * You create a subclass implementing `onCreate`, `onUpgrade` and
 * optionally `onOpen`, and this class takes care of opening the database
 * if it exists, creating it if it does not, and upgrading it as necessary.
 * Transactions are used to make sure the database is always in a sensible state.
 *
 * - Note: this class assumes monotonically increasing version numbers for upgrades.
 */
class SQLiteOpenHelper {

    /// The database file, or `nil` for an in-memory database.
    let databaseUrl: URL?
    let version: Int
    let logger: LoggerProtocol?
    private let excludeFromBackup: (URL) throws -> Void
    private let removeFile: (String) throws -> Void

    /// The file removal `deleteDatabase()` uses unless another one is injected.
    static let defaultRemoveFile: (String) throws -> Void = { try TealiumFileManager.deleteAtPath(path: $0) }

    /// The backup exclusion `getDatabase()` uses unless another one is injected.
    static let defaultExcludeFromBackup: (URL) throws -> Void = { try TealiumFileManager.setIsExcludedFromBackup(to: true, for: $0) }

    /// The files SQLite keeps next to the database, excluded from backup and deleted with it. `-journal` never exists in WAL mode.
    static let sidecarSuffixes = ["-wal", "-shm", "-journal"]

    /**
     * Creates a new `SQLiteOpenHelper`
     *
     *  - Parameters:
     *     - version: the current version of the DB, used to compare with the stored version and perform upgrades/downgrades
     *     - databaseUrl: the location of the database file, or `nil` for an in-memory database
     *     - logger: the logger used to report non-fatal problems with the database, such as a failed backup exclusion
     *     - excludeFromBackup: excludes the file at the given URL from backups, called on the database files by `getDatabase()`
     *     - removeFile: removes the file at the given path, used by `deleteDatabase()`
     */
    init(version: Int,
         databaseUrl: URL?,
         logger: LoggerProtocol? = nil,
         excludeFromBackup: @escaping (URL) throws -> Void = SQLiteOpenHelper.defaultExcludeFromBackup,
         removeFile: @escaping (String) throws -> Void = SQLiteOpenHelper.defaultRemoveFile) {
        self.version = version
        self.databaseUrl = databaseUrl
        self.logger = logger
        self.excludeFromBackup = excludeFromBackup
        self.removeFile = removeFile
    }

    /**
     * Creates a new database `Connection`, preparing it for usage.
     *
     * The returned connection will be to a disk database if there is a `databaseUrl`,
     * otherwise will be an in memory one.
     *
     * This method will prepare the database with the methods `onConfigure`,
     * `onCreate`, `onUpgrade`, `onDowngrade`, `onOpen` as necessary
     * before returning the connection.
     */
    func getDatabase() throws -> Connection {
        guard let url = databaseUrl else {
            let connection = try Connection(.inMemory)
            try prepare(database: connection)
            return connection
        }
        // Best-effort, as a failed exclusion must not cost the file. Runs after `prepare`, which creates -wal/-shm, and even when
        // opening the file or `prepare` throws, since the files stay on disk either way.
        defer { excludeExistingFilesFromBackup([url.path] + Self.sidecarSuffixes.map { url.path + $0 }) }
        let connection = try Connection(url.path)
        try prepare(database: connection)
        return connection
    }

    /// Excludes from backup every file in `paths` that exists, and logs one warning for those that fail.
    private func excludeExistingFilesFromBackup(_ paths: [String]) {
        var failures = [(file: String, error: Error)]()
        for path in paths where FileManager.default.fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path)
            do {
                try excludeFromBackup(url)
            } catch {
                failures.append((url.lastPathComponent, error))
            }
        }
        guard !failures.isEmpty else { return }
        logger?.warn(category: LogCategory.persistence,
                     "The database files could not be excluded from backup; they are used anyway and the exclusion is retried on the next launch."
                     + Self.describe(failures))
    }

    /// Lists each failed file with its error, as appended to the warnings.
    private static func describe(_ failures: [(file: String, error: Error)]) -> String {
        failures.map { " \($0.file): \($0.error)" }.joined(separator: ";")
    }

    /// Deletes the database and its sidecar files from disk, if present.
    ///
    /// A sidecar that can't be removed is logged as a warning, not thrown: SQLite discards it next to the new file.
    ///
    /// - Throws: the error removing the main file, only if it fails for any reason other than the file
    /// not existing. The main file is then still on disk, and the sidecars are left untouched.
    func deleteDatabase() throws {
        guard let path = self.databaseUrl?.path else {
            return
        }
        // The main file goes first, as removing the -wal or -journal of a database still on disk can corrupt it.
        // The same files as Android's SQLiteDatabase.deleteDatabase, except the -mj* super-journals this SDK never creates.
        // Android (Kotlin): returns a `deleted` Boolean and logs "No database file was deleted"; Swift throws only when the main file
        // stays, warns about sidecars, and has no nothing-deleted log, since the recreate path only runs right after opening the file.
        try removeIgnoringMissingFile(path)
        var sidecarFailures = [(file: String, error: Error)]()
        for suffix in Self.sidecarSuffixes {
            do {
                try removeIgnoringMissingFile(path + suffix)
            } catch {
                sidecarFailures.append((URL(fileURLWithPath: path + suffix).lastPathComponent, error))
            }
        }
        guard !sidecarFailures.isEmpty else { return }
        logger?.warn(category: LogCategory.persistence,
                     "The database file was deleted, but some of its sidecar files could not be removed; SQLite discards them next to the new file."
                     + Self.describe(sidecarFailures))
    }

    private func removeIgnoringMissingFile(_ path: String) throws {
        do {
            try removeFile(path)
        } catch let error as NSError where error.isNoSuchFile {
            return
        }
    }

    /**
     * Called when the database connection is being configured, to enable features
     * such as write-ahead logging or foreign key support.
     *
     * This method is called before `onCreate`, `onUpgrade`,
     * `onDowngrade`, or `onOpen` are called.  It should not modify
     * the database except to configure the database connection as required.
     *
     * This method should only call methods that configure the parameters of the
     * database connection, such as `Connection.foreignKeys`
     * or executing PRAGMA statements.
     *
     * - parameter database: The database.
     */
    func onConfigure(database: Connection) throws { }

    /**
     * Called when the database is created for the first time. This is where the
     * creation of tables and the initial population of the tables should happen.
     *
     * This method must create the database in the newest version available.
     * Updates won't be run on the initial database creation.
     *
     * - parameter database: The database.
     */
    func onCreate(database: Connection) throws { }

    /**
     * Called when the database needs to be upgraded. The implementation
     * should use this method to drop tables, add tables, or do anything else it
     * needs to upgrade to the new schema version.
     *
     * This method executes within a transaction. If an exception is thrown, all changes
     * will automatically be rolled back.
     *
     * - Parameters:
     *     - database: The database.
     *     - oldVersion: The old database version.
     *     - newVersion: The new database version.
     */
    func onUpgrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws { }

    /**
     * Called when the database needs to be downgraded. This is strictly similar to
     * the `onUpgrade` method, but is called whenever the current version is newer than the requested one.
     *
     * If not overridden, the default implementation will reject downgrade and
     * throw `DatabaseError.unsupportedDowngrade`.
     *
     * This method executes within a transaction.  If an exception is thrown, all changes
     * will automatically be rolled back.
     *
     * - Parameters:
     *     - database: The database.
     *     - oldVersion: The old database version.
     *     - newVersion: The new database version.
     */
    func onDowngrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
        throw DatabaseError.unsupportedDowngrade
    }

    /**
     * Called when the database has been opened.
     *
     * This method is called after the database connection has been configured
     * and after the database schema has been created, upgraded or downgraded as necessary.
     * If the database connection must be configured in some way before the schema
     * is created, upgraded, or downgraded, do it in `onConfigure` instead.
     *
     * - parameter database: The database.
     */
    func onOpen(database: Connection) throws { }

    func prepare(database: Connection) throws {
        guard version > 0 else {
            throw DatabaseError.invalidDatabaseVersion(version)
        }
        try onConfigure(database: database)
        // Not `Connection.userVersion`, whose getter turns a failed read into version 0 and so into `onCreate`.
        // `PRAGMA user_version` always returns a row, so a missing value is an error too.
        // Android (Kotlin): the platform deletes and recreates a file whose header is corrupt; Swift throws here and keeps
        // the file, falling back to memory, until MT-2271 routes corruption.
        guard let stored = try database.scalar("PRAGMA user_version") as? Int64 else {
            throw MissingUserVersionError()
        }
        let storedVersion = Int(stored)
        if storedVersion != version {
            // The connection is local to `getDatabase()` until it returns, so nothing interleaves between BEGIN and COMMIT.
            // Android (Kotlin): records `initializationFailure`, as the platform `SQLiteOpenHelper`'s `endTransaction` can mask the
            // callback's exception; Swift owns the transaction and throws the real cause directly.
            try database.run("BEGIN DEFERRED TRANSACTION")
            do {
                if storedVersion == 0 {
                    try onCreate(database: database)
                } else if storedVersion < version {
                    try onUpgrade(database: database, fromOldVersion: storedVersion, toNewVersion: version)
                } else {
                    try onDowngrade(database: database, fromOldVersion: storedVersion, toNewVersion: version)
                }
                // Not `Connection.userVersion`, whose setter ignores a failed write. Inside the transaction,
                // so a failed stamp rolls the changes back.
                try database.run("PRAGMA user_version = \(version)")
                try database.run("COMMIT TRANSACTION")
            } catch {
                // The real cause is thrown, not ROLLBACK's error. ROLLBACK usually fails because SQLite already rolled back
                // (after SQLITE_FULL or SQLITE_IOERR), and closing the connection rolls back anything still open.
                _ = try? database.run("ROLLBACK TRANSACTION")
                throw error
            }
        }
        try self.onOpen(database: database)
    }
}

/// `PRAGMA user_version` returned no integer, which SQLite never does for a readable database.
struct MissingUserVersionError: Error { }

private extension NSError {
    /// Whether this error says that the file to remove doesn't exist.
    var isNoSuchFile: Bool {
        (domain == NSCocoaErrorDomain && code == NSFileNoSuchFileError)
            || (domain == NSPOSIXErrorDomain && code == Int(ENOENT))
    }
}
