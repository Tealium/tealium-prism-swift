//
//  SQLiteOpenHelper.swift
//  tealium-swift
//
//  Created by Tyler Rister on 12/5/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite
import SQLite3

/**
 * An abstract class that is used to open a Database connection but defers all creation/configuration/upgrade/downgrade to it's sub class.
 */
class SQLiteOpenHelper {

    let databaseUrl: URL?
    let version: Int

    /**
     * Creates a new `SQLiteOpenHelper`
     *
     *  - Parameters:
     *     - databaseName: the name of the database used to store the file to disk. Nil for in memory DB.
     *     - version: the current version of the DB, used to compare with the stored version and perform upgrades/downgrades
     *     - config: the configuration used to get the correct DB for account/profile
     */
    init(databaseName: String?, version: Int, config: TealiumConfig) {
        if let databaseName = databaseName {
            databaseUrl = TealiumFileManager.getApplicationFileUrl(for: config.account,
                                                                   profile: config.profile,
                                                                   fileName: "\(databaseName).sqlite3")
        } else {
            databaseUrl = nil
        }
        self.version = version
    }

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

    func deleteDatabase() {
        guard let path = self.databaseUrl?.path else {
            return
        }
        try? TealiumFileManager.deleteAtPath(path: path)
    }

    func onConfigure(database: Connection) throws {
    }

    func onCreate(database: Connection) throws {
    }

    func onDowngrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
    }

    func onOpen(database: Connection) {
    }

    func onUpgrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
    }

    func prepare(database: Connection) throws {
        try self.onConfigure(database: database)
        try database.transaction {
            var currentVersion: Int = Int(database.userVersion ?? 0)
            if currentVersion == 0 {
                try self.onCreate(database: database)
                database.userVersion = UserVersion(1)
                currentVersion = 1
            }
            if currentVersion > 0 {
                if currentVersion < self.version {
                    try self.onUpgrade(database: database, fromOldVersion: currentVersion, toNewVersion: self.version)
                } else if currentVersion > self.version {
                    try self.onDowngrade(database: database, fromOldVersion: currentVersion, toNewVersion: self.version)
                }
            }

            if currentVersion != self.version {
                database.userVersion = UserVersion(self.version)
            }

            self.onOpen(database: database)
        }
    }
}
