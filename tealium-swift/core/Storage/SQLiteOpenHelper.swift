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

public class SQLiteOpenHelper {

    public var databaseUrl: URL?
    public var version: Int

    var database: Connection?
    private let coreSettings: CoreSettings

    init(databaseName: String?, version: Int, coreSettings: CoreSettings) throws {
        if let databaseName = databaseName {
            let path = TealiumFileManager.getApplicationFileUrl(for: coreSettings.account ?? "default",
                                                                profile: coreSettings.profile ?? "default",
                                                                fileName: "\(databaseName).sqlite3")
            self.databaseUrl = path
        } else {
            self.databaseUrl = nil
        }
        self.version = version
        self.coreSettings = coreSettings
        do {
            try self.prepare()
        } catch DatabaseErrors.unsupportedDowgrade {
            deleteDatabase()
            try prepare()
        }
    }

    public func getDatabase() -> Connection? {
        guard let database = self.database else {
            do {
                if let url = self.databaseUrl {
                    self.database = try Connection(url.path)
                    try TealiumFileManager.setIsExcludedFromBackup(to: true, for: url)
                } else {
                    self.database = try Connection(.inMemory)
                }
            } catch {
                self.database = try? Connection(.inMemory)
            }
            return self.database
        }
        return database
    }

    public func deleteDatabase() {
        database = nil
        guard let path = self.databaseUrl?.path else {
            return
        }
        try? TealiumFileManager.deleteAtPath(path: path)
    }

    public func closeDatabase() {
        database = nil
    }

    public func onConfigure(database: Connection) throws {
    }

    public func onCreate(database: Connection) throws {
    }

    public func onDowngrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
        throw DatabaseErrors.unsupportedDowgrade
    }

    public func onOpen(database: Connection) {
    }

    public func onUpgrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
    }

    public func prepare() throws {
        guard let database = self.getDatabase() else {
            return
        }
        try database.transaction {
            try self.onConfigure(database: database)
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
