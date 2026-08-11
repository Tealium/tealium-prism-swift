//
//  SQLiteOpenHelper.swift
//  tealium-prism
//
//  Created by Tyler Rister on 12/5/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite
import SQLite3

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

    let databaseUrl: URL?
    let version: Int

    /**
     * Creates a new `SQLiteOpenHelper`
     *
     *  - Parameters:
     *     - version: the current version of the DB, used to compare with the stored version and perform upgrades/downgrades
     *     - config: the configuration used to get the correct DB for account/profile
     */
    init(version: Int, config: TealiumConfig?) {
        self.version = version
        guard let config,
              let databaseName = config.databaseName else {
            databaseUrl = nil
            return
        }
        databaseUrl = TealiumFileManager.getApplicationFileUrl(for: config.account,
                                                               profile: config.profile,
                                                               fileName: "\(databaseName).sqlite3")
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
        let connection: Connection
        if let url = self.databaseUrl {
            connection = try Connection(url.path)
            try TealiumFileManager.setIsExcludedFromBackup(to: true, for: url)
        } else {
            connection = try Connection(.inMemory)
        }
        try prepare(database: connection)
        return connection
    }

    /// Deletes the database from disk, if present.
    func deleteDatabase() {
        guard let path = self.databaseUrl?.path else {
            return
        }
        try? TealiumFileManager.deleteAtPath(path: path)
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
        let storedVersion: Int = Int(database.userVersion ?? 0)
        if storedVersion != version {
            try database.transaction {
                if storedVersion == 0 {
                    try onCreate(database: database)
                } else {
                    if storedVersion < version {
                        try onUpgrade(database: database,
                                      fromOldVersion: storedVersion,
                                      toNewVersion: version)
                    } else if storedVersion > version {
                        try onDowngrade(database: database,
                                        fromOldVersion: storedVersion,
                                        toNewVersion: version)
                    }
                }
                database.userVersion = UserVersion(version)
            }
        }
        try self.onOpen(database: database)
    }
}
